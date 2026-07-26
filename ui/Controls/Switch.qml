import QtQuick
import QtQuick.Controls.Basic as T

import GenyConnect 1.0

T.Switch {
    id: control
    property string title
    property string setIcon
    property bool animation : false

    text: I18n.t(title)
    font.family: FontSystem.contentFontFamily
    font.pixelSize: Typography.t2
    LayoutMirroring.enabled: false

    indicator: Rectangle {
        id: rectangle
        implicitWidth: 42
        implicitHeight: 22
        x: I18n.isRtl
           ? control.width - width - control.rightPadding
           : control.leftPadding
        radius: 11
        anchors.verticalCenter: parent.verticalCenter
        color: control.checked ? Colors.dsPrimarySolid : Colors.dsSurface
        border.color: control.checked ? Colors.dsPrimarySolid : Colors.dsBorder

        Rectangle {
            id: rectTwo
            x: control.checked
               ? (I18n.isRtl ? 5 : parent.width - width - 5)
               : (I18n.isRtl ? parent.width - width - 5 : 5)
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
        text: I18n.t(control.text)
        font: control.font
        fontSizeMode: Text.Fit
        opacity: enabled ? 1.0 : 0.3
        color: Colors.dsText
        leftPadding: I18n.isRtl ? 0 : control.indicator.width + control.spacing
        rightPadding: I18n.isRtl ? control.indicator.width + control.spacing : 0
        topPadding: 5
        horizontalAlignment: I18n.isRtl ? Text.AlignRight : Text.AlignLeft
        wrapMode: Text.WordWrap
        Behavior on color { ColorAnimation { duration: Animations.normal} }
    }

}
