import QtQuick
import QtQuick.Layouts

import "../Core"

Rectangle {
    id: sectionCard

    property var root: null
    property string title: ""
    property string subtitle: ""
    property string glyph: ""
    property color accentColor: Colors.dsPrimarySolid
    property bool animated: true

    default property alias content: sectionBody.data

    Layout.fillWidth: true
    radius: Metrics.radiusLg
    color: Colors.dsSurface
    border.width: 1
    border.color: Colors.dsBorderSoft
    implicitHeight: sectionLayout.implicitHeight + 28

    Behavior on border.color {
        enabled: sectionCard.animated
        ColorAnimation { duration: 120 }
    }

    ColumnLayout {
        id: sectionLayout
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                visible: sectionCard.glyph.length > 0
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 17
                color: Qt.rgba(sectionCard.accentColor.r,
                               sectionCard.accentColor.g,
                               sectionCard.accentColor.b,
                               Colors.lightMode ? 0.12 : 0.20)

                Text {
                    anchors.centerIn: parent
                    text: sectionCard.glyph
                    color: sectionCard.accentColor
                    font.family: sectionCard.root ? sectionCard.root.faSolid : FontSystem.contentFontFamily
                    font.pixelSize: 14
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: sectionCard.title
                    color: Colors.dsText
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: Typography.uiTitleSm
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: sectionCard.subtitle.length > 0
                    text: sectionCard.subtitle
                    color: Colors.dsTextMuted
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: Typography.uiBody
                    wrapMode: Text.WordWrap
                }
            }
        }

        ColumnLayout {
            id: sectionBody
            Layout.fillWidth: true
            spacing: 10
        }
    }
}
