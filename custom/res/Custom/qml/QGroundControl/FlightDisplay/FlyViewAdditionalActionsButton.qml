/****************************************************************************
 * DroneHub GCS — Fly View additional MAVLink actions tool strip button.
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightDisplay
import QGroundControl.Controllers

ToolStripAction {
    id:         action
    text:       qsTr("Actions")
    iconSource: "/qmlimages/HamburgerThin.svg"
    visible:    _additionalActions.anyActionAvailable
                || _mavlinkActions.anyActionAvailable
                || _customActions.anyActionAvailable
    enabled:    true

    property var _guidedController: globals.guidedControllerFlyView

    property var _additionalActions: FlyViewAdditionalActionsList {
        guidedController: _guidedController
    }

    property var _mavlinkActions: MavlinkActionManager {
        actionFileNameFact: QGroundControl.settingsManager.mavlinkActionsSettings.flyViewActionsFile

        property bool anyActionAvailable: QGroundControl.multiVehicleManager.activeVehicle
                                          && actions.count > 0
    }

    property var _customActions: FlyViewAdditionalCustomActionsList {
        guidedController: _guidedController
    }

    dropPanelComponent: Component {
        FlyViewAdditionalActionsPanel {
            additionalActions:  _additionalActions
            mavlinkActions:     _mavlinkActions.actions
            customActions:      _customActions
        }
    }
}
