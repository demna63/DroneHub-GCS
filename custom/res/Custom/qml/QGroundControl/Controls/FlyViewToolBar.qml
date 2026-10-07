/****************************************************************************
 * DroneHub GCS — Fly View toolbar override (QGC 5.1 layout: left / center / right panels).
 *
 * Upstream structure is kept (QGCFlickable > Row[leftPanel, centerPanel, rightPanel],
 * guided-action confirm in the center, ParameterDownloadProgress overlay) so future
 * rebases stay small. DroneHub additions:
 *   • frosted chrome background + bottom hairline (Theme.chromeGlass / Theme.divider)
 *   • logo button toggling the Fly tool strip (Theme.flyToolStripExpanded)
 *   • main-status chip
 *   • mission clock + camera-panel toggle at the right edge
 * The primary indicator chips (health / mode / GPS / RC / battery / video) live in
 * FlyViewToolBarIndicators.qml.
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView

import Custom

Item {
    required property var guidedValueSlider

    id:     control
    width:  parent.width
    height: ScreenTools.toolbarHeight

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false
    property color  _mainStatusBGColor: Theme.bgElevated
    property real   _leftRightMargin:   ScreenTools.defaultFontPixelWidth * 0.75
    property var    _guidedController:  globals.guidedControllerFlyView

    function dropMainStatusIndicatorTool() {
        mainStatusIndicator.dropMainStatusIndicator();
    }

    QGCPalette { id: qgcPal }

    // Frosted chrome behind the whole bar (the per-panel backgrounds are intentionally transparent).
    Rectangle {
        anchors.fill:   parent
        color:          Theme.chromeGlass
    }

    Rectangle {
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        height:         1
        color:          Theme.divider
    }

    QGCFlickable {
        anchors.fill:       parent
        contentWidth:       toolBarLayout.width
        flickableDirection: Flickable.HorizontalFlick

        Row {
            id:         toolBarLayout
            height:     parent.height
            spacing:    0

            Item {
                id:     leftPanel
                width:  leftPanelLayout.implicitWidth + control._leftRightMargin * 2
                height: parent.height

                RowLayout {
                    id:                 leftPanelLayout
                    x:                  control._leftRightMargin
                    height:             parent.height - 1   // keep clear of the bottom hairline
                    spacing:            ScreenTools.defaultFontPixelWidth / 2

                    Item {
                        id:                     currentButton
                        objectName:             "toolbar_dhgLogo"
                        Layout.preferredHeight: leftPanelLayout.height
                        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 15
                        clip:                   true

                        Image {
                            id:                 toolbarLogo
                            source:             Theme.logoSource
                            anchors.centerIn:   parent
                            width:              parent.width
                            height:             parent.height
                            fillMode:           Image.PreserveAspectFit
                            scale:              Theme.toolbarLogoVisualScale
                            transformOrigin:    Item.Center
                            mipmap:             true
                            smooth:             true
                        }

                        MouseArea {
                            anchors.fill:       parent
                            cursorShape:        Qt.PointingHandCursor
                            hoverEnabled:       true
                            onClicked:          Theme.flyToolStripExpanded = !Theme.flyToolStripExpanded
                        }
                    }

                    Rectangle {
                        Layout.preferredHeight: leftPanelLayout.height - ScreenTools.defaultFontPixelHeight * 0.35
                        Layout.preferredWidth:  mainStatusIndicator.implicitWidth + Theme.spacingUnit * 2
                        radius:                 Theme.radiusSm
                        color:                  Theme.bgElevated
                        border.width:           1
                        border.color:           Theme.divider

                        MainStatusIndicator {
                            id:                 mainStatusIndicator
                            objectName:         "toolbar_mainStatusIndicator"
                            anchors.centerIn:   parent
                            height:             parent.height - Theme.spacingUnit * 0.5
                        }
                    }

                    QGCButton {
                        id:         disconnectButton
                        text:       qsTr("Disconnect")
                        onClicked:  _activeVehicle.closeVehicle()
                        visible:    _activeVehicle && _communicationLost
                    }
                }
            }

            Item {
                id:     centerPanel
                // center panel takes up all remaining space in toolbar between left and right panels
                width:  Math.max(guidedActionConfirm.visible ? guidedActionConfirm.width : 0, control.width - (leftPanel.width + rightPanel.width))
                height: parent.height

                GuidedActionConfirm {
                    id:                         guidedActionConfirm
                    height:                     parent.height
                    anchors.horizontalCenter:   parent.horizontalCenter
                    guidedController:           control._guidedController
                    guidedValueSlider:          control.guidedValueSlider
                    messageDisplay:             guidedActionMessageDisplay
                }
            }

            Item {
                id:     rightPanel
                width:  rightPanelLayout.implicitWidth
                height: parent.height

                RowLayout {
                    id:         rightPanelLayout
                    height:     parent.height - 1
                    spacing:    0

                    FlyViewToolBarIndicators {
                        id:                 flyViewIndicators
                        Layout.fillHeight:  true
                    }

                    // Mission clock — glanceable info at the right edge.
                    Item {
                        id:                     clockItem
                        Layout.fillHeight:      true
                        Layout.preferredWidth:  clockColumn.implicitWidth + Theme.spacingUnit * 2.5

                        Rectangle {   // subtle separator from the indicator cluster
                            anchors.left:           parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width:                  1
                            height:                 parent.height * 0.5
                            color:                  Theme.divider
                        }

                        Column {
                            id:                 clockColumn
                            anchors.centerIn:   parent
                            spacing:            -1

                            Text {
                                id:                         clockTime
                                anchors.horizontalCenter:   parent.horizontalCenter
                                color:                      Theme.textPrimary
                                font.family:                Theme.fontFamily
                                font.pixelSize:             Theme.fontBody
                                font.bold:                  true
                            }
                            Text {
                                id:                         clockDate
                                anchors.horizontalCenter:   parent.horizontalCenter
                                color:                      Theme.textSecondary
                                font.family:                Theme.fontFamily
                                font.pixelSize:             Theme.fontMicro
                            }
                        }

                        function _tick() {
                            var d = new Date()
                            clockTime.text = Qt.formatTime(d, "HH:mm:ss")
                            clockDate.text = Qt.formatDate(d, "dd.MM.yyyy")   // locale-neutral; avoids English month in the Georgian UI
                        }
                        Timer { interval: 1000; repeat: true; running: true; onTriggered: clockItem._tick() }
                        Component.onCompleted: clockItem._tick()
                    }

                    Item {
                        id:                     cameraToggleButton
                        Layout.fillHeight:      true
                        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 5.5

                        Image {
                            source:             "/qmlimages/camera_video.svg"
                            anchors.fill:       parent
                            anchors.margins:    Math.max(4, cameraToggleButton.height * 0.18)
                            fillMode:           Image.PreserveAspectFit
                        }

                        MouseArea {
                            anchors.fill:       parent
                            cursorShape:        Qt.PointingHandCursor
                            hoverEnabled:       true
                            onClicked:          Theme.flyCameraPanelExpanded = !Theme.flyCameraPanelExpanded
                        }
                    }
                }
            }
        }
    }

    // The guided action message display is outside of the GuidedActionConfirm control so that it doesn't end up as
    // part of the Flickable
    Rectangle {
        id:                         guidedActionMessageDisplay
        anchors.top:                control.bottom
        anchors.topMargin:          _margins
        x:                          control.mapFromItem(guidedActionConfirm.parent, guidedActionConfirm.x, 0).x + (guidedActionConfirm.width - guidedActionMessageDisplay.width) / 2
        width:                      messageLabel.contentWidth + (_margins * 2)
        height:                     messageLabel.contentHeight + (_margins * 2)
        color:                      Theme.chromeGlass
        radius:                     ScreenTools.defaultBorderRadius
        visible:                    guidedActionConfirm.visible

        QGCLabel {
            id:         messageLabel
            x:          _margins
            y:          _margins
            width:      ScreenTools.defaultFontPixelWidth * 30
            wrapMode:   Text.WordWrap
            text:       guidedActionConfirm.message
        }

        PropertyAnimation {
            id:         messageOpacityAnimation
            target:     guidedActionMessageDisplay
            property:   "opacity"
            from:       1
            to:         0
            duration:   500
        }

        Timer {
            id:             messageFadeTimer
            interval:       4000
            onTriggered:    messageOpacityAnimation.start()
        }
    }

    ParameterDownloadProgress {
        anchors.fill: parent
    }
}
