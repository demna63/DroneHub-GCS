/****************************************************************************
 * DroneHub GCS — Plan View toolbar mission stats strip.
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.Palette
import QGroundControl.UTMSP

import Custom

Item {
    width: missionStats.width + _margins

    property var    planMasterController

    property var    _planMasterController:      planMasterController
    property var    _currentMissionItem:        _planMasterController.missionController.currentPlanViewItem

    property var    missionItems:               _controllerValid ? _planMasterController.missionController.visualItems : undefined
    property real   missionPlannedDistance:     _controllerValid ? _planMasterController.missionController.missionPlannedDistance : NaN
    property real   missionTime:                _controllerValid ? _planMasterController.missionController.missionTime : 0
    property real   missionMaxTelemetry:        _controllerValid ? _planMasterController.missionController.missionMaxTelemetry : NaN
    property bool   missionDirty:               _controllerValid ? _planMasterController.missionController.dirty : false

    property bool   _controllerValid:           _planMasterController !== undefined && _planMasterController !== null
    property bool   _controllerOffline:         _controllerValid ? _planMasterController.offline : true
    property var    _controllerDirty:           _controllerValid ? _planMasterController.dirty : false
    property var    _controllerSyncInProgress:  _controllerValid ? _planMasterController.syncInProgress : false

    property bool   _currentMissionItemValid:   _currentMissionItem && _currentMissionItem !== undefined && _currentMissionItem !== null
    property bool   _curreItemIsFlyThrough:     _currentMissionItemValid && _currentMissionItem.specifiesCoordinate && !_currentMissionItem.isStandaloneCoordinate
    property bool   _currentItemIsVTOLTakeoff:  _currentMissionItemValid && _currentMissionItem.command == 84
    property bool   _missionValid:              missionItems !== undefined

    property real   _dataFontSize:              ScreenTools.defaultFontPointSize
    property real   _sectionFontSize:           ScreenTools.defaultFontPointSize
    property real   _largeValueWidth:           ScreenTools.defaultFontPixelWidth * 8
    property real   _mediumValueWidth:          ScreenTools.defaultFontPixelWidth * 4
    property real   _smallValueWidth:           ScreenTools.defaultFontPixelWidth * 3
    property real   _labelToValueSpacing:       ScreenTools.defaultFontPixelWidth
    property real   _rowSpacing:                ScreenTools.isMobile ? 2 : 1
    property real   _distance:                  _currentMissionItemValid ? _currentMissionItem.distance : NaN
    property real   _altDifference:             _currentMissionItemValid ? _currentMissionItem.altDifference : NaN
    property real   _azimuth:                   _currentMissionItemValid ? _currentMissionItem.azimuth : NaN
    property real   _heading:                   _currentMissionItemValid ? _currentMissionItem.missionVehicleYaw : NaN
    property real   _missionPlannedDistance:    _missionValid ? missionPlannedDistance : NaN
    property real   _missionMaxTelemetry:       _missionValid ? missionMaxTelemetry : NaN
    property real   _missionTime:               _missionValid ? missionTime : 0
    property int    _batteryChangePoint:        _controllerValid ? _planMasterController.missionController.batteryChangePoint : -1
    property int    _batteriesRequired:         _controllerValid ? _planMasterController.missionController.batteriesRequired : -1
    property bool   _batteryInfoAvailable:      _batteryChangePoint >= 0 || _batteriesRequired >= 0
    property real   _gradient:                  _currentMissionItemValid && _currentMissionItem.distance > 0 ?
                                                    (_currentItemIsVTOLTakeoff ?
                                                         0 :
                                                         (Math.atan(_currentMissionItem.altDifference / _currentMissionItem.distance) * (180.0/Math.PI)))
                                                  : NaN

    property string _distanceText:                  isNaN(_distance) ?                  "-.-" : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_distance).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
    property string _altDifferenceText:             isNaN(_altDifference) ?             "-.-" : QGroundControl.unitsConversion.metersToAppSettingsVerticalDistanceUnits(_altDifference).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString
    property string _gradientText:                  isNaN(_gradient) ?                  "-.-" : _gradient.toFixed(0) + qsTr(" deg")
    property string _azimuthText:                   isNaN(_azimuth) ?                   "-.-" : Math.round(_azimuth) % 360
    property string _headingText:                   isNaN(_azimuth) ?                   "-.-" : Math.round(_heading) % 360
    property string _missionPlannedDistanceText:    isNaN(_missionPlannedDistance) ?    "-.-" : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionPlannedDistance).toFixed(0) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
    property string _missionMaxTelemetryText:       isNaN(_missionMaxTelemetry) ?       "-.-" : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionMaxTelemetry).toFixed(0) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
    property string _batteryChangePointText:        _batteryChangePoint < 0 ?           qsTr("N/A") : _batteryChangePoint
    property string _batteriesRequiredText:         _batteriesRequired < 0 ?            qsTr("N/A") : _batteriesRequired

    readonly property real _margins: ScreenTools.defaultFontPixelWidth

    property bool   _utmspEnabled:                       QGroundControl.utmspSupported

    function getMissionTime() {
        if (!_missionTime) {
            return "00:00:00"
        }
        var t = new Date(2021, 0, 0, 0, 0, Number(_missionTime))
        var days = Qt.formatDateTime(t, 'dd')
        var complete

        if (days == 31) {
            days = '0'
            complete = Qt.formatTime(t, 'hh:mm:ss')
        } else {
            complete = days + " days " + Qt.formatTime(t, 'hh:mm:ss')
        }
        return complete
    }

    component StatLabel: QGCLabel {
        font.pointSize: _dataFontSize
        font.family:    Theme.fontFamily
        color:          Theme.textSecondary
    }

    component StatValue: QGCLabel {
        font.pointSize: _dataFontSize
        font.family:    Theme.fontFamily
        color:          Theme.textPrimary
    }

    component SectionTitle: QGCLabel {
        font.pointSize: _sectionFontSize
        font.family:    Theme.fontFamily
        font.weight:    Font.DemiBold
        color:          Theme.textSecondary
    }

    RowLayout {
        id:                     missionStats
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.leftMargin:     _margins
        anchors.left:           parent.left
        spacing:                ScreenTools.defaultFontPixelWidth * 2

        QGCButton {
            id:          uploadButton
            text:        _controllerDirty ? qsTr("Upload Required") : qsTr("Upload")
            enabled:     _utmspEnabled ? !_controllerSyncInProgress && UTMSPStateStorage.enableMissionUploadButton : !_controllerSyncInProgress
            visible:     !_controllerOffline && !_controllerSyncInProgress
            primary:     _controllerDirty
            onClicked: {
                if (_utmspEnabled) {
                    QGroundControl.utmspManager.utmspVehicle.triggerActivationStatusBar(true);
                    UTMSPStateStorage.removeFlightPlanState = true
                    UTMSPStateStorage.indicatorDisplayStatus = true
                }
                _planMasterController.upload();
            }

            PropertyAnimation on opacity {
                easing.type:    Easing.OutQuart
                from:           0.5
                to:             1
                loops:          Animation.Infinite
                running:        _controllerDirty && !_controllerSyncInProgress
                alwaysRunToEnd: true
                duration:       2000
            }
        }

        GridLayout {
            columns:                8
            rowSpacing:             _rowSpacing
            columnSpacing:          _labelToValueSpacing

            SectionTitle {
                text:               qsTr("Selected Waypoint")
                Layout.columnSpan:  8
            }

            StatLabel { text: qsTr("Alt diff:") }
            StatValue {
                text:                   _altDifferenceText
                Layout.minimumWidth:    _mediumValueWidth
            }

            Item { width: 1; height: 1 }

            StatLabel { text: qsTr("Azimuth:") }
            StatValue {
                text:                   _azimuthText
                Layout.minimumWidth:    _smallValueWidth
            }

            Item { width: 1; height: 1 }

            StatLabel { text: qsTr("Dist prev WP:") }
            StatValue {
                text:                   _distanceText
                Layout.minimumWidth:    _largeValueWidth
            }

            StatLabel { text: qsTr("Gradient:") }
            StatValue {
                text:                   _gradientText
                Layout.minimumWidth:    _mediumValueWidth
            }

            Item { width: 1; height: 1 }

            StatLabel { text: qsTr("Heading:") }
            StatValue {
                text:                   _headingText
                Layout.minimumWidth:    _smallValueWidth
            }
        }

        GridLayout {
            columns:                5
            rowSpacing:             _rowSpacing
            columnSpacing:          _labelToValueSpacing

            SectionTitle {
                text:               qsTr("Total Mission")
                Layout.columnSpan:  5
            }

            StatLabel { text: qsTr("Distance:") }
            StatValue {
                text:                   _missionPlannedDistanceText
                Layout.minimumWidth:    _largeValueWidth
            }

            Item { width: 1; height: 1 }

            StatLabel { text: qsTr("Max telem dist:") }
            StatValue {
                text:                   _missionMaxTelemetryText
                Layout.minimumWidth:    _largeValueWidth
            }

            StatLabel { text: qsTr("Time:") }
            StatValue {
                text:                   getMissionTime()
                Layout.minimumWidth:    _largeValueWidth
            }
        }

        GridLayout {
            columns:                3
            rowSpacing:             _rowSpacing
            columnSpacing:          _labelToValueSpacing
            visible:                _batteryInfoAvailable

            SectionTitle {
                text:               qsTr("Battery")
                Layout.columnSpan:  3
            }

            StatLabel { text: qsTr("Batteries required:") }
            StatValue {
                text:                   _batteriesRequiredText
                Layout.minimumWidth:    _mediumValueWidth
            }
        }
    }
}
