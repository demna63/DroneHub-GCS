/****************************************************************************
 * DroneHub GCS — MAVLink action slide-to-confirm dialog.
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.Palette

import Custom

Rectangle {
    id:         _root
    parent:     Overlay.overlay
    anchors.fill: parent
    color:      "#66000000"
    visible:    false
    z:          10000

    property var mavlinkAction
    property var vehicle

    readonly property color _brandPrimary:   Theme.brandPrimary
    readonly property color _cardFill:       Theme.toastFill
    readonly property color _cardBorder:     Theme.toastBorder
    readonly property color _textPrimary:    Theme.textPrimary
    readonly property color _textSecondary:  Theme.textSecondary
    readonly property color _danger:         Theme.danger
    readonly property real  _radiusLg:       Theme.toastRadius
    readonly property string _fontFamily:    Theme.fontFamily
    readonly property real  _margins:      ScreenTools.defaultFontPixelWidth * 1.15
    readonly property real  _trackHeight:  ScreenTools.defaultFontPixelHeight * 2.5
    readonly property string _slideHint:   ScreenTools.isMobile
                                                ? qsTr("Slide to confirm")
                                                : qsTr("Slide or hold spacebar")

    function open() {
        slider.reset()
        visible = true
        slider.focus = true
    }

    function close() {
        visible = false
    }

    Keys.onEscapePressed: close()
    Keys.onReleased: (event) => {
        if (event.key === Qt.Key_Escape) {
            event.accepted = true
            close()
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: _root.close()
    }

    Rectangle {
        id:                 card
        anchors.centerIn:   parent
        width:              Math.min(
                                Math.max(ScreenTools.defaultFontPixelWidth * 54, cardLayout.implicitWidth + (_margins * 2)),
                                parent.width * 0.88)
        height:             cardLayout.implicitHeight + (_margins * 2)
        radius:             _radiusLg
        color:              _cardFill
        border.width:       1
        border.color:       _cardBorder

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id:                 cardLayout
            anchors.fill:       parent
            anchors.margins:    _margins
            spacing:            _margins * 0.85

            Text {
                Layout.fillWidth:       true
                text:                   mavlinkAction ? mavlinkAction.label : ""
                horizontalAlignment:    Text.AlignHCenter
                wrapMode:               Text.WordWrap
                color:                  _textPrimary
                font.family:            _fontFamily
                font.pixelSize:         ScreenTools.defaultFontPointSize * 1.2
                font.bold:              true
                style:                  Text.Outline
                styleColor:             "#99000000"
            }

            Text {
                Layout.fillWidth:       true
                text:                   mavlinkAction ? mavlinkAction.description : ""
                horizontalAlignment:    Text.AlignHCenter
                wrapMode:               Text.WordWrap
                color:                  _textSecondary
                font.family:            _fontFamily
                font.pixelSize:         ScreenTools.defaultFontPointSize
                lineHeight:             1.3
                style:                  Text.Outline
                styleColor:             "#88000000"
            }

            Text {
                Layout.fillWidth:       true
                Layout.topMargin:       _margins * 0.15
                text:                   _slideHint
                wrapMode:               Text.WordWrap
                horizontalAlignment:    Text.AlignHCenter
                color:                  _textSecondary
                font.family:            _fontFamily
                font.pixelSize:         ScreenTools.defaultFontPointSize * 0.95
                style:                  Text.Outline
                styleColor:             "#88000000"
            }

            RowLayout {
                Layout.fillWidth:   true
                Layout.topMargin:   _margins * 0.25
                spacing:            ScreenTools.defaultFontPixelWidth

                SliderSwitch {
                    id:                 slider
                    confirmText:        ""
                    trackHeight:        _trackHeight
                    Layout.fillWidth:   true
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 38

                    onAccept: {
                        if (mavlinkAction && vehicle) {
                            mavlinkAction.sendTo(vehicle)
                        }
                        _root.close()
                    }
                }

                Rectangle {
                    Layout.alignment:   Qt.AlignVCenter
                    height:             _trackHeight
                    width:              height
                    radius:             height / 2
                    color:              _danger
                    border.width:       1
                    border.color:       Theme.sliderThumbBorder

                    QGCColoredImage {
                        anchors.margins:    parent.height / 4
                        anchors.fill:       parent
                        source:             "/res/XDelete.svg"
                        fillMode:           Image.PreserveAspectFit
                        color:              _textPrimary
                    }

                    QGCMouseArea {
                        fillItem:   parent
                        onClicked:  _root.close()
                    }
                }
            }
        }
    }
}
