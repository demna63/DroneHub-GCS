/****************************************************************************
 * DroneHub GCS — Fly View custom overlay (F2).
 *
 * QGC core-ის FlyViewCustomLayer.qml override (interceptor გადაამისამართებს:
 *   qrc:/qml/QGroundControl/FlightDisplay/FlyViewCustomLayer.qml
 *   → qrc:/Custom/qml/QGroundControl/FlightDisplay/FlyViewCustomLayer.qml).
 *
 * კონტრაქტი (არ ვცვლით): property parentToolInsets / totalToolInsets / mapControl.
 * totalToolInsets-ში ვამატებთ ჩვენი ტელემეტრიის პანელის footprint-ს, რომ core
 * კონტროლები არ გადაეფაროს.
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

import Custom

Item {
    id: _root

    property var parentToolInsets
    property var totalToolInsets:   _toolInsets
    property var mapControl

    property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    property var  _battery:         (_activeVehicle && _activeVehicle.batteries.count > 0)
                                        ? _activeVehicle.batteries.get(0) : null
    property real _margin:          ScreenTools.defaultFontPixelWidth * 1.5
    property real _panelWidth:      ScreenTools.defaultFontPixelWidth * 20

    // ---- ტელემეტრიის პანელი (მარცხენა კიდე, ვერტიკალურად ცენტრში) ----
    Rectangle {
        id:                 telemetryPanel
        width:              _panelWidth
        height:             contentColumn.height + (_margin * 2)
        radius:             Theme.radiusMd
        color:              Theme.bgSurface
        opacity:            0.92
        border.width:       1
        border.color:       Theme.divider
        visible:            _activeVehicle && !ScreenTools.isMobile
        anchors.left:       parent.left
        anchors.leftMargin: _margin
        anchors.verticalCenter: parent.verticalCenter

        ColumnLayout {
            id:                 contentColumn
            anchors.left:       parent.left
            anchors.right:      parent.right
            anchors.top:        parent.top
            anchors.margins:    _margin
            spacing:            Theme.spacingUnit

            // header
            RowLayout {
                Layout.fillWidth:   true
                spacing:            Theme.spacingUnit
                Image {
                    source:                 Theme.logoSource
                    sourceSize.height:      ScreenTools.defaultFontPixelHeight * 1.2
                    fillMode:               Image.PreserveAspectFit
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width:      ScreenTools.defaultFontPixelWidth
                    height:     width
                    radius:     width / 2
                    color:      (_activeVehicle && _activeVehicle.armed) ? Theme.brandAccent : Theme.textDisabled
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }

            // telemetry rows
            TelemRow { label: qsTr("Altitude");    fact: _activeVehicle ? _activeVehicle.vehicle.altitudeRelative : null }
            TelemRow { label: qsTr("Ground Speed"); fact: _activeVehicle ? _activeVehicle.vehicle.groundSpeed    : null }
            TelemRow { label: qsTr("Climb Rate");  fact: _activeVehicle ? _activeVehicle.vehicle.climbRate       : null }
            TelemRow { label: qsTr("Distance");    fact: _activeVehicle ? _activeVehicle.vehicle.flightDistance  : null }
            TelemRow { label: qsTr("Satellites");  fact: _activeVehicle ? _activeVehicle.gps.count               : null }
            TelemRow { label: qsTr("Battery");     fact: _battery ? _battery.percentRemaining                    : null }
        }
    }

    // ---- ერთი ტელემეტრიის სტრიქონი: ლეიბლი + მნიშვნელობა + ერთეული ----
    component TelemRow: RowLayout {
        property string label
        property var    fact
        Layout.fillWidth:   true
        spacing:            Theme.spacingUnit

        QGCLabel {
            text:               label
            color:              Theme.textSecondary
            font.pixelSize:     Theme.fontCaption
            font.family:        Theme.fontFamily
        }
        Item { Layout.fillWidth: true }
        QGCLabel {
            text:               fact ? fact.valueString : "—"
            color:              Theme.textPrimary
            font.pixelSize:     Theme.fontBody
            font.family:        Theme.fontFamily
            horizontalAlignment: Text.AlignRight
        }
        QGCLabel {
            text:               fact ? fact.units : ""
            color:              Theme.textDisabled
            font.pixelSize:     Theme.fontCaption
            font.family:        Theme.fontFamily
            visible:            text.length > 0
        }
    }

    // ---- insets: core კონტროლებს ვუთმობთ ადგილს ჩვენი პანელის გვერდით ----
    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeTopInset:       parentToolInsets.leftEdgeTopInset
        leftEdgeCenterInset:    telemetryPanel.visible
                                    ? telemetryPanel.x + telemetryPanel.width + _margin
                                    : parentToolInsets.leftEdgeCenterInset
        leftEdgeBottomInset:    parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      parentToolInsets.rightEdgeTopInset
        rightEdgeCenterInset:   parentToolInsets.rightEdgeCenterInset
        rightEdgeBottomInset:   parentToolInsets.rightEdgeBottomInset
        topEdgeLeftInset:       parentToolInsets.topEdgeLeftInset
        topEdgeCenterInset:     parentToolInsets.topEdgeCenterInset
        topEdgeRightInset:      parentToolInsets.topEdgeRightInset
        bottomEdgeLeftInset:    parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  parentToolInsets.bottomEdgeCenterInset
        bottomEdgeRightInset:   parentToolInsets.bottomEdgeRightInset
    }
}
