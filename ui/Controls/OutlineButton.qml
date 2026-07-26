import QtQuick
import QtQuick.Controls.Basic as T
import GenyConnect 1.0

T.Button {
    id: control

    property bool compact: false
    property color strokeColor: Colors.dsPrimarySolid
    property color textColor: Colors.dsPrimarySolid

    implicitHeight: compact ? Metrics.rowHeightCompact : Metrics.rowHeightLarge
    leftPadding: 14
    rightPadding: 14
    hoverEnabled: true

    contentItem: Text {
        text: I18n.t(control.text)
        color: control.enabled ? control.textColor : Colors.dsTextSubtle
        font.family: FontSystem.getContentFontBold.name
        font.pixelSize: compact ? Typography.uiBodyLg : Typography.uiTitleSm
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
    }

    background: Rectangle {
        radius: Metrics.radiusPill
        color: control.down ? Colors.dsPrimaryTint : "transparent"
        border.width: 1
        border.color: control.strokeColor
    }

    opacity: control.enabled ? 1 : 0.5
}
