/****************************************************************************
 * DroneHub GCS — toolbar indicator row (RC link beside flight mode / GPS / battery).
 ****************************************************************************/

import QtQuick

import QGroundControl
import QGroundControl.ScreenTools

Row {
    id:                 indicatorRow
    anchors.top:        parent.top
    anchors.bottom:     parent.bottom
    anchors.margins:    _toolIndicatorMargins
    spacing:            ScreenTools.defaultFontPixelWidth * 1.75

    property var  _activeVehicle:           QGroundControl.multiVehicleManager.activeVehicle
    property real _toolIndicatorMargins:    ScreenTools.defaultFontPixelHeight * 0.66

    // Primary status chips in field-ops order: health → mode → GPS → RC link → battery → extras.
    readonly property var _primaryVehicleIndicators: [
        "qrc:/qml/QGroundControl/Toolbar/VehicleHealthIndicator.qml",
        "qrc:/qml/QGroundControl/Controls/FlightModeIndicator.qml",
        "qrc:/qml/QGroundControl/Toolbar/VehicleGPSIndicator.qml",
        "qrc:/qml/QGroundControl/Toolbar/RCRSSIIndicator.qml",
        "qrc:/qml/QGroundControl/Controls/BatteryIndicator.qml",
        "qrc:/qml/QGroundControl/Toolbar/VideoStatusIndicator.qml",
        "qrc:/qml/QGroundControl/Toolbar/TelemetryRSSIIndicator.qml",
        "qrc:/qml/QGroundControl/Toolbar/RemoteIDIndicator.qml",
        "qrc:/qml/QGroundControl/Toolbar/GimbalIndicator.qml"
    ]

    Repeater {
        model:  QGroundControl.corePlugin.toolBarIndicators
        Loader {
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            source:             modelData
            visible:            item && item.showIndicator
        }
    }

    Repeater {
        model: _activeVehicle ? _primaryVehicleIndicators : []
        Loader {
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            source:             modelData
            visible:            item && item.showIndicator
        }
    }

    Repeater {
        model: _activeVehicle ? _activeVehicle.modeIndicators : []
        Loader {
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            source:             modelData
            visible:            item && item.showIndicator
        }
    }
}
