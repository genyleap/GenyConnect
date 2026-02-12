import QtQuick
import GenyConnect 1.0

Item {
    id: root

    property string text: "Connect"
    property bool enabled: true
    property bool busy: false

    signal clicked()

    width: 300
    height: 88

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 6
        radius: 30
        color: "#2b5ec4"
        opacity: 0.18
    }

    Rectangle {
        id: buttonFace
        anchors.fill: parent
        radius: 30
        border.width: 1
        border.color: Qt.rgba(0.16, 0.33, 0.70, 0.9)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2f6ff1" }
            GradientStop { position: 1.0; color: "#2d65d8" }
        }

        Text {
            anchors.centerIn: parent
            text: root.text
            color: "#ffffff"
            font.family: FontSystem.getContentFont.name
            font.pixelSize: 44 * 0.6
            font.bold: true
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled && !root.busy
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: buttonFace.scale = 0.985
        onReleased: buttonFace.scale = 1.0
        onCanceled: buttonFace.scale = 1.0
        onClicked: root.clicked()
    }

    opacity: root.enabled ? 1.0 : 0.55

    Behavior on opacity {
        NumberAnimation { duration: 120 }
    }
}
