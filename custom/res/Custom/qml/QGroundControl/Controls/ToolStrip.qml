/****************************************************************************
 * DroneHub GCS — Fly View left tool strip container.
 ****************************************************************************/

import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.Controls

Rectangle {
    id:         _root
    color:      "#990B0E14"
    border.width: 1
    border.color: "#40FFFFFF"
    width:      ScreenTools.defaultFontPixelWidth * 10.5
    height:     Math.min(maxHeight, toolStripColumn.height + (flickable.anchors.margins * 2))
    radius:     12

    property alias  model:              repeater.model
    property real   maxHeight
    property alias  title:              titleLabel.text
    property var    fontSize:           ScreenTools.defaultFontPointSize * 0.85

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
        anchors.margins:    ScreenTools.defaultFontPixelWidth * 0.4
        anchors.top:        parent.top
        anchors.left:       parent.left
        anchors.right:      parent.right
        height:             parent.height - anchors.margins * 2
        contentHeight:      toolStripColumn.height
        flickableDirection: Flickable.VerticalFlick
        clip:               true

        Column {
            id:             toolStripColumn
            anchors.left:   parent.left
            anchors.right:  parent.right
            spacing:        ScreenTools.defaultFontPixelWidth * 0.35

            QGCLabel {
                id:                     titleLabel
                anchors.left:           parent.left
                anchors.right:          parent.right
                horizontalAlignment:    Text.AlignHCenter
                font.pointSize:         ScreenTools.defaultFontPointSize * 0.85
                visible:                title != ""
            }

            Repeater {
                id: repeater

                ToolStripHoverButton {
                    id:                 buttonTemplate
                    anchors.left:       toolStripColumn.left
                    anchors.right:      toolStripColumn.right
                    width:              toolStripColumn.width
                    height:             Math.max(width * 0.92, implicitHeight)
                    radius:             ScreenTools.defaultFontPixelWidth / 2
                    fontPointSize:      _root.fontSize
                    toolStripAction:    modelData
                    dropPanel:          _dropPanel
                    onDropped: (index) => _root.dropped(index)

                    onCheckedChanged: {
                        if (checked) {
                            for (var i=0; i<repeater.count; i++) {
                                if (i != index) {
                                    var button = repeater.itemAt(i)
                                    if (button.checked) {
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
