import QtQuick
import QtQuick.Layouts
import GenyConnect 1.0

GlassCard {
    id: root

    property string title: ""
    property string subtitle: ""
    property string glyph: ""
    property string glyphFontFamily: FontSystem.getAwesomeSolid.name
    property bool showChevron: true
    property bool compact: false

    signal clicked()

    cardRadius: Metrics.radiusMd
    cardPadding: compact ? 12 : 14
    elevated: false
    fillColor: Colors.gcPanelSoft
    strokeColor: Colors.gcBorder2

    implicitHeight: compact ? 72 : 78

    RowLayout {
        anchors.fill: parent
        spacing: 12

        Rectangle {
            Layout.preferredWidth: compact ? 40 : 44
            Layout.preferredHeight: compact ? 40 : 44
            radius: width / 2
            color: Colors.gcPanelTint

            Text {
                anchors.centerIn: parent
                text: root.glyph
                color: Colors.dsPrimarySolid
                font.family: root.glyphFontFamily
                font.pixelSize: compact ? 16 : 18
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: I18n.t(root.title)
                color: Colors.dsText
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: compact ? Typography.uiTitleSm : Typography.uiTitle
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: root.subtitle.length > 0
                text: I18n.t(root.subtitle)
                color: Colors.dsTextMuted
                font.family: FontSystem.contentFontFamily
                font.pixelSize: Typography.uiBody
                elide: Text.ElideRight
            }
        }

        Text {
            visible: root.showChevron
            text: I18n.isRtl ? "\uf053" : "\uf054"
            color: Colors.dsTextSubtle
            font.family: FontSystem.getAwesomeSolid.name
            font.pixelSize: 14
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
