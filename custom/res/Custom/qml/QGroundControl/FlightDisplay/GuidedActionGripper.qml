/****************************************************************************
 * DroneHub GCS — gripper guided action (tool strip).
 ****************************************************************************/

import QGroundControl.FlightDisplay
import QGroundControl

GuidedToolStripAction {
    property var   activeVehicle:           QGroundControl.multiVehicleManager.activeVehicle
    property bool  _initialConnectComplete: activeVehicle ? activeVehicle.initialConnectComplete : false
    property bool  _grip_enable:            _initialConnectComplete ? activeVehicle.hasGripper : false
    property bool  _isVehicleArmed:         _initialConnectComplete ? activeVehicle.armed : false

    text:       _guidedController.gripperTitle
    iconSource: "/res/Gripper.svg"
    visible:    !_isVehicleArmed && _grip_enable
    enabled:    _grip_enable
    actionID:   _guidedController.actionGripper
}
