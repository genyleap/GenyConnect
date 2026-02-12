import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts
import GenyConnect 1.0

T.ComboBox {
    id: control

    property color fillColor: Colors.backgroundItemActivated
    property color strokeColor: Colors.borderActivated
    property color focusColor: Colors.secondry
    property int cornerRadius: 15

    font.family: FontSystem.getContentFont.name
    font.pixelSize: Typography.t2

    leftPadding: 12
    rightPadding: 28
    topPadding: 6
    bottomPadding: 6

    contentItem: Text {
        text: control.displayText
        font.family: control.font.family
        font.pixelSize: control.font.pixelSize
        color: Colors.textPrimary
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Text {
        text: "\u25BE"
        font.family: FontSystem.getContentFont.name
        font.pixelSize: Typography.t3
        color: Colors.textMuted
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
    }

    background: Rectangle {
        radius: control.cornerRadius
        color: control.fillColor
        border.color: control.activeFocus ? control.focusColor : control.strokeColor
        border.width: 1
    }
}
