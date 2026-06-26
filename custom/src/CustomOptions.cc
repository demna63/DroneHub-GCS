#include "CustomOptions.h"

/*===========================================================================*/

CustomFlyViewOptions::CustomFlyViewOptions(CustomOptions* options, QObject* parent)
    : QGCFlyViewOptions(options, parent)
{
}

// DroneHub field ops fly a single vehicle — keep the multi-vehicle list hidden.
bool CustomFlyViewOptions::showMultiVehicleList() const
{
    return false;
}

// Standard instrument panel stays visible (no custom panel yet).
bool CustomFlyViewOptions::showInstrumentPanel() const
{
    return true;
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
