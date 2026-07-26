import QtQuick
import QtQuick.Layouts
import GenyConnect 1.0

Rectangle {
    id: root

    property string label: ""
    property bool selected: false

    signal clicked()

    radius: 16
    border.width: 1
    border.color: selected ? Colors.dsPrimarySolid : Colors.dsBorder
    color: selected ? Colors.dsPrimarySolid : Colors.dsSurface
    implicitHeight: 48

    Text {
        anchors.centerIn: parent
        text: I18n.localizeDigits(I18n.t(root.label))
        color: selected ? Colors.dsPrimaryText : Colors.dsText
        font.family: FontSystem.getContentFontBold.name
        font.pixelSize: Typography.uiTitleSm
        font.bold: true
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
