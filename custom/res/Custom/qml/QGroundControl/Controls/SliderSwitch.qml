/****************************************************************************
 * DroneHub GCS — slide-to-confirm control (guided actions).
 ****************************************************************************/

import QtQuick
import QtQuick.Controls

import QGroundControl.ScreenTools
import QGroundControl.Palette

Rectangle {
    id:             _root
    implicitWidth:  label.contentWidth + (_diameter * 2.5) + (_border * 4)
    implicitHeight: Math.max(label.height * 2.5, ScreenTools.defaultFontPixelHeight * 2.4)
    radius:         height / 2
    color:          _trackFill
    border.width:   1
    border.color:   _trackBorder

    signal accept

    property string confirmText
    property alias  fontPointSize: label.font.pointSize

    readonly property color _brandPrimary:  "#0A84FF"
    readonly property color _trackFill:     "#442A323F"
    readonly property color _trackBorder:   "#44FFFFFF"
    readonly property color _hintText:      "#B8C4D4"
    readonly property color _thumbText:     "#FFFFFF"

    property real _border:   4
    property real _diameter: height - (_border * 2)
    property real _dragStartX: _border
    property real _dragStopX:  _root.width - (_diameter + _border)

    Keys.onSpacePressed: (event) => {
        if (visible && event.modifiers === Qt.NoModifier && !sliderDragArea.drag.active) {
            event.accepted = true
            sliderAnimation.start()
        }
    }

    Keys.onReleased: (event) => {
        if (visible && event.key === Qt.Key_Space && !event.isAutoRepeat) {
            event.accepted = true
            resetSpaceBarSliding()
        }
    }

    function resetSpaceBarSliding() {
        slider.reset()
    }

    Text {
        id:                         label
        x:                          _diameter + _border + 4
        width:                      parent.width - x - _border
        anchors.verticalCenter:     parent.verticalCenter
        horizontalAlignment:        Text.AlignHCenter
        text:                       confirmText
        color:                      _hintText
        font.family:                "Noto Sans Georgian"
        font.pixelSize:             ScreenTools.smallFontPointSize
        font.weight:                Font.Medium
        style:                      Text.Outline
        styleColor:                 "#88000000"
    }

    Rectangle {
        id:         slider
        x:          _border
        y:          _border
        height:     _diameter
        width:      _diameter
        radius:     _diameter / 2
        color:      _brandPrimary
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.2)

        QGCColoredImage {
            anchors.centerIn:       parent
            width:                  parent.width * 0.42
            height:                 parent.height * 0.42
            sourceSize.height:        height
            fillMode:               Image.PreserveAspectFit
            smooth:                 true
            color:                  _thumbText
            cache:                  false
            source:                 "/res/ArrowRight.svg"
        }

        PropertyAnimation on x {
            id:         sliderAnimation
            duration:   1500
            from:       _dragStartX
            to:         _dragStopX
            running:    false

            onFinished: {
                slider.reset()
                _root.accept()
            }
        }

        function reset() {
            slider.x = _border
            sliderAnimation.stop()
        }
    }

    QGCMouseArea {
        id:                 sliderDragArea
        anchors.leftMargin: -ScreenTools.defaultFontPixelWidth * 15
        fillItem:           slider
        drag.target:        slider
        drag.axis:          Drag.XAxis
        drag.minimumX:      _dragStartX
        drag.maximumX:      _dragStopX
        preventStealing:    true

        property bool dragActive: drag.active

        onDragActiveChanged: {
            if (!sliderDragArea.drag.active) {
                if (slider.x > _dragStopX - _border) {
                    _root.accept()
                }
                slider.reset()
            }
        }
    }
}
