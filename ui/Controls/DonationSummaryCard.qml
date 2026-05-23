import QtQuick
import QtQuick.Layouts
import GenyConnect 1.0

Rectangle {
    id: root

    property string amountText: "0"
    property string tokenSymbol: "GENY"
    property string estimatedValueText: "≈ $ --"
    readonly property bool isGeny: (tokenSymbol || "").toUpperCase() === "GENY"
    readonly property bool compact: width < 420
    readonly property bool narrow: width < 620

    radius: 18
    color: Colors.dsSurface
    border.width: 1
    border.color: Colors.dsBorder
    implicitHeight: narrow ? 132 : 104

    RowLayout {
        visible: !root.narrow
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
            Layout.preferredWidth: Math.min(root.width * 0.42,
                                            Math.max(compact ? 96 : 118,
                                                     estimatedValueLabel.implicitWidth,
                                                     estimatedValueCaption.implicitWidth))
            Layout.minimumWidth: compact ? 96 : 118

            Text {
                id: estimatedValueLabel
                Layout.alignment: Qt.AlignRight
                Layout.fillWidth: true
                text: root.estimatedValueText
                color: Colors.dsText
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: compact ? Typography.uiBody : Typography.uiTitleSm
                font.bold: true
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }

            Text {
                id: estimatedValueCaption
                Layout.alignment: Qt.AlignRight
                Layout.fillWidth: true
                text: "Est. value"
                color: Colors.dsTextSubtle
                font.family: FontSystem.contentFontFamily
                font.pixelSize: compact ? Typography.uiBodySm : Typography.uiTitleSm
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    ColumnLayout {
        visible: root.narrow
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
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
                    Layout.fillWidth: true
                    text: "You are donating"
                    color: Colors.dsTextMuted
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: compact ? Typography.uiTitleSm : Typography.uiTitle
                    elide: Text.ElideRight
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
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 68
            spacing: 8

            Text {
                text: "Est. value"
                color: Colors.dsTextSubtle
                font.family: FontSystem.contentFontFamily
                font.pixelSize: Typography.uiTitleSm
            }

            Text {
                Layout.fillWidth: true
                text: root.estimatedValueText
                color: Colors.dsText
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: Typography.uiTitleSm
                font.bold: true
                elide: Text.ElideRight
            }
        }
    }
}
