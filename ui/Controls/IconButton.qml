import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts
import GenyConnect 1.0

T.Button {
    id: control

    property string glyph: ""
    property string glyphFallback: ""
    property color accentColor: Colors.secondry
    property bool ghost: false
    property bool compact: false
    property bool rounded: true

    hoverEnabled: true
    padding: compact ? 6 : 10

    contentItem: RowLayout {
        spacing: 6
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

        Text {
            text: glyph.length > 0 ? glyph : glyphFallback
            font.family: FontSystem.getAwesomeSolid.name.length > 0
                ? FontSystem.getAwesomeSolid.name
                : FontSystem.getAwesomeRegular.name
            font.pixelSize: compact ? Typography.t3 : Typography.t2
            color: control.enabled ? Colors.textPrimary : Colors.textMuted
            visible: glyph.length > 0 || glyphFallback.length > 0
        }

        Text {
            text: control.text
            font.family: FontSystem.getContentFont.name
            font.pixelSize: compact ? Typography.t3 : Typography.t2
            color: control.enabled ? Colors.textPrimary : Colors.textMuted
            visible: control.text.length > 0
        }
    }

    background: Rectangle {
        radius: rounded ? 12 : 6
        color: ghost ? "transparent" : (control.down ? Colors.backgroundHovered : Colors.backgroundItemActivated)
        border.color: control.hovered ? accentColor : Colors.borderActivated
        border.width: ghost ? 0 : 1
    }
}
