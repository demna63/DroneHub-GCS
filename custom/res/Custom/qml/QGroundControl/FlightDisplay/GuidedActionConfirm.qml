/****************************************************************************
 * DroneHub GCS — guided action confirm (slide-to-confirm).
 *
 * QGC 5.1 hosts this control in the Fly View toolbar centre (property API unchanged:
 * guidedController / guidedValueSlider / messageDisplay / title / message / action ...).
 * DroneHub keeps the deliberate slide-or-hold-space confirmation instead of the stock
 * QGCDelayButton, styled with the Theme tokens. UTMSP hooks were removed with 5.1.
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

import Custom

Item {
    id:         control
    width:      mainLayout.width
    visible:    false

    property var    guidedController
    property var    guidedValueSlider
    property var    messageDisplay
    property string title
    property string message
    property int    action
    property var    actionData
    property bool   hideTrigger:        false
    property var    mapIndicator
    property alias  optionText:         optionCheckBox.text
    property alias  optionChecked:      optionCheckBox.checked

    property real _margins:         2
    property bool _emergencyAction: action === guidedController.actionEmergencyStop

    readonly property string _slideHint: ScreenTools.isMobile
                                            ? qsTr("Slide to confirm")
                                            : qsTr("Slide or hold spacebar")

    Component.onCompleted: guidedController.confirmDialog = this

    onHideTriggerChanged: {
        if (hideTrigger) {
            confirmCancelled()
        }
    }

    function show(immediate) {
        if (immediate) {
            _reallyShow()
        } else {
            // We delay showing the confirmation for a small amount in order for any other state
            // changes to propogate through the system. This way only the final state shows up.
            visibleTimer.restart()
        }
    }

    function reset() {
        visible = false
        guidedValueSlider.visible = false
        hideTrigger = false
        visibleTimer.stop()
        messageDisplay.opacity = 1.0
        messageFadeTimer.stop()
        messageOpacityAnimation.stop()
    }

    // Cancel the current pending action and notify its map indicator.
    // Pass incomingIndicator when superseding one action with another (e.g. from confirmAction):
    // if the old and new indicator are the same object, actionCancelled() is intentionally skipped
    // so that a show() call made before confirmAction() is not undone (e.g. goto -> goto).
    // Omit incomingIndicator (or pass undefined) for explicit user cancellation via the X button
    // or auto-hide trigger, where the indicator must always be notified.
    function confirmCancelled(incomingIndicator) {
        reset()
        if (mapIndicator && mapIndicator !== incomingIndicator) {
            mapIndicator.actionCancelled()
        }
        mapIndicator = undefined
    }

    function _reallyShow() {
        visible = true
        messageDisplay.opacity = 1.0
        messageFadeTimer.start()
    }

    function _executeConfirmedAction() {
        control.visible = false
        var sliderOutputValue = 0
        if (guidedValueSlider.visible) {
            sliderOutputValue = guidedValueSlider.getOutputValue()
            guidedValueSlider.visible = false
        }
        hideTrigger = false
        let success = guidedController.executeAction(control.action, control.actionData, sliderOutputValue, control.optionChecked)
        if (mapIndicator) {
            if (success) {
                mapIndicator.actionConfirmed()
            } else {
                mapIndicator.actionCancelled()
            }
            mapIndicator = undefined
        }
    }

    Timer {
        id:             visibleTimer
        interval:       1000
        repeat:         false
        onTriggered:    _reallyShow()
    }

    QGCPalette { id: qgcPal }

    RowLayout {
        id:         mainLayout
        y:          2
        height:     parent.height - 4
        spacing:    ScreenTools.defaultFontPixelWidth

        Text {
            id:                     titleLabel
            Layout.alignment:       Qt.AlignVCenter
            text:                   control.title
            color:                  Theme.textPrimary
            font.family:            Theme.fontFamily
            font.pixelSize:         ScreenTools.defaultFontPixelHeight
            font.bold:              true
        }

        SliderSwitch {
            id:                     slider
            Layout.alignment:       Qt.AlignVCenter
            Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 34
            trackHeight:            mainLayout.height
            confirmText:            ""
            focus:                  control.visible
            onAccept:               control._executeConfirmedAction()

            // Emergency stop is rendered in the danger colour so it is never confused with routine actions.
            Rectangle {
                anchors.fill:   parent
                radius:         height / 2
                color:          "transparent"
                border.width:   control._emergencyAction ? 2 : 0
                border.color:   Theme.danger
                visible:        control._emergencyAction
            }
        }

        Text {
            Layout.alignment:       Qt.AlignVCenter
            text:                   control._slideHint
            color:                  Theme.textSecondary
            font.family:            Theme.fontFamily
            font.pixelSize:         ScreenTools.defaultFontPixelHeight * 0.8
            visible:                !ScreenTools.isMobile
        }

        QGCCheckBox {
            id:                 optionCheckBox
            visible:            text !== ""
        }

        QGCColoredImage {
            id:                 closeButton
            Layout.alignment:   Qt.AlignVCenter
            width:              height
            height:             ScreenTools.defaultFontPixelHeight * 0.7
            source:             "/res/XDelete.svg"
            fillMode:           Image.PreserveAspectFit
            color:              qgcPal.text

            QGCMouseArea {
                fillItem:   parent
                onClicked:  confirmCancelled()
            }
        }
    }
}
