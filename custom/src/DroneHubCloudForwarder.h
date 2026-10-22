#pragma once

#include <QtCore/QObject>
#include <QtCore/QTimer>
#include <QtCore/QString>
#include <QtNetwork/QNetworkAccessManager>

class Vehicle;

/// dronehub.ge Cloud backend telemetry forwarder service.
/// Periodically posts JSON telemetry over HTTPS/REST with bearer token authentication.
class DroneHubCloudForwarder : public QObject
{
    Q_OBJECT
public:
    explicit DroneHubCloudForwarder(QObject* parent = nullptr);
    ~DroneHubCloudForwarder() override;

    void setEnabled(bool enabled);
    bool enabled() const { return _enabled; }

    void setServerUrl(const QString& url);
    QString serverUrl() const { return _serverUrl; }

    void setApiKey(const QString& key);
    QString apiKey() const { return _apiKey; }

    void setRateHz(double hz);
    double rateHz() const { return _rateHz; }

signals:
    void statusChanged(const QString& status);

private slots:
    void _tick();

private:
    QByteArray _buildPayload(Vehicle* v) const;
    void _sendPayload(const QByteArray& payload);

    bool                    _enabled = false;
    QString                 _serverUrl = QStringLiteral("https://api.dronehub.ge/v1/telemetry");
    QString                 _apiKey;
    double                  _rateHz = 1.0;
    QTimer                  _timer;
    QNetworkAccessManager   _nam;
    bool                    _inFlight = false;
};
