import QtQuick
import QtQuick.Controls.Basic as T
import GenyConnect 1.0

T.Button {
    id: control

    property bool compact: false

    implicitHeight: compact ? Metrics.rowHeight : Metrics.rowHeightLarge
    leftPadding: 14
    rightPadding: 14
    hoverEnabled: true

    contentItem: Text {
        text: control.text
        color: control.enabled ? Colors.dsText : Colors.dsTextSubtle
        font.family: FontSystem.getContentFontBold.name
        font.pixelSize: compact ? Typography.uiBodyLg : Typography.uiTitleSm
        font.bold: true
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
    }

    background: Rectangle {
        radius: Metrics.radiusPill
        color: control.down ? Colors.dsSurfaceElevated : Colors.dsSurface
        border.width: 1
        border.color: Colors.dsBorder
    }

    opacity: control.enabled ? 1 : 0.5
}
