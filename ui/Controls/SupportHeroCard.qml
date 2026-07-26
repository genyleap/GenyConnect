import QtQuick
import QtQuick.Layouts
import GenyConnect 1.0

GlassCard {
    id: root

    property bool compact: false
    property string title: "Support GenyConnect"
    property string description: "Your donation helps us improve GenyConnect, maintain infrastructure, and grow the Geny ecosystem."
    property string networkName: "Base Mainnet"

    readonly property bool stacked: compact || width < 640

    cardRadius: Metrics.radiusLg
    cardPadding: compact ? 14 : 18
    fillColor: Colors.dsSurfaceSoft
    strokeColor: Colors.dsBorderSoft
    elevated: true
    implicitHeight: (root.stacked
                     ? heroText.implicitHeight
                     : Math.max(heroText.implicitHeight, 160))
                    + (cardPadding * 2)

    RowLayout {
        anchors.fill: parent
        spacing: root.stacked ? 0 : 16

        ColumnLayout {
            id: heroText
            Layout.fillWidth: true
            spacing: 10

            Text {
                Layout.fillWidth: true
                text: I18n.t(root.title)
                color: Colors.dsText
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: root.compact ? 16 : 18
                font.bold: true
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                text: I18n.t(root.description)
                color: Colors.dsTextMuted
                font.family: FontSystem.contentFontFamily
                font.pixelSize: Typography.uiBody
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.preferredHeight: 42
                Layout.preferredWidth: networkDot.width + 8 + networkLabel.implicitWidth + 24
                radius: 14
                color: Colors.dsSurface
                border.width: 1
                border.color: Colors.dsBorder
                clip: true

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Rectangle {
                        id: networkDot
                        Layout.preferredWidth: 12
                        Layout.preferredHeight: 12
                        radius: 6
                        color: Colors.dsPrimarySolid
                    }

                    Text {
                        id: networkLabel
                        text: I18n.t(root.networkName)
                        color: Colors.dsText
                        font.family: FontSystem.getContentFontBold.name
                        font.pixelSize: Typography.uiBodyLg
                        font.bold: true
                    }
                }
            }
        }

        Item {
            Layout.preferredWidth: 188
            Layout.preferredHeight: 160
            Layout.maximumWidth: root.stacked ? 0 : 188
            Layout.maximumHeight: root.stacked ? 0 : 160
            visible: !root.stacked

            Loader {
                anchors.fill: parent
                active: !root.stacked
                sourceComponent: heroArtwork
            }
        }
    }

    Component {
        id: heroArtwork

        Rectangle {
            anchors.centerIn: parent
            width: 178
            height: 124
            radius: 24
            color: Colors.dsSurface
            border.width: 1
            border.color: Colors.dsBorder

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.78
                    height: parent.height * 0.56
                    radius: 18
                    color: Qt.rgba(Colors.dsPrimarySolid.r, Colors.dsPrimarySolid.g, Colors.dsPrimarySolid.b, 0.24)
                }

            Text {
                anchors.centerIn: parent
                text: "\uf004"
                font.family: FontSystem.getAwesomeSolid.name
                font.pixelSize: 42
                color: Colors.dsPrimarySolid
            }
        }
    }
}
