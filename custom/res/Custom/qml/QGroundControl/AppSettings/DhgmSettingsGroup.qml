/****************************************************************************
 * DroneHub GCS — DHGM forwarding group for Settings → Telemetry.
 *
 * QGC 5.1 generates TelemetrySettings.qml from Telemetry.SettingsUI.json; this group is
 * injected there as a "component" entry (custom/patches/AppSettings-dhgm-telemetry.patch)
 * instead of replacing the whole page, so upstream additions (signing key manager,
 * link status, initial-download option) stay intact.
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

SettingsGroupLayout {
    id: root

    Layout.fillWidth:   true
    heading:            qsTr("DHGM")
    headingDescription: qsTr("ტელემეტრია პირდაპირ GCS-იდან → DHGM რუკა (CoT) + plugin პანელი (JSON). Python bridge აღარ სჭირდება.")

    /// DhgmSettings lives on CustomPlugin, not SettingsManager, so it cannot be a generated control.
    readonly property var _dhgm:     QGroundControl.corePlugin.dhgmSettings
    readonly property bool _enabled: _dhgm ? _dhgm.forwarding.rawValue : false

    visible: _dhgm !== null && _dhgm !== undefined

    FactCheckBoxSlider {
        Layout.fillWidth:   true
        text:               qsTr("DHGM-ზე გადაცემა")
        fact:               root._dhgm ? root._dhgm.forwarding : null
    }

    LabelledFactTextField {
        Layout.fillWidth:           true
        textFieldPreferredWidth:    ScreenTools.defaultFontPixelWidth * 22
        label:                      qsTr("CoT multicast")
        fact:                       root._dhgm ? root._dhgm.cotMulticast : null
        enabled:                    root._enabled
    }

    LabelledFactTextField {
        Layout.fillWidth:           true
        textFieldPreferredWidth:    ScreenTools.defaultFontPixelWidth * 10
        label:                      qsTr("Plugin TCP პორტი")
        fact:                       root._dhgm ? root._dhgm.pluginTcpPort : null
        enabled:                    root._enabled
    }

    LabelledFactTextField {
        Layout.fillWidth:           true
        textFieldPreferredWidth:    ScreenTools.defaultFontPixelWidth * 8
        label:                      qsTr("გადაცემის სიხშირე (Hz)")
        fact:                       root._dhgm ? root._dhgm.rateHz : null
        enabled:                    root._enabled
    }

    LabelledFactTextField {
        Layout.fillWidth:           true
        textFieldPreferredWidth:    ScreenTools.defaultFontPixelWidth * 8
        label:                      qsTr("Stale timeout (წმ)")
        fact:                       root._dhgm ? root._dhgm.staleSeconds : null
        enabled:                    root._enabled
    }
}
