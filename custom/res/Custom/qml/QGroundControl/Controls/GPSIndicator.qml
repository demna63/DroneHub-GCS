/****************************************************************************
 * DroneHub GCS — GPS toolbar indicator with safety coloring.
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
    width:          gpsIndicatorRow.width
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property var    _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property bool   _rtkConnected:  QGroundControl.gpsRtk.connected.value

    function _satCount() {
        if (!_activeVehicle || _activeVehicle.gps.count.rawValue === undefined
                || isNaN(_activeVehicle.gps.count.rawValue)) {
            return NaN
        }
        return _activeVehicle.gps.count.rawValue
    }

    function _gpsLock() {
        if (!_activeVehicle || _activeVehicle.gps.lock.rawValue === undefined) {
            return 0
        }
        return _activeVehicle.gps.lock.rawValue
    }

    function _gpsColor() {
        if (!_activeVehicle) {
            return qgcPal.textDisabled
        }
        var lock = _gpsLock()
        var count = _satCount()
        if (lock <= 1 || (!isNaN(count) && count < 4)) {
            return qgcPal.colorRed
        }
        if (lock === 2 || (!isNaN(count) && count < 8)) {
            return qgcPal.colorOrange
        }
        if (!isNaN(_activeVehicle.gps.hdop.rawValue) && _activeVehicle.gps.hdop.rawValue > 2.0) {
            return qgcPal.colorOrange
        }
        return qgcPal.colorGreen
    }

    QGCPalette { id: qgcPal }

    Row {
        id:             gpsIndicatorRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        spacing:        ScreenTools.defaultFontPixelWidth / 2

        Row {
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            spacing:        -ScreenTools.defaultFontPixelWidth / 2

            QGCLabel {
                id:                     gpsLabel
                rotation:               90
                text:                   qsTr("RTK")
                color:                  _gpsColor()
                anchors.verticalCenter: parent.verticalCenter
                visible:                _rtkConnected
            }

            QGCColoredImage {
                id:                 gpsIcon
                width:              height
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                source:             "/qmlimages/Gps.svg"
                fillMode:           Image.PreserveAspectFit
                sourceSize.height:  height
                opacity:            (_activeVehicle && _satCount() >= 0) ? 1 : 0.5
                color:              _gpsColor()
            }
        }

        Column {
            id:                     gpsValuesColumn
            anchors.verticalCenter: parent.verticalCenter
            visible:                _activeVehicle && !isNaN(_activeVehicle.gps.hdop.value)
            spacing:                0

            QGCLabel {
                anchors.horizontalCenter:   hdopValue.horizontalCenter
                color:              _gpsColor()
                text:               _activeVehicle ? _activeVehicle.gps.count.valueString : ""
            }

            QGCLabel {
                id:     hdopValue
                color:  _gpsColor()
                text:   _activeVehicle ? _activeVehicle.gps.hdop.value.toFixed(1) : ""
            }
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorDrawer(gpsIndicatorPage, control)
    }

    Component {
        id: gpsIndicatorPage

        GPSIndicatorPage { }
    }
}
