#pragma once

#include "SettingsGroup.h"

/// DHGM forwarding პარამეტრები — Settings → Telemetry → „DHGM".
class DhgmSettings : public SettingsGroup
{
    Q_OBJECT
public:
    explicit DhgmSettings(QObject* parent = nullptr);
    DEFINE_SETTING_NAME_GROUP()

    DEFINE_SETTINGFACT(forwarding)
    DEFINE_SETTINGFACT(cotMulticast)
    DEFINE_SETTINGFACT(pluginTcpPort)
    DEFINE_SETTINGFACT(rateHz)
    DEFINE_SETTINGFACT(staleSeconds)
};
