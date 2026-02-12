import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts
import GenyConnect 1.0

T.Button {
    id: control

    property var menu
    property string glyph: ""
    property string glyphFallback: ""

    hoverEnabled: true
    padding: 6

    contentItem: RowLayout {
        spacing: 6
        Text {
            text: glyph.length > 0 ? glyph : glyphFallback
            font.family: FontSystem.getAwesomeSolid.name.length > 0
                ? FontSystem.getAwesomeSolid.name
                : FontSystem.getAwesomeRegular.name
            font.pixelSize: Typography.t3
            color: Colors.textPrimary
            visible: glyph.length > 0 || glyphFallback.length > 0
        }
        Text {
            text: control.text
            font.family: FontSystem.getContentFont.name
            font.pixelSize: Typography.t3
            color: Colors.textPrimary
        }
        Text {
            text: "\u25BE"
            font.family: FontSystem.getContentFont.name
            font.pixelSize: Typography.t4
            color: Colors.textMuted
        }
    }

    background: Rectangle {
        radius: 10
        color: control.down ? Colors.backgroundHovered : Colors.backgroundItemActivated
        border.color: control.hovered ? Colors.secondry : Colors.borderActivated
        border.width: 1
    }

    onClicked: {
        if (!menu) return
        var p = control.mapToItem(null, 0, control.height + 6)
        menu.x = p.x
        menu.y = p.y
        menu.open()
    }
}
