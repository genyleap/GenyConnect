import QtQuick
import QtQuick.Controls.Basic as T
import GenyConnect 1.0

T.TextField {
    id: control

    property color fillColor: Colors.dsSurface
    property color strokeColor: Colors.dsBorder
    property color focusColor: Colors.dsPrimarySolid
    property int cornerRadius: Metrics.radiusSm

    // Keep the typed value and Basic's placeholder on the same leading edge,
    // including Latin names entered on an RTL page. Callers can override this
    // alignment for technical values without inherited mirroring reversing it.
    LayoutMirroring.enabled: false
    LayoutMirroring.childrenInherit: true
    horizontalAlignment: I18n.isRtl ? TextInput.AlignRight : TextInput.AlignLeft
    verticalAlignment: TextInput.AlignVCenter

    font.family: FontSystem.contentFontFamily
    font.pixelSize: Typography.uiBodyLg
    color: Colors.dsText
    placeholderTextColor: Colors.dsTextSubtle
    selectionColor: Colors.dsPrimarySolid
    selectedTextColor: Colors.dsPrimaryText

    leftPadding: 12
    rightPadding: 12
    topPadding: 8
    bottomPadding: 8

    background: Rectangle {
        radius: control.cornerRadius
        color: control.fillColor
        border.color: control.activeFocus ? control.focusColor : control.strokeColor
        border.width: 1
    }
}
