/****************************************************************************
 * DroneHub GCS — Plan View toolbar (frosted chrome + "Exit Plan" affordance; 5.1 layout kept).
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.PlanView

import Custom

Rectangle {
    id: _root
    width: parent.width
    height: ScreenTools.toolbarHeight
    color: Theme.chromeGlass

    property var planMasterController
    property bool showRallyPointsHelp: false

    signal toolbarButtonClicked()

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property real _controllerProgressPct: planMasterController.missionController.progressPct

    QGCPalette { id: qgcPal }

    /// Bottom divider (matches Fly View toolbar).
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.divider
    }

    // Replaces the stock QGC logo button: DroneHub plan view leaves via an explicit "Exit Plan" control.
    Item {
        id: qgcButton
        objectName: "toolbar_exitPlan"
        height: parent.height
        width: viewButtonRow.width + ScreenTools.defaultFontPixelWidth * 2

        RowLayout {
            id: viewButtonRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: ScreenTools.defaultFontPixelWidth
            spacing: ScreenTools.defaultFontPixelWidth / 2

            QGCLabel {
                font.pointSize: ScreenTools.largeFontPointSize
                text: "‹"
                color: Theme.brandPrimary
            }

            QGCLabel {
                text: qsTr("Exit Plan")
                font.pointSize: ScreenTools.largeFontPointSize
                color: Theme.textPrimary
            }
        }

        QGCMouseArea {
            anchors.fill: parent
            onClicked: mainWindow.showFlyView()
        }
    }

    QGCFlickable {
        id: toolsFlickable
        anchors.bottomMargin: 1
        anchors.left: qgcButton.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        contentWidth: toolIndicators.width
        flickableDirection: Flickable.HorizontalFlick

        PlanToolBarIndicators {
            id: toolIndicators
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            planMasterController: _root.planMasterController
            showRallyPointsHelp: _root.showRallyPointsHelp
            onToolbarButtonClicked: _root.toolbarButtonClicked()
        }
    }

    // Small mission download progress bar
    Rectangle {
        id: progressBar
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        height: 4
        width: _controllerProgressPct * parent.width
        color: qgcPal.colorGreen
        visible: false

        onVisibleChanged: {
            if (visible) {
                largeProgressBar._userHide = false
            }
        }
    }

    // Large mission download progress bar
    Rectangle {
        id: largeProgressBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height
        color: qgcPal.window
        visible: _showLargeProgress

        property bool _userHide: false
        property bool _showLargeProgress: progressBar.visible && !_userHide && qgcPal.globalTheme === QGCPalette.Light

        Connections {
            target: QGroundControl.multiVehicleManager
            function onActiveVehicleChanged(activeVehicle) { largeProgressBar._userHide = false }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: _controllerProgressPct * parent.width
            color: qgcPal.colorGreen
        }

        QGCLabel {
            anchors.centerIn: parent
            text: qsTr("Syncing Mission")
            font.pointSize: ScreenTools.largeFontPointSize
            visible: _controllerProgressPct !== 1
        }

        QGCLabel {
            anchors.centerIn: parent
            text: qsTr("Done")
            font.pointSize: ScreenTools.largeFontPointSize
            visible: _controllerProgressPct === 1
        }

        QGCLabel {
            anchors.margins: _margin
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            text: qsTr("Click anywhere to hide")

            property real _margin: ScreenTools.defaultFontPixelWidth / 2
        }

        MouseArea {
            anchors.fill: parent
            onClicked: largeProgressBar._userHide = true
        }
    }

    // Progress bar
    Connections {
        target: planMasterController.missionController

        function onProgressPctChanged(progressPct) {
            if (progressPct === 1) {
                if (_root.visible) {
                    resetProgressTimer.start()
                } else {
                    progressBar.visible = false
                }
            } else if (progressPct > 0) {
                progressBar.visible = true
            }
        }
    }

    Timer {
        id: resetProgressTimer
        interval: 3000
        onTriggered: progressBar.visible = false
    }
}
