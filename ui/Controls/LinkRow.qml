import QtQuick
import QtQuick.Layouts
import GenyConnect 1.0

GlassCard {
    id: root

    property string title: ""
    property string subtitle: ""
    property string glyph: ""
    property string glyphFontFamily: FontSystem.getAwesomeSolid.name
    property color iconBackground: Colors.dsLinkIconBgBlue
    property color iconColor: Colors.dsLinkIconBlue
    property bool compact: false

    signal clicked()

    cardRadius: Metrics.radiusSm
    cardPadding: compact ? 10 : 12
    elevated: false
    fillColor: Colors.dsSurface
    strokeColor: Colors.dsBorderSoft
    implicitHeight: compact ? 52 : 58

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            radius: 15
            color: root.iconBackground

            Text {
                anchors.centerIn: parent
                text: root.glyph
                color: root.iconColor
                font.family: root.glyphFontFamily
                font.pixelSize: 14
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.title
                color: Colors.dsText
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: compact ? Typography.uiBodyLg : Typography.uiTitleSm
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: root.subtitle.length > 0
                text: root.subtitle
                color: Colors.dsTextMuted
                font.family: FontSystem.contentFontFamily
                font.pixelSize: Typography.uiBodySm
                elide: Text.ElideRight
            }
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
