import QtQuick
import QtQuick.Controls.Basic as T
import GenyConnect 1.0

T.TextArea {
    id: control

    property color fillColor: Colors.dsSurface
    property color strokeColor: Colors.dsBorder
    property color focusColor: Colors.dsPrimarySolid
    property int cornerRadius: Metrics.radiusMd

    font.family: FontSystem.contentFontFamily
    font.pixelSize: Typography.uiBodyLg
    color: Colors.dsText
    placeholderTextColor: Colors.dsTextSubtle
    selectionColor: Colors.dsPrimarySolid
    selectedTextColor: Colors.staticPrimary

    leftPadding: 12
    rightPadding: 12
    topPadding: 10
    bottomPadding: 10

    background: Rectangle {
        radius: control.cornerRadius
        color: control.fillColor
        border.color: control.activeFocus ? control.focusColor : control.strokeColor
        border.width: 1
    }
}
