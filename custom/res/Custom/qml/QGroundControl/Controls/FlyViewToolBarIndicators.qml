/****************************************************************************
 * DroneHub GCS — toolbar indicator row (RC link beside flight mode / GPS / battery).
 *
 * QGC 5.1 shape (Item wrapper exposing implicitWidth to FlyViewToolBar's right panel);
 * the indicator list/order is ours.
 ****************************************************************************/

import QtQuick

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Toolbar

Item {
    objectName:    "flyViewToolBarIndicators"
    implicitWidth: mainLayout.width + _widthMargin

    property var  _activeVehicle:           QGroundControl.multiVehicleManager.activeVehicle
    property real _toolIndicatorMargins:    ScreenTools.defaultFontPixelHeight * 0.66
    property real _widthMargin:             _toolIndicatorMargins * 2

    // Primary status chips in field-ops order: health → mode → GPS → RC link → battery → extras.
    readonly property var _primaryVehicleIndicators: [
        "qrc:/qml/QGroundControl/Toolbar/VehicleHealthIndicator.qml",
        "qrc:/qml/QGroundControl/Toolbar/FlightModeIndicator.qml",
        "qrc:/qml/QGroundControl/Toolbar/VehicleGPSIndicator.qml",
        "qrc:/qml/QGroundControl/Toolbar/RCRSSIIndicator.qml",
        "qrc:/qml/QGroundControl/Toolbar/BatteryIndicator.qml",
        "qrc:/qml/QGroundControl/Toolbar/VideoStatusIndicator.qml",
        "qrc:/qml/QGroundControl/Toolbar/TelemetryRSSIIndicator.qml",
        "qrc:/qml/QGroundControl/Toolbar/GPSResilienceIndicator.qml",
        "qrc:/qml/QGroundControl/Toolbar/RemoteIDIndicator.qml",
        "qrc:/qml/QGroundControl/Toolbar/GimbalIndicator.qml",
        "qrc:/qml/QGroundControl/Toolbar/EscIndicator.qml",
        "qrc:/qml/QGroundControl/Toolbar/JoystickIndicator.qml"
    ]

    Row {
        id:                 mainLayout
        anchors.margins:    _toolIndicatorMargins
        anchors.left:       parent.left
        anchors.top:        parent.top
        anchors.bottom:     parent.bottom
        spacing:            ScreenTools.defaultFontPixelWidth * 1.75

        Repeater {
            id:     appRepeater
            model:  QGroundControl.corePlugin.toolBarIndicators
            Loader {
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                source:             modelData
                visible:            item && item.showIndicator
            }
        }

        Repeater {
            id:     primaryIndicatorsRepeater
            model:  _activeVehicle ? _primaryVehicleIndicators : []
            Loader {
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                source:             modelData
                visible:            item && item.showIndicator
            }
        }
    }
}
