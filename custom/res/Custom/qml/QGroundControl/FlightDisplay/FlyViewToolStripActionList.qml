/****************************************************************************
 * DroneHub GCS — Fly View left tool strip (Plan / Setup / Analyze / Settings).
 ****************************************************************************/

import QtQml.Models
import QtCore

import QGroundControl
import QGroundControl.Controls

ToolStripActionList {
    id: _root

    signal displayPreFlightChecklist

    // macOS + GStreamer: entire app uses OpenGL 2.1; Viewer3D cannot render (white scene).
    readonly property bool _viewer3DBlockedByGstMac: Qt.platform.os === "osx"
                                                       && QGroundControl.videoManager.gstreamerEnabled

    model: [
        ToolStripAction {
            property bool _is3DViewOpen:            viewer3DWindow.isOpen
            property bool _viewer3DEnabled:         QGroundControl.settingsManager.viewer3DSettings.enabled.rawValue

            id: view3DIcon
            visible:            _viewer3DEnabled && !_root._viewer3DBlockedByGstMac
            text:           qsTr("3D View")
            iconSource:     "/qmlimages/Viewer3D/City3DMapIcon.svg"
            onTriggered: {
                if (_is3DViewOpen === false) {
                    viewer3DWindow.open()
                } else {
                    viewer3DWindow.close()
                }
            }

            on_Is3DViewOpenChanged: {
                if (_is3DViewOpen === true) {
                    view3DIcon.iconSource = "/qmlimages/PaperPlane.svg"
                    text = qsTr("Fly")
                } else {
                    iconSource = "/qmlimages/Viewer3D/City3DMapIcon.svg"
                    text = qsTr("3D View")
                }
            }
        },
        ToolStripAction {
            text:           qsTr("Plan")
            iconSource:     "/qmlimages/Plan.svg"
            onTriggered:    mainWindow.showPlanView()
        },
        PreFlightCheckListShowAction { onTriggered: displayPreFlightChecklist() },
        GuidedActionTakeoff { },
        GuidedActionLand { },
        GuidedActionRTL { },
        GuidedActionPause { },
        FlyViewAdditionalActionsButton { },
        GuidedActionGripper { },
        ToolStripAction {
            text:           qsTr("Setup")
            iconSource:     "/qmlimages/Gears.svg"
            onTriggered:    mainWindow.showVehicleConfig()
        },
        ToolStripAction {
            text:           qsTr("Analyze")
            iconSource:     "/qmlimages/Analyze.svg"
            visible:        true   // always available — operators rely on log download, MAVLink console/inspector
            onTriggered:    mainWindow.showAnalyzeTool()
        },
        ToolStripAction {
            text:           qsTr("Settings")
            iconSource:     "/qmlimages/CogWheel.svg"
            onTriggered:    mainWindow.showSettingsTool()
        }
    ]
}
