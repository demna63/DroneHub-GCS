#include "CustomPlugin.h"
#include "CustomOptions.h"

#include <QtGui/QFontDatabase>
#include <QtCore/QLocale>
#include <QtCore/QTranslator>
#include <QtCore/QCoreApplication>
#include <QtCore/QLoggingCategory>

QGC_LOGGING_CATEGORY(CustomPluginLog, "DroneHub.CustomPlugin")

CustomPlugin::CustomPlugin(QGCApplication* app, QGCToolbox* toolbox)
    : QGCCorePlugin(app, toolbox)
{
    _options = new CustomOptions(this, this);
}

CustomPlugin::~CustomPlugin() = default;

void CustomPlugin::setToolbox(QGCToolbox* toolbox)
{
    QGCCorePlugin::setToolbox(toolbox);
    // Palette override is driven from QML (Custom/Theme.qml) via resource override.
}

QGCOptions* CustomPlugin::options()
{
    return _options;
}

bool CustomPlugin::overrideSettingsGroupVisibility(QString name)
{
    // Hide groups irrelevant to DroneHub field ops; default = visible.
    return QGCCorePlugin::overrideSettingsGroupVisibility(name);
}

QString CustomPlugin::showAdvancedUIMessage() const
{
    return tr("გაფართოებული რეჟიმი მხოლოდ გამოცდილი ოპერატორებისთვისაა. გავაგრძელო?");
}

/// Bundled font + locale pin. Call from main() BEFORE QQmlApplicationEngine.
void CustomPlugin::applyGeorgianLocaleAndFont()
{
    const int fontId = QFontDatabase::addApplicationFont(
        QStringLiteral(":/custom/res/fonts/NotoSansGeorgian.ttf"));

    if (fontId < 0) {
        qCWarning(CustomPluginLog) << "Georgian font failed to load — glyphs may render as boxes.";
    } else {
        const QStringList families = QFontDatabase::applicationFontFamilies(fontId);
        if (!families.isEmpty()) {
            QGuiApplication::setFont(QFont(families.first()));
            qCDebug(CustomPluginLog) << "Georgian font registered:" << families.first();
        }
    }

    // Pin UI locale to Georgian regardless of host OS locale.
    QLocale::setDefault(QLocale(QLocale::Georgian, QLocale::Georgia));
}
