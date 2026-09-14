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
    // The native switch needs the page direction for pointer dragging. Its
    // visual children opt out below because their alignment is explicit.
    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true
    padding: 4
    spacing: 8

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                           (text.length > 0 ? implicitContentWidth : implicitIndicatorWidth)
                           + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                            implicitContentHeight + topPadding + bottomPadding,
                            implicitIndicatorHeight + topPadding + bottomPadding)

    indicator: Rectangle {
        id: rectangle
        LayoutMirroring.enabled: false
        LayoutMirroring.childrenInherit: true
        implicitWidth: 42
        implicitHeight: 22
        x: control.text.length > 0
           ? (control.mirrored ? control.width - width - control.rightPadding : control.leftPadding)
           : control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + (control.availableHeight - height) / 2
        radius: 11
        color: control.checked ? Colors.dsPrimarySolid : Colors.gcControlBg
        border.color: control.checked ? Colors.dsPrimarySolid : Colors.dsBorder
        opacity: control.enabled ? 1 : 0.45

        Rectangle {
            id: rectTwo
            x: 3 + control.visualPosition * (parent.width - width - 6)
            width: 16
            height: 16
            radius: width
            anchors.verticalCenter: parent.verticalCenter
            color: control.checked ? Colors.dsPrimaryText : Colors.dsTextMuted

            Behavior on x {
                enabled: !control.down
                NumberAnimation {
                    duration: Animations.normal
                    easing.type: Easing.Linear
                }
            }

            Behavior on color { ColorAnimation { duration: 200} }

        }
    }

    contentItem: Text {
        LayoutMirroring.enabled: false
        LayoutMirroring.childrenInherit: true
        text: I18n.t(control.text)
        font: control.font
        opacity: control.enabled ? 1 : 0.45
        color: Colors.dsText
        leftPadding: control.text.length > 0 && !control.mirrored ? control.indicator.width + control.spacing : 0
        rightPadding: control.text.length > 0 && control.mirrored ? control.indicator.width + control.spacing : 0
        horizontalAlignment: control.mirrored ? Text.AlignRight : Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        Behavior on color { ColorAnimation { duration: Animations.normal} }
    }

    background: Rectangle {
        radius: Metrics.radiusSm
        color: "transparent"
        border.width: control.visualFocus ? 1 : 0
        border.color: Colors.dsPrimarySolid
    }
}
