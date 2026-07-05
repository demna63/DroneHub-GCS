#include "CotForwarder.h"

#include "Vehicle.h"
#include "MultiVehicleManager.h"
#include "QmlObjectListModel.h"
#include "FactGroup.h"
#include "Fact.h"

#include <QDateTime>
#include <QGeoCoordinate>
#include <QtMath>

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
        _udp.setSocketOption(QAbstractSocket::MulticastTtlOption, 1);
        if (_tcpPort > 0 && !_tcpServer.isListening()) {
            // 0.0.0.0 — ტელეფონი/plugin ქსელიდანაც წვდება (Python bridge-ის იგივე)
            _tcpServer.listen(QHostAddress::AnyIPv4, _tcpPort);
        }
        _timer.start(qMax(50, int(1000.0 / qMax(0.1, _rateHz))));
        emit statusChanged(QStringLiteral("DHGM forwarding ჩართული"));
    } else {
        _timer.stop();
        for (QTcpSocket* c : _tcpClients) {
            c->disconnectFromHost();
        }
        _tcpClients.clear();
        if (_tcpServer.isListening()) {
            _tcpServer.close();
        }
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

void CotForwarder::setPluginTcpPort(quint16 port) { _tcpPort = port; }
void CotForwarder::setRateHz(double hz)           { _rateHz = qMax(0.1, hz); }
void CotForwarder::setStaleSeconds(double s)      { _staleS = qMax(1.0, s); }

QString CotForwarder::_cotTime(qint64 ms)
{
    return QDateTime::fromMSecsSinceEpoch(ms, Qt::UTC)
            .toString(QStringLiteral("yyyy-MM-ddTHH:mm:ss.zzZ"));
}

// ---- ვეჰიკლის telemetry fact-ის უსაფრთხო წაკითხვა (vehicleFactGroup) ----
// altitudeAMSL/altitudeRelative/heading/groundSpeed VehicleFactGroup-შია, არა
// პირდაპირ Vehicle-ზე — getFact-ით ვკითხულობთ (compile-რობუსტული).
static double vfg(Vehicle* v, const QString& name, double dflt)
{
    FactGroup* fg = v ? v->vehicleFactGroup() : nullptr;
    Fact* f = fg ? fg->getFact(name) : nullptr;
    return (f && f->rawValue().isValid()) ? f->rawValue().toDouble() : dflt;
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

QByteArray CotForwarder::_buildCot(Vehicle* v, qint64 nowMs) const
{
    const QGeoCoordinate c = v->coordinate();
    const QString uid = QStringLiteral("DHGM.%1").arg(v->id());
    const QString callsign = QStringLiteral("%1-%2").arg(_prefix).arg(v->id());
    const double hae = vfg(v, QStringLiteral("altitudeAMSL"), 0.0);
    const double agl = vfg(v, QStringLiteral("altitudeRelative"), 0.0);
    const double spd = vfg(v, QStringLiteral("groundSpeed"), 0.0);
    const double hdg = vfg(v, QStringLiteral("heading"), 0.0);
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
        .arg(callsign).arg(spd, 0, 'f', 2).arg(hdg, 0, 'f', 1).arg(remarks.toHtmlEscaped());
    return xml.toUtf8();
}

QByteArray CotForwarder::_buildJson(Vehicle* v, qint64 nowMs) const
{
    const QGeoCoordinate c = v->coordinate();
    const double bat = batteryPct(v);
    QString j = QStringLiteral(
        "{\"type\":\"telemetry\",\"ts\":%1,\"sysid\":%2,\"callsign\":\"%3-%2\","
        "\"lat\":%4,\"lon\":%5,\"speed_mps\":%6,\"course_deg\":%7,"
        "\"alt_agl_m\":%8,\"alt_msl_m\":%9,\"flight_mode\":\"%10\"")
        .arg(nowMs / 1000.0, 0, 'f', 3).arg(v->id()).arg(_prefix)
        .arg(c.latitude(), 0, 'f', 7).arg(c.longitude(), 0, 'f', 7)
        .arg(vfg(v, QStringLiteral("groundSpeed"), 0.0), 0, 'f', 2)
        .arg(vfg(v, QStringLiteral("heading"), 0.0), 0, 'f', 1)
        .arg(vfg(v, QStringLiteral("altitudeRelative"), 0.0), 0, 'f', 1)
        .arg(vfg(v, QStringLiteral("altitudeAMSL"), 0.0), 0, 'f', 1)
        .arg(v->flightMode());
    if (bat >= 0) {
        j += QStringLiteral(",\"battery_pct\":%1").arg(int(bat));
    }
    j += QStringLiteral("}\n");
    return j.toUtf8();
}

void CotForwarder::_sendCot(const QByteArray& xml)
{
    _udp.writeDatagram(xml, _cotAddr, _cotPort);
}

void CotForwarder::_broadcastJson(const QByteArray& line)
{
    for (QTcpSocket* c : _tcpClients) {
        if (c->state() == QAbstractSocket::ConnectedState) {
            c->write(line);
        }
    }
}

void CotForwarder::_tick()
{
    QmlObjectListModel* vehicles = MultiVehicleManager::instance()->vehicles();
    if (!vehicles) {
        return;
    }
    const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();
    int sent = 0;
    for (int i = 0; i < vehicles->count(); ++i) {
        Vehicle* v = qobject_cast<Vehicle*>(vehicles->get(i));
        if (!v || !v->coordinate().isValid()) {
            continue;
        }
        _sendCot(_buildCot(v, nowMs));
        if (_tcpPort > 0 && !_tcpClients.isEmpty()) {
            _broadcastJson(_buildJson(v, nowMs));
        }
        ++sent;
    }
    emit statusChanged(QStringLiteral("DHGM: %1 drone · %2 client")
                       .arg(sent).arg(_tcpClients.count()));
}

void CotForwarder::_onNewTcpConnection()
{
    while (_tcpServer.hasPendingConnections()) {
        QTcpSocket* c = _tcpServer.nextPendingConnection();
        connect(c, &QTcpSocket::disconnected, this, &CotForwarder::_onTcpDisconnected);
        _tcpClients.append(c);
        // bridge_hello (plugin-ის იგივე handshake)
        c->write(QByteArrayLiteral("{\"type\":\"bridge_hello\",\"version\":\"1.0.0\",\"source\":\"gcs\"}\n"));
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
