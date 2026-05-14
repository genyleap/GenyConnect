import QtQuick
import GenyConnect 1.0

Item {
    id: root

    property string iconText: ""
    property string iconFontFamily: FontSystem.contentFontFamily
    property real diameter: 46
    property color backgroundColor: Colors.gcIconButtonBg
    property color borderColor: Colors.gcIconButtonBorder
    property color iconColor: Colors.gcIconButtonIcon
    property real iconPixelSize: Math.round(diameter * 0.46)
    property bool elevated: true
    property bool enabled: true

    signal clicked()

    width: diameter
    height: diameter

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: root.elevated ? 3 : 0
        radius: width / 2
        color: "#000000"
        opacity: root.elevated ? 0.06 : 0
    }

    Rectangle {
        id: face
        anchors.fill: parent
        radius: width / 2
        color: root.enabled
               ? root.backgroundColor
               : (Colors.lightMode ? Qt.darker(root.backgroundColor, 1.04) : Qt.lighter(root.backgroundColor, 1.12))

        Text {
            anchors.centerIn: parent
            text: root.iconText
            color: root.iconColor
            font.family: root.iconFontFamily
            font.pixelSize: root.iconPixelSize
            renderType: Text.NativeRendering
        }

        Behavior on color {
            ColorAnimation { duration: 120 }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: face.scale = 0.97
        onReleased: face.scale = 1.0
        onCanceled: face.scale = 1.0
        onClicked: root.clicked()
    }

    Behavior on opacity {
        NumberAnimation { duration: 120 }
    }

    opacity: root.enabled ? 1.0 : 0.45
}
