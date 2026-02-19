import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts

import GenyConnect 1.0

T.Button {
    id: control

    property bool isDefault : true
    property bool isBold : true

    property string setIcon : ""
    property color style : Colors.primary
    property string sizeType : "normal"

    width: setIcon ? 128 * 1.5 : 128
    implicitHeight: 46
    Layout.fillWidth: true
    implicitWidth: 128

    opacity: control.enabled ? 1 : 0.5

    contentItem: Item {

        anchors.fill: parent

        anchors.topMargin: AppGlobals.rtl ? 0 : 3 // patch fix for unsupported font [latin] position.

        Text {
            text: control.text
            anchors.centerIn: parent
            font.family: FontSystem.getContentFontRegular.font.family
            font.pixelSize: Typography.t3
            font.bold: control.isBold ? Font.Bold : Font.Normal
            font.weight: control.isBold ? Font.Bold : Font.Normal
            color: control.isDefault ? Colors.staticPrimary : Colors.secondry

            Behavior on color {
                ColorAnimation {
                    duration: Animations.normal;
                    easing.type: Easing.Linear;
                }
            }
            elide: Text.ElideRight
            scale: control.pressed ? 0.9 : 1.0
            Behavior on scale { NumberAnimation { duration: 200; } }
        }

        // Row {

        //     anchors.centerIn: parent
        //     spacing: 0

        //     Item { width: 5; }

        //     Text {
        //         text: control.text
        //         Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        //         Layout.fillWidth: false
        //         font.family: FontSystem.getContentFont.name
        //         font.pixelSize: Typography.t3
        //         font.bold: isBold ? Font.Bold : Font.Normal
        //         font.weight: isBold ? Font.Bold : Font.Normal
        //         color: isDefault ? Colors.textSecondary : Colors.textPrimary

        //         Behavior on color {
        //             ColorAnimation {
        //                 duration: Animations.normal;
        //                 easing.type: Easing.Linear;
        //             }
        //         }

        //         horizontalAlignment: Text.AlignHCenter
        //         verticalAlignment: Text.AlignVCenter
        //         elide: Text.ElideRight
        //         scale: control.pressed ? 0.9 : 1.0
        //         Behavior on scale { NumberAnimation { duration: 200; } }
        //     }

        //     HorizontalSpacer { visible: setIcon ? true : false }

        //     Text {
        //         text: setIcon
        //         font.family: FontSystem.getAwesomeRegular.name
        //         font.pixelSize: Typography.t3
        //         font.weight: isBold ? Font.Normal : Font.Light
        //         font.bold: isBold ? Font.Bold : Font.Normal
        //         color: isDefault ? Colors.accent : Colors.foregroundFocused
        //         horizontalAlignment: Text.AlignHCenter
        //         verticalAlignment: Text.AlignVCenter
        //         elide: Text.ElideRight
        //         visible: setIcon ? true : false
        //         scale: control.pressed ? 0.9 : 1.0
        //         Behavior on scale { NumberAnimation { duration: 200; } }
        //     }

        //     Item { width: 5; }
        // }

    }

    background: Rectangle {
        implicitWidth: control.width
        implicitHeight: control.height
        Layout.fillWidth: true
        radius: Colors.outerRadius
        color: control.isDefault ? Colors.primaryBack : "transparent"
        border.width: control.isDefault ? 0 : 1
        border.color: control.isDefault ? "transparent" : Colors.secondry
    }

    MouseArea {
        id: mouseArea
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
        anchors.fill: parent
    }
}
