#include "DhgmSettings.h"

#include <QtQml/QQmlEngine>

DECLARE_SETTINGGROUP(DHGM, "DHGM")
{
    qmlRegisterUncreatableType<DhgmSettings>(
        "QGroundControl", 1, 0, "DhgmSettings", "Reference only");
}

DECLARE_SETTINGSFACT(DhgmSettings, forwarding)
DECLARE_SETTINGSFACT(DhgmSettings, cotMulticast)
DECLARE_SETTINGSFACT(DhgmSettings, pluginTcpPort)
DECLARE_SETTINGSFACT(DhgmSettings, rateHz)
DECLARE_SETTINGSFACT(DhgmSettings, staleSeconds)
