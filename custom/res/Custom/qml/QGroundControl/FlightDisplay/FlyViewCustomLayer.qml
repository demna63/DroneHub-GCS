/****************************************************************************
 * DroneHub GCS — Fly View custom HUD overlay.
 *
 * QGC core-ის FlyViewCustomLayer.qml override (interceptor გადაამისამართებს:
 *   qrc:/qml/QGroundControl/FlightDisplay/FlyViewCustomLayer.qml
 *   → qrc:/Custom/qml/QGroundControl/FlightDisplay/FlyViewCustomLayer.qml).
 *
 * კონტრაქტი (არ ვცვლით): property parentToolInsets / totalToolInsets / mapControl.
 * სტატუსი — მხოლოდ QGC toolbar-ში (dedup); HUD აჩვენებს მხოლოდ ტელემეტრიას.
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
    property bool _hasVehicle:      _activeVehicle !== null
    property bool _hudExpanded:     false
    property bool _cleanMapActive:  false
    property string _storedMapProvider: ""
    property string _storedMapType:     ""
    property real _margin:          ScreenTools.defaultFontPixelHeight
    property real _bottomSafe:      _margin + (Qt.platform.os === "osx" ? _margin * 0.75 : 0)
    property real _instrumentSize:  _hudExpanded ? Theme.instrumentSizeExpanded : Theme.instrumentSizeCompact

    function _factValue(fact) {
        if (!fact || fact.rawValue === undefined) {
            return Theme.emptyValue
        }
        return fact.valueString
    }

    function _factWithUnit(fact, unit) {
        var value = _factValue(fact)
        return value === Theme.emptyValue ? value : value + unit
    }

    function getHeadingLetter(heading) {
        if (heading === undefined || isNaN(heading)) {
            return Theme.emptyValue
        }
        var directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        var index = Math.round(((heading % 360) / 45)) % 8
        return directions[index]
    }

    function _headingNumber() {
        if (!_activeVehicle || _activeVehicle.vehicle.heading.rawValue === undefined) {
            return Theme.emptyValue
        }
        return Math.round(_activeVehicle.vehicle.heading.rawValue)
    }

    function _valueColor(hasData) {
        if (!_hasVehicle || !hasData) {
            return Theme.textDisabled
        }
        return Theme.textPrimary
    }

    function _findSatelliteMapType(fms) {
        if (!fms || !fms.mapType) {
            return ""
        }
        var types = fms.mapType.enumStrings
        for (var i = 0; i < types.length; i++) {
            var name = types[i]
            var lower = name.toLowerCase()
            if (lower.indexOf("satellite") >= 0
                    && lower.indexOf("hybrid") < 0
                    && lower.indexOf("street") < 0
                    && lower.indexOf("road") < 0) {
                return name
            }
        }
        for (var j = 0; j < types.length; j++) {
            if (types[j].toLowerCase().indexOf("imagery") >= 0) {
                return types[j]
            }
        }
        return ""
    }

    function _applyCleanMap(enabled) {
        var fms = QGroundControl.settingsManager.flightMapSettings
        if (!fms) {
            return
        }

        if (enabled) {
            if (!_cleanMapActive) {
                _storedMapProvider = fms.mapProvider.rawValue
                _storedMapType = fms.mapType.rawValue
            }

            var satelliteType = _findSatelliteMapType(fms)
            if (satelliteType !== "") {
                fms.mapType.rawValue = satelliteType
            }

            var providers = fms.mapProvider.enumStrings
            for (var p = 0; p < providers.length; p++) {
                if (providers[p].indexOf("Esri") >= 0) {
                    fms.mapProvider.rawValue = providers[p]
                    var esriTypes = fms.mapType.enumStrings
                    for (var e = 0; e < esriTypes.length; e++) {
                        if (esriTypes[e].indexOf("Imagery") >= 0) {
                            fms.mapType.rawValue = esriTypes[e]
                            break
                        }
                    }
                    break
                }
            }
            _cleanMapActive = true
        } else {
            if (_storedMapProvider !== "") {
                fms.mapProvider.rawValue = _storedMapProvider
            }
            if (_storedMapType !== "") {
                fms.mapType.rawValue = _storedMapType
            }
            _cleanMapActive = false
        }

        if (mapControl && typeof mapControl.updateActiveMapType === "function") {
            mapControl.updateActiveMapType()
        }
    }

    // ---- Reusable HUD components ----
    component HudIcon: Canvas {
        property string iconType: ""
        property color  iconColor: Theme.textSecondary

        width:  16
        height: 16

        onIconColorChanged: requestPaint()
        onIconTypeChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.strokeStyle = iconColor
            ctx.fillStyle = iconColor
            ctx.lineWidth = 1.5
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            if (iconType === "home") {
                ctx.beginPath()
                ctx.moveTo(8, 2)
                ctx.lineTo(14, 8)
                ctx.lineTo(11, 8)
                ctx.lineTo(11, 14)
                ctx.lineTo(5, 14)
                ctx.lineTo(5, 8)
                ctx.lineTo(2, 8)
                ctx.closePath()
                ctx.stroke()
            } else if (iconType === "speed") {
                ctx.beginPath()
                ctx.arc(8, 9, 5, Math.PI, 2 * Math.PI)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(8, 9)
                ctx.lineTo(11, 6)
                ctx.stroke()
            } else if (iconType === "clock") {
                ctx.beginPath()
                ctx.arc(8, 8, 5, 0, 2 * Math.PI)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(8, 8)
                ctx.lineTo(8, 4)
                ctx.moveTo(8, 8)
                ctx.lineTo(11, 8)
                ctx.stroke()
            } else if (iconType === "battery") {
                ctx.strokeRect(3, 4, 8, 10)
                ctx.fillRect(6, 2, 2, 2)
                ctx.fillRect(5, 7, 4, 6)
            } else if (iconType === "temp") {
                ctx.beginPath()
                ctx.arc(8, 11, 2.5, 0, 2 * Math.PI)
                ctx.fill()
                ctx.beginPath()
                ctx.moveTo(6.5, 9)
                ctx.lineTo(6.5, 4)
                ctx.arc(8, 4, 1.5, Math.PI, 2 * Math.PI)
                ctx.lineTo(9.5, 9)
                ctx.stroke()
            } else if (iconType === "height") {
                ctx.beginPath()
                ctx.moveTo(8, 2)
                ctx.lineTo(8, 14)
                ctx.moveTo(5, 5)
                ctx.lineTo(8, 2)
                ctx.lineTo(11, 5)
                ctx.moveTo(5, 11)
                ctx.lineTo(8, 14)
                ctx.lineTo(11, 11)
                ctx.stroke()
            } else if (iconType === "mountain") {
                ctx.beginPath()
                ctx.moveTo(2, 14)
                ctx.lineTo(7, 5)
                ctx.lineTo(12, 14)
                ctx.moveTo(5, 14)
                ctx.lineTo(9, 8)
                ctx.lineTo(13, 14)
                ctx.stroke()
            } else if (iconType === "radar") {
                ctx.beginPath()
                ctx.arc(8, 12, 1, 0, 2 * Math.PI)
                ctx.fill()
                ctx.beginPath()
                ctx.arc(8, 12, 4, 1.25 * Math.PI, 1.75 * Math.PI)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(8, 12, 7, 1.25 * Math.PI, 1.75 * Math.PI)
                ctx.stroke()
            } else if (iconType === "satellite") {
                ctx.beginPath()
                ctx.arc(8, 8, 2, 0, 2 * Math.PI)
                ctx.fill()
                ctx.beginPath()
                ctx.moveTo(8, 2)
                ctx.lineTo(8, 5)
                ctx.moveTo(8, 11)
                ctx.lineTo(8, 14)
                ctx.moveTo(2, 8)
                ctx.lineTo(5, 8)
                ctx.moveTo(11, 8)
                ctx.lineTo(14, 8)
                ctx.stroke()
            }
        }

        Component.onCompleted: requestPaint()
    }

    component HeroMetric: ColumnLayout {
        property string label: ""
        property string valueText: Theme.emptyValue

        spacing: Theme.spacingUnit * 0.5
        Layout.preferredWidth: 96

        Text {
            text: label
            color: Theme.textSecondary
            font.pixelSize: Theme.fontCaption
            font.family: Theme.fontFamily
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }
        Text {
            text: valueText
            color: valueText === Theme.emptyValue ? Theme.textDisabled : Theme.textPrimary
            font.pixelSize: _root._hudExpanded ? Theme.fontHero : Theme.fontBody
            font.bold: true
            font.family: Theme.fontFamily
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            style: Text.Outline
            styleColor: Qt.rgba(0, 0, 0, 0.45)
        }
    }

    component MetricRow: RowLayout {
        property string label: ""
        property string valueText: Theme.emptyValue
        property color  valueColor: _root._valueColor(valueText !== Theme.emptyValue)
        property string iconType: ""
        property color  iconColor: Theme.textSecondary
        property bool   alignRight: false

        Layout.alignment: alignRight ? Qt.AlignRight : Qt.AlignLeft
        spacing: Theme.spacingUnit

        HudIcon {
            visible: iconType !== "" && !alignRight
            iconType: parent.iconType
            iconColor: parent.iconColor
        }
        ColumnLayout {
            spacing: 1
            Layout.alignment: alignRight ? Qt.AlignRight : Qt.AlignLeft
            Text {
                text: label
                color: Theme.textSecondary
                font.pixelSize: Theme.fontMicro
                font.family: Theme.fontFamily
                horizontalAlignment: alignRight ? Text.AlignRight : Text.AlignLeft
            }
            Text {
                text: valueText
                color: valueColor
                font.pixelSize: Theme.fontCaption
                font.bold: true
                font.family: Theme.fontFamily
                horizontalAlignment: alignRight ? Text.AlignRight : Text.AlignLeft
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, 0.35)
            }
        }
        HudIcon {
            visible: iconType !== "" && alignRight
            iconType: parent.iconType
            iconColor: parent.iconColor
        }
    }

    component HudToolButton: Rectangle {
        id:     toolButton
        property string label: ""
        property bool   toggled: false
        signal clicked()

        radius:         Theme.radiusSm
        color:          toggled ? Theme.hudControlActive : "transparent"
        border.width:   toggled ? 1 : 0
        border.color:   Theme.hudControlBorder
        implicitHeight: toolLabel.implicitHeight + Theme.spacingUnit
        implicitWidth:  toolLabel.implicitWidth + Theme.spacingUnit * 2

        Text {
            id:             toolLabel
            anchors.centerIn: parent
            text:           toolButton.label
            color:          toolButton.toggled ? Theme.brandPrimary : Theme.textSecondary
            font.pixelSize: Theme.fontMicro
            font.family:    Theme.fontFamily
        }

        MouseArea {
            anchors.fill:   parent
            onClicked:      toolButton.clicked()
        }
    }

    component CompassDial: Rectangle {
        id:             compassRoot
        property real  dialSize: _root._instrumentSize

        width:          dialSize
        height:         dialSize
        radius:         width / 2
        color:          Theme.instrumentBackground
        border.width:   1.5
        border.color:   Theme.instrumentBorder
        opacity:        _hasVehicle ? 1.0 : 0.45

        Repeater {
            model: 12
            Rectangle {
                width:  1.5
                height: (index % 3 === 0) ? 8 : 4
                color:  Theme.textSecondary
                x:      compassRoot.width / 2 - width / 2
                y:      2
                transformOrigin: Item.Bottom
                transform: Rotation {
                    angle: index * 30
                    origin.x: width / 2
                    origin.y: compassRoot.height / 2 - 2
                }
            }
        }

        Text {
            text: "N"
            color: Theme.textPrimary
            font.bold: true
            font.pixelSize: Theme.fontCaption
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 8
        }
        Text {
            text: "S"
            color: Theme.textPrimary
            font.bold: true
            font.pixelSize: Theme.fontCaption
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
        }
        Text {
            text: "W"
            color: Theme.textPrimary
            font.bold: true
            font.pixelSize: Theme.fontCaption
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 8
        }
        Text {
            text: "E"
            color: Theme.textPrimary
            font.bold: true
            font.pixelSize: Theme.fontCaption
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 8
        }

        Canvas {
            id:                 arrowCanvas
            anchors.centerIn:   parent
            width:              compassRoot.dialSize * 0.22
            height:             width
            rotation:           (_activeVehicle
                                 && _activeVehicle.vehicle.heading.rawValue !== undefined)
                                ? _activeVehicle.vehicle.heading.rawValue : 0

            onPaint: {
                var ctx = getContext("2d")
                var cx = width / 2
                var cy = height / 2
                ctx.reset()
                ctx.fillStyle = Theme.textPrimary
                ctx.beginPath()
                ctx.moveTo(cx, 2)
                ctx.lineTo(width - 2, height - 2)
                ctx.lineTo(cx, cy)
                ctx.lineTo(2, height - 2)
                ctx.closePath()
                ctx.fill()
                ctx.strokeStyle = Theme.bgSurface
                ctx.lineWidth = 1.5
                ctx.stroke()
            }

            Connections {
                target: _activeVehicle ? _activeVehicle.vehicle.heading : null
                function onRawValueChanged() { arrowCanvas.requestPaint() }
            }

            Component.onCompleted: requestPaint()
        }

        Text {
            text:               _root._headingNumber()
            color:              Theme.textPrimary
            font.bold:          true
            font.pixelSize:     Theme.fontBody
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom:     parent.bottom
            anchors.bottomMargin: compassRoot.height * 0.22
            style: Text.Outline
            styleColor: Qt.rgba(0, 0, 0, 0.4)
        }

        Text {
            text:               _root.getHeadingLetter(
                                      _activeVehicle
                                      ? _activeVehicle.vehicle.heading.rawValue
                                      : undefined)
            color:              Theme.textSecondary
            font.pixelSize:     Theme.fontMicro
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom:     parent.bottom
            anchors.bottomMargin: compassRoot.height * 0.12
        }
    }

    // ---- Central bottom HUD pane ----
    Rectangle {
        id:                     hudPanel
        width:                  Math.min(hudColumn.width + Theme.spacingUnit * 5, _root.width - _margin * 2)
        height:                 hudColumn.height + Theme.spacingUnit * 3
        radius:                 Theme.radiusMd
        color:                  _hasVehicle ? Theme.hudBackground : Theme.hudBackgroundIdle
        border.width:           1
        border.color:           Theme.hudBorder
        opacity:                _hasVehicle ? 1.0 : 0.72
        anchors.bottom:         parent.bottom
        anchors.bottomMargin:   _bottomSafe
        anchors.horizontalCenter: parent.horizontalCenter
        visible:                !ScreenTools.isMobile

        ColumnLayout {
            id:                 hudColumn
            anchors.centerIn:   parent
            spacing:            Theme.spacingUnit * 1.5

            // ---- HUD controls ----
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: Theme.spacingUnit

                HudToolButton {
                    label: _cleanMapActive ? qsTr("Standard map") : qsTr("Clean map")
                    toggled: _cleanMapActive
                    onClicked: _root._applyCleanMap(!_cleanMapActive)
                }
                HudToolButton {
                    label: _hudExpanded ? qsTr("Collapse") : qsTr("Expand")
                    onClicked: _hudExpanded = !_hudExpanded
                }
            }

            // ---- Tier 1: critical flight metrics ----
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.spacingUnit * (_hudExpanded ? 4 : 2)

                HeroMetric {
                    label: qsTr("Altitude")
                    valueText: _root._factWithUnit(
                        _activeVehicle ? _activeVehicle.vehicle.altitudeRelative : null, " m")
                }
                HeroMetric {
                    label: qsTr("Ground Speed")
                    valueText: _root._factWithUnit(
                        _activeVehicle ? _activeVehicle.vehicle.groundSpeed : null, " m/s")
                }
                HeroMetric {
                    label: qsTr("Battery")
                    valueText: {
                        var pct = _root._factValue(_battery ? _battery.percentRemaining : null)
                        return pct === Theme.emptyValue ? pct : pct + "%"
                    }
                }

                QGCAttitudeWidget {
                    size:           _instrumentSize
                    vehicle:        _activeVehicle
                    showHeading:    false
                    opacity:        _hasVehicle ? 1.0 : 0.45
                    Layout.alignment: Qt.AlignVCenter
                }

                CompassDial {
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Rectangle {
                visible:            _hudExpanded
                Layout.fillWidth: true
                Layout.preferredWidth: hudColumn.width - Theme.spacingUnit * 2
                height:             visible ? 1 : 0
                color:              Theme.divider
            }

            RowLayout {
                visible:            _hudExpanded
                Layout.alignment:   Qt.AlignHCenter
                spacing:            Theme.spacingUnit * 3

                ColumnLayout {
                    spacing: Theme.spacingUnit
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 130

                    MetricRow {
                        alignRight: true
                        label: qsTr("Distance")
                        valueText: _root._factWithUnit(
                            _activeVehicle ? _activeVehicle.vehicle.distanceToHome : null, " m")
                        iconType: "home"
                    }
                    MetricRow {
                        alignRight: true
                        label: qsTr("Climb Rate")
                        valueText: _root._factWithUnit(
                            _activeVehicle ? _activeVehicle.vehicle.climbRate : null, " m/s")
                        iconType: "height"
                    }
                    MetricRow {
                        alignRight: true
                        label: qsTr("Flight Time")
                        valueText: _root._factValue(
                            _activeVehicle ? _activeVehicle.vehicle.flightTime : null)
                        valueColor: _root._valueColor(
                            _activeVehicle && _activeVehicle.vehicle.flightTime
                            && _activeVehicle.vehicle.flightTime.rawValue !== undefined)
                        iconType: "clock"
                        iconColor: Theme.textSecondary
                    }
                    MetricRow {
                        alignRight: true
                        label: qsTr("Air Speed")
                        valueText: _root._factWithUnit(
                            _activeVehicle ? _activeVehicle.vehicle.airSpeed : null, " m/s")
                        iconType: "speed"
                    }
                }

                ColumnLayout {
                    spacing: Theme.spacingUnit
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 130

                    MetricRow {
                        label: qsTr("Temperature")
                        valueText: {
                            var t = _root._factValue(_battery ? _battery.temperature : null)
                            return t === Theme.emptyValue ? t : t + "°C"
                        }
                        valueColor: {
                            if (!_hasVehicle || !_battery || _battery.temperature.rawValue === undefined) {
                                return Theme.textDisabled
                            }
                            return Theme.telemetryAccent
                        }
                        iconType: "temp"
                        iconColor: Theme.telemetryAccent
                    }
                    MetricRow {
                        label: qsTr("AMSL")
                        valueText: _root._factWithUnit(
                            _activeVehicle ? _activeVehicle.vehicle.altitudeAMSL : null, " m")
                        iconType: "mountain"
                    }
                    MetricRow {
                        label: qsTr("Current")
                        valueText: {
                            var a = _root._factValue(_battery ? _battery.current : null)
                            return a === Theme.emptyValue ? a : a + " A"
                        }
                        valueColor: _root._valueColor(
                            _battery && _battery.current
                            && _battery.current.rawValue !== undefined)
                        iconType: "battery"
                    }
                    MetricRow {
                        label: qsTr("Satellites")
                        valueText: _root._factValue(
                            _activeVehicle ? _activeVehicle.gps.count : null)
                        iconType: "satellite"
                    }
                    MetricRow {
                        label: qsTr("Wind")
                        valueText: _root._factWithUnit(
                            _activeVehicle ? _activeVehicle.wind.speed : null, " m/s")
                        iconType: "radar"
                    }
                }
            }
        }
    }

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
                                    ? hudPanel.height + (_bottomSafe * 2)
                                    : parentToolInsets.bottomEdgeCenterInset
        bottomEdgeRightInset:   parentToolInsets.bottomEdgeRightInset
    }
}
