/****************************************************************************
 * DroneHub GCS — Fly View left tool strip (Viewer3D hidden on macOS+GStreamer).
 ****************************************************************************/

import QtQml.Models
import QtCore

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Viewer3D

ToolStripActionList {
    id: _root

    signal displayPreFlightChecklist

    // macOS + GStreamer: entire app uses OpenGL 2.1; Viewer3D cannot render (white scene).
    readonly property bool _viewer3DBlockedByGstMac: Qt.platform.os === "osx"
                                                       && QGroundControl.videoManager.gstreamerEnabled

    model: [
        Viewer3DShowAction { visible: _viewer3DEnabled && !_root._viewer3DBlockedByGstMac },
        PreFlightCheckListShowAction { onTriggered: displayPreFlightChecklist() },
        GuidedActionTakeoff { },
        GuidedActionLand { },
        GuidedActionRTL { },
        GuidedActionPause { },
        FlyViewAdditionalActionsButton { },
        FlyViewGripperButton { }
    ]
}
