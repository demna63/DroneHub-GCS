/****************************************************************************
 * DHGM ინტეგრაცია — CotForwarder
 *
 * DroneHub GCS-ის შიდა მოდული, რომელიც ცალკე Python bridge-ს ცვლის: GCS-ის
 * ვეჰიკლების ტელემეტრიას პირდაპირ გარდაქმნის Cursor-on-Target-ად (ATAK/DHGM
 * multicast-ისთვის) და JSON-ად (DHGM plugin-ის TCP პანელისთვის).
 *
 * ფორმატები იდენტურია `DHGM/bridge/dhgm_bridge.py` + `plugin_json.py`-ს:
 *   CoT:  uid "DHGM.<id>", callsign "DH-<id>", type a-f-A-M-F-Q,
 *         multicast 239.2.3.1:6969
 *   JSON: {"type":"telemetry", sysid, lat, lon, alt_agl_m, speed_mps, ...}
 *         TCP :14550 (newline-delimited)
 *
 * ჩართვა: Settings → DHGM forwarding (CustomOptions). "no hard-fork" —
 * ცალკე ფაილები custom/src/-ში, core უცვლელი.
 ****************************************************************************/
#pragma once

#include <QObject>
#include <QTimer>
#include <QUdpSocket>
#include <QTcpServer>
#include <QTcpSocket>
#include <QHostAddress>
#include <QList>
#include <QString>

class Vehicle;

class CotForwarder : public QObject
{
    Q_OBJECT
public:
    explicit CotForwarder(QObject* parent = nullptr);
    ~CotForwarder() override;

    /// ჩართვა/გამორთვა (Settings-იდან). ჩართვისას იწყებს multicast + TCP server-ს.
    void setEnabled(bool enabled);
    bool enabled() const { return _enabled; }

    /// კონფიგურაცია (default-ები Python bridge-ის იდენტური).
    void setCotMulticast(const QString& hostPort);   ///< "239.2.3.1:6969"
    void setPluginTcpPort(quint16 port);              ///< 14550 (0 = გამორთული)
    void setRateHz(double hz);                        ///< default 1.0
    void setStaleSeconds(double s);                   ///< default 10.0

signals:
    void statusChanged(const QString& status);        ///< UI-სთვის (N drone, M client)

private slots:
    void _tick();                                     ///< rate-ზე: ყველა ვეჰიკლი → CoT+JSON
    void _onNewTcpConnection();
    void _onTcpDisconnected();

private:
    QByteArray _buildCot(Vehicle* v, qint64 nowMs) const;
    QByteArray _buildJson(Vehicle* v, qint64 nowMs) const;
    void       _sendCot(const QByteArray& xml);
    void       _broadcastJson(const QByteArray& line);
    static QString _cotTime(qint64 ms);

    bool         _enabled = false;
    QTimer       _timer;
    QUdpSocket   _udp;
    QTcpServer   _tcpServer;
    QList<QTcpSocket*> _tcpClients;

    QHostAddress _cotAddr = QHostAddress(QStringLiteral("239.2.3.1"));
    quint16      _cotPort = 6969;
    quint16      _tcpPort = 14550;
    double       _rateHz = 1.0;
    double       _staleS = 10.0;
    QString      _prefix = QStringLiteral("DH");
};
