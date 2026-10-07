#pragma once

#include <QtGui/QColor>

#include "QGCOptions.h"

class CustomPlugin;
class CustomOptions;

/// Fly View behaviour tweaks for DroneHub single-vehicle field ops.
class CustomFlyViewOptions : public QGCFlyViewOptions
{
public:
    explicit CustomFlyViewOptions(CustomOptions* options, QObject* parent = nullptr);

    // QGCFlyViewOptions overrides
    bool showInstrumentPanel()  const final;
    bool showMultiVehicleList() const final;
};

/// DroneHub UI option overrides (toolbar colors, calibration, fly-view).
/// API ემთხვევა QGC v5.1.x-ს: ctor(CustomPlugin*, QObject*) + flyViewOptions().
class CustomOptions : public QGCOptions
{
public:
    explicit CustomOptions(CustomPlugin* plugin, QObject* parent = nullptr);

    // QGCOptions overrides
    bool                showFirmwareUpgrade()        const final;
    const QGCFlyViewOptions* flyViewOptions()        const final;
    QColor              toolbarBackgroundLight()      const final;
    QColor              toolbarBackgroundDark()       const final;

private:
    CustomPlugin*         _plugin         = nullptr;   // forward-declared above
    CustomFlyViewOptions* _flyViewOptions = nullptr;
};
