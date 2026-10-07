/****************************************************************************
 * DroneHub GCS — Fly View left tool strip (icon-first glass panel; 5.1 structure kept).
 ****************************************************************************/

import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls

import Custom

Rectangle {
    id:         _root
    color:      Theme.toolbarGlass
    border.width: 1
    border.color: Theme.divider
    width:      ScreenTools.defaultFontPixelWidth * 8
    height:     Math.min(maxHeight, toolStripColumn.height + (flickable.anchors.margins * 2))
    radius:     Theme.radiusMd

    property alias  model:              repeater.model
    property real   maxHeight           ///< Maximum height for control, determines whether text is hidden to make control shorter
    property var    fontSize:           ScreenTools.defaultFontPointSize * 0.72

    property var _dropPanel: dropPanel

    function simulateClick(buttonIndex) {
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
        anchors.fill:       parent
        contentHeight:      toolStripColumn.height
        flickableDirection: Flickable.VerticalFlick
        clip:               true

        Column {
            id:             toolStripColumn
            anchors.left:   parent.left
            anchors.right:  parent.right
            spacing:        ScreenTools.defaultFontPixelWidth * 0.25

            Repeater {
                id: repeater

                ToolStripHoverButton {
                    id:                 buttonTemplate
                    anchors.left:       toolStripColumn.left
                    anchors.right:      toolStripColumn.right
                    height:             width
                    radius:             Theme.radiusSm
                    fontPointSize:      _root.fontSize
                    toolStripAction:    modelData
                    dropPanel:          _dropPanel
                    onDropped: (index) => _root.dropped(index)

                    onCheckedChanged: {
                        // We deal with exclusive check state manually since usinug autoExclusive caused all sorts of crazt problems
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
