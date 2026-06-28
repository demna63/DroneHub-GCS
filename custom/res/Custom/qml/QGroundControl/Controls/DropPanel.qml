/****************************************************************************
 * DroneHub GCS — anchored drop panel (toast glass aligned with Theme.qml).
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Palette

import Custom

Popup {
    id:             _root
    padding:        _innerMargin
    leftPadding:    _dropRight ? _innerMargin + _arrowPointWidth : _innerMargin
    rightPadding:   _dropRight ? _innerMargin : _innerMargin + _arrowPointWidth
    modal:          true
    focus:          true
    closePolicy:    Popup.CloseOnEscape | Popup.CloseOnPressOutside
    clip:           false
    dim:            false

    property var  sourceComponent
    property var  clickRect:        Qt.rect(0, 0, 0, 0)
    property var  dropViewPort:     Qt.rect(0, 0, parent.width, parent.height)

    property var  _qgcPal:              QGroundControl.globalPalette
    property real _innerMargin:         ScreenTools.defaultFontPixelWidth * 0.5
    property real _arrowPointWidth:     ScreenTools.defaultFontPixelWidth * 2
    property real _arrowPointPositionY: height / 2
    property bool _dropRight:           true

    onAboutToShow: {
        let xPos = clickRect.x + clickRect.width

        if (xPos + _root.width > dropViewPort.x + dropViewPort.width) {
            _dropRight = false
            xPos = clickRect.x - _root.width
        }

        let yPos = clickRect.y + (clickRect.height / 2)
        yPos -= _root.height / 2

        let originalYPos = yPos
        yPos = Math.max(yPos, dropViewPort.y)
        yPos = Math.min(yPos, dropViewPort.y + dropViewPort.height - _root.height)

        _root.x = xPos
        _root.y = yPos

        _arrowPointPositionY += originalYPos - yPos
    }

    background: Item {
        implicitWidth:  contentItem.implicitWidth + _innerMargin * 2 + _arrowPointWidth
        implicitHeight: contentItem.implicitHeight + _innerMargin * 2

        Rectangle {
            x:      _dropRight ? _arrowPointWidth : 0
            radius: Theme.toastRadius
            width:  parent.implicitWidth - _arrowPointWidth
            height: parent.implicitHeight
            color:  Theme.toastFill
            border.color: Theme.toastBorder
            border.width: 1
        }

        Canvas {
            x:      _dropRight ? 0 : parent.width - _arrowPointWidth
            y:      _arrowPointPositionY - _arrowPointWidth
            width:  _arrowPointWidth
            height: _arrowPointWidth * 2

            onPaint: {
                var context = getContext("2d")
                context.reset()
                context.beginPath()
                context.moveTo(_dropRight ? 0 : _arrowPointWidth, _arrowPointWidth)
                context.lineTo(_dropRight ? _arrowPointWidth : 0, 0)
                context.lineTo(_dropRight ? _arrowPointWidth : 0, _arrowPointWidth * 2)
                context.closePath()
                context.fillStyle = Theme.toastFillHex
                context.fill()

                context.strokeStyle = Theme.toastBorder
                context.lineWidth = 1
                context.beginPath()
                context.moveTo(_dropRight ? 0 : _arrowPointWidth, _arrowPointWidth)
                context.lineTo(_dropRight ? _arrowPointWidth : 0, 0)
                context.moveTo(_dropRight ? 0 : _arrowPointWidth, _arrowPointWidth)
                context.lineTo(_dropRight ? _arrowPointWidth : 0, _arrowPointWidth * 2)
                context.stroke()
            }
        }
    }

    contentItem: SettingsGroupLayout {
        Loader {
            sourceComponent: _root.sourceComponent
        }
    }
}
