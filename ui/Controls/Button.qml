import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts

import GenyConnect 1.0

T.Button {
    id: control

    property bool isDefault: true
    property bool isBold: true
    property string setIcon: ""
    property color style: Colors.primary
    property string sizeType: "normal"
    property bool compact: sizeType === "compact"
    property bool subtle: sizeType === "subtle"
    property bool gradientPrimary: false

    Layout.fillWidth: true
    implicitWidth: setIcon.length > 0 ? 150 : 128
    implicitHeight: compact ? Metrics.rowHeightCompact : Metrics.rowHeightLarge
    hoverEnabled: true
    opacity: enabled ? 1.0 : 0.52

    contentItem: Item {
        width: control.availableWidth
        height: control.availableHeight
        implicitWidth: buttonContent.implicitWidth
        implicitHeight: buttonContent.implicitHeight
        clip: false

        RowLayout {
            id: buttonContent
            anchors.centerIn: parent
            spacing: 8

            Text {
                id: buttonIcon
                visible: control.setIcon.length > 0
                text: control.setIcon
                font.family: FontSystem.getAwesomeSolid.name.length > 0
                    ? FontSystem.getAwesomeSolid.name
                    : FontSystem.getAwesomeRegular.name
                font.pixelSize: compact ? Typography.uiBody : Typography.uiBodyLg
                color: control.isDefault ? Colors.dsPrimaryText : Colors.dsPrimarySolid
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                id: buttonLabel
                text: control.text
                font.family: control.isBold ? FontSystem.getContentFontBold.name : FontSystem.contentFontFamily
                font.pixelSize: compact ? Typography.uiBodyLg : Typography.uiTitleSm
                font.bold: control.isBold
                color: control.isDefault ? Colors.dsPrimaryText : Colors.dsPrimarySolid
                width: Math.min(
                    implicitWidth,
                    Math.max(
                        20,
                        control.availableWidth
                            - (buttonIcon.visible ? (buttonIcon.implicitWidth + buttonContent.spacing) : 0)
                            - 8))
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignVCenter
                scale: control.pressed ? 0.98 : 1.0
                Behavior on scale { NumberAnimation { duration: 120 } }
            }
        }
    }

    background: Rectangle {
        id: buttonBg
        radius: Metrics.radiusPill
        property color flatFill: control.isDefault
                                 ? (control.pressed ? Colors.dsPrimaryPressed : Colors.dsPrimarySolid)
                                 : (control.pressed ? Colors.dsPrimaryTint : (control.subtle ? "transparent" : Colors.dsSurface))
        border.width: control.isDefault ? 0 : 1
        border.color: control.isDefault ? "transparent" : Colors.dsPrimarySolid
        color: flatFill
    }

    MouseArea {
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
        anchors.fill: parent
    }
}
