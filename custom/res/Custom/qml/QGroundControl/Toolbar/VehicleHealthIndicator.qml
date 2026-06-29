/****************************************************************************
 * DroneHub GCS — aggregated vehicle health (toolbar diagnostics drawer).
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Palette

Item {
    id:             control
    width:          statusRow.width
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator: true

    property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    property var  _videoManager:    QGroundControl.videoManager
    property var  _videoSettings:   QGroundControl.settingsManager.videoSettings
    property bool _linkLost:        _activeVehicle
                                    ? _activeVehicle.vehicleLinkManager.communicationLost
                                    : false
    property var  _battery:         (_activeVehicle && _activeVehicle.batteries.count > 0)
                                    ? _activeVehicle.batteries.get(0) : null
    property int  _batteryPct:      (_battery && !isNaN(_battery.percentRemaining.rawValue))
                                    ? Math.round(_battery.percentRemaining.rawValue) : -1
    property bool _rcDataValid:     _activeVehicle
                                    && _activeVehicle.rcRSSI > 0
                                    && _activeVehicle.rcRSSI <= 100
    property int  _gpsLock:           (_activeVehicle && _activeVehicle.gps.lock.rawValue !== undefined)
                                    ? _activeVehicle.gps.lock.rawValue : -1
    property int  _gpsCount:          (_activeVehicle && !isNaN(_activeVehicle.gps.count.rawValue))
                                    ? _activeVehicle.gps.count.rawValue : -1
    property real _gpsHdop:           (_activeVehicle && !isNaN(_activeVehicle.gps.hdop.rawValue))
                                    ? _activeVehicle.gps.hdop.rawValue : NaN
    property bool _videoLive:         _videoSettings.streamEnabled.rawValue
                                    && _videoManager.hasVideo
                                    && _videoManager.decoding

    readonly property int _levelOk:   0
    readonly property int _levelWarn:   1
    readonly property int _levelCrit:   2
    readonly property int _levelIdle:   3

    property int _worstLevel: {
        if (!_activeVehicle) {
            return _levelIdle
        }
        if (_linkLost) {
            return _levelCrit
        }
        var level = _levelOk
        if (_batteryPct >= 0) {
            if (_batteryPct < 25) {
                level = Math.max(level, _levelCrit)
            } else if (_batteryPct < 50) {
                level = Math.max(level, _levelWarn)
            }
        }
        if (_rcDataValid) {
            if (_activeVehicle.rcRSSI < 30) {
                level = Math.max(level, _levelCrit)
            } else if (_activeVehicle.rcRSSI < 60) {
                level = Math.max(level, _levelWarn)
            }
        }
        if (_gpsLock <= 0) {
            level = Math.max(level, _levelCrit)
        } else if (_gpsCount < 6 || (!isNaN(_gpsHdop) && _gpsHdop > 2.0)) {
            level = Math.max(level, _levelWarn)
        }
        return level
    }

    function _shortLabel() {
        switch (_worstLevel) {
        case _levelOk:   return qsTr("OK")
        case _levelWarn: return qsTr("Warn")
        case _levelCrit: return qsTr("Crit")
        default:         return "—"
        }
    }

    function _statusColor() {
        switch (_worstLevel) {
        case _levelOk:   return qgcPal.colorGreen
        case _levelWarn: return qgcPal.colorOrange
        case _levelCrit: return qgcPal.colorRed
        default:         return qgcPal.textDisabled
        }
    }

    function _gpsSummary() {
        if (!_activeVehicle) {
            return qsTr("No vehicle")
        }
        if (_gpsLock <= 0) {
            return qsTr("No GPS lock")
        }
        var text = _gpsCount >= 0 ? (_gpsCount + " " + qsTr("sats")) : qsTr("Locked")
        if (!isNaN(_gpsHdop)) {
            text += " · HDOP " + _activeVehicle.gps.hdop.valueString
        }
        return text
    }

    function _linkSummary() {
        if (!_activeVehicle) {
            return qsTr("No vehicle")
        }
        return _linkLost ? qsTr("Link lost") : qsTr("Link OK")
    }

    function _rcSummary() {
        if (!_activeVehicle) {
            return qsTr("No vehicle")
        }
        if (!_activeVehicle.supportsRadio) {
            return qsTr("Not supported")
        }
        return _rcDataValid ? (_activeVehicle.rcRSSI + "%") : qsTr("No data")
    }

    function _batterySummary() {
        if (!_battery || _batteryPct < 0) {
            return qsTr("No data")
        }
        return _batteryPct + "%"
    }

    function _videoSummary() {
        if (!_videoSettings.streamEnabled.rawValue) {
            return qsTr("Disabled")
        }
        if (!_videoManager.hasVideo) {
            return qsTr("Not compiled")
        }
        if (_videoLive) {
            return qsTr("Live")
        }
        return qsTr("Waiting")
    }

    QGCPalette { id: qgcPal }

    Component {
        id: healthPage

        ToolIndicatorPage {
            showExpand: false

            contentComponent: SettingsGroupLayout {
                heading: qsTr("Vehicle health")

                LabelledLabel {
                    label:      qsTr("Link")
                    labelText:  control._linkSummary()
                }
                LabelledLabel {
                    label:      qsTr("Flight mode")
                    labelText:  _activeVehicle ? _activeVehicle.flightMode : qsTr("No vehicle")
                }
                LabelledLabel {
                    label:      qsTr("Armed")
                    labelText:  !_activeVehicle ? qsTr("No vehicle")
                                    : (_activeVehicle.armed ? qsTr("Yes") : qsTr("No"))
                }
                LabelledLabel {
                    label:      qsTr("GPS")
                    labelText:  control._gpsSummary()
                }
                LabelledLabel {
                    label:      qsTr("RC link")
                    labelText:  control._rcSummary()
                }
                LabelledLabel {
                    label:      qsTr("Battery")
                    labelText:  control._batterySummary()
                }
                LabelledLabel {
                    label:      qsTr("Video")
                    labelText:  control._videoSummary()
                }
            }
        }
    }

    Row {
        id:             statusRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        spacing:        ScreenTools.defaultFontPixelWidth / 2

        Rectangle {
            width:              height
            height:             parent.height * 0.55
            anchors.verticalCenter: parent.verticalCenter
            radius:             width / 2
            color:              control._statusColor()
            opacity:            _worstLevel === _levelIdle ? 0.45 : 1.0
        }

        QGCLabel {
            anchors.verticalCenter: parent.verticalCenter
            text:                   control._shortLabel()
            color:                  control._statusColor()
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorDrawer(healthPage, control)
    }
}
