#include "CotForwarder.h"

#include "Vehicle.h"
#include <climits>
#include "MultiVehicleManager.h"
#include "QmlObjectListModel.h"
#include "FactGroup.h"
#include "Fact.h"
#include "VehicleLinkManager.h"
#include "VehicleGPSFactGroup.h"

#include <QDateTime>
#include <QDebug>
#include <QNetworkInterface>
#include <QGeoCoordinate>
#include <QtMath>

namespace {
constexpr const char* kBridgeVersion = "0.3.0";
/// ჩეჭდილ კლიენტის ზღვარ: ~1 Hz × ~400 B × N დრონი → 256 KiB = წუთებ ჩეჭდება.
constexpr qint64 kMaxClientBacklogBytes = 256 * 1024;

/// true მხოლოდ loopback / RFC1918 private / link-local (169.254/16) IPv4-ზე.
/// IPv4-mapped IPv6 (::ffff:a.b.c.d) ასევე სწორად იკითხება (toIPv4Address).
bool isLocalNetworkPeer(const QHostAddress& addr)
{
    bool ok = false;
    const quint32 ip = addr.toIPv4Address(&ok);
    if (!ok) {
        return false;
    }
    const quint8 a = (ip >> 24) & 0xFF;
    const quint8 b = (ip >> 16) & 0xFF;
    return a == 127                              // 127.0.0.0/8
        || a == 10                               // 10.0.0.0/8
        || (a == 172 && b >= 16 && b <= 31)      // 172.16.0.0/12
        || (a == 192 && b == 168)                // 192.168.0.0/16
        || (a == 169 && b == 254);               // 169.254.0.0/16
}
}

CotForwarder::CotForwarder(QObject* parent)
    : QObject(parent)
{
    _timer.setInterval(1000);
    connect(&_timer, &QTimer::timeout, this, &CotForwarder::_tick);
    connect(&_tcpServer, &QTcpServer::newConnection, this, &CotForwarder::_onNewTcpConnection);
}

CotForwarder::~CotForwarder()
{
    setEnabled(false);
}

void CotForwarder::setEnabled(bool enabled)
{
    if (_enabled == enabled) {
        return;
    }
    _enabled = enabled;
    if (enabled) {
        // setMulticastInterface() bound socket-ს ითხოვს (თორემ ჩუმად იგნორირდება)
        if (_udp.state() != QAbstractSocket::BoundState) {
            _udp.bind(QHostAddress::AnyIPv4, 0, QAbstractSocket::ShareAddress);
        }
        _udp.setSocketOption(QAbstractSocket::MulticastTtlOption, 1);
        (void)_listenTcp();
        _timer.start(qMax(50, int(1000.0 / qMax(0.1, _rateHz))));
        _prevActiveSysids.clear();
        emit statusChanged(QStringLiteral("DHGM forwarding ჩართული"));
    } else {
        _timer.stop();
        const QList<QTcpSocket*> clients = _tcpClients;
        _tcpClients.clear();  // _onTcpDisconnected-ის removeAll no-op-ია
        for (QTcpSocket* c : clients) {
            c->disconnect(this);
            c->abort();
            c->deleteLater();
        }
        if (_tcpServer.isListening()) {
            _tcpServer.close();
        }
        _prevActiveSysids.clear();
        emit statusChanged(QStringLiteral("DHGM forwarding გამორთული"));
    }
}

void CotForwarder::setCotMulticast(const QString& hostPort)
{
    const int colon = hostPort.lastIndexOf(':');
    if (colon > 0) {
        _cotAddr = QHostAddress(hostPort.left(colon));
        _cotPort = quint16(hostPort.mid(colon + 1).toUInt());
    }
}

void CotForwarder::setPluginTcpPort(quint16 port)
{
    if (port == _tcpPort && (_tcpServer.isListening() || !_enabled)) {
        return;
    }
    _tcpPort = port;
    if (_tcpServer.isListening()) {
        _tcpServer.close();  // port შეიცვალა → ახალ port-ზე re-listen
    }
    if (_enabled) {
        (void)_listenTcp();
    }
}

bool CotForwarder::_listenTcp()
{
    if (_tcpPort == 0 || _tcpServer.isListening()) {
        return _tcpServer.isListening();
    }
    // 0.0.0.0 — ტელეფონი/plugin ქსელიდანაც წვდება (Python bridge-ის იგივე)
    if (!_tcpServer.listen(QHostAddress::AnyIPv4, _tcpPort)) {
        const QString err = QStringLiteral("DHGM: TCP :%1 listen ვერ მოხერხდა — %2")
                                .arg(_tcpPort).arg(_tcpServer.errorString());
        qWarning() << err;
        emit statusChanged(err);
        return false;
    }
    return true;
}

QString CotForwarder::_jsonEscape(const QString& s)
{
    QString out;
    out.reserve(s.size());
    for (const QChar ch : s) {
        switch (ch.unicode()) {
        case '"':  out += QStringLiteral("\\\""); break;
        case '\\': out += QStringLiteral("\\\\"); break;
        case '\n': out += QStringLiteral("\\n"); break;
        case '\r': out += QStringLiteral("\\r"); break;
        case '\t': out += QStringLiteral("\\t"); break;
        default:
            if (ch.unicode() < 0x20) {
                out += QStringLiteral("\\u%1").arg(int(ch.unicode()), 4, 16, QChar('0'));
            } else {
                out += ch;
            }
        }
    }
    return out;
}

void CotForwarder::setRateHz(double hz)
{
    _rateHz = qMax(0.1, hz);
    if (_timer.isActive()) {
        _timer.setInterval(qMax(50, int(1000.0 / _rateHz)));
    }
}

void CotForwarder::setStaleSeconds(double s) { _staleS = qMax(1.0, s); }

QString CotForwarder::_cotTime(qint64 ms)
{
    const QDateTime dt = QDateTime::fromMSecsSinceEpoch(ms, Qt::UTC);
    return dt.toString(QStringLiteral("yyyy-MM-ddTHH:mm:ss"))
            + QStringLiteral(".%1Z").arg(dt.time().msec() / 10, 2, 10, QChar('0'));
}

static double vfg(Vehicle* v, const QString& name, double dflt)
{
    FactGroup* fg = v ? v->vehicleFactGroup() : nullptr;
    Fact* f = fg ? fg->getFact(name) : nullptr;
    return (f && f->rawValue().isValid()) ? f->rawValue().toDouble() : dflt;
}

static Fact* gpsFact(Vehicle* v, const char* name)
{
    if (!v) {
        return nullptr;
    }
    FactGroup* gps = v->gpsFactGroup();
    return gps ? gps->getFact(QString::fromUtf8(name)) : nullptr;
}

static double batteryPct(Vehicle* v)
{
    QmlObjectListModel* batts = v->batteries();
    if (!batts || batts->count() == 0) {
        return -1.0;
    }
    FactGroup* bg = qobject_cast<FactGroup*>(batts->get(0));
    if (!bg) {
        return -1.0;
    }
    Fact* pct = bg->getFact(QStringLiteral("percentRemaining"));
    return (pct && pct->rawValue().isValid()) ? pct->rawValue().toDouble() : -1.0;
}

QString CotForwarder::_gpsFixName(int fixType)
{
    switch (fixType) {
    case 0:
    case 1: return QStringLiteral("NO");
    case 2: return QStringLiteral("2D");
    case 3: return QStringLiteral("3D");
    case 4: return QStringLiteral("DGPS");
    case 5:
    case 6: return QStringLiteral("RTK");
    default: return QStringLiteral("UNKNOWN");
    }
}

double CotForwarder::_courseDeg(Vehicle* v)
{
    const double hdg = vfg(v, QStringLiteral("heading"), qQNaN());
    if (qIsFinite(hdg)) {
        return hdg;
    }
    Fact* cog = gpsFact(v, "courseOverGround");
    if (cog && cog->rawValue().isValid()) {
        return cog->rawValue().toDouble();
    }
    return 0.0;
}

int CotForwarder::_rssiDbm(Vehicle* v)
{
    const int rssi = v->telemetryLRSSI();
    // QGC: 0 = unknown; plugin-ში dBm ვაჩვენებთ მხოლოდ როცა მოდის
    if (rssi == 0) {
        return INT_MIN;
    }
    return rssi;
}

int CotForwarder::_rcRssiPct(Vehicle* v)
{
    // QGC: 0..100 % (low-pass filtered), 255 = invalid/unknown
    const int rc = v ? v->rcRSSI() : 255;
    return (rc >= 0 && rc <= 100) ? rc : -1;
}

bool CotForwarder::_vehicleActive(Vehicle* v, qint64 /*nowMs*/) const
{
    if (!v || !v->coordinate().isValid()) {
        return false;
    }
    // fix-ის გარეშე autopilot-ებ lat=lon=0 აგზავნიან → Null Island-ზე მარკერი
    if (qFuzzyIsNull(v->coordinate().latitude()) && qFuzzyIsNull(v->coordinate().longitude())) {
        return false;
    }
    VehicleLinkManager* lm = v->vehicleLinkManager();
    if (lm && lm->communicationLost()) {
        return false;
    }
    return true;
}

QByteArray CotForwarder::_buildCot(Vehicle* v, qint64 nowMs) const
{
    const QGeoCoordinate c = v->coordinate();
    const QString uid = QStringLiteral("DHGM.%1").arg(v->id());
    const QString callsign = QStringLiteral("%1-%2").arg(_prefix).arg(v->id());
    const double hae = vfg(v, QStringLiteral("altitudeAMSL"), 0.0);
    const double agl = vfg(v, QStringLiteral("altitudeRelative"), 0.0);
    const double spd = vfg(v, QStringLiteral("groundSpeed"), 0.0);
    const double hdg = _courseDeg(v);
    const double bat = batteryPct(v);

    QString remarks = QStringLiteral("ALT %1 m AGL | SPD %2 m/s")
            .arg(agl, 0, 'f', 0).arg(spd, 0, 'f', 1);
    if (bat >= 0) {
        remarks += QStringLiteral(" | BAT %1%").arg(int(bat));
    }

    const QString xml = QStringLiteral(
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
        "<event version=\"2.0\" uid=\"%1\" type=\"a-f-A-M-F-Q\" how=\"m-g\" time=\"%2\" start=\"%2\" stale=\"%3\">"
        "<point lat=\"%4\" lon=\"%5\" hae=\"%6\" ce=\"10.0\" le=\"10.0\"/>"
        "<detail><contact callsign=\"%7\"/><track speed=\"%8\" course=\"%9\"/>"
        "<precisionlocation geopointsrc=\"GPS\" altsrc=\"GPS\"/><remarks>%10</remarks></detail>"
        "</event>")
        .arg(uid, _cotTime(nowMs), _cotTime(nowMs + qint64(_staleS * 1000)))
        .arg(c.latitude(), 0, 'f', 7).arg(c.longitude(), 0, 'f', 7).arg(hae, 0, 'f', 1)
        .arg(callsign.toHtmlEscaped()).arg(spd, 0, 'f', 2).arg(hdg, 0, 'f', 1).arg(remarks.toHtmlEscaped());
    return xml.toUtf8();
}

QByteArray CotForwarder::_buildJson(Vehicle* v, qint64 nowMs) const
{
    const QGeoCoordinate c = v->coordinate();
    const double bat = batteryPct(v);
    const double course = _courseDeg(v);

    Fact* lock = gpsFact(v, "lock");
    const int fixType = (lock && lock->rawValue().isValid()) ? lock->rawValue().toInt() : 0;
    Fact* sats = gpsFact(v, "count");
    const int satCount = (sats && sats->rawValue().isValid()) ? sats->rawValue().toInt() : -1;
    const int rssi = _rssiDbm(v);
    const int rcPct = _rcRssiPct(v);

    QString j = QStringLiteral(
        "{\"type\":\"telemetry\",\"ts\":%1,\"sysid\":%2,\"callsign\":\"%3-%2\","
        "\"lat\":%4,\"lon\":%5,\"speed_mps\":%6,\"course_deg\":%7,"
        "\"alt_agl_m\":%8,\"alt_msl_m\":%9,\"flight_mode\":\"%10\",\"gps_fix\":\"%11\"")
        .arg(nowMs / 1000.0, 0, 'f', 3).arg(v->id()).arg(_prefix)
        .arg(c.latitude(), 0, 'f', 7).arg(c.longitude(), 0, 'f', 7)
        .arg(vfg(v, QStringLiteral("groundSpeed"), 0.0), 0, 'f', 2)
        .arg(course, 0, 'f', 1)
        .arg(vfg(v, QStringLiteral("altitudeRelative"), 0.0), 0, 'f', 1)
        .arg(vfg(v, QStringLiteral("altitudeAMSL"), 0.0), 0, 'f', 1)
        .arg(_jsonEscape(v->flightMode())).arg(_gpsFixName(fixType));
    if (bat >= 0) {
        j += QStringLiteral(",\"battery_pct\":%1").arg(int(bat));
    }
    if (satCount >= 0) {
        j += QStringLiteral(",\"satellites\":%1").arg(satCount);
    }
    if (rssi != INT_MIN) {
        j += QStringLiteral(",\"rssi_dbm\":%1").arg(rssi);
    }
    if (rcPct >= 0) {
        j += QStringLiteral(",\"rc_rssi_pct\":%1").arg(rcPct);
    }
    j += QStringLiteral("}\n");
    return j.toUtf8();
}

void CotForwarder::_sendCot(const QByteArray& xml)
{
    _sendCotMulticast(xml);
    _sendCotUnicast(xml);
}

/// multicast ყოველ up/multicast-capable IPv4 ინტერფეისზე: default route შეიძლება
/// VPN-ზე ან virtual NIC-ზე გადიოდეს და Wi-Fi-ზე მყოფ ტაბლეტამდე არ აღწევდეს.
void CotForwarder::_sendCotMulticast(const QByteArray& xml)
{
    int sent = 0;
    const QList<QNetworkInterface> ifaces = QNetworkInterface::allInterfaces();
    for (const QNetworkInterface& iface : ifaces) {
        const QNetworkInterface::InterfaceFlags f = iface.flags();
        if (!f.testFlag(QNetworkInterface::IsUp)
                || !f.testFlag(QNetworkInterface::IsRunning)
                || !f.testFlag(QNetworkInterface::CanMulticast)
                || f.testFlag(QNetworkInterface::IsLoopBack)) {
            continue;
        }
        bool hasIPv4 = false;
        for (const QNetworkAddressEntry& e : iface.addressEntries()) {
            if (e.ip().protocol() == QAbstractSocket::IPv4Protocol) {
                hasIPv4 = true;
                break;
            }
        }
        if (!hasIPv4) {
            continue;
        }
        _udp.setMulticastInterface(iface);
        if (_udp.writeDatagram(xml, _cotAddr, _cotPort) > 0) {
            ++sent;
        }
    }
    if (sent == 0) {
        // fallback: OS-ის default route
        _udp.setMulticastInterface(QNetworkInterface());
        _udp.writeDatagram(xml, _cotAddr, _cotPort);
    }
}

/// unicast პანელის კლიენტებზე (:4242) — multicast-ის მფილტრავ ქსელებზე ეს მუშაობს.
void CotForwarder::_sendCotUnicast(const QByteArray& xml)
{
    QSet<QString> sent;  // ერთ მოწყობილობაზე ერთი პაკეტი, თუნდაც რამდენიმე კავშირი ჰქონდეს
    for (QTcpSocket* c : _tcpClients) {
        if (!c || c->state() != QAbstractSocket::ConnectedState) {
            continue;
        }
        QHostAddress addr = c->peerAddress();
        bool ok = false;
        const quint32 v4 = addr.toIPv4Address(&ok);  // ::ffff:a.b.c.d → a.b.c.d
        if (ok) {
            addr = QHostAddress(v4);
        }
        if (addr.isNull() || addr.isLoopback()) {
            continue;  // adb reverse: ATAK იმავე multicast-ს ლოკალურად იღებს
        }
        const QString key = addr.toString();
        if (sent.contains(key)) {
            continue;
        }
        sent.insert(key);
        _udp.writeDatagram(xml, addr, kAtakUnicastPort);
    }
}

void CotForwarder::_writeToClient(QTcpSocket* client, const QByteArray& line)
{
    if (!client || client->state() != QAbstractSocket::ConnectedState) {
        return;
    }
    if (client->bytesToWrite() > kMaxClientBacklogBytes) {
        // abort() → disconnected() → _onTcpDisconnected (removeAll + deleteLater)
        qWarning() << "DHGM: stalled plugin client dropped" << client->peerAddress().toString()
                   << "backlog" << client->bytesToWrite();
        client->abort();
        return;
    }
    client->write(line);
}

void CotForwarder::_broadcastJson(const QByteArray& line)
{
    // copy: abort()-ი sync-ურად disconnected-ს emit-ავს და _tcpClients-ს ცვლს
    const QList<QTcpSocket*> clients = _tcpClients;
    for (QTcpSocket* c : clients) {
        _writeToClient(c, line);
    }
}

void CotForwarder::_sendBridgeHello(QTcpSocket* client)
{
    QmlObjectListModel* vehicles = MultiVehicleManager::instance()->vehicles();
    QStringList ids;
    if (vehicles) {
        const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();
        for (int i = 0; i < vehicles->count(); ++i) {
            Vehicle* v = qobject_cast<Vehicle*>(vehicles->get(i));
            if (v && _vehicleActive(v, nowMs)) {
                ids << QString::number(v->id());
            }
        }
    }
    const QByteArray line = QStringLiteral(
        "{\"type\":\"bridge_hello\",\"version\":\"%1\",\"drones\":[%2]}\n")
        .arg(QString::fromUtf8(kBridgeVersion), ids.join(',')).toUtf8();
    _writeToClient(client, line);
}

void CotForwarder::_tick()
{
    QmlObjectListModel* vehicles = MultiVehicleManager::instance()->vehicles();
    const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();
    if (!vehicles) {
        // ვეჰიკლ-მენეჯერი ჯერ არ არის — heartbeat-ი მაინც (plugin-ი არ timeout-დეს)
        if (_tcpPort > 0 && !_tcpClients.isEmpty()) {
            _broadcastJson(QStringLiteral("{\"type\":\"bridge_heartbeat\",\"ts\":%1}\n")
                               .arg(nowMs / 1000.0, 0, 'f', 3).toUtf8());
        }
        return;
    }
    QSet<int> currentActive;
    int sent = 0;

    for (int i = 0; i < vehicles->count(); ++i) {
        Vehicle* v = qobject_cast<Vehicle*>(vehicles->get(i));
        if (!_vehicleActive(v, nowMs)) {
            continue;
        }
        currentActive.insert(v->id());
        _sendCot(_buildCot(v, nowMs));
        if (_tcpPort > 0 && !_tcpClients.isEmpty()) {
            _broadcastJson(_buildJson(v, nowMs));
        }
        ++sent;
    }

    if (_tcpPort > 0 && !_tcpClients.isEmpty()) {
        for (int gone : _prevActiveSysids) {
            if (!currentActive.contains(gone)) {
                _broadcastJson(QStringLiteral("{\"type\":\"drone_gone\",\"sysid\":%1,\"reason\":\"stale\"}\n")
                                   .arg(gone).toUtf8());
            }
        }
        // keepalive — დრონ ყონ თუ არა (plugin read timeout = 5 წმ)
        _broadcastJson(QStringLiteral("{\"type\":\"bridge_heartbeat\",\"ts\":%1}\n")
                           .arg(nowMs / 1000.0, 0, 'f', 3).toUtf8());
    }

    _prevActiveSysids = currentActive;
    emit statusChanged(QStringLiteral("DHGM: %1 drone · %2 client")
                       .arg(sent).arg(_tcpClients.count()));
}

void CotForwarder::_onNewTcpConnection()
{
    while (_tcpServer.hasPendingConnections()) {
        QTcpSocket* c = _tcpServer.nextPendingConnection();
        if (!isLocalNetworkPeer(c->peerAddress())) {
            // telemetry (პოზიცია/სიმაღლე) მხოლოდ ლოკალურ ქსელში — უცხო IP ეგრევე წყდება.
            qWarning() << "DHGM: TCP კლიენტი უარყოფილია (არა-ლოკალური IP):" << c->peerAddress().toString();
            c->abort();
            c->deleteLater();
            continue;
        }
        c->setSocketOption(QAbstractSocket::LowDelayOption, 1);
        connect(c, &QTcpSocket::disconnected, this, &CotForwarder::_onTcpDisconnected);
        _tcpClients.append(c);
        _sendBridgeHello(c);  // მხოლოდ ახალ კლიენტს
    }
}

void CotForwarder::_onTcpDisconnected()
{
    QTcpSocket* c = qobject_cast<QTcpSocket*>(sender());
    if (c) {
        _tcpClients.removeAll(c);
        c->deleteLater();
    }
}
