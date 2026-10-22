#include "CustomPlugin.h"
#include "CustomOptions.h"
#include "CotForwarder.h"
#include "DhgmSettings.h"
#include "DroneHubCloudSettings.h"
#include "DroneHubCloudForwarder.h"
#include "GeorgianMetadataMap.h"
#include "geo/geo_mag_declination.h"

#include "QGCLoggingCategory.h"
#include "AppSettings.h"
#include "QGCMAVLink.h"
#include "FactMetaData.h"
#include "SettingsManager.h"
#include "MavlinkActionsSettings.h"
#include "VideoSettings.h"
#include "Viewer3DSettings.h"
#include "Fact.h"

#include <QtCore/QDir>
#include <QtCore/QFile>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtCore/QApplicationStatic>
#include <QtCore/QLocale>
#include <QtCore/QMap>
#include <QtCore/QStringList>
#include <QtCore/QSettings>
#include <QtCore/QVariant>
#include <QtGui/QFont>
#include <QtGui/QFontDatabase>
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlApplicationEngine>

QGC_LOGGING_CATEGORY(CustomPluginLog, "DroneHub.CustomPlugin")

Q_APPLICATION_STATIC(CustomPlugin, _customPluginInstance);

/*===========================================================================*/

CustomPlugin::CustomPlugin(QObject* parent)
    : QGCCorePlugin(parent)
    , _options(new CustomOptions(this, this))
    , _cotForwarder(new CotForwarder(this))
    , _cloudForwarder(new DroneHubCloudForwarder(this))
{
    // DhgmSettings/DroneHubCloudSettings extend SettingsGroup, whose ctor calls QGCCorePlugin::instance().
    // Creating them here deadlocks Q_APPLICATION_STATIC while CustomPlugin is still constructing.
}

CustomPlugin::~CustomPlugin() = default;

QGCCorePlugin* CustomPlugin::instance()
{
    return _customPluginInstance();
}

void CustomPlugin::init()
{
    _dhgmSettings = new DhgmSettings(this);

    // ძველი QSettings გასაღებები (tcpPort) → DhgmSettings Facts
    QSettings legacy;
    if (legacy.contains(QStringLiteral("DHGM/forwarding"))) {
        _dhgmSettings->forwarding()->setRawValue(legacy.value(QStringLiteral("DHGM/forwarding")));
    }
    if (legacy.contains(QStringLiteral("DHGM/cotMulticast"))) {
        _dhgmSettings->cotMulticast()->setRawValue(legacy.value(QStringLiteral("DHGM/cotMulticast")));
    }
    if (legacy.contains(QStringLiteral("DHGM/tcpPort"))) {
        _dhgmSettings->pluginTcpPort()->setRawValue(legacy.value(QStringLiteral("DHGM/tcpPort")));
    }

    _applyGeorgianLocaleAndFont();
    _installDefaultMavlinkActions();
    _wireDhgmForwarding();

    _droneHubCloudSettings = new DroneHubCloudSettings(this);
    _wireDroneHubCloudForwarding();

    // Keep the Fly View video PiP visible. The window hides whenever
    // hasVideo == (streamEnabled && streamConfigured) is false, and QGC sets
    // streamEnabled=false on every disarm when disableWhenDisarmed is on — so the
    // PiP vanishes after the first disarm and never comes back on its own.
    //
    // Fresh installs get disableWhenDisarmed=false via adjustSettingMetaData.
    // For installs that already persisted the old defaults, run a ONE-TIME
    // migration (guarded by a marker) so we restore the video without fighting
    // the user's choice on later launches.
    QSettings settings;
    if (!settings.value(QStringLiteral("DroneHub/videoDefaultsMigrated"), false).toBool()) {
        if (SettingsManager* sm = SettingsManager::instance()) {
            if (VideoSettings* vs = sm->videoSettings()) {
                vs->disableWhenDisarmed()->setRawValue(false);
                const QString current = vs->videoSource()->rawValue().toString();
                if (current.isEmpty() || current == QString::fromUtf8(VideoSettings::videoDisabled)) {
                    vs->videoSource()->setRawValue(QString::fromUtf8(VideoSettings::videoSourceUDPH264));
                }
                vs->streamEnabled()->setRawValue(true);
            }
        }
        settings.setValue(QStringLiteral("DroneHub/videoDefaultsMigrated"), true);
    }

}

void CustomPlugin::cleanup()
{
    // The engine is already gone here (destroyQmlApplicationEngine ran first), so only the
    // interceptor object itself is released. Never touch _qmlEngine in this path.
    delete _selector;
    _selector = nullptr;
}

void CustomPlugin::destroyQmlApplicationEngine(QQmlApplicationEngine* qmlEngine)
{
    if (qmlEngine && qmlEngine == _qmlEngine && _selector) {
        qmlEngine->removeUrlInterceptor(_selector);
    }
    if (qmlEngine == _qmlEngine) {
        _qmlEngine = nullptr;
    }
    QGCCorePlugin::destroyQmlApplicationEngine(qmlEngine);
}

QGCOptions* CustomPlugin::options()
{
    return _options;
}

QString CustomPlugin::showAdvancedUIMessage() const
{
    return tr("გაფართოებული რეჟიმი მხოლოდ გამოცდილი ოპერატორებისთვისაა და შეიცავს "
              "პარამეტრებს, რომლებიც ფრენის უსაფრთხოებაზე მოქმედებს. გავაგრძელო?");
}

bool CustomPlugin::overrideSettingsGroupVisibility(const QString& name)
{
    // NOTE: QGC 5.1 removed BrandImageSettings (and brandImageIndoor/Outdoor), so there is
    // nothing left to hide for the branding logo.

    return QGCCorePlugin::overrideSettingsGroupVisibility(name);
}

// F3: offline Plan-ის default firmware/vehicle — DroneHub PX4 multirotor.
// ეს განსაზღვრავს, რა აპარატისთვის იქმნება mission, როცა vehicle არ არის მიერთებული.
// QGC 5.1 signature: void + `bool& userVisible` (false = hidden and pinned to the default value,
// the same semantics the old `return false` had).
void CustomPlugin::adjustSettingMetaData(const QString& settingsGroup, FactMetaData& metaData, bool& userVisible)
{
    QGCCorePlugin::adjustSettingMetaData(settingsGroup, metaData, userVisible);

    // Localize enum display strings using DroneHub dictionary.
    const auto& enumMap = DroneHub::enumGeorgianMap();
    if (!metaData.enumStrings().isEmpty()) {
        QStringList strings = metaData.enumStrings();
        bool changed = false;
        for (QString& s : strings) {
            const auto it = enumMap.constFind(s);
            if (it != enumMap.constEnd()) {
                s = it.value();
                changed = true;
            }
        }
        if (changed) {
            metaData.setEnumInfo(strings, metaData.enumValues());
        }
    }

    // Some settings pages render the field label straight from shortDescription.
    const auto& shortDescMap = DroneHub::shortDescGeorgianMap();
    {
        const auto it = shortDescMap.constFind(metaData.shortDescription());
        if (it != shortDescMap.constEnd()) {
            metaData.setShortDescription(it.value());
        }
    }

    if (settingsGroup == AppSettings::settingsGroup) {
        if (metaData.name() == AppSettings::offlineEditingFirmwareClassName) {
            metaData.setRawDefaultValue(QGCMAVLink::FirmwareClassPX4);
            userVisible = false;
            return;
        } else if (metaData.name() == AppSettings::offlineEditingVehicleClassName) {
            metaData.setRawDefaultValue(QGCMAVLink::VehicleClassMultiRotor);
            userVisible = false;
            return;
        }
    }

    // Default the video source to UDP h.264 (port 5600) so the Fly View video
    // window is live out of the box. QGC ships "" (disabled) as the default, which
    // left the bottom-left PiP hidden on every fresh launch.
    if (settingsGroup == VideoSettings::settingsGroup) {
        if (metaData.name() == VideoSettings::videoSourceName) {
            metaData.setRawDefaultValue(QString::fromUtf8(VideoSettings::videoSourceUDPH264));
            userVisible = false;
            return;
        }
        // Don't kill the video stream on disarm — keeps the Fly View PiP visible.
        if (metaData.name() == VideoSettings::disableWhenDisarmedName) {
            metaData.setRawDefaultValue(false);
            userVisible = false;
            return;
        }
    }

    // 3D View is compiled in (QGC_VIEWER3D=ON). QGC ships it disabled by default, so
    // the Fly View "3D View" tool-strip button (gated on viewer3DSettings.enabled) is
    // hidden out of the box. Default it on so operators get the 3D map without digging
    // through settings. QGC 5.1 renders video through QVideoSink on any RHI backend
    // (Metal on macOS), so the old macOS+GStreamer OpenGL 2.1 exception is gone.
    if (settingsGroup == Viewer3DSettings::settingsGroup) {
        if (metaData.name() == Viewer3DSettings::enabledName) {
            metaData.setRawDefaultValue(true);
            userVisible = false;
            return;
        }
    }

    if (settingsGroup == MavlinkActionsSettings::settingsGroup) {
        if (metaData.name() == MavlinkActionsSettings::flyViewActionsFileName) {
            metaData.setRawDefaultValue(QStringLiteral("DroneHub-flyview-actions.json"));
            userVisible = false;
            return;
        }
        if (metaData.name() == MavlinkActionsSettings::joystickActionsFileName) {
            metaData.setRawDefaultValue(QStringLiteral("DroneHub-joystick-actions.json"));
            userVisible = false;
            return;
        }
    }

}

// DroneHub პალიტრა → QGC palette tokens. ფერები ემთხვევა Custom/Theme.qml-ს
// (single source). Dark = field-first; Light = დღის სინათლეზე.
void CustomPlugin::paletteOverride(const QString& colorName, QGCPalette::PaletteColorInfo_t& colorInfo)
{
    const auto set = [&](const QColor& darkEnabled, const QColor& darkDisabled,
                         const QColor& lightEnabled, const QColor& lightDisabled) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled]   = darkEnabled;
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled]  = darkDisabled;
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled]  = lightEnabled;
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = lightDisabled;
    };

    if (colorName == QStringLiteral("window")) {
        set(QColor("#0B0E14"), QColor("#0B0E14"), QColor("#FFFFFF"), QColor("#F8F9FA"));        // bgBase
    } else if (colorName == QStringLiteral("windowShade")) {
        set(QColor("#151A23"), QColor("#151A23"), QColor("#F1F3F5"), QColor("#E9ECEF"));        // bgSurface
    } else if (colorName == QStringLiteral("windowShadeDark")) {
        set(QColor("#080A0F"), QColor("#080A0F"), QColor("#E9ECEF"), QColor("#D9D9D9"));
    } else if (colorName == QStringLiteral("text")) {
        set(QColor("#FFFFFF"), QColor("#9AA6B8"), QColor("#212529"), QColor("#9D9D9D"));
    } else if (colorName == QStringLiteral("warningText")) {
        set(QColor("#FF453A"), QColor("#FF453A"), QColor("#CC0808"), QColor("#CC0808"));        // danger
    } else if (colorName == QStringLiteral("button")) {
        set(QColor("#1E2530"), QColor("#1E2530"), QColor("#FFFFFF"), QColor("#FFFFFF"));        // bgElevated
    } else if (colorName == QStringLiteral("buttonText")) {
        set(QColor("#FFFFFF"), QColor("#9AA6B8"), QColor("#212529"), QColor("#9D9D9D"));
    } else if (colorName == QStringLiteral("buttonHighlight")) {
        set(QColor("#0A84FF"), QColor("#2A323F"), QColor("#0A84FF"), QColor("#E4E4E4"));        // brandPrimary
    } else if (colorName == QStringLiteral("buttonHighlightText")) {
        set(QColor("#FFFFFF"), QColor("#5A6473"), QColor("#FFFFFF"), QColor("#2C2C2C"));
    } else if (colorName == QStringLiteral("primaryButton")) {
        set(QColor("#0A84FF"), QColor("#2A323F"), QColor("#0A84FF"), QColor("#585858"));        // brandPrimary
    } else if (colorName == QStringLiteral("primaryButtonText")) {
        set(QColor("#FFFFFF"), QColor("#FFFFFF"), QColor("#FFFFFF"), QColor("#CAD0D0"));
    } else if (colorName == QStringLiteral("textField")) {
        set(QColor("#0B0E14"), QColor("#1E2530"), QColor("#F1F3F5"), QColor("#FFFFFF"));
    } else if (colorName == QStringLiteral("textFieldText")) {
        set(QColor("#F2F4F8"), QColor("#5A6473"), QColor("#212529"), QColor("#808080"));
    } else if (colorName == QStringLiteral("colorGreen")) {
        set(QColor("#30D158"), QColor("#1F8F3C"), QColor("#1A9E31"), QColor("#1A9E31"));        // brandAccent
    } else if (colorName == QStringLiteral("colorOrange")) {
        set(QColor("#FF9F0A"), QColor("#B45D04"), QColor("#B95604"), QColor("#B95604"));        // warning
    } else if (colorName == QStringLiteral("colorRed")) {
        set(QColor("#FF453A"), QColor("#C32C25"), QColor("#ED3939"), QColor("#ED3939"));        // danger
    } else if (colorName == QStringLiteral("colorBlue")) {
        set(QColor("#0A84FF"), QColor("#0A84FF"), QColor("#1A72FF"), QColor("#1A72FF"));        // brandPrimary
    } else if (colorName == QStringLiteral("colorGrey")) {
        set(QColor("#A0AAB8"), QColor("#A0AAB8"), QColor("#808080"), QColor("#808080"));        // textSecondary
    } else if (colorName == QStringLiteral("colorYellow")) {
        set(QColor("#FF9F0A"), QColor("#B45D04"), QColor("#B95604"), QColor("#B95604"));        // warning
    } else if (colorName == QStringLiteral("colorYellowGreen")) {
        set(QColor("#9DBE2F"), QColor("#799F26"), QColor("#9DBE2F"), QColor("#799F26"));
    } else if (colorName == QStringLiteral("hoverColor")) {
        set(QColor("#0A84FF"), QColor("#33C494"), QColor("#AEEBD0"), QColor("#464F5A"));
    } else if (colorName == QStringLiteral("alertBackground")) {
        set(QColor("#1E2530"), QColor("#151A23"), QColor("#1E2530"), QColor("#151A23"));        // toast surface
    } else if (colorName == QStringLiteral("alertBorder")) {
        set(QColor("#FF453A"), QColor("#88FF453A"), QColor("#FF453A"), QColor("#88FF453A"));  // danger accent
    } else if (colorName == QStringLiteral("alertText")) {
        set(QColor("#FFFFFF"), QColor("#D0D8E4"), QColor("#FFFFFF"), QColor("#D0D8E4"));
    }
    // დანარჩენი palette tokens — QGC default-ზე რჩება.
}

double CustomPlugin::magneticDeclination(double latitude, double longitude) const
{
    if (!qIsFinite(latitude) || !qIsFinite(longitude)) {
        return qQNaN();
    }

    return static_cast<double>(get_mag_declination_degrees(
        static_cast<float>(latitude), static_cast<float>(longitude)));
}

// QQmlApplicationEngine-ის override: ვამატებთ Custom.Theme module-ის import path-ს
// და QML override interceptor-ს (F2/F3 view override-ებისთვის).
QQmlApplicationEngine* CustomPlugin::createQmlApplicationEngine(QObject* parent)
{
    _qmlEngine = QGCCorePlugin::createQmlApplicationEngine(parent);
    _qmlEngine->addImportPath(QStringLiteral("qrc:/Custom/imports"));

    _selector = new CustomOverrideInterceptor();
    _qmlEngine->addUrlInterceptor(_selector);

    return _qmlEngine;
}

void CustomPlugin::_applyGeorgianLocaleAndFont()
{
    const int fontId = QFontDatabase::addApplicationFont(
        QStringLiteral(":/custom/fonts/NotoSansGeorgian.ttf"));

    if (fontId < 0) {
        qCWarning(CustomPluginLog) << "Georgian font failed to load — glyphs may render as boxes.";
    } else {
        const QStringList families = QFontDatabase::applicationFontFamilies(fontId);
        if (!families.isEmpty()) {
            QGuiApplication::setFont(QFont(families.first()));
            qCDebug(CustomPluginLog) << "Georgian font registered:" << families.first();
        }
    }

    // UI locale → ქართული, host OS locale-ის მიუხედავად.
    QLocale::setDefault(QLocale(QLocale::Georgian, QLocale::Georgia));
}

void CustomPlugin::_installDefaultMavlinkActions()
{
    static const QString kFlyViewFile = QStringLiteral("DroneHub-flyview-actions.json");
    static const QString kJoystickFile = QStringLiteral("DroneHub-joystick-actions.json");
    constexpr int kBundledMavlinkActionsVersion = 3;

    const auto readBundleVersion = [](const QString& filePath) -> int {
        QFile file(filePath);
        if (!file.open(QIODevice::ReadOnly)) {
            return 0;
        }
        const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
        if (!doc.isObject()) {
            return 0;
        }
        return doc.object().value(QStringLiteral("bundleVersion")).toInt(0);
    };

    SettingsManager* settingsManager = SettingsManager::instance();
    if (!settingsManager || !settingsManager->appSettings() || !settingsManager->mavlinkActionsSettings()) {
        qCWarning(CustomPluginLog) << "MAVLink actions: settings not ready — skipping install";
        return;
    }

    AppSettings* appSettings = settingsManager->appSettings();
    MavlinkActionsSettings* mavlinkSettings = settingsManager->mavlinkActionsSettings();

    const QString destDir = appSettings->mavlinkActionsSavePath();
    if (destDir.isEmpty()) {
        qCWarning(CustomPluginLog) << "MAVLink actions: save path empty — skipping install";
        return;
    }

    QDir().mkpath(destDir);

    const auto installBundled = [&](const QString& fileName) {
        const QString destPath = QDir(destDir).filePath(fileName);
        const QString resourcePath = QStringLiteral(":/custom/mavlink-actions/") + fileName;
        if (!QFile::exists(resourcePath)) {
            qCWarning(CustomPluginLog) << "MAVLink actions: bundled resource missing:" << resourcePath;
            return;
        }
        if (QFile::exists(destPath)) {
            const int destVer = readBundleVersion(destPath);
            if (destVer >= kBundledMavlinkActionsVersion) {
                return;
            }
            if (!QFile::remove(destPath)) {
                qCWarning(CustomPluginLog) << "MAVLink actions: failed to replace outdated file:" << destPath;
                return;
            }
            qCDebug(CustomPluginLog) << "MAVLink actions: upgrading" << destPath
                                     << "from bundleVersion" << destVer << "to" << kBundledMavlinkActionsVersion;
        }
        if (!QFile::copy(resourcePath, destPath)) {
            qCWarning(CustomPluginLog) << "MAVLink actions: failed to copy" << resourcePath << "to" << destPath;
        } else {
            qCDebug(CustomPluginLog) << "MAVLink actions: installed" << destPath;
        }
    };

    installBundled(kFlyViewFile);
    installBundled(kJoystickFile);

    if (mavlinkSettings->flyViewActionsFile()->rawValue().toString().isEmpty()) {
        mavlinkSettings->flyViewActionsFile()->setRawValue(kFlyViewFile);
    }
    if (mavlinkSettings->joystickActionsFile()->rawValue().toString().isEmpty()) {
        mavlinkSettings->joystickActionsFile()->setRawValue(kJoystickFile);
    }
}

void CustomPlugin::_wireDhgmForwarding()
{
    const auto apply = [this]() {
        _cotForwarder->setCotMulticast(_dhgmSettings->cotMulticast()->rawValue().toString());
        _cotForwarder->setPluginTcpPort(quint16(_dhgmSettings->pluginTcpPort()->rawValue().toUInt()));
        _cotForwarder->setRateHz(_dhgmSettings->rateHz()->rawValue().toDouble());
        _cotForwarder->setStaleSeconds(_dhgmSettings->staleSeconds()->rawValue().toDouble());
        _cotForwarder->setEnabled(_dhgmSettings->forwarding()->rawValue().toBool());
    };

    apply();

    connect(_dhgmSettings->forwarding(), &Fact::rawValueChanged, this, apply);
    connect(_dhgmSettings->cotMulticast(), &Fact::rawValueChanged, this, apply);
    connect(_dhgmSettings->pluginTcpPort(), &Fact::rawValueChanged, this, apply);
    connect(_dhgmSettings->rateHz(), &Fact::rawValueChanged, this, apply);
    connect(_dhgmSettings->staleSeconds(), &Fact::rawValueChanged, this, apply);
}

void CustomPlugin::_wireDroneHubCloudForwarding()
{
    const auto apply = [this]() {
        _cloudForwarder->setServerUrl(_droneHubCloudSettings->serverUrl()->rawValue().toString());
        _cloudForwarder->setApiKey(_droneHubCloudSettings->apiKey()->rawValue().toString());
        _cloudForwarder->setRateHz(_droneHubCloudSettings->rateHz()->rawValue().toDouble());
        _cloudForwarder->setEnabled(_droneHubCloudSettings->enabled()->rawValue().toBool());
    };

    apply();

    connect(_droneHubCloudSettings->enabled(), &Fact::rawValueChanged, this, apply);
    connect(_droneHubCloudSettings->serverUrl(), &Fact::rawValueChanged, this, apply);
    connect(_droneHubCloudSettings->apiKey(), &Fact::rawValueChanged, this, apply);
    connect(_droneHubCloudSettings->rateHz(), &Fact::rawValueChanged, this, apply);
}

/*===========================================================================*/

CustomOverrideInterceptor::CustomOverrideInterceptor()
    : QQmlAbstractUrlInterceptor()
{
}

QUrl CustomOverrideInterceptor::intercept(const QUrl& url, QQmlAbstractUrlInterceptor::DataType type)
{
    // DataType is inherited from QQmlAbstractUrlInterceptor; a local alias trips -Werror=shadow (GCC).
    switch (type) {
    case QQmlAbstractUrlInterceptor::QmlFile:
    case QQmlAbstractUrlInterceptor::UrlString:
        if (url.scheme() == QStringLiteral("qrc")) {
            const QString overrideRes = QStringLiteral(":/Custom%1").arg(url.path());
            if (QFile::exists(overrideRes)) {
                QUrl result;
                result.setScheme(QStringLiteral("qrc"));
                result.setPath(overrideRes.mid(1)); // ":/Custom/..." → "/Custom/..."
                return result;
            }
        }
        break;
    default:
        break;
    }
    return url;
}
