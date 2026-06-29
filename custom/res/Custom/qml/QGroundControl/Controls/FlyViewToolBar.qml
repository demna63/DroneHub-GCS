/****************************************************************************
 * DroneHub GCS — Fly View toolbar override (branding + readable status zone).
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Controllers

import Custom

Rectangle {
    id:     _root
    width:  parent.width
    height: ScreenTools.toolbarHeight
    color:  Theme.chromeGlass

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false
    property color  _mainStatusBGColor: Theme.bgElevated

    function dropMainStatusIndicatorTool() {
        mainStatusIndicator.dropMainStatusIndicator();
    }

    QGCPalette { id: qgcPal }

    Rectangle {
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        height:         1
        color:          Theme.divider
    }

    RowLayout {
        id:                     viewButtonRow
        anchors.bottomMargin:   1
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.left:           parent.left
        anchors.leftMargin:     ScreenTools.defaultFontPixelWidth * 0.75
        spacing:                ScreenTools.defaultFontPixelWidth / 2

        Item {
            id:                     currentButton
            Layout.preferredHeight: viewButtonRow.height
            Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 15
            clip:                   true

            Image {
                id:                 toolbarLogo
                source:             Theme.logoSource
                anchors.centerIn:   parent
                width:              parent.width
                height:             parent.height
                fillMode:           Image.PreserveAspectFit
                scale:              Theme.toolbarLogoVisualScale
                transformOrigin:    Item.Center
                mipmap:             true
                smooth:             true
            }

            MouseArea {
                anchors.fill:       parent
                cursorShape:        Qt.PointingHandCursor
                hoverEnabled:       true
                onClicked:          Theme.flyToolStripExpanded = !Theme.flyToolStripExpanded
            }
        }

        Rectangle {
            Layout.preferredHeight: viewButtonRow.height - ScreenTools.defaultFontPixelHeight * 0.35
            Layout.preferredWidth:  mainStatusIndicator.implicitWidth + Theme.spacingUnit * 2
            radius:                 Theme.radiusSm
            color:                  Theme.bgElevated
            border.width:           1
            border.color:           Theme.divider

            MainStatusIndicator {
                id: mainStatusIndicator
                anchors.centerIn: parent
                height: parent.height - Theme.spacingUnit * 0.5
            }
        }

        QGCButton {
            id:                 disconnectButton
            text:               qsTr("Disconnect")
            onClicked:          _activeVehicle.closeVehicle()
            visible:            _activeVehicle && _communicationLost
        }
    }

    QGCFlickable {
        id:                     toolsFlickable
        anchors.leftMargin:     ScreenTools.defaultFontPixelWidth * ScreenTools.largeFontPointRatio * 1.5
        anchors.rightMargin:    ScreenTools.defaultFontPixelWidth / 2
        anchors.left:           viewButtonRow.right
        anchors.bottomMargin:   1
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.right:          cameraToggleButton.left
        contentWidth:           toolIndicators.width
        flickableDirection:     Flickable.HorizontalFlick

        FlyViewToolBarIndicators { id: toolIndicators }
    }

    Item {
        id:                     cameraToggleButton
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.right:          parent.right
        anchors.bottomMargin:   1
        width:                  ScreenTools.defaultFontPixelWidth * 5.5

        Image {
            source:             "/qmlimages/camera_video.svg"
            anchors.fill:       parent
            anchors.margins:    Math.max(4, cameraToggleButton.height * 0.18)
            fillMode:           Image.PreserveAspectFit
        }

        MouseArea {
            anchors.fill:       parent
            cursorShape:        Qt.PointingHandCursor
            hoverEnabled:       true
            onClicked:          Theme.flyCameraPanelExpanded = !Theme.flyCameraPanelExpanded
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        height:         _root.height * 0.05
        width:          _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
        color:          qgcPal.colorGreen
        visible:        !largeProgressBar.visible
    }

    Rectangle {
        id:             largeProgressBar
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right
        height:         parent.height
        color:          qgcPal.window
        visible:        _showLargeProgress

        property bool _initialDownloadComplete: _activeVehicle ? _activeVehicle.initialConnectComplete : true
        property bool _userHide:                false
        property bool _showLargeProgress:       !_initialDownloadComplete && !_userHide && qgcPal.globalTheme === QGCPalette.Light

        Connections {
            target:                 QGroundControl.multiVehicleManager
            function onActiveVehicleChanged(activeVehicle) { largeProgressBar._userHide = false }
        }

        Rectangle {
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            width:          _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
            color:          qgcPal.colorGreen
        }

        QGCLabel {
            anchors.centerIn:   parent
            text:               qsTr("Downloading")
            font.pointSize:     ScreenTools.largeFontPointSize
        }

        QGCLabel {
            anchors.margins:    _margin
            anchors.right:      parent.right
            anchors.bottom:     parent.bottom
            text:               qsTr("Click anywhere to hide")
            property real _margin: ScreenTools.defaultFontPixelWidth / 2
        }

        MouseArea {
            anchors.fill:   parent
            onClicked:      largeProgressBar._userHide = true
        }
    }
}
