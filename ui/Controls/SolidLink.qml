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
    property string setIcon : "\uf002"
    property string setTitle : ""
    property bool isBold : false

    signal click();

    implicitWidth: 55
    implicitHeight: 48
    opacity: enabled ? 1 : 0.3
    radius: width / 2
    color: isDefault ? style : "transparent";

    MouseArea {
        id: mouseArea
        hoverEnabled: true
        anchors.fill: parent
        onClicked: click();
    }

    Behavior on color {
        ColorAnimation {
            duration: appStyle.duration;
            easing.type: Easing.Linear;
        }
    }

    ColumnLayout {
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

        Text {
            text: setIcon
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            font.family: fontSystem.getAwesomeLight.name
            font.pixelSize: isBold ? appStyle.h6 : appStyle.h6
            font.weight: isBold ? Font.Bold : Font.Normal
            color: enabled ? isDefault ? appStyle.primary : appStyle.foregroundDeactivated : appStyle.accent
            scale: mouseArea.containsPress ? 0.8 : 1.0
            Behavior on scale { NumberAnimation { duration: 200; } }
        }
        Text {
            text: setTitle
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            font.family: fontSystem.getContentFont.name
            font.pixelSize: isBold ? appStyle.t2 : appStyle.t2
            font.weight: isBold ? Font.Bold : Font.Normal
            color: enabled ? isDefault ? appStyle.foregroundActivated : appStyle.foregroundDeactivated : appStyle.accent
            scale: mouseArea.containsPress ? 0.8 : 1.0
            Behavior on scale { NumberAnimation { duration: 200; } }
            visible: setTitle ? true : false
        }
    }
}
