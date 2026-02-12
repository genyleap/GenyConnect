import QtQuick 2.15
import QtQuick.Controls 2.15 as Default
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

import "../Controls" as Controls

Rectangle {

    id: control

    property bool isDefault : false
    property color style : appStyle.backgroundActivated
    property bool noBorder : true
    property string setIcon : "\uf0c5"
    property string setLink : "https://"
    property bool isBold : false

    implicitWidth: 120
    implicitHeight: 48
    opacity: enabled ? 1 : 0.3
    color: appStyle.backgroundItemHovered
    height: 48
    border.color: control.focus ? appStyle.primary :  appStyle.borderActivated
    border.width: control.focus  ? 2 : 1
    radius: appStyle.radius

    Behavior on border.color {
        ColorAnimation {
            duration: 200
        }
    }

    MouseArea {
        id: mouseArea
        hoverEnabled: true
        anchors.fill: parent
    }

    Behavior on color {
        ColorAnimation {
            duration: appStyle.duration;
            easing.type: Easing.Linear;
        }
    }

    RowLayout {
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        Layout.fillWidth: true
        Layout.margins: 10

        Item { width: 10; }

        Text {
            text: setLink
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            font.family: fontSystem.getContentFont.name
            font.pixelSize: isBold ? appStyle.t2 : appStyle.t1
            font.weight: isBold ? Font.Bold : Font.Normal
            color: enabled ? isDefault ? appStyle.foregroundActivated : appStyle.foregroundDeactivated : appStyle.accent
            scale: mouseArea.containsPress ? 0.8 : 1.0
            Behavior on scale { NumberAnimation { duration: 200; } }
        }
        Controls.HorizontalSpacer { }
        Text {
            text: setIcon
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            font.family: fontSystem.getAwesomeLight.name
            font.pixelSize: isBold ? appStyle.h6 : appStyle.t1
            font.weight: isBold ? Font.Bold : Font.Normal
            color: enabled ? isDefault ? appStyle.primary : appStyle.foregroundDeactivated : appStyle.accent
            scale: mouseArea.containsPress ? 0.8 : 1.0
            Behavior on scale { NumberAnimation { duration: 200; } }
        }
        Item { width: 10; }
    }
}
