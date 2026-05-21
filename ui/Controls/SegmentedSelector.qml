import QtQuick
import QtQuick.Layouts
import GenyConnect 1.0

Item {
    id: root

    property var model: []
    property string currentKey: ""
    property bool compact: false
    property int segmentHeight: compact ? Metrics.rowHeightCompact : Metrics.rowHeight

    signal activated(string key)

    implicitHeight: segmentHeight
    implicitWidth: row.implicitWidth

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: Metrics.gap8

        Repeater {
            model: root.model

            delegate: Rectangle {
                required property var modelData
                readonly property string keyValue: (typeof modelData === "string")
                                                  ? modelData
                                                  : (modelData.key || "")
                readonly property string labelValue: (typeof modelData === "string")
                                                    ? (modelData.charAt(0).toUpperCase() + modelData.slice(1))
                                                    : (modelData.label || keyValue)
                readonly property bool active: root.currentKey === keyValue

                Layout.fillWidth: true
                Layout.preferredHeight: root.segmentHeight
                radius: Metrics.radiusSm
                color: active ? Colors.dsPrimaryTint : Colors.dsSurface
                border.width: 1
                border.color: active ? Colors.dsPrimarySolid : Colors.dsBorder

                Text {
                    anchors.centerIn: parent
                    text: parent.labelValue
                    color: parent.active ? Colors.dsPrimarySolid : Colors.dsTextMuted
                    font.family: parent.active ? FontSystem.getContentFontBold.name : FontSystem.contentFontFamily
                    font.pixelSize: Typography.uiBodyLg
                    font.bold: parent.active
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activated(parent.keyValue)
                }
            }
        }
    }
}
