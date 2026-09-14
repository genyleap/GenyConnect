import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts
import GenyConnect 1.0

Item {
    id: root

    property var model: []
    property string currentKey: ""
    property bool compact: false
    property int segmentHeight: compact ? 40 : Metrics.rowHeight

    signal activated(string key)

    implicitHeight: Math.max(segmentHeight, row.implicitHeight)
    implicitWidth: row.implicitWidth
    LayoutMirroring.enabled: false
    LayoutMirroring.childrenInherit: true

    RowLayout {
        id: row
        anchors.fill: parent
        layoutDirection: I18n.isRtl ? Qt.RightToLeft : Qt.LeftToRight
        spacing: Metrics.gap6

        Repeater {
            id: segments
            model: root.model

            delegate: T.Button {
                id: segment
                required property int index
                required property var modelData
                readonly property string keyValue: typeof modelData === "string" ? modelData : (modelData.key || "")
                readonly property string labelValue: typeof modelData === "string"
                    ? modelData.charAt(0).toUpperCase() + modelData.slice(1)
                    : (modelData.label || keyValue)
                readonly property bool selected: root.currentKey === keyValue

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                Layout.minimumWidth: 0
                implicitWidth: 96
                implicitHeight: Math.max(root.segmentHeight, implicitContentHeight + topPadding + bottomPadding)
                leftPadding: 8
                rightPadding: 8
                topPadding: 8
                bottomPadding: 8
                focusPolicy: Qt.StrongFocus
                hoverEnabled: Qt.platform.os !== "android" && Qt.platform.os !== "ios"
                text: I18n.t(labelValue)
                Accessible.name: text
                Accessible.checkable: true
                Accessible.checked: selected
                onClicked: root.activated(keyValue)
                Keys.onPressed: function(event) {
                    let nextIndex = index
                    if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                        const step = event.key === Qt.Key_Right ? 1 : -1
                        nextIndex = (index + (I18n.isRtl ? -step : step) + segments.count) % segments.count
                    } else if (event.key === Qt.Key_Home) {
                        nextIndex = 0
                    } else if (event.key === Qt.Key_End) {
                        nextIndex = segments.count - 1
                    } else {
                        return
                    }
                    const nextSegment = segments.itemAt(nextIndex)
                    if (nextSegment) {
                        nextSegment.forceActiveFocus(Qt.TabFocusReason)
                        root.activated(nextSegment.keyValue)
                        event.accepted = true
                    }
                }

                contentItem: Text {
                    text: segment.text
                    color: segment.selected ? Colors.dsLinkIconBlue : Colors.dsTextMuted
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: root.compact ? Typography.uiBodySm : Typography.uiBodyLg
                    font.weight: segment.selected ? Font.DemiBold : Font.Normal
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }
                background: Rectangle {
                    radius: Metrics.radiusSm
                    color: segment.selected ? Colors.dsPrimaryTint
                        : segment.down || segment.hovered ? Colors.dsSurfaceSoft : Colors.dsSurface
                    border.width: segment.visualFocus ? 2 : 1
                    border.color: segment.visualFocus ? Colors.dsPrimarySolid
                        : segment.selected ? Colors.dsBorderStrong : Colors.dsBorderSoft
                }
            }
        }
    }
}
