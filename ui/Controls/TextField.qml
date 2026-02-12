import QtQuick
import QtQuick.Controls.Basic as T
import GenyConnect 1.0

T.TextField {
    id: control

    property color fillColor: Colors.backgroundItemActivated
    property color strokeColor: Colors.borderActivated
    property color focusColor: Colors.secondry
    property int cornerRadius: 10

    font.family: FontSystem.getContentFont.name
    font.pixelSize: Typography.t2
    color: Colors.textPrimary
    placeholderTextColor: Colors.textMuted
    selectionColor: Colors.secondry
    selectedTextColor: Colors.staticPrimary

    leftPadding: 12
    rightPadding: 12
    topPadding: 8
    bottomPadding: 8

    background: Rectangle {
        radius: control.cornerRadius
        color: control.fillColor
        border.color: control.activeFocus ? control.focusColor : control.strokeColor
        border.width: 1
    }
}
