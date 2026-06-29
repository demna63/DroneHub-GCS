/****************************************************************************
 * DroneHub GCS — Fly View left tool strip (icon-first, scrollable).
 ****************************************************************************/

import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.Controls

import Custom

Rectangle {
    id:         _root
    color:      Theme.toolbarGlass
    border.width: 1
    border.color: Theme.divider
    width:      ScreenTools.defaultFontPixelWidth * 8
    radius:     Theme.radiusMd

    property alias  model:              repeater.model
    property real   maxHeight
    property alias  title:              titleLabel.text
    property var    fontSize:           ScreenTools.defaultFontPointSize * 0.72

    readonly property real innerPadding: ScreenTools.defaultFontPixelWidth * 0.35

    height:     maxHeight > 0
                    ? Math.min(maxHeight, toolStripColumn.height + innerPadding * 2)
                    : toolStripColumn.height + innerPadding * 2

    property var _dropPanel: dropPanel

    function simulateClick(buttonIndex) {
        buttonIndex = buttonIndex + 1
        var button = toolStripColumn.children[buttonIndex]
        if (button.checkable) {
            button.checked = !button.checked
        }
        button.clicked()
    }

    signal dropped(int index)

    DeadMouseArea {
        anchors.fill: parent
    }

    QGCFlickable {
        id:                 flickable
        anchors.margins:    innerPadding
        anchors.top:        parent.top
        anchors.left:       parent.left
        anchors.right:      parent.right
        height:             parent.height - innerPadding * 2
        contentHeight:      toolStripColumn.height
        flickableDirection: Flickable.VerticalFlick
        clip:               true

        Column {
            id:             toolStripColumn
            width:          flickable.width
            spacing:        ScreenTools.defaultFontPixelWidth * 0.2

            QGCLabel {
                id:                     titleLabel
                width:                  parent.width
                horizontalAlignment:    Text.AlignHCenter
                font.pointSize:         ScreenTools.defaultFontPointSize * 0.7
                font.family:            Theme.fontFamily
                color:                  Theme.textSecondary
                visible:                title != ""
            }

            Repeater {
                id: repeater

                ToolStripHoverButton {
                    width:              toolStripColumn.width
                    height:             width
                    radius:             Theme.radiusSm
                    fontPointSize:      _root.fontSize
                    toolStripAction:    modelData
                    dropPanel:          _dropPanel
                    onDropped: (rowIndex) => _root.dropped(rowIndex)

                    onCheckedChanged: {
                        if (checked) {
                            for (var i = 0; i < repeater.count; i++) {
                                if (i !== index) {
                                    var button = repeater.itemAt(i)
                                    if (button && button.checked) {
                                        button.checked = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ToolStripDropPanel {
        id:         dropPanel
        toolStrip:  _root
    }
}
