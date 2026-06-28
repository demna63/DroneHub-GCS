/****************************************************************************
 * DroneHub GCS — slide-to-confirm track (optional hint above track).
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl.ScreenTools
import QGroundControl.Palette

import Custom

Item {
    id:             _root
    implicitWidth:  track.width
    implicitHeight: (hintText.visible ? hintText.implicitHeight + spacing : 0) + track.height

    signal accept

    property string confirmText: ""
    property alias  fontPointSize: hintText.font.pointSize
    property real   trackHeight: ScreenTools.defaultFontPixelHeight * 2.5

    readonly property color _brandPrimary:  Theme.brandPrimary
    readonly property color _trackFill:     Theme.sliderTrackFill
    readonly property color _trackBorder:   Theme.sliderTrackBorder
    readonly property color _hintText:      Theme.textSecondary
    readonly property color _thumbText:     Theme.textPrimary

    property real spacing: ScreenTools.defaultFontPixelHeight * 0.35
    property real _border: 4

    Keys.onSpacePressed: (event) => {
        if (visible && event.modifiers === Qt.NoModifier && !sliderDragArea.drag.active) {
            event.accepted = true
            sliderAnimation.start()
        }
    }

    Keys.onReleased: (event) => {
        if (visible && event.key === Qt.Key_Space && !event.isAutoRepeat) {
            event.accepted = true
            slider.reset()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: _root.spacing

        Text {
            id:                     hintText
            Layout.fillWidth:       true
            visible:                confirmText !== ""
            text:                   confirmText
            wrapMode:               Text.WordWrap
            horizontalAlignment:    Text.AlignHCenter
            color:                  _hintText
            font.family:            Theme.fontFamily
            font.pixelSize:         ScreenTools.defaultFontPointSize * 0.9
            font.weight:            Font.Medium
            style:                  Text.Outline
            styleColor:             "#88000000"
        }

        Rectangle {
            id:                 track
            Layout.fillWidth:   true
            height:             _root.trackHeight
            radius:             height / 2
            color:              _trackFill
            border.width:       1
            border.color:       _trackBorder

            property real _diameter: height - (_root._border * 2)
            property real _dragStartX: _root._border
            property real _dragStopX:  Math.max(_root._border, width - (_diameter + _root._border))

            onWidthChanged: slider.x = Math.min(slider.x, _dragStopX)

            Rectangle {
                id:         slider
                x:          track._dragStartX
                y:          _root._border
                height:     track._diameter
                width:      track._diameter
                radius:     track._diameter / 2
                color:      _brandPrimary
                border.width: 1
                border.color: Theme.sliderThumbBorder

                QGCColoredImage {
                    anchors.centerIn:       parent
                    width:                  parent.width * 0.42
                    height:                 parent.height * 0.42
                    sourceSize.height:      height
                    fillMode:               Image.PreserveAspectFit
                    smooth:                 true
                    color:                  _thumbText
                    cache:                  false
                    source:                 "/res/ArrowRight.svg"
                }

                PropertyAnimation on x {
                    id:         sliderAnimation
                    duration:   1500
                    from:       track._dragStartX
                    to:         track._dragStopX
                    running:    false

                    onFinished: {
                        slider.reset()
                        _root.accept()
                    }
                }

                function reset() {
                    slider.x = track._dragStartX
                    sliderAnimation.stop()
                }
            }

            QGCMouseArea {
                id:                 sliderDragArea
                anchors.leftMargin: -ScreenTools.defaultFontPixelWidth * 15
                fillItem:           slider
                drag.target:        slider
                drag.axis:          Drag.XAxis
                drag.minimumX:      track._dragStartX
                drag.maximumX:      track._dragStopX
                preventStealing:    true

                property bool dragActive: drag.active

                onDragActiveChanged: {
                    if (!sliderDragArea.drag.active) {
                        if (slider.x >= track._dragStopX - _root._border) {
                            _root.accept()
                        }
                        slider.reset()
                    }
                }
            }
        }
    }
}
