/****************************************************************************
 * DroneHub GCS — Fly View tool strip button (icon-first, glass highlight; 5.1 structure kept).
 ****************************************************************************/

import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls

import Custom

Button {
    id:             control
    objectName:     toolStripAction ? toolStripAction.objectName : ""
    width:          contentLayoutItem.contentWidth + (contentMargins * 2)
    height:         width
    hoverEnabled:   !ScreenTools.isMobile
    enabled:        toolStripAction ? toolStripAction.enabled : true
    visible:        toolStripAction ? toolStripAction.visible : true
    opacity:        enabled ? 1.0 : 0.45
    imageSource:    (toolStripAction && modelData) ? (toolStripAction.showAlternateIcon ? modelData.alternateIconSource : modelData.iconSource) : ""
    text:           toolStripAction ? toolStripAction.text : ""
    checked:        toolStripAction ? toolStripAction.checked : false
    checkable:      toolStripAction ? (toolStripAction.dropPanelComponent || (modelData && modelData.checkable)) : false

    property var    toolStripAction:    undefined
    property var    dropPanel:          undefined
    property alias  radius:             buttonBkRect.radius
    property alias  fontPointSize:      innerText.font.pointSize
    property alias  imageSource:        innerImage.source
    property alias  contentWidth:       innerText.contentWidth

    property bool forceImageScale11: false
    property real imageScale:        forceImageScale11 && (text == "") ? 0.8 : 0.6
    property real contentMargins:    innerText.height * 0.1

    property color _currentContentColor:  (checked || pressed || hovered) ? Theme.textPrimary : Theme.textSecondary
    property color _currentContentColorSecondary:  _currentContentColor

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

    onCheckedChanged: { if (toolStripAction) toolStripAction.checked = checked }

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

        Column {
            anchors.centerIn:   parent
            spacing:            0

            Image {
                id:                         innerImageColorful
                height:                     contentLayoutItem.height * imageScale
                width:                      contentLayoutItem.width  * imageScale
                smooth:                     true
                mipmap:                     true
                fillMode:                   Image.PreserveAspectFit
                antialiasing:               true
                sourceSize.height:          height
                sourceSize.width:           width
                anchors.horizontalCenter:   parent.horizontalCenter
                source:                     control.imageSource
                visible:                    source != "" && !!modelData && modelData.fullColorIcon
            }

            QGCColoredImage {
                id:                         innerImage
                height:                     contentLayoutItem.height * imageScale
                width:                      contentLayoutItem.width  * imageScale
                smooth:                     true
                mipmap:                     true
                color:                      _currentContentColor
                fillMode:                   Image.PreserveAspectFit
                antialiasing:               true
                sourceSize.height:          height
                sourceSize.width:           width
                anchors.horizontalCenter:   parent.horizontalCenter
                visible:                    source != "" && !(modelData && modelData.fullColorIcon)

                QGCColoredImage {
                    id:                         innerImageSecondColor
                    source:                     modelData ? modelData.alternateIconSource : ""
                    height:                     contentLayoutItem.height * imageScale
                    width:                      contentLayoutItem.width  * imageScale
                    smooth:                     true
                    mipmap:                     true
                    color:                      _currentContentColorSecondary
                    fillMode:                   Image.PreserveAspectFit
                    antialiasing:               true
                    sourceSize.height:          height
                    sourceSize.width:           width
                    anchors.horizontalCenter:   parent.horizontalCenter
                    visible:                    source != "" && !!modelData && modelData.biColorIcon
                }
            }

            QGCLabel {
                id:                         innerText
                text:                       control.text
                color:                      _currentContentColor
                anchors.horizontalCenter:   parent.horizontalCenter
                horizontalAlignment:        Text.AlignHCenter
                wrapMode:                   Text.WordWrap
                maximumLineCount:           2
                font.family:                Theme.fontFamily
                font.bold:                  true
                visible:                    !innerImage.visible && !innerImageColorful.visible
            }
        }
    }

    background: Rectangle {
        id:             buttonBkRect
        radius:         Theme.radiusSm
        color:          (control.checked || control.pressed) ? "#30FFFFFF"
                            : ((control.enabled && control.hovered) ? "#15FFFFFF" : "transparent")
        border.width:   (control.checked || control.pressed) ? 1 : 0
        border.color:   "#40FFFFFF"
    }
}
