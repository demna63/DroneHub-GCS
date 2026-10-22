#include "DroneHubCloudForwarder.h"

#include "Vehicle.h"
#include "MultiVehicleManager.h"
#include "QmlObjectListModel.h"
#include "FactGroup.h"
#include "Fact.h"
#include "VehicleLinkManager.h"
#include "VehicleGPSFactGroup.h"

#include <QtCore/QDateTime>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtCore/QLoggingCategory>
#include <QtCore/QUrl>
#include <QtNetwork/QNetworkRequest>
#include <QtNetwork/QNetworkReply>

#include <algorithm>

Q_LOGGING_CATEGORY(DroneHubCloudLog, "DroneHubCloudLog")

namespace {
double factVal(FactGroup* fg, const QString& name, double fallback = 0.0)
{
    if (!fg) {
        return fallback;
    }
    Fact* f = fg->getFact(name);
    return (f && f->rawValue().isValid()) ? f->rawValue().toDouble() : fallback;
}
}

DroneHubCloudForwarder::DroneHubCloudForwarder(QObject* parent)
    : QObject(parent)
{
    _timer.setInterval(1000);
    connect(&_timer, &QTimer::timeout, this, &DroneHubCloudForwarder::_tick);
}

DroneHubCloudForwarder::~DroneHubCloudForwarder()
{
    setEnabled(false);
}

void DroneHubCloudForwarder::setEnabled(bool enabled)
{
    if (_enabled == enabled) {
        return;
    }
    _enabled = enabled;
    if (_enabled) {
        _timer.start(std::max(100, static_cast<int>(1000.0 / std::max(0.1, _rateHz))));
        emit statusChanged(QStringLiteral("dronehub.ge Cloud ჩართული"));
    } else {
        _timer.stop();
        _inFlight = false;
        emit statusChanged(QStringLiteral("dronehub.ge Cloud გამორთული"));
    }
}

void DroneHubCloudForwarder::setServerUrl(const QString& url)
{
    _serverUrl = url.trimmed();
}

void DroneHubCloudForwarder::setApiKey(const QString& key)
{
    _apiKey = key.trimmed();
}

void DroneHubCloudForwarder::setRateHz(double hz)
{
    _rateHz = std::max(0.1, std::min(10.0, hz));
    if (_timer.isActive()) {
        _timer.setInterval(std::max(100, static_cast<int>(1000.0 / _rateHz)));
    }
}

void DroneHubCloudForwarder::_tick()
{
    if (!_enabled || _serverUrl.isEmpty() || _inFlight) {
        return;
    }

    MultiVehicleManager* mvm = MultiVehicleManager::instance();
    if (!mvm) {
        return;
    }

    Vehicle* v = mvm->activeVehicle();
    if (!v || !v->coordinate().isValid()) {
        return;
    }
    if (qFuzzyIsNull(v->coordinate().latitude()) && qFuzzyIsNull(v->coordinate().longitude())) {
        return;
    }

    VehicleLinkManager* lm = v->vehicleLinkManager();
    if (lm && lm->communicationLost()) {
        return;
    }

    const QByteArray payload = _buildPayload(v);
    if (!payload.isEmpty()) {
        _sendPayload(payload);
    }
}

QByteArray DroneHubCloudForwarder::_buildPayload(Vehicle* v) const
{
    QJsonObject root;
    root[QStringLiteral("sysid")] = v->id();
    root[QStringLiteral("timestamp")] = QDateTime::currentMSecsSinceEpoch();
    root[QStringLiteral("flight_mode")] = v->flightMode();
    root[QStringLiteral("armed")] = v->armed();
    root[QStringLiteral("flying")] = v->flying();

    // Battery
    QJsonObject batObj;
    QmlObjectListModel* batts = v->batteries();
    if (batts && batts->count() > 0) {
        if (FactGroup* bg = qobject_cast<FactGroup*>(batts->get(0))) {
            batObj[QStringLiteral("voltage")] = factVal(bg, QStringLiteral("voltage"), 0.0);
            batObj[QStringLiteral("current")] = factVal(bg, QStringLiteral("current"), 0.0);
            batObj[QStringLiteral("percent")] = factVal(bg, QStringLiteral("percentRemaining"), 0.0);
        }
    }
    root[QStringLiteral("battery")] = batObj;

    // Position
    FactGroup* vg = v->vehicleFactGroup();
    QJsonObject gpsObj;
    gpsObj[QStringLiteral("lat")] = v->coordinate().latitude();
    gpsObj[QStringLiteral("lon")] = v->coordinate().longitude();
    gpsObj[QStringLiteral("alt_rel")] = factVal(vg, QStringLiteral("altitudeRelative"), 0.0);
    gpsObj[QStringLiteral("alt_msl")] = factVal(vg, QStringLiteral("altitudeAMSL"), 0.0);

    FactGroup* gpsg = v->gpsFactGroup();
    if (gpsg) {
        gpsObj[QStringLiteral("hdop")] = factVal(gpsg, QStringLiteral("hdop"), 0.0);
        gpsObj[QStringLiteral("satellites")] = static_cast<int>(factVal(gpsg, QStringLiteral("count"), 0.0));
        gpsObj[QStringLiteral("fix_type")] = static_cast<int>(factVal(gpsg, QStringLiteral("lock"), 0.0));
    }
    root[QStringLiteral("gps")] = gpsObj;

    // Motion
    QJsonObject motionObj;
    motionObj[QStringLiteral("ground_speed")] = factVal(vg, QStringLiteral("groundSpeed"), 0.0);
    motionObj[QStringLiteral("air_speed")] = factVal(vg, QStringLiteral("airSpeed"), 0.0);
    motionObj[QStringLiteral("climb_rate")] = factVal(vg, QStringLiteral("climbRate"), 0.0);
    motionObj[QStringLiteral("heading")] = factVal(vg, QStringLiteral("heading"), 0.0);
    root[QStringLiteral("motion")] = motionObj;

    // Link quality
    QJsonObject linkObj;
    FactGroup* radio = v->radioStatusFactGroup();
    if (radio) {
        Fact* lrssi = radio->getFact(QStringLiteral("lrssi"));
        if (lrssi && lrssi->rawValue().isValid()) {
            linkObj[QStringLiteral("telemetry_rssi_dbm")] = lrssi->rawValue().toInt();
        }
    }
    if (vg) {
        Fact* rc = vg->getFact(QStringLiteral("rcRSSI"));
        if (rc && rc->rawValue().isValid()) {
            const int rcPct = rc->rawValue().toInt();
            if (rcPct >= 0 && rcPct <= 100) {
                linkObj[QStringLiteral("rc_rssi_pct")] = rcPct;
            }
        }
    }
    root[QStringLiteral("link")] = linkObj;

    const QJsonDocument doc(root);
    return doc.toJson(QJsonDocument::Compact);
}

void DroneHubCloudForwarder::_sendPayload(const QByteArray& payload)
{
    const QUrl url(_serverUrl);
    if (!url.isValid()) {
        return;
    }

    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("User-Agent", "DroneHub-GCS/1.1");
    if (!_apiKey.isEmpty()) {
        request.setRawHeader("Authorization", "Bearer " + _apiKey.toUtf8());
    }

    _inFlight = true;
    QNetworkReply* reply = _nam.post(request, payload);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        _inFlight = false;
        if (reply->error() != QNetworkReply::NoError) {
            qCDebug(DroneHubCloudLog) << "DroneHubCloud upload failed:" << reply->errorString();
        }
        reply->deleteLater();
    });
}
