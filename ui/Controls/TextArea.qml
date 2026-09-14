import QtQuick
import QtQuick.Controls.Basic as T
import GenyConnect 1.0

T.TextArea {
    id: control

    property color fillColor: Colors.dsSurface
    property color strokeColor: Colors.dsBorder
    property color focusColor: Colors.dsPrimarySolid
    property color hintColor: Colors.dsTextSubtle
    property int cornerRadius: Metrics.radiusMd

    implicitWidth: 240
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding,
                             hint.implicitHeight + topPadding + bottomPadding)
    font.family: FontSystem.contentFontFamily
    font.pixelSize: Typography.uiBodyLg
    color: Colors.dsText
    // Basic's built-in placeholder always elides. Keep its native editing and
    // context menu, but draw a wrapping hint independently of the editor text.
    placeholderTextColor: "transparent"
    selectionColor: Colors.dsPrimarySolid
    selectedTextColor: Colors.staticPrimary

    leftPadding: 12
    rightPadding: 12
    topPadding: 10
    bottomPadding: 10

    Text {
        id: hint
        x: control.leftPadding
        y: control.topPadding
        width: Math.max(0, control.width - control.leftPadding - control.rightPadding)
        height: Math.max(0, control.height - control.topPadding - control.bottomPadding)
        text: control.placeholderText
        font: control.font
        color: control.hintColor
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        horizontalAlignment: I18n.isRtl ? Text.AlignRight : Text.AlignLeft
        verticalAlignment: control.verticalAlignment
        LayoutMirroring.enabled: false
        visible: !control.length && !control.preeditText
        clip: true
        renderType: control.renderType
        Accessible.ignored: true
    }

    background: Rectangle {
        radius: control.cornerRadius
        color: control.fillColor
        border.color: control.activeFocus ? control.focusColor : control.strokeColor
        border.width: 1
    }
}
