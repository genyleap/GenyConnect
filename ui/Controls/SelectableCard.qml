import QtQuick
import QtQuick.Layouts
import GenyConnect 1.0

GlassCard {
    id: root

    property bool selected: false
    property string title: ""
    property string subtitle: ""
    property string badgeText: ""
    property string iconGlyph: ""
    property string iconFontFamily: FontSystem.getAwesomeSolid.name
    property url iconImageSource: ""
    property color iconBackground: Colors.dsPrimaryTint

    signal clicked()

    cardRadius: Metrics.radiusMd
    cardPadding: 12
    fillColor: selected ? Colors.dsPrimaryTint : Colors.dsSurface
    strokeColor: selected ? Colors.dsPrimarySolid : Colors.dsBorder

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 20
            color: root.iconBackground
            clip: true

            Image {
                anchors.centerIn: parent
                width: 24
                height: 24
                source: root.iconImageSource
                visible: source.toString().length > 0
                fillMode: Image.PreserveAspectFit
                mipmap: true
                smooth: true
            }

            Text {
                anchors.centerIn: parent
                visible: root.iconGlyph.length > 0 && root.iconImageSource.toString().length === 0
                text: root.iconGlyph
                font.family: root.iconFontFamily
                font.pixelSize: 16
                color: Colors.dsPrimarySolid
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: I18n.t(root.title)
                    color: Colors.dsText
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: Typography.uiTitle
                    font.bold: true
                    elide: Text.ElideRight
                }

                Rectangle {
                    visible: root.badgeText.length > 0
                    radius: Metrics.radiusPill
                    color: Colors.dsPrimarySolid
                    implicitHeight: 22
                    implicitWidth: Math.min(112, badgeLabel.implicitWidth + 12)

                    Text {
                        id: badgeLabel
                        anchors.centerIn: parent
                        width: parent.width - 8
                        text: I18n.t(root.badgeText)
                        color: Colors.dsPrimaryText
                        font.family: FontSystem.getContentFontBold.name
                        font.pixelSize: Typography.uiBodySm
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }

                Item { Layout.fillWidth: true }
            }

            Text {
                Layout.fillWidth: true
                text: I18n.t(root.subtitle)
                color: Colors.dsTextMuted
                font.family: FontSystem.contentFontFamily
                font.pixelSize: Typography.uiTitleSm
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
