/****************************************************************************
 * DroneHub GCS — Fly View additional actions panel (MAVLink confirm + categories).
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

ColumnLayout {
    property var additionalActions
    property var mavlinkActions
    property var customActions

    property var  _activeVehicle:       QGroundControl.multiVehicleManager.activeVehicle
    property var  _guidedController:    globals.guidedControllerFlyView

    function _categoryLabel(description) {
        if (!description) {
            return ""
        }
        const dot = description.indexOf(" · ")
        return dot > 0 ? description.substring(0, dot) : ""
    }

    function _actionCategory(action) {
        const label = _categoryLabel(action.description)
        if (label !== "") {
            return label
        }
        return qsTr("Other")
    }

    function _categorySortKey(category) {
        switch (category) {
        case "ფრენა":       return 0
        case "ტვირთი":      return 1
        case "უსაფრთხოება": return 2
        case "ლოგირება":    return 3
        default:            return 4
        }
    }

    function _sortedMavlinkActions() {
        if (!mavlinkActions) {
            return []
        }
        const items = []
        for (let i = 0; i < mavlinkActions.count; i++) {
            const action = mavlinkActions.get(i)
            if (action) {
                items.push(action)
            }
        }
        items.sort(function(a, b) {
            const catA = _actionCategory(a)
            const catB = _actionCategory(b)
            const keyDiff = _categorySortKey(catA) - _categorySortKey(catB)
            if (keyDiff !== 0) {
                return keyDiff
            }
            return a.label.localeCompare(b.label)
        })
        return items
    }

    function _runMavlinkAction(action) {
        if (!action || !_activeVehicle) {
            return
        }
        dropPanel.hide()
        if (action.requiresConfirm) {
            const dialog = mavlinkActionConfirmComponent.createObject(mainWindow, {
                mavlinkAction: action,
                vehicle:       _activeVehicle
            })
            dialog.open()
        } else {
            action.sendTo(_activeVehicle)
        }
    }

    Component {
        id: mavlinkActionConfirmComponent
        MavlinkActionConfirm { }
    }

    // Pre-defined Additional Guided Actions
    Repeater {
        model: additionalActions.model

        QGCButton {
            Layout.fillWidth:   true
            text:               modelData.title
            visible:            modelData.visible

            onClicked: {
                dropPanel.hide()
                _guidedController.confirmAction(modelData.action)
            }
        }
    }

    // Custom Build Actions
    Repeater {
        model: customActions.model

        QGCButton {
            Layout.fillWidth:   true
            text:               modelData.title
            visible:            modelData.visible

            onClicked: {
                dropPanel.hide()
                _guidedController.confirmAction(modelData.action)
            }
        }
    }

    // User-defined Mavlink Actions (grouped by category prefix in description)
    Repeater {
        model: _activeVehicle ? _sortedMavlinkActions() : []

        delegate: ColumnLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth * 0.35

            property string sectionLabel: {
                const cat = _actionCategory(modelData)
                if (index === 0) {
                    return cat
                }
                const prev = _sortedMavlinkActions()[index - 1]
                const prevCat = prev ? _actionCategory(prev) : ""
                return cat !== prevCat ? cat : ""
            }

            QGCLabel {
                Layout.fillWidth:   true
                text:               parent.sectionLabel
                visible:            parent.sectionLabel !== ""
                font.bold:          true
            }

            QGCButton {
                Layout.fillWidth:   true
                text:               modelData.label

                onClicked: _runMavlinkAction(modelData)
            }
        }
    }
}
