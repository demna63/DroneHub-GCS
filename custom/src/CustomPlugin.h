#pragma once

#include "QGCCorePlugin.h"
#include "QGCOptions.h"

class CustomOptions;

/// DroneHub GCS core plugin.
/// Overrides QGC branding, palette and forces Georgian (ka) locale +
/// registers a Georgian-capable font so glyphs render correctly.
class CustomPlugin : public QGCCorePlugin
{
    Q_OBJECT
public:
    explicit CustomPlugin(QGCApplication* app, QGCToolbox* toolbox);
    ~CustomPlugin() override;

    // QGCCorePlugin overrides
    void                setToolbox(QGCToolbox* toolbox) override;
    QGCOptions*         options() override;
    QString             brandImageIndoor()  const override { return QStringLiteral("/custom/res/DroneHubLogo.svg"); }
    QString             brandImageOutdoor() const override { return QStringLiteral("/custom/res/DroneHubLogo.svg"); }
    bool                overrideSettingsGroupVisibility(QString name) override;
    QString             showAdvancedUIMessage() const override;

    /// Registers bundled Georgian font and pins QLocale to ka.
    /// Must run before the QML engine loads any text.
    static void         applyGeorgianLocaleAndFont();

private:
    CustomOptions*      _options = nullptr;
};
