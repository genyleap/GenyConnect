import QtQuick
import QtQuick.Controls.Basic as T
import GenyConnect 1.0

T.Button {
    id: control

    property color fillColor: Colors.backgroundItemActivated
    property color strokeColor: Colors.borderActivated
    property color textColor: Colors.textPrimary

    hoverEnabled: true
    padding: 6

    contentItem: Text {
        text: control.text
        font.family: FontSystem.getContentFont.name
        font.pixelSize: Typography.t3
        color: control.enabled ? control.textColor : Colors.textMuted
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: 999
        color: control.down ? Colors.backgroundHovered : control.fillColor
        border.color: control.strokeColor
        border.width: 1
    }
}
