#pragma once

#include "QGCOptions.h"

/// DroneHub UI option overrides (toolbar, multi-vehicle, etc.).
class CustomOptions : public QGCOptions
{
    Q_OBJECT
public:
    explicit CustomOptions(QGCCorePlugin* corePlugin, QObject* parent = nullptr);

    bool wifiReliableForCalibration() const override { return false; }
    bool showFirmwareUpgrade()        const override { return true;  }
    QColor toolbarBackgroundLight()   const override;
    QColor toolbarBackgroundDark()    const override;
};
