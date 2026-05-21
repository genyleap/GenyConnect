import QtQuick
import QtQuick.Layouts
import GenyConnect 1.0

Rectangle {
    id: root

    property string amountText: "0"
    property string tokenSymbol: "GENY"
    readonly property bool isGeny: (tokenSymbol || "").toUpperCase() === "GENY"
    readonly property bool compact: width < 420

    radius: 18
    color: Colors.dsSurface
    border.width: 1
    border.color: Colors.dsBorder
    implicitHeight: compact ? 112 : 104

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        Rectangle {
            Layout.preferredWidth: 56
            Layout.preferredHeight: 56
            radius: 18
            color: root.isGeny ? Colors.dsLinkIconBgGreen : Colors.dsPrimaryTint

            Text {
                anchors.centerIn: parent
                text: root.isGeny ? "\uf471" : "\uf51e"
                font.family: FontSystem.getAwesomeSolid.name
                font.pixelSize: 24
                color: root.isGeny ? Colors.dsLinkIconGreen : Colors.dsPrimaryEnd
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "You are donating"
                color: Colors.dsTextMuted
                font.family: FontSystem.contentFontFamily
                font.pixelSize: compact ? Typography.uiTitleSm : Typography.uiTitle
            }

            Text {
                Layout.fillWidth: true
                text: root.amountText + " " + root.tokenSymbol
                color: Colors.dsText
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: compact ? 22 : 28
                font.bold: true
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            Layout.preferredWidth: compact ? 82 : 92

            Text {
                Layout.alignment: Qt.AlignRight
                text: "≈ $ --"
                color: Colors.dsText
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: compact ? Typography.uiTitleSm : Typography.uiTitle
                font.bold: true
            }

            Text {
                Layout.alignment: Qt.AlignRight
                text: "Est. value"
                color: Colors.dsTextSubtle
                font.family: FontSystem.contentFontFamily
                font.pixelSize: compact ? Typography.uiBodySm : Typography.uiTitleSm
            }
        }
    }
}
