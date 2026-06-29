#include "CustomPlugin.h"
#include "CustomOptions.h"
#include "geo/geo_mag_declination.h"

#include "QGCLoggingCategory.h"
#include "BrandImageSettings.h"
#include "AppSettings.h"
#include "QGCMAVLink.h"
#include "FactMetaData.h"
#include "SettingsManager.h"
#include "MavlinkActionsSettings.h"

#include <QtCore/QDir>
#include <QtCore/QFile>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtCore/QApplicationStatic>
#include <QtCore/QLocale>
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
{
}

CustomPlugin::~CustomPlugin() = default;

QGCCorePlugin* CustomPlugin::instance()
{
    return _customPluginInstance();
}

void CustomPlugin::init()
{
    _applyGeorgianLocaleAndFont();
    _installDefaultMavlinkActions();
}

void CustomPlugin::cleanup()
{
    if (_qmlEngine && _selector) {
        _qmlEngine->removeUrlInterceptor(_selector);
    }
    delete _selector;
    _selector = nullptr;
}

QGCOptions* CustomPlugin::options()
{
    return _options;
}

QString CustomPlugin::brandImageIndoor() const
{
    return QStringLiteral("/custom/img/dggcs-logo-original.png");
}

QString CustomPlugin::brandImageOutdoor() const
{
    return QStringLiteral("/custom/img/dggcs-logo-original.png");
}

QString CustomPlugin::showAdvancedUIMessage() const
{
    return tr("გაფართოებული რეჟიმი მხოლოდ გამოცდილი ოპერატორებისთვისაა და შეიცავს "
              "პარამეტრებს, რომლებიც ფრენის უსაფრთხოებაზე მოქმედებს. გავაგრძელო?");
}

bool CustomPlugin::overrideSettingsGroupVisibility(const QString& name)
{
    // ჩვენი ბრენდის ლოგო fix-ირებულია — დავმალოთ Brand Image პარამეტრები,
    // რომ მომხმარებელმა ვერ შეცვალოს.
    if (name == BrandImageSettings::name) {
        return false;
    }
    return QGCCorePlugin::overrideSettingsGroupVisibility(name);
}

// F3: offline Plan-ის default firmware/vehicle — DroneHub PX4 multirotor.
// ეს განსაზღვრავს, რა აპარატისთვის იქმნება mission, როცა vehicle არ არის მიერთებული.
bool CustomPlugin::adjustSettingMetaData(const QString& settingsGroup, FactMetaData& metaData)
{
    const bool parentResult = QGCCorePlugin::adjustSettingMetaData(settingsGroup, metaData);

    if (settingsGroup == AppSettings::settingsGroup) {
        if (metaData.name() == AppSettings::offlineEditingFirmwareClassName) {
            metaData.setRawDefaultValue(QGCMAVLink::FirmwareClassPX4);
            return false;
        } else if (metaData.name() == AppSettings::offlineEditingVehicleClassName) {
            metaData.setRawDefaultValue(QGCMAVLink::VehicleClassMultiRotor);
            return false;
        }
    }

    if (settingsGroup == MavlinkActionsSettings::settingsGroup) {
        if (metaData.name() == MavlinkActionsSettings::flyViewActionsFileName) {
            metaData.setRawDefaultValue(QStringLiteral("DroneHub-flyview-actions.json"));
            return false;
        }
        if (metaData.name() == MavlinkActionsSettings::joystickActionsFileName) {
            metaData.setRawDefaultValue(QStringLiteral("DroneHub-joystick-actions.json"));
            return false;
        }
    }

    return parentResult;
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
    constexpr int kBundledMavlinkActionsVersion = 2;

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

/*===========================================================================*/

CustomOverrideInterceptor::CustomOverrideInterceptor()
    : QQmlAbstractUrlInterceptor()
{
}

QUrl CustomOverrideInterceptor::intercept(const QUrl& url, QQmlAbstractUrlInterceptor::DataType type)
{
    switch (type) {
    using DataType = QQmlAbstractUrlInterceptor::DataType;
    case DataType::QmlFile:
    case DataType::UrlString:
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
