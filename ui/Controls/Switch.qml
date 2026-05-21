import QtQuick
import QtQuick.Controls.Basic as T

import GenyConnect 1.0

T.Switch {
    id: control
    property string title
    property string setIcon
    property bool animation : false

    text: title
    font.family: FontSystem.contentFontFamily
    font.pixelSize: Typography.t2

    indicator: Rectangle {
        id: rectangle
        implicitWidth: 42
        implicitHeight: 22
        x: control.leftPadding
        radius: 11
        anchors.verticalCenter: parent.verticalCenter
        color: control.checked ? Colors.dsPrimarySolid : Colors.dsSurface
        border.color: control.checked ? Colors.dsPrimarySolid : Colors.dsBorder

        Rectangle {
            id: rectTwo
            x: control.checked ? parent.width / 1.7 : 5
            width: 13
            height: 13
            radius: width
            anchors.verticalCenter: parent.verticalCenter
            color: control.checked ? Colors.dsPrimaryText : Colors.dsTextMuted

            Behavior on x {
                enabled: true
                NumberAnimation {
                    duration: Animations.normal
                    easing.type: Easing.Linear
                }
            }

            Behavior on color { ColorAnimation { duration: 200} }

        }
    }

    contentItem: Text {
        text: control.text
        font: control.font
        fontSizeMode: Text.Fit
        opacity: enabled ? 1.0 : 0.3
        color: Colors.dsText
        leftPadding: control.indicator.width + control.spacing
        topPadding: 5
        wrapMode: Text.WordWrap
        Behavior on color { ColorAnimation { duration: Animations.normal} }
    }

}
