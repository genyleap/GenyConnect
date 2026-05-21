import QtQuick
import QtQuick.Layouts
import GenyConnect 1.0

GlassCard {
    id: root

    property string title: ""
    property string body: ""
    property string glyph: "\uf05a"
    property string glyphFontFamily: FontSystem.getAwesomeSolid.name
    property color accentColor: Colors.dsPrimarySolid

    cardRadius: Metrics.radiusMd
    cardPadding: 12
    fillColor: Colors.dsPrimaryTint
    strokeColor: Colors.dsBorder
    elevated: false

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            radius: 15
            color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.16)

            Text {
                anchors.centerIn: parent
                text: root.glyph
                color: root.accentColor
                font.family: root.glyphFontFamily
                font.pixelSize: 13
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Text {
                Layout.fillWidth: true
                text: root.title
                color: Colors.dsText
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: Typography.uiBodyLg
                font.bold: true
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                text: root.body
                color: Colors.dsTextMuted
                font.family: FontSystem.contentFontFamily
                font.pixelSize: Typography.uiBody
                wrapMode: Text.WordWrap
            }
        }
    }
}
