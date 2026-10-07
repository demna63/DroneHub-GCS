/****************************************************************************
 * DroneHub GCS — video surface (upstream FlightDisplayViewVideo + branded placeholder).
 ****************************************************************************/

import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.FlyView
import QGroundControl.FlightMap
import QGroundControl.Controls

Item {
    id:     root
    clip:   true

    property bool useSmallFont: true

    property double _ar:                (cameraLoader.visible && cameraLoader.status === Loader.Ready)
                                            ? cameraLoader.item.implicitWidth / cameraLoader.item.implicitHeight
                                            : QGroundControl.videoManager.aspectRatio
    property bool   _showGrid:          QGroundControl.settingsManager.videoSettings.gridLines.rawValue
    property var    _dynamicCameras:    globals.activeVehicle ? globals.activeVehicle.cameraManager : null
    property bool   _connected:         globals.activeVehicle ? !globals.activeVehicle.communicationLost : false
    property int    _curCameraIndex:    _dynamicCameras ? _dynamicCameras.currentCamera : 0
    property bool   _isCamera:          _dynamicCameras ? _dynamicCameras.cameras.count > 0 : false
    property var    _camera:            _isCamera ? _dynamicCameras.cameras.get(_curCameraIndex) : null
    property bool   _hasZoom:           _camera && _camera.hasZoom
    property int    _fitMode:           QGroundControl.settingsManager.videoSettings.videoFit.rawValue
    property bool   _streamEnabled:     QGroundControl.settingsManager.videoSettings.streamEnabled.rawValue
    property bool   _showStreamLoader:  QGroundControl.videoManager.decoding
    property bool   _showUvcLoader:     QGroundControl.videoManager.isUvc

    property bool   _isMode_FIT_WIDTH:  _fitMode === 0
    property bool   _isMode_FIT_HEIGHT: _fitMode === 1
    property bool   _isMode_FILL:       _fitMode === 2
    property bool   _isMode_NO_CROP:    _fitMode === 3

    function getWidth() {
        return videoBackground.getWidth()
    }
    function getHeight() {
        return videoBackground.getHeight()
    }

    property double _thermalHeightFactor: 0.85 //-- TODO

    // Branded "no video" state: transparent light logo on the dark surface (no white
    // box), a slow breathing pulse while waiting, and a quiet status line with
    // animated dots instead of a black label chip.
    Item {
        id:             noVideo
        anchors.fill:   parent
        visible:        !_showStreamLoader && !_showUvcLoader

        readonly property bool _waiting: _streamEnabled

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#10141C" }
                GradientStop { position: 1.0; color: "#080A0F" }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing:          ScreenTools.defaultFontPixelHeight * (useSmallFont ? 0.6 : 1.1)

            Image {
                id:                       placeholderLogo
                source:                   "qrc:/custom/img/dhg-logo-dark.png"
                width:                    Math.min(root.width * (useSmallFont ? 0.42 : 0.24),
                                                   root.height * (useSmallFont ? 0.9 : 0.5) * sourceSize.width / Math.max(1, sourceSize.height))
                fillMode:                 Image.PreserveAspectFit
                smooth:                   true
                mipmap:                   true
                anchors.horizontalCenter: parent.horizontalCenter
                opacity:                  noVideo._waiting ? 0.85 : 0.35

                SequentialAnimation on opacity {
                    running:    noVideo.visible && noVideo._waiting
                    loops:      Animation.Infinite
                    NumberAnimation { from: 0.85; to: 0.45; duration: 1600; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.45; to: 0.85; duration: 1600; easing.type: Easing.InOutSine }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing:                  ScreenTools.defaultFontPixelWidth * 0.8

                QGCLabel {
                    id:                 noVideoLabel
                    anchors.verticalCenter: parent.verticalCenter
                    text:               noVideo._waiting ? qsTr("WAITING FOR VIDEO") : qsTr("VIDEO DISABLED")
                    color:              "#9AA6B8"
                    font.letterSpacing: 1.5
                    font.pointSize:     useSmallFont ? ScreenTools.smallFontPointSize : ScreenTools.defaultFontPointSize
                }

                // Three pulsing dots — activity cue while waiting for the stream.
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    visible:                noVideo._waiting
                    spacing:                ScreenTools.defaultFontPixelWidth * 0.4

                    Repeater {
                        model: 3
                        Rectangle {
                            width:      ScreenTools.defaultFontPixelWidth * 0.6
                            height:     width
                            radius:     width / 2
                            color:      "#20B2AA"
                            opacity:    0.25

                            SequentialAnimation on opacity {
                                running:    noVideo.visible && noVideo._waiting
                                loops:      Animation.Infinite
                                PauseAnimation  { duration: index * 200 }
                                NumberAnimation { to: 1.0;  duration: 400; easing.type: Easing.OutQuad }
                                NumberAnimation { to: 0.25; duration: 400; easing.type: Easing.InQuad }
                                PauseAnimation  { duration: (2 - index) * 200 }
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id:             videoBackground
        anchors.fill:   parent
        color:          "black"
        visible:        _showStreamLoader || _showUvcLoader
        function getWidth() {
            if(_ar != 0.0){
                if(_isMode_FIT_HEIGHT
                        || (_isMode_FILL && (root.width/root.height < _ar))
                        || (_isMode_NO_CROP && (root.width/root.height > _ar))){
                    return root.height * _ar
                }
            }
            return root.width
        }
        function getHeight() {
            if(_ar != 0.0){
                if(_isMode_FIT_WIDTH
                        || (_isMode_FILL && (root.width/root.height > _ar))
                        || (_isMode_NO_CROP && (root.width/root.height < _ar))){
                    return root.width * (1 / _ar)
                }
            }
            return root.height
        }
        Loader {
            id:                 videoStreamLoader
            anchors.fill:       videoContentArea
            visible:            _showStreamLoader
            sourceComponent:    videoOutputComponent

            property bool videoDisabled: QGroundControl.settingsManager.videoSettings.videoSource.rawValue === QGroundControl.settingsManager.videoSettings.disabledVideoSource
        }
        Component {
            id: videoOutputComponent
            FlightDisplayViewVideoOutput {
            }
        }
        //-- UVC Video (USB Camera or Video Device)
        Loader {
            id:             cameraLoader
            anchors.fill:   videoContentArea
            visible:        _showUvcLoader
            source:         _showUvcLoader ? "qrc:/qml/QGroundControl/FlyView/FlightDisplayViewUVC.qml" : "qrc:/qml/QGroundControl/FlyView/FlightDisplayViewDummy.qml"
        }

        Item {
            id:                 videoContentArea
            height:             parent.getHeight()
            width:              parent.getWidth()
            anchors.centerIn:   parent
            visible:           _showStreamLoader || _showUvcLoader

            // grid lines
            Item {
                anchors.fill:   parent
                visible:        _showGrid && !QGroundControl.videoManager.fullScreen

                Rectangle {
                    color:  Qt.rgba(1,1,1,0.5)
                    height: parent.height
                    width:  1
                    x:      parent.width * 0.33
                }
                Rectangle {
                    color:  Qt.rgba(1,1,1,0.5)
                    height: parent.height
                    width:  1
                    x:      parent.width * 0.66
                }
                Rectangle {
                    color:  Qt.rgba(1,1,1,0.5)
                    width:  parent.width
                    height: 1
                    y:      parent.height * 0.33
                }
                Rectangle {
                    color:  Qt.rgba(1,1,1,0.5)
                    width:  parent.width
                    height: 1
                    y:      parent.height * 0.66
                }
            }
        }

        Item {
            id:                 thermalItem
            width:              height * QGroundControl.videoManager.thermalAspectRatio
            height:             _camera ? (_camera.thermalMode === MavlinkCameraControlInterface.THERMAL_FULL ? parent.height : (_camera.thermalMode === MavlinkCameraControlInterface.THERMAL_PIP ? ScreenTools.defaultFontPixelHeight * 12 : parent.height * _thermalHeightFactor)) : 0
            anchors.centerIn:   parent
            visible:            QGroundControl.videoManager.hasThermal && _camera && _camera.thermalMode !== MavlinkCameraControlInterface.THERMAL_OFF
            function pipOrNot() {
                if(_camera) {
                    if(_camera.thermalMode === MavlinkCameraControlInterface.THERMAL_PIP) {
                        anchors.centerIn    = undefined
                        anchors.top         = parent.top
                        anchors.topMargin   = mainWindow.header.height + (ScreenTools.defaultFontPixelHeight * 0.5)
                        anchors.left        = parent.left
                        anchors.leftMargin  = ScreenTools.defaultFontPixelWidth * 12
                    } else {
                        anchors.top         = undefined
                        anchors.topMargin   = undefined
                        anchors.left        = undefined
                        anchors.leftMargin  = undefined
                        anchors.centerIn    = parent
                    }
                }
            }
            Connections {
                target:                 _camera
                function onThermalModeChanged() { thermalItem.pipOrNot() }
            }
            onVisibleChanged: {
                thermalItem.pipOrNot()
            }
            Loader {
                id:             thermalVideo
                anchors.fill:   parent
                opacity:        _camera ? (_camera.thermalMode === MavlinkCameraControlInterface.THERMAL_BLEND ? _camera.thermalOpacity / 100 : 1.0) : 0
                sourceComponent: thermalOutputComponent
                onLoaded: { if (item) item.objectName = "thermalVideo" }

                Component {
                    id: thermalOutputComponent
                    FlightDisplayViewVideoOutput {}
                }
            }
        }
        PinchArea {
            id:             pinchZoom
            enabled:        _hasZoom
            anchors.fill:   parent
            onPinchStarted: pinchZoom.zoom = 0
            onPinchUpdated: {
                if(_hasZoom) {
                    var z = 0
                    if(pinch.scale < 1) {
                        z = Math.round(pinch.scale * -10)
                    } else {
                        z = Math.round(pinch.scale)
                    }
                    if(pinchZoom.zoom != z) {
                        _camera.stepZoom(z)
                    }
                }
            }
            property int zoom: 0
        }
    }
}
