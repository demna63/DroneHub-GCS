/****************************************************************************
 * DroneHub GCS — guided action confirm dialog (slide-to-confirm).
 * Glass card aligned with Fly View transparent OSD.
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.UTMSP

Rectangle {
    id:         _root
    width:      Math.min(ScreenTools.defaultFontPixelWidth * 42, parent ? parent.width * 0.72 : 520)
    height:     mainLayout.height + (_margins * 2.5)
    radius:     _radiusLg
    color:      _cardFill
    border.width: 1
    border.color: _cardBorder
    visible:    _utmspEnabled === true ? utmspSliderTrigger : false

    property var    guidedController
    property var    guidedValueSlider
    property string title
    property alias  message:            messageText.text
    property int    action
    property var    actionData
    property bool   hideTrigger:        false
    property var    mapIndicator
    property alias  optionText:         optionCheckBox.text
    property alias  optionChecked:      optionCheckBox.checked

    property real _margins:         ScreenTools.defaultFontPixelWidth * 0.85
    property bool _emergencyAction: action === guidedController.actionEmergencyStop

    property bool   utmspSliderTrigger
    property bool   _utmspEnabled: QGroundControl.utmspSupported

    readonly property color _brandPrimary:   "#0A84FF"
    readonly property color _cardFill:       Qt.rgba(0.08, 0.11, 0.14, 0.92)
    readonly property color _cardBorder:     "#55FFFFFF"
    readonly property color _textPrimary:      "#FFFFFF"
    readonly property color _textSecondary:  "#D0D8E4"
    readonly property real  _radiusLg:       ScreenTools.defaultFontPixelWidth * 0.9
    readonly property string _fontFamily:    "Noto Sans Georgian"

    Component.onCompleted: guidedController.confirmDialog = this

    onVisibleChanged: {
        if (visible) {
            slider.focus = true
        }
    }

    onHideTriggerChanged: {
        if (hideTrigger) {
            confirmCancelled()
        }
    }

    function show(immediate) {
        if (immediate) {
            visible = true
        } else {
            visibleTimer.restart()
        }
    }

    function confirmCancelled() {
        guidedValueSlider.visible = false
        visible = false
        hideTrigger = false
        visibleTimer.stop()
        if (mapIndicator) {
            mapIndicator.actionCancelled()
            mapIndicator = undefined
        }
    }

    Timer {
        id:             visibleTimer
        interval:       1000
        repeat:         false
        onTriggered:    visible = true
    }

    ColumnLayout {
        id:                 mainLayout
        anchors.centerIn:   parent
        width:              parent.width - (_margins * 2)
        spacing:            _margins * 1.1

        Text {
            id:                     messageText
            Layout.fillWidth:       true
            horizontalAlignment:    Text.AlignHCenter
            wrapMode:               Text.WordWrap
            color:                  _textPrimary
            font.family:             _fontFamily
            font.pixelSize:         ScreenTools.defaultFontPointSize * 1.05
            font.bold:              true
            style:                  Text.Outline
            styleColor:             "#99000000"
        }

        QGCCheckBox {
            id:                 optionCheckBox
            Layout.alignment:   Qt.AlignHCenter
            text:               ""
            visible:            text !== ""
        }

        RowLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth * 0.75

            SliderSwitch {
                id:                 slider
                confirmText:        ScreenTools.isMobile
                                        ? qsTr("Slide to confirm")
                                        : qsTr("Slide or hold spacebar")
                Layout.fillWidth:   true
                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.6
                enabled:            _utmspEnabled === true ? utmspSliderTrigger : true
                opacity:            _utmspEnabled ? (utmspSliderTrigger === true ? 1 : 0.5) : 1

                onAccept: {
                    _root.visible = false
                    var sliderOutputValue = 0
                    if (guidedValueSlider.visible) {
                        sliderOutputValue = guidedValueSlider.getOutputValue()
                        guidedValueSlider.visible = false
                    }
                    hideTrigger = false
                    guidedController.executeAction(
                        _root.action, _root.actionData, sliderOutputValue, _root.optionChecked)
                    if (mapIndicator) {
                        mapIndicator.actionConfirmed()
                        mapIndicator = undefined
                    }

                    UTMSPStateStorage.indicatorOnMissionStatus = true
                    UTMSPStateStorage.currentNotificationIndex = 7
                    UTMSPStateStorage.currentStateIndex = 3
                }
            }

            Rectangle {
                height: Math.max(slider.height * 0.78, ScreenTools.defaultFontPixelHeight * 2.2)
                width:  height
                radius: height / 2
                color:  _emergencyAction ? "#FF453A" : _brandPrimary
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.25)

                QGCColoredImage {
                    anchors.margins:    parent.height / 4
                    anchors.fill:       parent
                    source:             "/res/XDelete.svg"
                    fillMode:           Image.PreserveAspectFit
                    color:              _textPrimary
                }

                QGCMouseArea {
                    fillItem:   parent
                    onClicked:  confirmCancelled()
                }
            }
        }
    }
}
