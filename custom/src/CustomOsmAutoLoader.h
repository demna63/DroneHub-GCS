/****************************************************************************
 * DroneHub GCS — Viewer3D OSM building auto-loader.
 *
 * Hybrid building-data source for the 3D view:
 *   • Online  → auto-download OSM buildings around the vehicle GPS ref from the
 *               Overpass API, drop them in a temp .osm, and point
 *               viewer3DSettings.osmFilePath at it so the stock CityMapGeometry
 *               loader renders them for the current area (no parser changes).
 *   • Offline / manual → if the user has selected their own .osm file, we leave it
 *               untouched; if a download fails, the manual "select OSM file" flow
 *               (Settings ▸ 3D View) still works.
 *
 * Wired from a one-line call in Viewer3DQmlBackend (custom patch) when the GPS ref
 * is set. Singleton so the QNetworkAccessManager and area-cache survive view reopens.
 ****************************************************************************/

#pragma once

#include <QtCore/QObject>
#include <QtPositioning/QGeoCoordinate>

class QNetworkAccessManager;
class QNetworkReply;

class CustomOsmAutoLoader : public QObject
{
    Q_OBJECT

public:
    static CustomOsmAutoLoader* instance();

    /// Auto-download OSM buildings around `center` if appropriate (online, no manual
    /// file chosen, not already downloading, area moved since the last fetch). No-op
    /// otherwise — safe to call on every GPS-ref change.
    void autoLoad(const QGeoCoordinate& center);

private slots:
    void _onReplyFinished();

private:
    explicit CustomOsmAutoLoader(QObject* parent = nullptr);
    bool _shouldAutoLoad(const QGeoCoordinate& center) const;

    QNetworkAccessManager* _nam    = nullptr;
    QNetworkReply*         _reply  = nullptr;
    bool                   _busy   = false;
    QGeoCoordinate         _lastCenter;
};
