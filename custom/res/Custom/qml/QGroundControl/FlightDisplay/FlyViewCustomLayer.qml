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
import QGroundControl.FlightMap
import QGroundControl.ScreenTools

Item {
    id: _root

    property var parentToolInsets
    property var totalToolInsets:   _toolInsets
    property var mapControl

    // Inline tokens — FlyViewCustomLayer compiles into FlightDisplayModule (qmlcache);
    // must not import Custom module (loads before engine import paths are ready).
    readonly property QtObject _t: QtObject {
        readonly property color brandPrimary:       "#0A84FF"
        readonly property color telemetryAccent:    "#64D2FF"
        readonly property color hudGlass:           "#28000000"
        readonly property color hudGlassStrong:   "#44000000"
        readonly property color hudBorder:          "#55FFFFFF"
        readonly property color instrumentGlass:    "#18000000"
        readonly property color instrumentBorder:   "#66FFFFFF"
        readonly property color hudControlActive:   "#660A84FF"
        readonly property color hudControlBorder:   "#990A84FF"
        readonly property color textPrimary:        "#FFFFFF"
        readonly property color textSecondary:      "#D0D8E4"
        readonly property color textDisabled:       "#9AA6B8"
        readonly property color textOutline:        "#CC000000"
        readonly property real  radiusSm:           6
        readonly property real  radiusMd:           12
        readonly property real  radiusLg:           20
        readonly property real  spacingUnit:        8
        readonly property real  instrumentSizeCompact:  92
        readonly property real  instrumentSizeExpanded: 116
        readonly property string fontFamily:        "Noto Sans Georgian"
        readonly property string fontFamilyNumeric: ScreenTools.normalFontFamily
        readonly property real  fontHero:           28
        readonly property real  fontBody:           18
        readonly property real  fontCaption:        12
        readonly property real  fontMicro:          11
        readonly property string emptyValue:        "—"
    }

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
    property real _topChromeInset:  parentToolInsets
                                        ? Math.max(parentToolInsets.topEdgeLeftInset,
                                                   parentToolInsets.topEdgeCenterInset,
                                                   parentToolInsets.topEdgeRightInset)
                                        : _margin
    property real _instrumentSize:  _hudExpanded ? _t.instrumentSizeExpanded : _t.instrumentSizeCompact

    function _factValue(fact) {
        if (!fact || fact.rawValue === undefined) {
            return _t.emptyValue
        }
        return fact.valueString
    }

    function _factWithUnit(fact, unit) {
        var value = _factValue(fact)
        return value === _t.emptyValue ? value : value + unit
    }

    function getHeadingLetter(heading) {
        if (heading === undefined || isNaN(heading)) {
            return _t.emptyValue
        }
        var directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        var index = Math.round(((heading % 360) / 45)) % 8
        return directions[index]
    }

    function _headingNumber() {
        if (!_activeVehicle || _activeVehicle.heading.rawValue === undefined) {
            return _t.emptyValue
        }
        return Math.round(_activeVehicle.heading.rawValue)
    }

    function _valueColor(hasData) {
        if (!_hasVehicle || !hasData) {
            return _t.textDisabled
        }
        return _t.textPrimary
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
        property color  iconColor: _t.textSecondary

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

    component FloatingMetric: Item {
        property string label: ""
        property string valueText: _t.emptyValue
        property real   valueSize: _root._hudExpanded ? _t.fontHero : _t.fontBody + 4

        implicitWidth: metricCol.implicitWidth
        implicitHeight: metricCol.implicitHeight

        ColumnLayout {
            id: metricCol
            anchors.centerIn: parent
            spacing: 2

            Text {
                text: label.toUpperCase()
                color: _t.textSecondary
                font.pixelSize: _t.fontMicro
                font.family: _t.fontFamily
                font.weight: Font.Medium
                font.letterSpacing: 0.6
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
            Text {
                text: valueText
                color: valueText === _t.emptyValue ? _t.textDisabled : _t.textPrimary
                font.pixelSize: valueSize
                font.bold: true
                font.family: _t.fontFamilyNumeric
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                style: Text.Outline
                styleColor: _t.textOutline
            }
        }
    }

    component HeroMetric: FloatingMetric { }

    component GlassPill: Rectangle {
        id:     glassPill
        property string label: ""
        property bool   toggled: false
        signal clicked()

        radius:         height / 2
        color:          toggled ? _t.hudControlActive : _t.hudGlass
        border.width:   1
        border.color:   toggled ? _t.hudControlBorder : _t.hudBorder
        implicitHeight: pillLabel.implicitHeight + _t.spacingUnit * 1.1
        implicitWidth:  pillLabel.implicitWidth + _t.spacingUnit * 2.2

        Text {
            id:             pillLabel
            anchors.centerIn: parent
            text:           glassPill.label
            color:          glassPill.toggled ? _t.brandPrimary : _t.textPrimary
            font.pixelSize: _t.fontCaption
            font.family:    _t.fontFamily
            font.weight:    Font.Medium
            style:          Text.Outline
            styleColor:     _t.textOutline
        }

        MouseArea {
            anchors.fill:   parent
            onClicked:      glassPill.clicked()
        }
    }

    component HudToolButton: GlassPill { }

    component MetricRow: RowLayout {
        property string label: ""
        property string valueText: _t.emptyValue
        property color  valueColor: _root._valueColor(valueText !== _t.emptyValue)
        property string iconType: ""
        property color  iconColor: _t.textSecondary
        property bool   alignRight: false

        Layout.alignment: alignRight ? Qt.AlignRight : Qt.AlignLeft
        spacing: _t.spacingUnit

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
                color: _t.textSecondary
                font.pixelSize: _t.fontCaption
                font.family: _t.fontFamily
                font.weight: Font.Medium
                horizontalAlignment: alignRight ? Text.AlignRight : Text.AlignLeft
            }
            Text {
                text: valueText
                color: valueColor
                font.pixelSize: _t.fontBody
                font.bold: true
                font.family: _t.fontFamilyNumeric
                horizontalAlignment: alignRight ? Text.AlignRight : Text.AlignLeft
                style: Text.Outline
                styleColor: _t.textOutline
            }
        }
        HudIcon {
            visible: iconType !== "" && alignRight
            iconType: parent.iconType
            iconColor: parent.iconColor
        }
    }

    component CompassDial: Rectangle {
        id:             compassRoot
        property real  dialSize: _root._instrumentSize

        width:          dialSize
        height:         dialSize
        radius:         width / 2
        color:          _t.instrumentGlass
        border.width:   1.5
        border.color:   _t.instrumentBorder

        Repeater {
            model: 12
            Rectangle {
                width:  1.5
                height: (index % 3 === 0) ? 8 : 4
                color:  _t.textSecondary
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
            color: _t.textPrimary
            font.bold: true
            font.pixelSize: _t.fontCaption
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 8
        }
        Text {
            text: "S"
            color: _t.textPrimary
            font.bold: true
            font.pixelSize: _t.fontCaption
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
        }
        Text {
            text: "W"
            color: _t.textPrimary
            font.bold: true
            font.pixelSize: _t.fontCaption
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 8
        }
        Text {
            text: "E"
            color: _t.textPrimary
            font.bold: true
            font.pixelSize: _t.fontCaption
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
                                 && _activeVehicle.heading.rawValue !== undefined)
                                ? _activeVehicle.heading.rawValue : 0

            onPaint: {
                var ctx = getContext("2d")
                var cx = width / 2
                var cy = height / 2
                ctx.reset()
                ctx.fillStyle = _t.textPrimary
                ctx.beginPath()
                ctx.moveTo(cx, 2)
                ctx.lineTo(width - 2, height - 2)
                ctx.lineTo(cx, cy)
                ctx.lineTo(2, height - 2)
                ctx.closePath()
                ctx.fill()
                ctx.strokeStyle = _t.textOutline
                ctx.lineWidth = 1.5
                ctx.stroke()
            }

            Connections {
                target: _activeVehicle ? _activeVehicle.heading : null
                function onRawValueChanged() { arrowCanvas.requestPaint() }
            }

            Component.onCompleted: requestPaint()
        }

        Text {
            text:               _root._headingNumber()
            color:              _t.textPrimary
            font.bold:          true
            font.pixelSize:     _t.fontBody
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom:     parent.bottom
            anchors.bottomMargin: compassRoot.height * 0.22
            style: Text.Outline
            styleColor: Qt.rgba(0, 0, 0, 0.4)
        }

        Text {
            text:               _root.getHeadingLetter(
                                      _activeVehicle
                                      ? _activeVehicle.heading.rawValue
                                      : undefined)
            color:              _t.textSecondary
            font.pixelSize:     _t.fontMicro
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom:     parent.bottom
            anchors.bottomMargin: compassRoot.height * 0.12
        }
    }

    // ---- Transparent OSD layer (UniGCS-style) ----
    RowLayout {
        id:                     osdControls
        visible:                osRoot.visible
        anchors.right:          parent.right
        anchors.rightMargin:    _margin
        anchors.top:            parent.top
        anchors.topMargin:      _topChromeInset + _t.spacingUnit
        spacing:                _t.spacingUnit
        z:                      2

        GlassPill {
            label: _cleanMapActive ? qsTr("Standard map") : qsTr("Clean map")
            toggled: _cleanMapActive
            onClicked: _root._applyCleanMap(!_cleanMapActive)
        }
        GlassPill {
            label: _hudExpanded ? qsTr("Collapse") : qsTr("Expand")
            toggled: _hudExpanded
            onClicked: _hudExpanded = !_hudExpanded
        }
    }

    FloatingMetric {
        id:                     topLeftAlt
        visible:                osRoot.visible
        anchors.left:           parent.left
        anchors.leftMargin:     _margin + (parentToolInsets ? parentToolInsets.leftEdgeCenterInset : 0)
        anchors.top:            osdControls.bottom
        anchors.topMargin:      _t.spacingUnit * 2
        z:                      2
        label: qsTr("Altitude")
        valueText: _root._factWithUnit(
            _activeVehicle ? _activeVehicle.altitudeRelative : null, " m")
    }

    FloatingMetric {
        id:                     topRightSpeed
        visible:                osRoot.visible
        anchors.right:          parent.right
        anchors.rightMargin:    _margin
        anchors.top:            osdControls.bottom
        anchors.topMargin:      _t.spacingUnit * 2
        z:                      2
        label: qsTr("Ground Speed")
        valueText: _root._factWithUnit(
            _activeVehicle ? _activeVehicle.groundSpeed : null, " m/s")
    }

    Item {
        id:                     osRoot
        anchors.bottom:         parent.bottom
        anchors.bottomMargin:   _bottomSafe
        anchors.horizontalCenter: parent.horizontalCenter
        width:                  Math.min(osColumn.implicitWidth + _t.spacingUnit * 2, _root.width - _margin * 2)
        height:                 osColumn.implicitHeight
        visible:                !ScreenTools.isMobile
        z:                      1

        ColumnLayout {
            id:                 osColumn
            width:              parent.width
            spacing:            _t.spacingUnit * 1.25

            RowLayout {
                Layout.alignment:       Qt.AlignHCenter
                spacing:                _t.spacingUnit * (_hudExpanded ? 3 : 2)

                FloatingMetric {
                    label: qsTr("Battery")
                    valueText: {
                        var pct = _root._factValue(_battery ? _battery.percentRemaining : null)
                        return pct === _t.emptyValue ? pct : pct + "%"
                    }
                }

                Item {
                    Layout.preferredWidth:  _instrumentSize + 8
                    Layout.preferredHeight: _instrumentSize + 8
                    Layout.alignment:       Qt.AlignVCenter

                    Rectangle {
                        anchors.centerIn:   parent
                        width:            _instrumentSize + 6
                        height:           _instrumentSize + 6
                        radius:           width / 2
                        color:            _t.instrumentGlass
                        border.width:     1.5
                        border.color:     _t.instrumentBorder
                    }
                    QGCAttitudeWidget {
                        anchors.centerIn:   parent
                        size:               _instrumentSize
                        vehicle:            _activeVehicle
                        showHeading:        false
                        opacity:            _hasVehicle ? 1.0 : 0.75
                    }
                }

                CompassDial {
                    Layout.alignment: Qt.AlignVCenter
                }

                FloatingMetric {
                    visible: _hudExpanded
                    label: qsTr("Satellites")
                    valueText: _root._factValue(
                        _activeVehicle ? _activeVehicle.gps.count : null)
                }
            }

            Rectangle {
                visible:            _hudExpanded
                Layout.fillWidth:   true
                Layout.preferredHeight: expandedStrip.implicitHeight + _t.spacingUnit * 2
                radius:             _t.radiusLg
                color:              _t.hudGlassStrong
                border.width:       1
                border.color:       _t.hudBorder

                RowLayout {
                    id:             expandedStrip
                    anchors.centerIn: parent
                    spacing:        _t.spacingUnit * 3

                    ColumnLayout {
                        spacing: _t.spacingUnit * 0.75
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 140

                        MetricRow {
                            alignRight: true
                            label: qsTr("Distance")
                            valueText: _root._factWithUnit(
                                _activeVehicle ? _activeVehicle.distanceToHome : null, " m")
                            iconType: "home"
                        }
                        MetricRow {
                            alignRight: true
                            label: qsTr("Climb Rate")
                            valueText: _root._factWithUnit(
                                _activeVehicle ? _activeVehicle.climbRate : null, " m/s")
                            iconType: "height"
                        }
                        MetricRow {
                            alignRight: true
                            label: qsTr("Flight Time")
                            valueText: _root._factValue(
                                _activeVehicle ? _activeVehicle.flightTime : null)
                            valueColor: _root._valueColor(
                                _activeVehicle && _activeVehicle.flightTime
                                && _activeVehicle.flightTime.rawValue !== undefined)
                            iconType: "clock"
                        }
                        MetricRow {
                            alignRight: true
                            label: qsTr("Air Speed")
                            valueText: _root._factWithUnit(
                                _activeVehicle ? _activeVehicle.airSpeed : null, " m/s")
                            iconType: "speed"
                        }
                    }

                    ColumnLayout {
                        spacing: _t.spacingUnit * 0.75
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 140

                        MetricRow {
                            label: qsTr("Temperature")
                            valueText: {
                                var temp = _root._factValue(_battery ? _battery.temperature : null)
                                return temp === _t.emptyValue ? temp : temp + "°C"
                            }
                            valueColor: {
                                if (!_hasVehicle || !_battery || _battery.temperature.rawValue === undefined) {
                                    return _t.textDisabled
                                }
                                return _t.telemetryAccent
                            }
                            iconType: "temp"
                            iconColor: _t.telemetryAccent
                        }
                        MetricRow {
                            label: qsTr("AMSL")
                            valueText: _root._factWithUnit(
                                _activeVehicle ? _activeVehicle.altitudeAMSL : null, " m")
                            iconType: "mountain"
                        }
                        MetricRow {
                            label: qsTr("Current")
                            valueText: {
                                var a = _root._factValue(_battery ? _battery.current : null)
                                return a === _t.emptyValue ? a : a + " A"
                            }
                            iconType: "battery"
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
    }

    // Legacy id for tool insets
    property alias hudPanel: osRoot

    Rectangle {
        id:                     bottomScrim
        anchors.left:           parent.left
        anchors.right:          parent.right
        anchors.bottom:         parent.bottom
        height:                 osRoot.height + _bottomSafe + _t.spacingUnit * 6
        visible:                osRoot.visible
        z:                      0
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "#00000000" }
            GradientStop { position: 0.65; color: "#33000000" }
            GradientStop { position: 1.0; color: "#88000000" }
        }
    }

    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeTopInset:       parentToolInsets ? parentToolInsets.leftEdgeTopInset : 0
        leftEdgeCenterInset:    parentToolInsets ? parentToolInsets.leftEdgeCenterInset : 0
        leftEdgeBottomInset:    parentToolInsets ? parentToolInsets.leftEdgeBottomInset : 0
        rightEdgeTopInset:      parentToolInsets ? parentToolInsets.rightEdgeTopInset : 0
        rightEdgeCenterInset:   parentToolInsets ? parentToolInsets.rightEdgeCenterInset : 0
        rightEdgeBottomInset:   parentToolInsets ? parentToolInsets.rightEdgeBottomInset : 0
        topEdgeLeftInset:       parentToolInsets ? parentToolInsets.topEdgeLeftInset : 0
        topEdgeCenterInset:     parentToolInsets ? parentToolInsets.topEdgeCenterInset : 0
        topEdgeRightInset:      parentToolInsets ? parentToolInsets.topEdgeRightInset : 0
        bottomEdgeLeftInset:    parentToolInsets ? parentToolInsets.bottomEdgeLeftInset : 0
        bottomEdgeCenterInset:  osRoot.visible
                                    ? osRoot.height + (_bottomSafe * 2)
                                    : (parentToolInsets ? parentToolInsets.bottomEdgeCenterInset : 0)
        bottomEdgeRightInset:   parentToolInsets ? parentToolInsets.bottomEdgeRightInset : 0
    }
}
