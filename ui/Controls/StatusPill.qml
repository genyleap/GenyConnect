import QtQuick
import QtQuick.Layouts
import GenyConnect 1.0

Rectangle {
    id: root

    property string text: ""
    property string glyph: ""
    property string glyphFontFamily: FontSystem.getAwesomeSolid.name
    property color pillColor: Colors.dsSurface
    property color borderColor: Colors.dsBorder
    property color textColor: Colors.dsText
    property bool bold: true

    radius: Metrics.radiusPill
    color: pillColor
    border.width: 1
    border.color: borderColor
    implicitHeight: 34
    implicitWidth: row.implicitWidth + 16

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            visible: root.glyph.length > 0
            text: root.glyph
            color: root.textColor
            font.family: root.glyphFontFamily
            font.pixelSize: Typography.uiBody
        }

        Text {
            text: root.text
            color: root.textColor
            font.family: bold ? FontSystem.getContentFontBold.name : FontSystem.contentFontFamily
            font.pixelSize: Typography.uiTitleSm
            font.bold: root.bold
        }
    }
}
