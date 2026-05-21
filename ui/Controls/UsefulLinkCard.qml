import QtQuick
import QtQuick.Layouts
import GenyConnect 1.0

Rectangle {
    id: root

    property string title: ""
    property string glyph: ""
    property string glyphFontFamily: FontSystem.getAwesomeSolid.name
    property color iconBackground: Colors.dsLinkIconBgBlue
    property color iconColor: Colors.dsLinkIconBlue

    signal clicked()

    radius: 16
    color: Colors.dsSurface
    border.width: 1
    border.color: Colors.dsBorder
    implicitHeight: 64

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            radius: 17
            color: root.iconBackground

            Text {
                anchors.centerIn: parent
                text: root.glyph
                color: root.iconColor
                font.family: root.glyphFontFamily
                font.pixelSize: 16
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.title
            color: Colors.dsText
            font.family: FontSystem.getContentFontBold.name
            font.pixelSize: Typography.uiTitleSm
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            text: "\uf054"
            color: Colors.dsTextSubtle
            font.family: FontSystem.getAwesomeSolid.name
            font.pixelSize: 12
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
