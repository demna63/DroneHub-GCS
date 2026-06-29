/****************************************************************************
 * DroneHub GCS — video stream status (toolbar diagnostics).
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

    property var  _videoManager:    QGroundControl.videoManager
    property var  _videoSettings:   QGroundControl.settingsManager.videoSettings
    property bool _streamEnabled:   _videoSettings.streamEnabled.rawValue
    property bool _hasBackend:      _videoManager.hasVideo
    property bool _decoding:        _videoManager.decoding

    readonly property int _stateOff:       0
    readonly property int _stateNoBackend: 1
    readonly property int _stateWaiting:   2
    readonly property int _stateLive:      3

    property int _state: {
        if (!_streamEnabled) {
            return _stateOff
        }
        if (!_hasBackend) {
            return _stateNoBackend
        }
        if (_decoding) {
            return _stateLive
        }
        return _stateWaiting
    }

    function _shortLabel() {
        switch (_state) {
        case _stateOff:       return qsTr("Off")
        case _stateNoBackend: return qsTr("N/A")
        case _stateWaiting:   return qsTr("Wait")
        case _stateLive:      return qsTr("Live")
        default:              return "—"
        }
    }

    function _detailLabel() {
        switch (_state) {
        case _stateOff:       return qsTr("Video off")
        case _stateNoBackend: return qsTr("No video backend")
        case _stateWaiting:   return qsTr("Video waiting")
        case _stateLive:      return qsTr("Video live")
        default:              return qsTr("Video")
        }
    }

    function _statusColor() {
        switch (_state) {
        case _stateLive:      return qgcPal.colorGreen
        case _stateWaiting:   return qgcPal.colorOrange
        case _stateNoBackend: return qgcPal.colorRed
        default:              return qgcPal.textDisabled
        }
    }

    QGCPalette { id: qgcPal }

    Component {
        id: videoStatusPage

        ToolIndicatorPage {
            showExpand: false

            contentComponent: SettingsGroupLayout {
                heading: qsTr("Video status")

                LabelledLabel {
                    label:      qsTr("Stream")
                    labelText:  _streamEnabled ? qsTr("Enabled") : qsTr("Disabled")
                }
                LabelledLabel {
                    label:      qsTr("Backend")
                    labelText:  _hasBackend ? qsTr("Available") : qsTr("Not compiled")
                }
                LabelledLabel {
                    label:      qsTr("State")
                    labelText:  control._detailLabel()
                }
            }
        }
    }

    Row {
        id:             statusRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        spacing:        ScreenTools.defaultFontPixelWidth / 2

        QGCColoredImage {
            width:              height
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            sourceSize.height:  height
            source:             "/qmlimages/camera_video.svg"
            fillMode:           Image.PreserveAspectFit
            color:              control._statusColor()
            opacity:            _state === _stateOff ? 0.55 : 1.0
        }

        QGCLabel {
            anchors.verticalCenter: parent.verticalCenter
            text:                   control._shortLabel()
            color:                  control._statusColor()
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorDrawer(videoStatusPage, control)
    }
}
