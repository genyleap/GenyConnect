import QtQuick
import QtQuick.Controls.Basic as T
import GenyConnect 1.0

T.Button {
    id: control

    property bool compact: false
    property string glyph: ""
    property string glyphFontFamily: FontSystem.getAwesomeSolid.name
    property bool flatStyle: true

    implicitHeight: compact ? Metrics.rowHeightCompact : Metrics.rowHeightLarge
    leftPadding: 14
    rightPadding: 14
    hoverEnabled: true

    contentItem: Item {
        width: control.availableWidth
        height: control.availableHeight
        implicitWidth: buttonContent.implicitWidth
        implicitHeight: buttonContent.implicitHeight
        clip: false

        Row {
            id: buttonContent
            spacing: 8
            anchors.centerIn: parent

            Text {
                id: primaryGlyph
                visible: control.glyph.length > 0
                text: control.glyph
                font.family: control.glyphFontFamily
                font.pixelSize: compact ? Typography.uiBody : Typography.uiBodyLg
                color: Colors.dsPrimaryText
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: I18n.t(control.text)
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: compact ? Typography.uiBodyLg : Typography.uiTitleSm
                color: Colors.dsPrimaryText
                font.bold: true
                width: Math.min(
                    implicitWidth,
                    Math.max(
                        20,
                        control.availableWidth
                            - (primaryGlyph.visible ? (primaryGlyph.implicitWidth + buttonContent.spacing) : 0)
                            - 8))
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    background: Rectangle {
        radius: Metrics.radiusPill
        border.width: 1
        border.color: Qt.darker(Colors.dsPrimaryStart, 1.06)
        color: control.down ? Colors.dsPrimaryPressed : Colors.dsPrimarySolid
    }

    opacity: control.enabled ? 1 : 0.5
}
