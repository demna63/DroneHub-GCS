/****************************************************************************
 * DroneHub GCS — standard dialog shell (toast glass aligned with Theme.qml).
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.ScreenTools

import Custom

Popup {
    id:                 root
    width:  mainWindow.width
    height: mainWindow.height
    parent:             Overlay.overlay
    modal:              true
    focus:              true
    margins:            0

    property string title
    property var    buttons:                Dialog.Ok
    property alias  acceptButtonEnabled:    acceptButton.enabled
    property alias  rejectButtonEnabled:    rejectButton.enabled
    property var    dialogProperties
    property bool   destroyOnClose:         true
    property bool   preventClose:           false

    readonly property real headerMinWidth: titleLable.implicitWidth + rejectButton.width + acceptButton.width + titleRowLayout.spacing * 2

    signal accepted
    signal rejected

    property var    _qgcPal:            QGroundControl.globalPalette
    property real   _frameSize:         ScreenTools.defaultFontPixelWidth
    property real   _contentMargin:     ScreenTools.defaultFontPixelHeight / 2
    property bool   _acceptAllowed:     acceptButton.visible
    property bool   _rejectAllowed:     rejectButton.visible
    property int    _previousValidationErrorCount: 0

    background: QGCMouseArea {
        width:  mainWindow.width
        height: mainWindow.height

        onClicked: {
            if (closePolicy & Popup.CloseOnPressOutside) {
                _reject()
            }
        }
    }

    Component.onCompleted: {
        contentChildren[contentChildren.length - 1].parent = dialogContentParent
    }

    onAboutToShow: {
        _previousValidationErrorCount = globals.validationErrorCount
        setupDialogButtons(buttons)
    }

    onClosed: {
        globals.validationErrorCount = _previousValidationErrorCount
        Qt.inputMethod.hide()
        if (destroyOnClose) {
            root.destroy()
        }
    }

    function _accept() {
        if (_acceptAllowed && mainWindow.allowViewSwitch(_previousValidationErrorCount)) {
            accepted()
            if (preventClose) {
                preventClose = false
            } else {
                close()
            }
        }
    }

    function _reject() {
        if (_rejectAllowed && ((buttons & Dialog.Cancel) || mainWindow.allowViewSwitch(_previousValidationErrorCount))) {
            rejected()
            if (preventClose) {
                preventClose = false
            } else {
                close()
            }
        }
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: parent.enabled }

    function setupDialogButtons(buttons) {
        acceptButton.visible = false
        rejectButton.visible = false
        if (buttons & Dialog.Ok) {
            acceptButton.text = qsTr("Ok")
            acceptButton.visible = true
        } else if (buttons & Dialog.Open) {
            acceptButton.text = qsTr("Open")
            acceptButton.visible = true
        } else if (buttons & Dialog.Save) {
            acceptButton.text = qsTr("Save")
            acceptButton.visible = true
        } else if (buttons & Dialog.Apply) {
            acceptButton.text = qsTr("Apply")
            acceptButton.visible = true
        } else if (buttons & Dialog.Open) {
            acceptButton.text = qsTr("Open")
            acceptButton.visible = true
        } else if (buttons & Dialog.SaveAll) {
            acceptButton.text = qsTr("Save All")
            acceptButton.visible = true
        } else if (buttons & Dialog.Yes) {
            acceptButton.text = qsTr("Yes")
            acceptButton.visible = true
        } else if (buttons & Dialog.YesToAll) {
            acceptButton.text = qsTr("Yes to All")
            acceptButton.visible = true
        } else if (buttons & Dialog.Retry) {
            acceptButton.text = qsTr("Retry")
            acceptButton.visible = true
        } else if (buttons & Dialog.Reset) {
            acceptButton.text = qsTr("Reset")
            acceptButton.visible = true
        } else if (buttons & Dialog.RestoreToDefaults) {
            acceptButton.text = qsTr("Restore to Defaults")
            acceptButton.visible = true
        } else if (buttons & Dialog.Ignore) {
            acceptButton.text = qsTr("Ignore")
            acceptButton.visible = true
        }

        if (buttons & Dialog.Cancel) {
            rejectButton.text = qsTr("Cancel")
            rejectButton.visible = true
        } else if (buttons & Dialog.Close) {
            rejectButton.text = qsTr("Close")
            rejectButton.visible = true
        } else if (buttons & Dialog.No) {
            rejectButton.text = qsTr("No")
            rejectButton.visible = true
        } else if (buttons & Dialog.NoToAll) {
            rejectButton.text = qsTr("No to All")
            rejectButton.visible = true
        } else if (buttons & Dialog.Abort) {
            rejectButton.text = qsTr("Abort")
            rejectButton.visible = true
        }

        closePolicy = Popup.NoAutoClose
        if (buttons & Dialog.Cancel) {
            closePolicy |= Popup.CloseOnEscape
        }
    }

    function disableAcceptButton() {
        acceptButton.enabled = false
    }

    Rectangle {
        x:              mainLayout.x - _contentMargin
        y:              mainLayout.y - _contentMargin
        width:          mainLayout.width + _contentMargin * 2
        height:         mainLayout.height + _contentMargin * 2
        color:          Theme.toastFill
        radius:         Theme.toastRadius
        border.width:   1
        border.color:   Theme.toastBorder
    }

    ColumnLayout {
        id:                 mainLayout
        anchors.centerIn:   parent
        x:          _contentMargin
        y:          _contentMargin
        spacing:    _contentMargin

        RowLayout {
            id:                     titleRowLayout
            Layout.fillWidth:       true
            spacing:                _contentMargin

            QGCLabel {
                id: titleLable
                Layout.fillWidth:   true
                text:               root.title
                font.family:        Theme.fontFamily
                font.pointSize:     ScreenTools.mediumFontPointSize
                verticalAlignment:  Text.AlignVCenter
            }

            QGCButton {
                id:                     rejectButton
                onClicked:              _reject()
                Layout.minimumWidth:    height * 1.5
            }

            QGCButton {
                id:                     acceptButton
                primary:                true
                onClicked:              _accept()
                Layout.minimumWidth:    height * 1.5
            }
        }

        Rectangle {
            Layout.fillWidth:       true
            Layout.preferredWidth:  Math.min(maxAvailableWidth, totalContentWidth)
            Layout.preferredHeight: Math.min(maxAvailableHeight, totalContentHeight)
            color:                  Qt.rgba(0, 0, 0, 0)

            property real maxAvailableWidth:    mainWindow.width - _contentMargin * 4
            property real maxAvailableHeight:   mainWindow.height - titleRowLayout.height - _contentMargin * 5
            property real totalContentWidth:    dialogContentParent.childrenRect.width + _contentMargin * 2
            property real totalContentHeight:   dialogContentParent.childrenRect.height + _contentMargin * 2

            QGCFlickable {
                anchors.margins:    _contentMargin
                anchors.fill:       parent
                contentWidth:       dialogContentParent.childrenRect.width
                contentHeight:      dialogContentParent.childrenRect.height

                Item {
                    id:     dialogContentParent
                    focus:  true

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape && _rejectAllowed) {
                            _reject()
                            event.accepted = true
                        }
                    }
                }
            }
        }
    }
}
