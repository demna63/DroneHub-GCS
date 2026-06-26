#pragma once

#include <QtCore/QObject>
#include <QtCore/QLoggingCategory>
#include <QtQml/QQmlAbstractUrlInterceptor>

#include "QGCCorePlugin.h"
#include "QGCOptions.h"
#include "QGCPalette.h"

class CustomOptions;
class QQmlApplicationEngine;

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
    QString                 brandImageIndoor()  const                                       final;
    QString                 brandImageOutdoor() const                                       final;
    QString                 showAdvancedUIMessage() const                                   final;
    bool                    overrideSettingsGroupVisibility(const QString& name)            final;
    bool                    adjustSettingMetaData(const QString& settingsGroup,
                                                  FactMetaData& metaData)                    final;
    void                    paletteOverride(const QString& colorName,
                                            QGCPalette::PaletteColorInfo_t& colorInfo)       final;
    QQmlApplicationEngine*  createQmlApplicationEngine(QObject* parent)                      final;

private:
    /// არეგისტრირებს bundled ქართულ ფონტს და pin-ავს default locale-ს ka-ზე.
    void _applyGeorgianLocaleAndFont();

    CustomOptions*                  _options   = nullptr;
    QQmlApplicationEngine*          _qmlEngine = nullptr;
    class CustomOverrideInterceptor* _selector = nullptr;
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
