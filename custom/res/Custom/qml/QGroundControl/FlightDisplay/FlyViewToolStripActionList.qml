/****************************************************************************
 * DroneHub GCS — Fly View left tool strip (3D / Plan / guided actions / Setup / Analyze / Settings).
 *
 * The DroneHub toolbar logo toggles this strip instead of opening QGC's view-select menu,
 * so the view-navigation actions live here. Upstream v5.1.5 items are kept in order;
 * DroneHub adds Plan, Setup, Analyze and Settings.
 *
 * `import QGroundControl.FlyView` is explicit because CustomOverrideInterceptor serves this
 * file from qrc:/Custom/qml/..., where implicit same-directory type lookup does not apply.
 ****************************************************************************/

import QtQml.Models

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Viewer3D
import QGroundControl.FlyView

ToolStripActionList {
    id: _root

    signal displayPreFlightChecklist

    /// Switch views through MainWindow's guard (blocks while a plan has unsaved validation errors).
    function _switchView(showFn) {
        if (mainWindow.allowViewSwitch()) {
            showFn()
        }
    }

    model: [
        Viewer3DShowAction { },
        ToolStripAction {
            text:           qsTr("Plan")
            iconSource:     "/qmlimages/Plan.svg"
            onTriggered:    _root._switchView(function() { mainWindow.showPlanView() })
        },
        PreFlightCheckListShowAction { onTriggered: displayPreFlightChecklist() },
        GuidedActionTakeoff { },
        GuidedActionLand { },
        GuidedActionRTL { },
        GuidedActionPause { },
        FlyViewAdditionalActionsButton { },
        FlyViewGripperButton { },
        ToolStripAction {
            text:           qsTr("Setup")
            iconSource:     "/qmlimages/Gears.svg"
            onTriggered:    _root._switchView(function() { mainWindow.showVehicleConfig() })
        },
        ToolStripAction {
            text:           qsTr("Analyze")
            iconSource:     "/qmlimages/Analyze.svg"
            onTriggered:    _root._switchView(function() { mainWindow.showAnalyzeTool() })
        },
        ToolStripAction {
            text:           qsTr("Settings")
            iconSource:     "/qmlimages/CogWheel.svg"
            onTriggered:    _root._switchView(function() { mainWindow.showSettingsTool() })
        }
    ]
}
