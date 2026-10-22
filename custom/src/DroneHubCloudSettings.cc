#include "DroneHubCloudSettings.h"

#include <QtQml/QQmlEngine>

DECLARE_SETTINGGROUP(DroneHubCloud, "DroneHubCloud")
{
    qmlRegisterUncreatableType<DroneHubCloudSettings>(
        "QGroundControl", 1, 0, "DroneHubCloudSettings", "Reference only");
}

DECLARE_SETTINGSFACT(DroneHubCloudSettings, enabled)
DECLARE_SETTINGSFACT(DroneHubCloudSettings, serverUrl)
DECLARE_SETTINGSFACT(DroneHubCloudSettings, apiKey)
DECLARE_SETTINGSFACT(DroneHubCloudSettings, rateHz)
