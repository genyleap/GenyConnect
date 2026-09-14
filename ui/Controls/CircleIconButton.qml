import QtQuick
import QtQuick.Controls.Basic as T
import GenyConnect 1.0

T.Button {
    id: control

    property string iconText: ""
    property string iconFontFamily: FontSystem.contentFontFamily
    property real diameter: 46
    property color backgroundColor: Colors.gcIconButtonBg
    property color borderColor: Colors.gcIconButtonBorder
    property color iconColor: Colors.gcIconButtonIcon
    property real iconPixelSize: Math.round(diameter * 0.46)
    property bool elevated: true
    property string accessibleName: ""

    implicitWidth: diameter
    implicitHeight: diameter
    width: diameter
    height: diameter
    padding: 0
    hoverEnabled: Qt.platform.os !== "android" && Qt.platform.os !== "ios"
    focusPolicy: Qt.StrongFocus
    Accessible.name: accessibleName.length > 0 ? accessibleName : text
    opacity: enabled ? 1.0 : 0.45

    background: Rectangle {
        radius: width / 2
        color: control.down ? Colors.dsPrimaryTint
                            : (control.hovered ? Colors.dsSurfaceSoft : control.backgroundColor)
        border.width: control.visualFocus ? 2 : 1
        border.color: control.visualFocus ? Colors.dsPrimarySolid : control.borderColor

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 3
            radius: width / 2
            color: Colors.dsShadowSoft
            visible: control.elevated
            z: -1
        }
    }

    contentItem: Text {
        text: control.iconText
        color: control.iconColor
        font.family: control.iconFontFamily
        font.pixelSize: control.iconPixelSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

}
