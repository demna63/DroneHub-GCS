/****************************************************************************
 * DroneHub GCS — Fly View custom HUD overlay.
 *
 * QGC core-ის FlyViewCustomLayer.qml override (interceptor გადაამისამართებს:
 *   qrc:/qml/QGroundControl/FlightDisplay/FlyViewCustomLayer.qml
 *   → qrc:/Custom/qml/QGroundControl/FlightDisplay/FlyViewCustomLayer.qml).
 *
 * კონტრაქტი (არ ვცვლით): property parentToolInsets / totalToolInsets / mapControl.
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.FlightMap

import Custom

Item {
    id: _root

    property var parentToolInsets
    property var totalToolInsets:   _toolInsets
    property var mapControl

    property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    property var  _battery:         (_activeVehicle && _activeVehicle.batteries.count > 0)
                                        ? _activeVehicle.batteries.get(0) : null
    property real _margin:          ScreenTools.defaultFontPixelHeight

    // Helper to calculate heading direction letter
    function getHeadingLetter(heading) {
        var directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
        var index = Math.round(((heading % 360) / 45)) % 8;
        return directions[index];
    }

    // Dynamic status text logic
    function getVehicleStatusText() {
        if (!_activeVehicle) {
            return qsTr("DISCONNECTED");
        }
        if (_activeVehicle.vehicleLinkManager.communicationLost) {
            return qsTr("COMMS LOST");
        }
        if (_activeVehicle.armed) {
            var modeStr = _activeVehicle.flightMode.toUpperCase();
            if (_activeVehicle.flying) {
                return qsTr("FLYING") + " | " + modeStr;
            }
            if (_activeVehicle.landing) {
                return qsTr("LANDING") + " | " + modeStr;
            }
            return qsTr("ARMED") + " | " + modeStr;
        }
        if (_activeVehicle.readyToFly) {
            return qsTr("READY TO FLY") + " | " + _activeVehicle.flightMode.toUpperCase();
        }
        return qsTr("NOT READY") + " | " + _activeVehicle.flightMode.toUpperCase();
    }

    // Dynamic status color logic
    function getVehicleStatusColor() {
        if (!_activeVehicle) {
            return "#FF453A"; // Red
        }
        if (_activeVehicle.vehicleLinkManager.communicationLost) {
            return "#FF453A"; // Red
        }
        if (_activeVehicle.armed) {
            return "#30D158"; // Green
        }
        if (_activeVehicle.readyToFly) {
            return "#30D158"; // Green
        }
        return "#FF9F0A"; // Orange/Yellow
    }

    // Fallbacks for Mock UI/UX preview
    function getMockStatusText() {
        if (_activeVehicle) {
            return getVehicleStatusText();
        }
        return "READY TO FLY | HOLD"; // Default mock status matching screenshot
    }

    function getMockStatusColor() {
        if (_activeVehicle) {
            return getVehicleStatusColor();
        }
        return "#30D158"; // Green
    }

    // ---- Reusable Minimalist Vector Icon Component ----
    component HudIcon: Canvas {
        property string iconType: ""
        property color  iconColor: "#A0AAB8"
        
        width:          16
        height:         16
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = iconColor;
            ctx.fillStyle = iconColor;
            ctx.lineWidth = 1.5;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            
            if (iconType === "home") {
                ctx.beginPath();
                ctx.moveTo(8, 2);
                ctx.lineTo(14, 8);
                ctx.lineTo(11, 8);
                ctx.lineTo(11, 14);
                ctx.lineTo(5, 14);
                ctx.lineTo(5, 8);
                ctx.lineTo(2, 8);
                ctx.closePath();
                ctx.stroke();
            } else if (iconType === "speed") {
                ctx.beginPath();
                ctx.arc(8, 9, 5, Math.PI, 2*Math.PI);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(8, 9);
                ctx.lineTo(11, 6);
                ctx.stroke();
            } else if (iconType === "clock") {
                ctx.beginPath();
                ctx.arc(8, 8, 5, 0, 2*Math.PI);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(8, 8);
                ctx.lineTo(8, 4);
                ctx.moveTo(8, 8);
                ctx.lineTo(11, 8);
                ctx.stroke();
            } else if (iconType === "battery") {
                ctx.strokeRect(3, 4, 8, 10);
                ctx.fillRect(6, 2, 2, 2);
                ctx.fillRect(5, 7, 4, 6);
            } else if (iconType === "temp") {
                ctx.beginPath();
                ctx.arc(8, 11, 2.5, 0, 2*Math.PI);
                ctx.fill();
                ctx.beginPath();
                ctx.moveTo(6.5, 9);
                ctx.lineTo(6.5, 4);
                ctx.arc(8, 4, 1.5, Math.PI, 2*Math.PI);
                ctx.lineTo(9.5, 9);
                ctx.stroke();
            } else if (iconType === "height") {
                ctx.beginPath();
                ctx.moveTo(8, 2);
                ctx.lineTo(8, 14);
                ctx.moveTo(5, 5);
                ctx.lineTo(8, 2);
                ctx.lineTo(11, 5);
                ctx.moveTo(5, 11);
                ctx.lineTo(8, 14);
                ctx.lineTo(11, 11);
                ctx.stroke();
            } else if (iconType === "mountain") {
                ctx.beginPath();
                ctx.moveTo(2, 14);
                ctx.lineTo(7, 5);
                ctx.lineTo(12, 14);
                ctx.moveTo(5, 14);
                ctx.lineTo(9, 8);
                ctx.lineTo(13, 14);
                ctx.stroke();
            } else if (iconType === "radar") {
                ctx.beginPath();
                ctx.arc(8, 12, 1, 0, 2*Math.PI);
                ctx.fill();
                ctx.beginPath();
                ctx.arc(8, 12, 4, 1.25*Math.PI, 1.75*Math.PI);
                ctx.stroke();
                ctx.beginPath();
                ctx.arc(8, 12, 7, 1.25*Math.PI, 1.75*Math.PI);
                ctx.stroke();
            }
        }
        
        Component.onCompleted: requestPaint()
    }

    // ---- Central bottom HUD Pane ----
    Rectangle {
        id:                     hudPanel
        width:                  hudLayout.width + 40
        height:                 hudLayout.height + 24
        radius:                 Theme.radiusMd
        
        // Translucent background color (ARGB) for high readability while being transparent
        color:                  "#990B0E14" // ~60% opacity dark slate
        border.width:           1
        border.color:           "#40FFFFFF" // subtle semi-transparent white border
        
        anchors.bottom:         parent.bottom
        anchors.bottomMargin:   _margin
        anchors.horizontalCenter: parent.horizontalCenter
        visible:                !ScreenTools.isMobile

        RowLayout {
            id:                 hudLayout
            anchors.centerIn:   parent
            spacing:            25

            // ================= LEFT COLUMN =================
            ColumnLayout {
                spacing:        8
                Layout.alignment: Qt.AlignVCenter

                // 1. Home Distance
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing:    8
                    Text {
                        text:   (_activeVehicle && _activeVehicle.vehicle.distanceToHome.rawValue !== undefined)
                                    ? _activeVehicle.vehicle.distanceToHome.valueString + " m"
                                    : "64.5m"
                        color:  "#FFFFFF"
                        font.pixelSize: 13
                        font.bold: true
                        font.family: Theme.fontFamily
                    }
                    HudIcon {
                        iconType: "home"
                        iconColor: "#A0AAB8"
                    }
                }

                // 2. Speeds (Ground & Air)
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing:    8
                    ColumnLayout {
                        spacing: 1
                        Text {
                            text: "g: " + ((_activeVehicle && _activeVehicle.vehicle.groundSpeed.rawValue !== undefined)
                                      ? _activeVehicle.vehicle.groundSpeed.valueString + " m/s"
                                      : "0.1m/s")
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.family: Theme.fontFamily
                        }
                        Text {
                            text: "a: " + ((_activeVehicle && _activeVehicle.vehicle.airSpeed.rawValue !== undefined)
                                      ? _activeVehicle.vehicle.airSpeed.valueString + " m/s"
                                      : "0.1m/s")
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.family: Theme.fontFamily
                        }
                    }
                    HudIcon {
                        iconType: "speed"
                        iconColor: "#A0AAB8"
                    }
                }

                // 3. Flight Time (Red!)
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing:    8
                    Text {
                        text:   (_activeVehicle && _activeVehicle.vehicle.flightTime.rawValue !== undefined)
                                    ? _activeVehicle.vehicle.flightTime.valueString
                                    : "08:50"
                        color:  "#FF453A"
                        font.pixelSize: 14
                        font.bold: true
                        font.family: Theme.fontFamily
                    }
                    HudIcon {
                        iconType: "clock"
                        iconColor: "#FF453A"
                    }
                }

                // 4. Battery & Wind
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing:    8
                    RowLayout {
                        spacing: 6
                        Text {
                            text: (_battery && _battery.percentRemaining.rawValue !== undefined)
                                      ? _battery.percentRemaining.valueString + "%"
                                      : "28%"
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                        HudIcon {
                            iconType: "battery"
                            iconColor: "#A0AAB8"
                            width: 12
                            height: 12
                        }
                        Text {
                            text: (_activeVehicle && _activeVehicle.wind.speed.rawValue !== undefined)
                                      ? _activeVehicle.wind.speed.valueString + " m/s"
                                      : "0.0m/s"
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.family: Theme.fontFamily
                        }
                        HudIcon {
                            iconType: "radar"
                            iconColor: "#A0AAB8"
                            width: 12
                            height: 12
                        }
                    }
                }
            }

            // ================= CENTRAL INSTRUMENTATION SECTION =================
            ColumnLayout {
                spacing:        8
                Layout.alignment: Qt.AlignVCenter

                // Status Badge Pill
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    height:         18
                    width:          statusTextItem.contentWidth + 16
                    radius:         9
                    // Transparent color glow: append hex "1C" (11% alpha) to color code
                    color:          getMockStatusColor() + "1C"
                    border.width:   1
                    border.color:   getMockStatusColor()
                    
                    Text {
                        id:             statusTextItem
                        text:           getMockStatusText()
                        color:          getMockStatusColor()
                        font.bold:      true
                        font.pixelSize: 9
                        font.family:    Theme.fontFamily
                        anchors.centerIn: parent
                    }
                }

                // Instruments Row (Artificial Horizon next to Compass)
                RowLayout {
                    spacing:    15
                    Layout.alignment: Qt.AlignHCenter

                    // QGC Attitude Widget (Artificial Horizon showing side roll and pitch)
                    QGCAttitudeWidget {
                        id:             attitudeIndicator
                        size:           130
                        vehicle:        _activeVehicle
                        showHeading:    false
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Compass Dial
                    Rectangle {
                        id:             compassDial
                        width:          130
                        height:         130
                        radius:         width / 2
                        color:          "#99151A22"
                        border.width:   1.5
                        border.color:   "#40FFFFFF"
                        Layout.alignment: Qt.AlignVCenter

                        // Compass ticks (every 30 degrees)
                        Repeater {
                            model: 12
                            Rectangle {
                                width:  1.5
                                height: (index % 3 === 0) ? 8 : 4
                                color:  "#A0AAB8"
                                x:      compassDial.width / 2 - width / 2
                                y:      2
                                transformOrigin: Item.Bottom
                                transform: Rotation {
                                    angle: index * 30
                                    origin.x: width / 2
                                    origin.y: compassDial.height / 2 - 2
                                }
                            }
                        }

                        // Cardinal Letters
                        Text { text: "N"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 12; anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: 8 }
                        Text { text: "S"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 12; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 8 }
                        Text { text: "W"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8 }
                        Text { text: "E"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: 8 }

                        // Intermediate Degrees
                        Text { text: "60"; color: "#A0AAB8"; font.pixelSize: 9; x: compassDial.width * 0.72; y: compassDial.height * 0.22 }
                        Text { text: "120"; color: "#A0AAB8"; font.pixelSize: 9; x: compassDial.width * 0.72; y: compassDial.height * 0.70 }
                        Text { text: "240"; color: "#A0AAB8"; font.pixelSize: 9; x: compassDial.width * 0.16; y: compassDial.height * 0.70 }
                        Text { text: "300"; color: "#A0AAB8"; font.pixelSize: 9; x: compassDial.width * 0.16; y: compassDial.height * 0.22 }

                        // Rotating Arrow Canvas (representing drone heading)
                        Canvas {
                            id:                 arrowCanvas
                            anchors.centerIn:   parent
                            width:              30
                            height:             30
                            rotation:           _activeVehicle ? _activeVehicle.vehicle.heading.rawValue : 0
                            
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.fillStyle = "#FFFFFF";
                                ctx.beginPath();
                                ctx.moveTo(15, 2);   // Top point of chevron
                                ctx.lineTo(26, 25);  // Bottom right
                                ctx.lineTo(15, 18);  // Inner center indent
                                ctx.lineTo(4, 25);   // Bottom left
                                ctx.closePath();
                                ctx.fill();
                                
                                // Thin dark border outline for separation
                                ctx.strokeStyle = "#151A22";
                                ctx.lineWidth = 1.5;
                                ctx.stroke();
                            }

                            // Keep canvas rotation updated dynamically
                            Connections {
                                target: _activeVehicle ? _activeVehicle.vehicle.heading : null
                                function onRawValueChanged() { arrowCanvas.requestPaint(); }
                            }
                            
                            Component.onCompleted: requestPaint()
                        }

                        // Heading Number
                        Text {
                            text:               Math.round(_activeVehicle ? _activeVehicle.vehicle.heading.rawValue : 276)
                            color:              "#FFFFFF"
                            font.bold:          true
                            font.pixelSize:     14
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom:     parent.bottom
                            anchors.bottomMargin: compassDial.height * 0.22
                        }

                        // Heading Letter
                        Text {
                            text:               getHeadingLetter(_activeVehicle ? _activeVehicle.vehicle.heading.rawValue : 276)
                            color:              "#A0AAB8"
                            font.pixelSize:     11
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom:     parent.bottom
                            anchors.bottomMargin: compassDial.height * 0.12
                        }
                    }
                }
            }

            // ================= RIGHT COLUMN =================
            ColumnLayout {
                spacing:        8
                Layout.alignment: Qt.AlignVCenter

                // 1. Thermometer / Battery Temp (Cyan!)
                RowLayout {
                    Layout.alignment: Qt.AlignLeft
                    spacing:    8
                    HudIcon {
                        iconType: "temp"
                        iconColor: "#64D2FF"
                    }
                    Text {
                        text:   (_battery && _battery.temperature.rawValue !== undefined)
                                    ? _battery.temperature.valueString + "°C"
                                    : "45.63°C"
                        color:  "#64D2FF"
                        font.pixelSize: 13
                        font.bold: true
                        font.family: Theme.fontFamily
                    }
                }

                // 2. Relative Height (H 44m & Climb Rate)
                RowLayout {
                    Layout.alignment: Qt.AlignLeft
                    spacing:    8
                    HudIcon {
                        iconType: "height"
                        iconColor: "#A0AAB8"
                    }
                    RowLayout {
                        spacing: 6
                        Text {
                            text: "H " + ((_activeVehicle && _activeVehicle.vehicle.altitudeRelative.rawValue !== undefined)
                                      ? _activeVehicle.vehicle.altitudeRelative.valueString + "m"
                                      : "44m")
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                        Text {
                            text: (_activeVehicle && _activeVehicle.vehicle.climbRate.rawValue !== undefined)
                                      ? _activeVehicle.vehicle.climbRate.valueString + " m/s"
                                      : "-0.1m/s"
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.family: Theme.fontFamily
                        }
                    }
                }

                // 3. Sea Level Alt & Current Draw (Green!)
                RowLayout {
                    Layout.alignment: Qt.AlignLeft
                    spacing:    8
                    HudIcon {
                        iconType: "mountain"
                        iconColor: "#A0AAB8"
                    }
                    RowLayout {
                        spacing: 6
                        Text {
                            text: (_activeVehicle && _activeVehicle.vehicle.altitudeAMSL.rawValue !== undefined)
                                      ? _activeVehicle.vehicle.altitudeAMSL.valueString + "m"
                                      : "47m"
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.family: Theme.fontFamily
                        }
                        Text {
                            text: (_battery && _battery.current.rawValue !== undefined)
                                      ? _battery.current.valueString + "A"
                                      : "0.0A"
                            color: "#30D158"
                            font.pixelSize: 11
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                    }
                }

                // 4. AGL / GL (Radar)
                RowLayout {
                    Layout.alignment: Qt.AlignLeft
                    spacing:    8
                    HudIcon {
                        iconType: "radar"
                        iconColor: "#A0AAB8"
                    }
                    Text {
                        text:   "AGL: 41.8  GL: 2.2"
                        color:  "#FFFFFF"
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                    }
                }
            }
        }
    }

    // ---- insets: push core controls up so they don't overlap our HUD ----
    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeTopInset:       parentToolInsets.leftEdgeTopInset
        leftEdgeCenterInset:    parentToolInsets.leftEdgeCenterInset
        leftEdgeBottomInset:    parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      parentToolInsets.rightEdgeTopInset
        rightEdgeCenterInset:   parentToolInsets.rightEdgeCenterInset
        rightEdgeBottomInset:   parentToolInsets.rightEdgeBottomInset
        topEdgeLeftInset:       parentToolInsets.topEdgeLeftInset
        topEdgeCenterInset:     parentToolInsets.topEdgeCenterInset
        topEdgeRightInset:      parentToolInsets.topEdgeRightInset
        bottomEdgeLeftInset:    parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  hudPanel.visible
                                    ? hudPanel.height + (_margin * 2)
                                    : parentToolInsets.bottomEdgeCenterInset
        bottomEdgeRightInset:   parentToolInsets.bottomEdgeRightInset
    }
}
