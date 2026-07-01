/****************************************************************************
 * DroneHub GCS — Viewer3D OSM building auto-loader (impl).
 ****************************************************************************/

#include "CustomOsmAutoLoader.h"

#include "SettingsManager.h"
#include "Viewer3DSettings.h"
#include "Fact.h"

#include <QtCore/QDir>
#include <QtCore/QFile>
#include <QtCore/QFileInfo>
#include <QtCore/QDateTime>
#include <QtCore/QStandardPaths>
#include <QtCore/QUrl>
#include <QtCore/QtMath>
#include <QtCore/QDebug>
#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QNetworkReply>
#include <QtNetwork/QNetworkRequest>

namespace {
constexpr double kRadiusMeters   = 800.0;   // ~1.6 km box around the vehicle
constexpr double kResampleMeters = 250.0;   // don't re-download until we move this far
const QString    kTempPrefix     = QStringLiteral("dronehub-osm-");
const QString    kPlaceholder    = QStringLiteral("Please select an OSM file");
}

CustomOsmAutoLoader* CustomOsmAutoLoader::instance()
{
    static CustomOsmAutoLoader s_instance;
    return &s_instance;
}

CustomOsmAutoLoader::CustomOsmAutoLoader(QObject* parent)
    : QObject(parent)
{
    _nam = new QNetworkAccessManager(this);
}

bool CustomOsmAutoLoader::_shouldAutoLoad(const QGeoCoordinate& center) const
{
    if (_busy || !center.isValid()) {
        return false;
    }

    Viewer3DSettings* settings = SettingsManager::instance()->viewer3DSettings();
    const QString path = settings->osmFilePath()->rawValue().toString();
    const bool ours = path.contains(kTempPrefix);

    // Respect a user-selected, existing file (manual / offline choice).
    if (!path.isEmpty() && path != kPlaceholder && QFileInfo::exists(path) && !ours) {
        return false;
    }

    // Already have this area cached — skip.
    if (ours && _lastCenter.isValid() && _lastCenter.distanceTo(center) < kResampleMeters) {
        return false;
    }
    return true;
}

void CustomOsmAutoLoader::autoLoad(const QGeoCoordinate& center)
{
    if (!_shouldAutoLoad(center)) {
        return;
    }

    const double lat  = center.latitude();
    const double lon  = center.longitude();
    const double dLat = kRadiusMeters / 111320.0;
    const double dLon = kRadiusMeters / (111320.0 * qCos(qDegreesToRadians(lat)));
    const double s = lat - dLat, w = lon - dLon, n = lat + dLat, e = lon + dLon;

    // Overpass QL: all building ways/relations in the bbox, plus their nodes.
    const QString query = QStringLiteral(
        "[out:xml][timeout:25];("
        "way[\"building\"](%1,%2,%3,%4);"
        "relation[\"building\"](%1,%2,%3,%4);"
        ");(._;>;);out body;")
        .arg(s, 0, 'f', 7).arg(w, 0, 'f', 7).arg(n, 0, 'f', 7).arg(e, 0, 'f', 7);

    QNetworkRequest req{QUrl(QStringLiteral("https://overpass-api.de/api/interpreter"))};
    req.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/x-www-form-urlencoded"));
    req.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("DroneHubGCS/1.0 (Viewer3D)"));

    _busy = true;
    _lastCenter = center;
    _reply = _nam->post(req, QByteArray("data=") + QUrl::toPercentEncoding(query));
    connect(_reply, &QNetworkReply::finished, this, &CustomOsmAutoLoader::_onReplyFinished);
    qInfo() << "DroneHub Viewer3D: auto-downloading OSM buildings around" << lat << lon;
}

void CustomOsmAutoLoader::_onReplyFinished()
{
    _busy = false;
    QNetworkReply* reply = _reply;
    _reply = nullptr;
    if (!reply) {
        return;
    }
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "DroneHub Viewer3D: OSM auto-download failed —" << reply->errorString()
                   << "· load an .osm file manually via Settings ▸ 3D View.";
        return;
    }

    const QByteArray data = reply->readAll();
    if (data.size() < 256) { // effectively empty (no buildings / error page)
        qWarning() << "DroneHub Viewer3D: no OSM buildings returned for this area.";
        return;
    }

    const QString dir  = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    const QString file = QDir(dir).filePath(
        QStringLiteral("%1%2.osm").arg(kTempPrefix).arg(QDateTime::currentMSecsSinceEpoch()));

    QFile f(file);
    if (!f.open(QIODevice::WriteOnly)) {
        qWarning() << "DroneHub Viewer3D: cannot write temp OSM file" << file;
        return;
    }
    f.write(data);
    f.close();

    // Hand off to the stock loader (CityMapGeometry watches this fact).
    SettingsManager::instance()->viewer3DSettings()->osmFilePath()->setRawValue(file);
    qInfo() << "DroneHub Viewer3D: OSM buildings loaded for current area ("
            << data.size() << "bytes ) →" << file;
}
