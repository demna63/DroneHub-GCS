#pragma once

#include <QtCore/QObject>
#include <QtCore/QLoggingCategory>
#include <QtQml/QQmlAbstractUrlInterceptor>

#include "QGCCorePlugin.h"
#include "QGCOptions.h"
#include "QGCPalette.h"
#include "DhgmSettings.h"

class CustomOptions;
class QQmlApplicationEngine;
class CotForwarder;

Q_DECLARE_LOGGING_CATEGORY(CustomPluginLog)

/// DroneHub GCS core plugin (QGC Stable_V5.0 API).
///
/// რეგისტრაცია ხდება CMake compile-defs-ით (CUSTOMHEADER/CUSTOMCLASS) —
/// QGC core თვითონ ქმნის singleton-ს instance()-ით.
///
/// პასუხისმგებლობა: branding (logo/app name), DroneHub პალიტრა (paletteOverride),
/// ქართული ფონტი + locale (init), QML override mechanism (createQmlApplicationEngine).
class CustomPlugin : public QGCCorePlugin
{
    Q_OBJECT
public:
    explicit CustomPlugin(QObject* parent = nullptr);
    ~CustomPlugin() override;

    static QGCCorePlugin* instance();

    // QGCCorePlugin overrides
    void                    init()                                                          final;
    void                    cleanup()                                                       final;
    QGCOptions*             options()                                                       final;
    QString                 showAdvancedUIMessage() const                                   final;
    bool                    overrideSettingsGroupVisibility(const QString& name)            final;
    void                    adjustSettingMetaData(const QString& settingsGroup,
                                                  FactMetaData& metaData,
                                                  bool& userVisible)                         final;
    void                    paletteOverride(const QString& colorName,
                                            QGCPalette::PaletteColorInfo_t& colorInfo)       final;
    QQmlApplicationEngine*  createQmlApplicationEngine(QObject* parent)                      final;

    /// WMM declination (degrees, east positive) — PX4 world_magnetic_model lookup, same as FC geo_lookup.
    Q_INVOKABLE double magneticDeclination(double latitude, double longitude) const;

    /// DHGM forwarding პარამეტრები (Settings → Telemetry).
    Q_PROPERTY(DhgmSettings* dhgmSettings READ dhgmSettings CONSTANT)

    DhgmSettings* dhgmSettings() { return _dhgmSettings; }

private:
    void _wireDhgmForwarding();
    /// არეგისტრირებს bundled ქართულ ფონტს და pin-ავს default locale-ს ka-ზე.
    void _applyGeorgianLocaleAndFont();

    /// Bundled MAVLink action JSON-ების კოპირება save path-ში + default არჩევა.
    void _installDefaultMavlinkActions();

    CustomOptions*                  _options   = nullptr;
    QQmlApplicationEngine*          _qmlEngine = nullptr;
    class CustomOverrideInterceptor* _selector = nullptr;

    /// DHGM ინტეგრაცია — ვეჰიკლების ტელემეტრია → CoT/JSON (DHGM plugin).
    class CotForwarder*             _cotForwarder = nullptr;
    DhgmSettings*                   _dhgmSettings = nullptr;
};

/*===========================================================================*/

/// გადაამისამართებს core QML resource URL-ებს custom override-ებზე, თუ არსებობს:
///   qrc:/qml/.../FlyView.qml  →  qrc:/Custom/qml/.../FlyView.qml
/// ეს არის QGC-ის sanctioned override mechanism (upstream QML-ს არ ვშლით).
class CustomOverrideInterceptor : public QQmlAbstractUrlInterceptor
{
public:
    CustomOverrideInterceptor();

    QUrl intercept(const QUrl& url, QQmlAbstractUrlInterceptor::DataType type) final;
};
