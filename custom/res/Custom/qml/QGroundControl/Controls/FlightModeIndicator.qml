/****************************************************************************
 * DroneHub GCS — flight-mode indicator with Georgian display labels.
 *
 * Override of the stock src/QmlControls/FlightModeIndicator.qml. PX4 v1.14+ sends
 * flight-mode names dynamically over MAVLink (Safe Recovery, Position Slow, …),
 * bypassing QGC's static tr() catalog, so the menu showed English. We map mode
 * names to Georgian for DISPLAY only: the current-mode label and each menu button
 * show _modeLabel(name), while selection, visibility and the edit-mode hide/show
 * logic all use the ORIGINAL name (modelData / modeRepeater.model[i]) — so the
 * value sent to the vehicle and the persisted hidden-modes list are never altered.
 * Only the label (50), the button text (modeButton) and the edit-mode match
 * (button.modeName) differ from upstream.
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.AutoPilotPlugin

RowLayout {
    id:         control
    spacing:    0

    property bool   showIndicator:          true
    property var    expandedPageComponent
    property bool   waitForParameters:      false

    property real fontPointSize:    ScreenTools.largeFontPointSize
    property var  activeVehicle:    QGroundControl.multiVehicleManager.activeVehicle
    property bool allowEditMode:    true
    property bool editMode:         false

    // DroneHub: display-only Georgian labels for PX4 flight modes (static + v1.14+
    // dynamic names). Unknown names fall through unchanged.
    readonly property var _modeMap: ({
        "Manual":                   "მანუალური",
        "Stabilized":               "სტაბილიზებული",
        "Acro":                     "აკრო",
        "Rattitude":                "Rattitude",
        "Altitude":                 "სიმაღლე",
        "Altitude Cruise":          "სიმაღლის კრუიზი",
        "Position":                 "პოზიცია",
        "Position Slow":            "პოზიცია (ნელი)",
        "Offboard":                 "Offboard",
        "Ready":                    "მზადაა",
        "Takeoff":                  "აფრენა",
        "VTOL Takeoff":             "VTOL აფრენა",
        "Hold":                     "შეჩერება",
        "Mission":                  "მისია",
        "Return":                   "დაბრუნება",
        "Return to Groundstation":  "დაბრუნება სადგურთან",
        "Land":                     "დაშვება",
        "Precision Land":           "ზუსტი დაშვება",
        "Precision Landing":        "ზუსტი დაშვება",
        "Follow Me":                "გამომყევი",
        "Follow Target":            "სამიზნის მიდევნება",
        "Orbit":                    "ორბიტა",
        "Simple":                   "მარტივი",
        "Safe Recovery":            "უსაფრთხო აღდგენა",
        "Guided Course":            "მართვადი კურსი",
        "Unknown":                  "უცნობი"
    })

    function _modeLabel(m) {
        return (m !== undefined && _modeMap[m] !== undefined) ? _modeMap[m] : m
    }

    RowLayout {
        Layout.fillWidth: true

        QGCColoredImage {
            id:         flightModeIcon
            width:      ScreenTools.defaultFontPixelWidth * 3
            height:     ScreenTools.defaultFontPixelHeight
            fillMode:   Image.PreserveAspectFit
            mipmap:     true
            color:      qgcPal.text
            source:     "/qmlimages/FlightModesComponentIcon.png"
        }

        QGCLabel {
            text:               activeVehicle ? control._modeLabel(activeVehicle.flightMode) : qsTr("N/A", "No data to display")
            font.pointSize:     fontPointSize
            Layout.alignment:   Qt.AlignCenter

            MouseArea {
                anchors.fill:   parent
                onClicked:      mainWindow.showIndicatorDrawer(drawerComponent, control)
            }
        }
    }

    Component {
        id: drawerComponent

        ToolIndicatorPage {
            showExpand:         true
            waitForParameters:  control.waitForParameters

            contentComponent:    flightModeContentComponent
            expandedComponent:   flightModeExpandedComponent

            onExpandedChanged: {
                if (!expanded) {
                    editMode = false
                }
            }
        }
    }

    Component {
        id: flightModeContentComponent

        ColumnLayout {
            id:         modeColumn
            spacing:    ScreenTools.defaultFontPixelWidth / 2

            property var    activeVehicle:            QGroundControl.multiVehicleManager.activeVehicle
            property var    flightModeSettings:       QGroundControl.settingsManager.flightModeSettings
            property var    hiddenFlightModesFact:    null
            property var    hiddenFlightModesList:    []

            Component.onCompleted: {
                // Hidden flight modes are classified by firmware and vehicle class
                var hiddenFlightModesPropPrefix
                if (activeVehicle.px4Firmware) {
                    hiddenFlightModesPropPrefix = "px4HiddenFlightModes"
                } else if (activeVehicle.apmFirmware) {
                    hiddenFlightModesPropPrefix = "apmHiddenFlightModes"
                } else {
                    control.allowEditMode = false
                }
                if (control.allowEditMode) {
                    var hiddenFlightModesProp = hiddenFlightModesPropPrefix + activeVehicle.vehicleClassInternalName()
                    if (flightModeSettings.hasOwnProperty(hiddenFlightModesProp)) {
                        hiddenFlightModesFact = flightModeSettings[hiddenFlightModesProp]
                        // Split string into list of flight modes
                        if (hiddenFlightModesFact && hiddenFlightModesFact.value !== "") {
                            hiddenFlightModesList = hiddenFlightModesFact.value.split(",")
                        }
                    } else {
                        control.allowEditMode = false
                    }
                }
                hiddenModesLabel.calcVisible()
            }

            Connections {
                target: control
                onEditModeChanged: {
                    if (editMode) {
                        for (var i=0; i<modeRepeater.count; i++) {
                            var button      = modeRepeater.itemAt(i).children[0]
                            var checkBox    = modeRepeater.itemAt(i).children[1]

                            // Match against the ORIGINAL mode name, not the localized button text.
                            checkBox.checked = !hiddenFlightModesList.find(item => { return item === button.modeName } )
                        }
                    }
                }
            }

            Repeater {
                id:     modeRepeater
                model:  activeVehicle ? activeVehicle.flightModes : []

                RowLayout {
                    spacing: ScreenTools.defaultFontPixelWidth
                    visible: editMode || !hiddenFlightModesList.find(item => { return item === modelData } )

                    QGCButton {
                        id:                 modeButton
                        property string     modeName: modelData          // original name, for set + edit-mode match
                        text:               control._modeLabel(modelData) // localized display only
                        Layout.fillWidth:   true

                        onClicked: {
                            if (editMode) {
                                parent.children[1].toggle()
                                parent.children[1].clicked()
                            } else {
                                //var controller = globals.guidedControllerFlyView
                                //controller.confirmAction(controller.actionSetFlightMode, modelData)
                                activeVehicle.flightMode = modelData
                                mainWindow.closeIndicatorDrawer()
                            }
                        }
                    }

                    QGCCheckBoxSlider {
                        visible: editMode

                        onClicked: {
                            hiddenFlightModesList = []
                            for (var i=0; i<modeRepeater.count; i++) {
                                var checkBox = modeRepeater.itemAt(i).children[1]
                                if (!checkBox.checked) {
                                    hiddenFlightModesList.push(modeRepeater.model[i])
                                }
                            }
                            hiddenFlightModesFact.value = hiddenFlightModesList.join(",")
                            hiddenModesLabel.calcVisible()
                        }
                    }
                }
            }

            QGCLabel {
                id:                     hiddenModesLabel
                text:                   qsTr("Some Modes Hidden")
                Layout.fillWidth:       true
                font.pointSize:         ScreenTools.smallFontPointSize
                horizontalAlignment:    Text.AlignHCenter
                visible:                false

                function calcVisible() {
                    hiddenModesLabel.visible = hiddenFlightModesList.length > 0
                }
            }
        }
    }

    Component {
        id: flightModeExpandedComponent

        ColumnLayout {
            Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 60
            spacing:                margins / 2

            property var  qgcPal:   QGroundControl.globalPalette
            property real margins:  ScreenTools.defaultFontPixelHeight

            Loader {
                sourceComponent: expandedPageComponent
            }

            SettingsGroupLayout {
                Layout.fillWidth:  true

                RowLayout {
                    Layout.fillWidth:   true
                    enabled:            control.allowEditMode

                    QGCLabel {
                        Layout.fillWidth:   true
                        text:               qsTr("Edit Displayed Flight Modes")
                    }

                    QGCCheckBoxSlider {
                        onClicked: control.editMode = checked
                    }
                }

                LabelledButton {
                    Layout.fillWidth:   true
                    label:              qsTr("Flight Modes")
                    buttonText:         qsTr("Configure")
                    visible:            _activeVehicle.autopilotPlugin.knownVehicleComponentAvailable(AutoPilotPlugin.KnownFlightModesVehicleComponent) &&
                                            QGroundControl.corePlugin.showAdvancedUI

                    onClicked: {
                        mainWindow.showKnownVehicleComponentConfigPage(AutoPilotPlugin.KnownFlightModesVehicleComponent)
                        mainWindow.closeIndicatorDrawer()
                    }
                }
            }
        }
    }
}
