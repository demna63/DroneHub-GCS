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
import Qt.labs.settings 1.0

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightMap
import QGroundControl.ScreenTools

Item {
    id: _root

    property var parentToolInsets
    property var totalToolInsets:   _toolInsets
    property var mapControl

    Settings {
        id: _flyViewPrefs
        category: "DroneHub/FlyView"
        property bool flyHudExpanded: false
    }

    // Inline tokens — FlyViewCustomLayer compiles into FlightDisplayModule (qmlcache);
    // must not import Custom module (loads before engine import paths are ready).
    readonly property QtObject _t: QtObject {
        readonly property color brandPrimary:       "#0A84FF"
        readonly property color telemetryAccent:    "#64D2FF"
        readonly property color hudGlass:           "#28000000"
        readonly property color hudGlassStrong:     "#D9151820"   // telemetry card over map — readable scrim
        readonly property color hudMetricPlate:     "#C8151820"   // compact HUD metric cells over map
        readonly property color hudBorder:          "#55FFFFFF"
        readonly property color instrumentGlass:    "#18000000"
        readonly property color instrumentBorder:   "#66FFFFFF"
        readonly property color textPrimary:        "#FFFFFF"
        readonly property color textSecondary:      "#D0D8E4"
        readonly property color textDisabled:       "#9AA6B8"
        readonly property color safeOk:             "#30D158"
        readonly property color safeWarn:           "#FF9F0A"
        readonly property color safeCrit:           "#FF453A"
        readonly property color textOutline:        "#CC000000"
        readonly property real  radiusSm:           6
        readonly property real  radiusMd:           12
        readonly property real  radiusLg:           20
        readonly property real  spacingUnit:        8
        readonly property real  instrumentSizeCompact:  100
        readonly property real  instrumentSizeExpanded: 128
        // HUD compact row — mirror Custom/Theme.qml (qmlcache cannot import Custom).
        readonly property real  hudMetricCellWidthEm:       12.5
        readonly property real  hudMetricColumnGapUnits:     1.5
        readonly property real  hudCompactWidthPadUnits:     2.0
        readonly property real  hudExpandedMaxWidthEm:      58
        readonly property int   hudMetricLabelMaxLines:      2
        readonly property real  hudMetricLabelLineHeight:  1.05
        readonly property string fontFamily:        "Noto Sans Georgian"
        readonly property string fontFamilyNumeric: ScreenTools.normalFontFamily
        readonly property real  fontHero:           28
        readonly property real  fontBody:           18
        readonly property real  fontCaption:        13
        readonly property real  fontMicro:          11
        readonly property string emptyValue:        "—"
    }

    property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    property var  _battery:         (_activeVehicle && _activeVehicle.batteries.count > 0)
                                        ? _activeVehicle.batteries.get(0) : null
    property var  _missionController: globals.planMasterControllerFlyView
                                        ? globals.planMasterControllerFlyView.missionController
                                        : null
    property bool _hasVehicle:      _activeVehicle !== null
    property bool _hudExpanded:     _flyViewPrefs.flyHudExpanded
    property real _margin:          ScreenTools.defaultFontPixelHeight
    property real _bottomSafe:      _margin + (Qt.platform.os === "osx" ? _margin * 0.75 : 0)
    property real _topChromeInset:  parentToolInsets
                                        ? Math.max(parentToolInsets.topEdgeLeftInset,
                                                   parentToolInsets.topEdgeCenterInset,
                                                   parentToolInsets.topEdgeRightInset)
                                        : _margin
    property real _metricCellWidth: ScreenTools.defaultFontPixelWidth * _t.hudMetricCellWidthEm
    property real _metricColumnGap: _t.spacingUnit * _t.hudMetricColumnGapUnits
    property real _instrumentSize:  _hudExpanded ? _t.instrumentSizeExpanded : _t.instrumentSizeCompact
    property real _hudCompactWidth: Math.max(
        _metricCellWidth * 4 + _metricColumnGap * 3 + _t.spacingUnit * _t.hudCompactWidthPadUnits,
        _instrumentSize * 2 + _t.spacingUnit * 6 + 12)

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

    function _normalizeHeading(deg) {
        if (deg === undefined || isNaN(deg)) {
            return NaN
        }
        var h = deg % 360
        return h < 0 ? h + 360 : h
    }

    function _headingRounded(fact) {
        if (!fact || fact.rawValue === undefined || isNaN(fact.rawValue)) {
            return NaN
        }
        return Math.round(_normalizeHeading(fact.rawValue))
    }

    function _headingLabel(fact) {
        var deg = _headingRounded(fact)
        return isNaN(deg) ? _t.emptyValue : (deg + "°")
    }

    /// MAVLink attitude yaw — true heading (NED / geographic north), not magnetic.
    function _trueHeadingDeg() {
        return _headingRounded(_activeVehicle ? _activeVehicle.heading : null)
    }

    /// WMM declination via CustomPlugin (PX4 world_magnetic_model — same tables as FC geo_lookup).
    function _declinationDeg() {
        if (!_activeVehicle) {
            return NaN
        }
        var lat = _activeVehicle.gps.lat.rawValue
        var lon = _activeVehicle.gps.lon.rawValue
        if (isNaN(lat) || isNaN(lon)) {
            return NaN
        }
        var dec = QGroundControl.corePlugin.magneticDeclination(lat, lon)
        return (dec === undefined || isNaN(dec)) ? NaN : dec
    }

    /// Magnetic heading = true heading − declination (east-positive WMM convention).
    function _magneticHeadingDeg() {
        var trueH = _trueHeadingDeg()
        var dec = _declinationDeg()
        if (isNaN(trueH)) {
            return NaN
        }
        if (isNaN(dec)) {
            return trueH
        }
        return Math.round(_normalizeHeading(trueH - dec))
    }

    function _magneticHeadingLabel() {
        var deg = _magneticHeadingDeg()
        return isNaN(deg) ? _t.emptyValue : (deg + "°")
    }

    function _trueHeadingLabel() {
        var deg = _trueHeadingDeg()
        return isNaN(deg) ? _t.emptyValue : (deg + "°")
    }

    function _mgrsText() {
        if (!_activeVehicle || _gpsLock() < 2) {
            return _t.emptyValue
        }
        var mgrs = _activeVehicle.gps.mgrs
        if (!mgrs || mgrs.valueString === undefined || mgrs.valueString === "") {
            return _t.emptyValue
        }
        return mgrs.valueString
    }

    function _gpsPositionVisible() {
        return _activeVehicle && _gpsLock() >= 2
    }

    function _coordText(fact, decimals) {
        if (!fact || fact.rawValue === undefined || isNaN(fact.rawValue)) {
            return _t.emptyValue
        }
        return fact.rawValue.toFixed(decimals !== undefined ? decimals : 5) + "°"
    }

    function _hdopText() {
        if (!_activeVehicle || _activeVehicle.gps.hdop.rawValue === undefined
                || isNaN(_activeVehicle.gps.hdop.rawValue)) {
            return _t.emptyValue
        }
        return _activeVehicle.gps.hdop.valueString
    }

    function _batteryVoltageText() {
        var volts = _factValue(_battery ? _battery.voltage : null)
        return volts === _t.emptyValue ? volts : volts + " V"
    }

    function _batteryTimeRemainingText() {
        if (!_battery) {
            return _t.emptyValue
        }
        var label = _factValue(_battery.timeRemainingStr)
        if (label !== _t.emptyValue && label !== "") {
            return label
        }
        return _factValue(_battery.timeRemaining)
    }

    function _windText() {
        if (!_activeVehicle) {
            return _t.emptyValue
        }
        var dir = _headingRounded(_activeVehicle.wind.direction)
        var spd = _factValue(_activeVehicle.wind.speed)
        if (isNaN(dir) && spd === _t.emptyValue) {
            return _t.emptyValue
        }
        if (isNaN(dir)) {
            return _factWithUnit(_activeVehicle.wind.speed, " m/s")
        }
        if (spd === _t.emptyValue) {
            return dir + "°"
        }
        return dir + "° · " + spd + " m/s"
    }

    function _missionActive() {
        return _activeVehicle
                && _activeVehicle.armed
                && _activeVehicle.flightMode === _activeVehicle.missionFlightMode
    }

    function _hasMissionWpTelemetry() {
        if (!_activeVehicle) {
            return false
        }
        var dist = _activeVehicle.distanceToNextWP
        if (dist && dist.rawValue !== undefined && !isNaN(dist.rawValue) && dist.rawValue >= 0) {
            return true
        }
        var hdg = _activeVehicle.headingToNextWP
        return hdg && hdg.rawValue !== undefined && !isNaN(hdg.rawValue)
    }

    function _missionNavVisible() {
        if (!_activeVehicle || !_activeVehicle.armed) {
            return false
        }
        if (_missionActive()) {
            return _missionController ? _missionController.missionItemCount > 0 : true
        }
        return _hasMissionWpTelemetry()
    }

    function _valueColor(hasData) {
        if (!_hasVehicle || !hasData) {
            return _t.textDisabled
        }
        return _t.textPrimary
    }

    function _batteryPercent() {
        if (!_battery || _battery.percentRemaining.rawValue === undefined
                || isNaN(_battery.percentRemaining.rawValue)) {
            return NaN
        }
        return _battery.percentRemaining.rawValue
    }

    function _batteryColor() {
        var pct = _batteryPercent()
        if (!_hasVehicle || isNaN(pct)) {
            return _t.textDisabled
        }
        if (_battery.chargeState && !isNaN(_battery.chargeState.rawValue)) {
            var cs = _battery.chargeState.rawValue
            if (cs === 3) {
                return _t.safeWarn
            }
            if (cs >= 4) {
                return _t.safeCrit
            }
        }
        if (pct > 50) {
            return _t.safeOk
        }
        if (pct > 25) {
            return _t.safeWarn
        }
        return _t.safeCrit
    }

    function _gpsSatCount() {
        if (!_activeVehicle || _activeVehicle.gps.count.rawValue === undefined
                || isNaN(_activeVehicle.gps.count.rawValue)) {
            return NaN
        }
        return _activeVehicle.gps.count.rawValue
    }

    function _gpsLock() {
        if (!_activeVehicle || _activeVehicle.gps.lock.rawValue === undefined) {
            return 0
        }
        return _activeVehicle.gps.lock.rawValue
    }

    function _gpsColor() {
        if (!_hasVehicle) {
            return _t.textDisabled
        }
        var lock = _gpsLock()
        var count = _gpsSatCount()
        if (lock <= 1 || (!isNaN(count) && count < 4)) {
            return _t.safeCrit
        }
        if (lock === 2 || (!isNaN(count) && count < 8)) {
            return _t.safeWarn
        }
        if (_activeVehicle.gps.hdop
                && !isNaN(_activeVehicle.gps.hdop.rawValue)
                && _activeVehicle.gps.hdop.rawValue > 2.0) {
            return _t.safeWarn
        }
        return _t.safeOk
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
        property color  valueColor: valueText === _t.emptyValue ? _t.textDisabled : _t.textPrimary
        property real   valueSize: _root._hudExpanded ? _t.fontBody + 6 : _t.fontBody + 4
        property real   cellWidth: _root._metricCellWidth
        property bool   togglesExpand: false

        // Fixed cell width — every metric plate is identical regardless of content
        // length, so the compact row reads as one uniform unit in both HUD states.
        implicitWidth: cellWidth
        implicitHeight: metricCol.implicitHeight + _t.spacingUnit * 1.25

        Rectangle {
            anchors.fill: metricCol
            anchors.margins: -_t.spacingUnit * 0.6
            radius: _t.radiusSm
            color: togglesExpand && metricMouse.containsMouse
                    ? Qt.rgba(1, 1, 1, 0.10) : _t.hudMetricPlate
            z: -1
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        ColumnLayout {
            id: metricCol
            width: parent.width
            spacing: _t.spacingUnit * 0.35

            Text {
                text: label
                color: _t.textSecondary
                font.pixelSize: _t.fontCaption
                font.family: _t.fontFamily
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
                // Always reserve two label lines so 1-line and 2-line labels
                // produce identical cell heights (uniform plates across the row).
                Layout.preferredHeight: _t.fontCaption * 2 * _t.hudMetricLabelLineHeight
                wrapMode: Text.WordWrap
                maximumLineCount: _t.hudMetricLabelMaxLines
                lineHeight: _t.hudMetricLabelLineHeight
            }
            Text {
                text: valueText
                color: valueColor
                font.pixelSize: valueSize
                font.bold: true
                font.family: _t.fontFamilyNumeric
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                style: Text.Outline
                styleColor: _t.textOutline
            }
        }

        MouseArea {
            id:                 metricMouse
            anchors.fill:       parent
            enabled:            togglesExpand
            hoverEnabled:       togglesExpand
            cursorShape:        togglesExpand ? Qt.PointingHandCursor : Qt.ArrowCursor
            preventStealing:    true
            onClicked:          _flyViewPrefs.flyHudExpanded = !_flyViewPrefs.flyHudExpanded
        }
    }

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

    // Shared label-column width so every GPS value lines up at the same x.
    readonly property real _gpsLabelColWidth: ScreenTools.defaultFontPixelWidth * 5.5

    component GpsDataRow: RowLayout {
        property string label: ""
        property string valueText: _t.emptyValue
        property color  valueColor: _t.telemetryAccent

        Layout.fillWidth: true
        spacing: _t.spacingUnit

        Text {
            text: label
            color: _t.textSecondary
            font.pixelSize: _t.fontCaption
            font.family: _t.fontFamily
            font.weight: Font.Medium
            Layout.preferredWidth: _root._gpsLabelColWidth
        }
        Text {
            text: valueText
            color: valueColor
            font.pixelSize: _t.fontBody
            font.bold: true
            font.family: _t.fontFamilyNumeric
            horizontalAlignment: Text.AlignLeft
            elide: Text.ElideRight
            style: Text.Outline
            styleColor: _t.textOutline
        }
        Item { Layout.fillWidth: true }   // absorb slack — keep label+value grouped left
    }

    component HudSectionLabel: Text {
        property string title: ""

        text: title
        color: _t.textSecondary
        font.pixelSize: _t.fontMicro
        font.family: _t.fontFamily
        font.weight: Font.DemiBold
        font.letterSpacing: 0.4
        opacity: 0.92
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        bottomPadding: _t.spacingUnit * 0.35
    }

    component CompassDial: Rectangle {
        id:             compassRoot
        property real  dialSize: _root._instrumentSize

        // implicit + Layout sizing so the RowLayout gives the compass the SAME
        // diameter as the attitude wrapper (which is sized via Layout.preferredWidth).
        implicitWidth:          dialSize
        implicitHeight:         dialSize
        Layout.preferredWidth:  dialSize
        Layout.preferredHeight: dialSize
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
            rotation:           !isNaN(_root._magneticHeadingDeg())
                                ? _root._magneticHeadingDeg() : 0

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
            Connections {
                target: _activeVehicle ? _activeVehicle.gps.lat : null
                function onRawValueChanged() { arrowCanvas.requestPaint() }
            }
            Connections {
                target: _activeVehicle ? _activeVehicle.gps.lon : null
                function onRawValueChanged() { arrowCanvas.requestPaint() }
            }

            Component.onCompleted: requestPaint()
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom:           parent.bottom
            anchors.bottomMargin:       compassRoot.height * 0.10
            spacing:                    1

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:               qsTr("Mag") + " " + _root._magneticHeadingLabel()
                color:              _t.textPrimary
                font.bold:          true
                font.pixelSize:     _t.fontCaption
                font.family:        _t.fontFamilyNumeric
                style:              Text.Outline
                styleColor:         _t.textOutline
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:               qsTr("True") + " " + _root._trueHeadingLabel()
                color:              _t.telemetryAccent
                font.bold:          true
                font.pixelSize:     _t.fontCaption
                font.family:        _t.fontFamilyNumeric
                style:              Text.Outline
                styleColor:         _t.textOutline
            }
        }
    }

    // Tap outside HUD to collapse expanded details.
    MouseArea {
        anchors.fill:   parent
        visible:        _hudExpanded && osRoot.visible
        z:              QGroundControl.zOrderWidgets + 1
        onClicked:      _flyViewPrefs.flyHudExpanded = false
    }

    // ---- Central HUD panel (screenshot reference layout) ----
    Item {
        id:                     osRoot
        anchors.bottom:         parent.bottom
        anchors.bottomMargin:   _bottomSafe
        anchors.horizontalCenter: parent.horizontalCenter
        width:                  _hudExpanded
                                    ? Math.min(_root.width - _margin * 3,
                                               ScreenTools.defaultFontPixelWidth * _t.hudExpandedMaxWidthEm)
                                    : Math.min(_hudCompactWidth, _root.width - _margin * 2)
        height:                 osColumn.implicitHeight
        visible:                !ScreenTools.isMobile
        z:                      QGroundControl.zOrderWidgets + 2

        ColumnLayout {
            id:                 osColumn
            width:              parent.width
            spacing:            _t.spacingUnit

            RowLayout {
                Layout.alignment:       Qt.AlignHCenter
                spacing:                _t.spacingUnit * 2

                Item {
                    // Same outer diameter + glass ring as CompassDial so the two
                    // instruments read as a matched pair.
                    Layout.preferredWidth:  _instrumentSize
                    Layout.preferredHeight: _instrumentSize
                    Layout.alignment:       Qt.AlignVCenter

                    Rectangle {
                        anchors.fill:       parent
                        radius:             width / 2
                        color:              _t.instrumentGlass
                        border.width:       1.5
                        border.color:       _t.instrumentBorder
                    }
                    QGCAttitudeWidget {
                        anchors.centerIn:   parent
                        size:               _instrumentSize - 4   // inset so the glass ring shows (matches compass)
                        vehicle:            _activeVehicle
                        showHeading:        false
                        opacity:            _hasVehicle ? 1.0 : 0.75
                    }
                }

                CompassDial {
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            GridLayout {
                Layout.alignment:   Qt.AlignHCenter   // keep the row compact + centered (same size in both HUD states)
                Layout.topMargin:   _t.spacingUnit   // clear the compass Mag/True readout above
                columns:            4
                columnSpacing:      _metricColumnGap
                rowSpacing:         0

                FloatingMetric {
                    Layout.preferredWidth:   _metricCellWidth
                    Layout.alignment:        Qt.AlignVCenter
                    togglesExpand:          true
                    label:                  qsTr("Altitude")
                    valueText:              _root._factWithUnit(
                        _activeVehicle ? _activeVehicle.altitudeRelative : null, " m")
                }
                FloatingMetric {
                    Layout.preferredWidth:   _metricCellWidth
                    Layout.alignment:        Qt.AlignVCenter
                    togglesExpand:          true
                    label:                  qsTr("Speed")
                    valueText:              _root._factWithUnit(
                        _activeVehicle ? _activeVehicle.groundSpeed : null, " m/s")
                }
                FloatingMetric {
                    Layout.preferredWidth:   _metricCellWidth
                    Layout.alignment:        Qt.AlignVCenter
                    togglesExpand:          true
                    label:                  qsTr("Battery")
                    valueText: {
                        var pct = _root._factValue(_battery ? _battery.percentRemaining : null)
                        return pct === _t.emptyValue ? pct : pct + "%"
                    }
                    valueColor:             _root._batteryColor()
                }
                FloatingMetric {
                    Layout.preferredWidth:   _metricCellWidth
                    Layout.alignment:        Qt.AlignVCenter
                    togglesExpand:          true
                    label:                  qsTr("Satellites")
                    valueText:              _root._factValue(
                        _activeVehicle ? _activeVehicle.gps.count : null)
                    valueColor:             _root._gpsColor()
                }
            }

            Rectangle {
                visible:                _hudExpanded
                Layout.fillWidth:       true
                radius:                 _t.radiusLg
                color:                  _t.hudGlassStrong
                border.width:           1
                border.color:           _t.hudBorder
                implicitHeight:         expandedBody.implicitHeight + _t.spacingUnit * 2
                Layout.preferredHeight: implicitHeight

                ColumnLayout {
                    id:                 expandedBody
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    anchors.top:        parent.top
                    anchors.margins:    _t.spacingUnit
                    spacing:            _t.spacingUnit

                    RowLayout {
                        Layout.alignment:   Qt.AlignHCenter
                        spacing:            _t.spacingUnit * 2
                        visible:            _root._missionNavVisible()

                        FloatingMetric {
                            Layout.preferredWidth:  _metricCellWidth
                            label:                  qsTr("WP Distance")
                            valueText:              _root._factWithUnit(
                                _activeVehicle ? _activeVehicle.distanceToNextWP : null, " m")
                        }
                        FloatingMetric {
                            Layout.preferredWidth:  _metricCellWidth
                            label:                  qsTr("WP Heading")
                            valueText:              _root._headingLabel(
                                _activeVehicle ? _activeVehicle.headingToNextWP : null)
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth:   true
                        spacing:            _t.spacingUnit * 0.4
                        visible:            _root._gpsPositionVisible()

                        GpsDataRow {
                            visible:    _root._mgrsText() !== _t.emptyValue
                            label:      qsTr("MGRS")
                            valueText:  _root._mgrsText()
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing:        _t.spacingUnit

                            // Lat group (left half) — label column + value grouped together.
                            RowLayout {
                                Layout.fillWidth:       true
                                Layout.preferredWidth:  1
                                spacing:                _t.spacingUnit
                                Text {
                                    text: qsTr("Lat")
                                    color: _t.textSecondary
                                    font.pixelSize: _t.fontCaption
                                    font.family: _t.fontFamily
                                    font.weight: Font.Medium
                                    Layout.preferredWidth: _root._gpsLabelColWidth
                                }
                                Text {
                                    text: _root._coordText(
                                        _activeVehicle ? _activeVehicle.gps.lat : null, 5)
                                    color: _t.telemetryAccent
                                    font.pixelSize: _t.fontBody
                                    font.bold: true
                                    font.family: _t.fontFamilyNumeric
                                    horizontalAlignment: Text.AlignLeft
                                    style: Text.Outline
                                    styleColor: _t.textOutline
                                }
                                Item { Layout.fillWidth: true }
                            }

                            // Lon group (right half).
                            RowLayout {
                                Layout.fillWidth:       true
                                Layout.preferredWidth:  1
                                spacing:                _t.spacingUnit
                                Text {
                                    text: qsTr("Lon")
                                    color: _t.textSecondary
                                    font.pixelSize: _t.fontCaption
                                    font.family: _t.fontFamily
                                    font.weight: Font.Medium
                                    Layout.preferredWidth: _root._gpsLabelColWidth
                                }
                                Text {
                                    text: _root._coordText(
                                        _activeVehicle ? _activeVehicle.gps.lon : null, 5)
                                    color: _t.telemetryAccent
                                    font.pixelSize: _t.fontBody
                                    font.bold: true
                                    font.family: _t.fontFamilyNumeric
                                    horizontalAlignment: Text.AlignLeft
                                    style: Text.Outline
                                    styleColor: _t.textOutline
                                }
                                Item { Layout.fillWidth: true }
                            }
                        }
                        GpsDataRow {
                            label:      qsTr("HDOP")
                            valueText:  _root._hdopText()
                            valueColor: _root._gpsColor()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth:   true
                        spacing:            _t.spacingUnit * 2

                        ColumnLayout {
                            spacing:            _t.spacingUnit * 0.55
                            Layout.fillWidth:   true
                            Layout.preferredWidth: parent.width * 0.46

                            HudSectionLabel {
                                title: qsTr("Flight & Navigation")
                            }

                            MetricRow {
                                Layout.fillWidth: true
                                label:          qsTr("Distance")
                                valueText:      _root._factWithUnit(
                                    _activeVehicle ? _activeVehicle.distanceToHome : null, " m")
                                iconType:       "home"
                            }
                            MetricRow {
                                Layout.fillWidth: true
                                label:          qsTr("AMSL")
                                valueText:      _root._factWithUnit(
                                    _activeVehicle ? _activeVehicle.altitudeAMSL : null, " m")
                                iconType:       "mountain"
                            }
                            MetricRow {
                                Layout.fillWidth: true
                                label:          qsTr("Climb Rate")
                                valueText:      _root._factWithUnit(
                                    _activeVehicle ? _activeVehicle.climbRate : null, " m/s")
                                iconType:       "height"
                            }
                            MetricRow {
                                Layout.fillWidth: true
                                label:          qsTr("Air Speed")
                                valueText:      _root._factWithUnit(
                                    _activeVehicle ? _activeVehicle.airSpeed : null, " m/s")
                                iconType:       "speed"
                            }
                            MetricRow {
                                Layout.fillWidth: true
                                label:          qsTr("Flight Time")
                                valueText:      _root._factValue(
                                    _activeVehicle ? _activeVehicle.flightTime : null)
                                valueColor:     _root._valueColor(
                                    _activeVehicle && _activeVehicle.flightTime
                                    && _activeVehicle.flightTime.rawValue !== undefined)
                                iconType:       "clock"
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth:  1
                            Layout.fillHeight:      true
                            Layout.topMargin:       _t.spacingUnit * 2.5
                            Layout.bottomMargin:    _t.spacingUnit * 0.5
                            color:                  Qt.rgba(1, 1, 1, 0.14)
                        }

                        ColumnLayout {
                            spacing:            _t.spacingUnit * 0.55
                            Layout.fillWidth:   true
                            Layout.preferredWidth: parent.width * 0.46

                            HudSectionLabel {
                                title: qsTr("Power & Environment")
                            }

                            MetricRow {
                                Layout.fillWidth: true
                                label:          qsTr("Voltage")
                                valueText:      _root._batteryVoltageText()
                                valueColor:     _root._batteryColor()
                                iconType:       "battery"
                            }
                            MetricRow {
                                Layout.fillWidth: true
                                label:          qsTr("Current")
                                valueText: {
                                    var a = _root._factValue(_battery ? _battery.current : null)
                                    return a === _t.emptyValue ? a : a + " A"
                                }
                                iconType:       "battery"
                            }
                            MetricRow {
                                Layout.fillWidth: true
                                label:          qsTr("Time Remaining")
                                valueText:      _root._batteryTimeRemainingText()
                                valueColor:     _root._batteryColor()
                                iconType:       "clock"
                            }
                            MetricRow {
                                Layout.fillWidth: true
                                label:          qsTr("Temperature")
                                valueText: {
                                    var temp = _root._factValue(_battery ? _battery.temperature : null)
                                    return temp === _t.emptyValue ? temp : temp + "°C"
                                }
                                valueColor: {
                                    if (!_hasVehicle || !_battery
                                            || _battery.temperature.rawValue === undefined) {
                                        return _t.textDisabled
                                    }
                                    return _t.telemetryAccent
                                }
                                iconType:       "temp"
                                iconColor:      _t.telemetryAccent
                            }
                            MetricRow {
                                Layout.fillWidth: true
                                label:          qsTr("Wind")
                                valueText:      _root._windText()
                                valueColor:     _root._valueColor(
                                    _root._windText() !== _t.emptyValue)
                                iconType:       "radar"
                            }
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
        anchors.horizontalCenter: osRoot.horizontalCenter
        anchors.bottom:         parent.bottom
        width:                  osRoot.width + _t.spacingUnit * 8
        height:                 osRoot.height + _bottomSafe + _t.spacingUnit * 4
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
