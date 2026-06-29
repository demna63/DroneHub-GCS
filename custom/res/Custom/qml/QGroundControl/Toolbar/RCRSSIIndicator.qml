/****************************************************************************
 * DroneHub GCS — RC transmitter link quality (toolbar).
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Palette

Item {
    id:             control
    width:          rssiRow.width
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    property bool _rcDataValid:     _activeVehicle
                                    && _activeVehicle.rcRSSI > 0
                                    && _activeVehicle.rcRSSI <= 100
    property int  _rcPercent:       _rcDataValid ? _activeVehicle.rcRSSI : 0

    // Show whenever the autopilot reports RC radio support — even before first RSSI sample.
    property bool showIndicator:    _activeVehicle && _activeVehicle.supportsRadio

    function _rcColor() {
        if (!_rcDataValid) {
            return qgcPal.textDisabled
        }
        if (_rcPercent < 30) {
            return qgcPal.colorRed
        }
        if (_rcPercent < 60) {
            return qgcPal.colorOrange
        }
        return qgcPal.colorGreen
    }

    Component {
        id: rcRSSIInfoPage

        ToolIndicatorPage {
            showExpand: false

            contentComponent: SettingsGroupLayout {
                heading: qsTr("RC RSSI Status")

                LabelledLabel {
                    label:      qsTr("RSSI")
                    labelText:  _rcDataValid ? (_activeVehicle.rcRSSI + "%") : qsTr("No data")
                }
            }
        }
    }

    Row {
        id:             rssiRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        spacing:        ScreenTools.defaultFontPixelWidth / 2

        QGCColoredImage {
            width:              height
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            sourceSize.height:  height
            source:             "/qmlimages/RC.svg"
            fillMode:           Image.PreserveAspectFit
            opacity:            _rcDataValid ? 1 : 0.5
            color:              _rcColor()
        }

        SignalStrength {
            anchors.verticalCenter: parent.verticalCenter
            size:                   parent.height * 0.5
            percent:                _rcPercent
        }

        QGCLabel {
            anchors.verticalCenter: parent.verticalCenter
            color:                  _rcColor()
            text:                   _rcDataValid ? (_activeVehicle.rcRSSI + "%") : "—"
        }
    }

    QGCPalette { id: qgcPal }

    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorDrawer(rcRSSIInfoPage, control)
    }
}
