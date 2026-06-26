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
/// API ემთხვევა QGC Stable_V5.0-ს: ctor(CustomPlugin*, QObject*) + flyViewOptions().
class CustomOptions : public QGCOptions
{
public:
    explicit CustomOptions(CustomPlugin* plugin, QObject* parent = nullptr);

    // QGCOptions overrides
    bool                wifiReliableForCalibration() const final;
    bool                showFirmwareUpgrade()        const final;
    QGCFlyViewOptions*  flyViewOptions()             const final;
    QColor              toolbarBackgroundLight()      const final;
    QColor              toolbarBackgroundDark()       const final;

private:
    QGCCorePlugin*        _plugin         = nullptr;
    CustomFlyViewOptions* _flyViewOptions = nullptr;
};
