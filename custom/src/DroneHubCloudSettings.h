#pragma once

#include "SettingsGroup.h"

/// dronehub.ge Cloud backend telemetry forwarding პარამეტრები.
class DroneHubCloudSettings : public SettingsGroup
{
    Q_OBJECT
public:
    explicit DroneHubCloudSettings(QObject* parent = nullptr);
    DEFINE_SETTING_NAME_GROUP()

    DEFINE_SETTINGFACT(enabled)
    DEFINE_SETTINGFACT(serverUrl)
    DEFINE_SETTINGFACT(apiKey)
    DEFINE_SETTINGFACT(rateHz)
};
