/****************************************************************************
 * DroneHub GCS — tool strip button (square icon-first; label in tooltip).
 ****************************************************************************/

import QtQuick
import QtQuick.Controls

import QGroundControl.ScreenTools
import QGroundControl.Palette

import Custom

Button {
    id:             control
    hoverEnabled:   !ScreenTools.isMobile
    enabled:        toolStripAction.enabled
    visible:        toolStripAction.visible
    opacity:        enabled ? 1.0 : 0.45
    text:           toolStripAction.text
    checked:        toolStripAction.checked
    checkable:      toolStripAction.dropPanelComponent || toolStripAction.checkable

    property var    toolStripAction:    undefined
    property var    dropPanel:          undefined
    property alias  radius:             buttonBkRect.radius
    property alias  fontPointSize:      innerText.font.pointSize

    property bool forceImageScale11: false
    property string _resolvedIconSource: {
        if (!toolStripAction) {
            return ""
        }
        return toolStripAction.showAlternateIcon
                ? toolStripAction.alternateIconSource
                : toolStripAction.iconSource
    }
    property bool _hasIcon:            _resolvedIconSource !== ""
    property bool _fullColorIcon:      toolStripAction ? toolStripAction.fullColorIcon : false
    property bool _biColorIcon:        toolStripAction ? toolStripAction.biColorIcon : false
    property real imageScale:          _hasIcon ? 0.58 : 0.72
    property real contentMargins:      ScreenTools.defaultFontPixelHeight * 0.12

    property color _currentContentColor: (checked || pressed || hovered)
                                         ? Theme.textPrimary
                                         : Theme.textSecondary
    property color _currentContentColorSecondary: _currentContentColor

    signal dropped(int index)

    ToolTip.visible: hovered && control.text !== ""
    ToolTip.text: control.text
    ToolTip.delay: 400

    // Icon-only buttons carry no visible label — expose name/role to assistive tech.
    Accessible.role:        Accessible.Button
    Accessible.name:        control.text
    Accessible.description: control.text
    Accessible.checkable:   control.checkable
    Accessible.checked:     control.checked
    Accessible.onPressAction: control.clicked()

    onCheckedChanged: toolStripAction.checked = checked

    onClicked: {
        if (mainWindow.allowViewSwitch()) {
            dropPanel.hide()
            if (!toolStripAction.dropPanelComponent) {
                toolStripAction.triggered(this)
            } else if (checked) {
                var panelEdgeTopPoint = mapToItem(_root, width, 0)
                dropPanel.show(panelEdgeTopPoint, toolStripAction.dropPanelComponent, this)
                checked = true
                control.dropped(index)
            }
        } else if (checkable) {
            checked = !checked
        }
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: control.enabled }

    contentItem: Item {
        id:                 contentLayoutItem
        anchors.fill:       parent
        anchors.margins:    contentMargins

        Image {
            id:                         innerImageColorful
            anchors.centerIn:           parent
            height:                     parent.height * imageScale
            width:                      height
            smooth:                     true
            mipmap:                     true
            fillMode:                   Image.PreserveAspectFit
            source:                     control._resolvedIconSource
            visible:                    _hasIcon && _fullColorIcon
        }

        QGCColoredImage {
            id:                         innerImage
            anchors.centerIn:           parent
            height:                     parent.height * imageScale
            width:                      height
            smooth:                     true
            mipmap:                     true
            color:                      control._currentContentColor
            fillMode:                   Image.PreserveAspectFit
            source:                     control._resolvedIconSource
            visible:                    _hasIcon && !_fullColorIcon

            QGCColoredImage {
                anchors.centerIn:           parent
                height:                     parent.height
                width:                      parent.width
                color:                      control._currentContentColorSecondary
                fillMode:                   Image.PreserveAspectFit
                source:                     toolStripAction ? toolStripAction.alternateIconSource : ""
                visible:                    _biColorIcon
            }
        }

        QGCLabel {
            id:                         innerText
            anchors.centerIn:           parent
            width:                      parent.width
            text:                       control.text
            color:                      control._currentContentColor
            horizontalAlignment:        Text.AlignHCenter
            wrapMode:                   Text.WordWrap
            maximumLineCount:           2
            font.pointSize:             control.fontPointSize
            font.family:                Theme.fontFamily
            font.bold:                  true
            visible:                    !_hasIcon
        }
    }

    background: Rectangle {
        id:             buttonBkRect
        radius:         Theme.radiusSm
        color:          (control.checked || control.pressed) ? "#30FFFFFF"
                            : ((control.enabled && control.hovered) ? "#15FFFFFF" : "transparent")
        border.width:   (control.checked || control.pressed) ? 1 : 0
        border.color:   "#40FFFFFF"
        anchors.fill:   parent
    }
}
