#include "CustomOptions.h"

/*===========================================================================*/

CustomFlyViewOptions::CustomFlyViewOptions(CustomOptions* options, QObject* parent)
    : QGCFlyViewOptions(options, parent)
{
}

// Inherit the upstream default (true). NOTE: in this QGC version this option has
// no QML consumer — the Fly View multi-vehicle panel (FlyViewTopRightPanel) is
// governed by the appSettings.enableMultiVehiclePanel setting plus vehicles.count>1,
// not by this flag. Returning false here was therefore a no-op that misleadingly
// implied single-vehicle-only; we defer to the base so a future QGC rebase that
// reconnects this flag does not silently hide multi-vehicle switching.
bool CustomFlyViewOptions::showMultiVehicleList() const
{
    return QGCFlyViewOptions::showMultiVehicleList();
}

// DroneHub custom HUD replaces the upstream instrument strip.
bool CustomFlyViewOptions::showInstrumentPanel() const
{
    return false;
}

/*===========================================================================*/

CustomOptions::CustomOptions(CustomPlugin* plugin, QObject* parent)
    : QGCOptions(parent)
    , _plugin(plugin)
    , _flyViewOptions(new CustomFlyViewOptions(this, this))
{
    Q_CHECK_PTR(_plugin);
}

QGCFlyViewOptions* CustomOptions::flyViewOptions() const
{
    return _flyViewOptions;
}

// Real-world WiFi telemetry links are not reliable enough to suppress the
// PX4 calibration WiFi warning — keep QGC's default safety warning.
bool CustomOptions::wifiReliableForCalibration() const
{
    return false;
}

bool CustomOptions::showFirmwareUpgrade() const
{
    return true;
}

// Toolbar background — mirrors Theme.bgSurface / Theme.bgBase.
QColor CustomOptions::toolbarBackgroundLight() const
{
    return QColor("#151A23");
}

QColor CustomOptions::toolbarBackgroundDark() const
{
    return QColor("#0B0E14");
}
