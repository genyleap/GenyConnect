import QtQuick
import QtQuick.Controls.Basic as T
import GenyConnect 1.0

T.SpinBox {
    id: control

    property color fillColor: Colors.backgroundItemActivated
    property color strokeColor: Colors.borderActivated
    property color focusColor: Colors.secondry
    property int cornerRadius: 10

    font.family: FontSystem.getContentFont.name
    font.pixelSize: Typography.t2
    editable: true

    background: Rectangle {
        radius: control.cornerRadius
        color: control.enabled ? control.fillColor : Colors.backgroundItemDeactivated
        border.color: control.activeFocus ? control.focusColor : control.strokeColor
        border.width: 1
    }
}
