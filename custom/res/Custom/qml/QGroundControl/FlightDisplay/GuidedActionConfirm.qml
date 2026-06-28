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

import Custom

Rectangle {
    id:         _root
    width:      Math.min(
                    Math.max(ScreenTools.defaultFontPixelWidth * 54, mainLayout.implicitWidth + (_margins * 2)),
                    parent ? parent.width * 0.88 : 680)
    height:     mainLayout.implicitHeight + (_margins * 2)
    radius:     _radiusLg
    color:      _cardFill
    border.width: 1
    border.color: _cardBorder
    visible:    false

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

    property real _margins:         ScreenTools.defaultFontPixelWidth * 1.15
    property bool _emergencyAction: action === guidedController.actionEmergencyStop

    property bool   utmspSliderTrigger
    property bool   _utmspEnabled: QGroundControl.utmspSupported

    readonly property color _brandPrimary:   Theme.brandPrimary
    readonly property color _cardFill:       Theme.toastFill
    readonly property color _cardBorder:     Theme.toastBorder
    readonly property color _textPrimary:    Theme.textPrimary
    readonly property color _textSecondary:  Theme.textSecondary
    readonly property real  _radiusLg:       Theme.toastRadius
    readonly property string _fontFamily:    Theme.fontFamily
    readonly property real  _trackHeight:  ScreenTools.defaultFontPixelHeight * 2.5
    readonly property string _slideHint:     ScreenTools.isMobile
                                                ? qsTr("Slide to confirm")
                                                : qsTr("Slide or hold spacebar")

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
        anchors.fill:       parent
        anchors.margins:    _margins
        spacing:            _margins * 0.85

        Text {
            id:                     messageText
            Layout.fillWidth:       true
            Layout.minimumWidth:    ScreenTools.defaultFontPixelWidth * 48
            horizontalAlignment:    Text.AlignHCenter
            wrapMode:               Text.WordWrap
            color:                  _textPrimary
            font.family:            _fontFamily
            font.pixelSize:         ScreenTools.defaultFontPointSize * 1.15
            font.bold:              true
            lineHeight:             1.3
            style:                  Text.Outline
            styleColor:             "#99000000"
        }

        QGCCheckBox {
            id:                 optionCheckBox
            Layout.alignment:   Qt.AlignHCenter
            text:               ""
            visible:            text !== ""
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
                Layout.alignment:   Qt.AlignVCenter
                height:             _trackHeight
                width:              height
                radius:             height / 2
                color:              _emergencyAction ? Theme.danger : Theme.brandPrimary
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
                    onClicked:  confirmCancelled()
                }
            }
        }
    }
}
