import QtQuick
import QtQuick.Layouts
import GenyConnect 1.0

GlassCard {
    id: root

    property string label: ""
    property string value: ""
    property string hint: ""
    property bool compact: false

    cardRadius: Metrics.radiusMd
    cardPadding: compact ? 10 : 12
    elevated: false
    fillColor: Colors.dsSurfaceElevated
    strokeColor: Colors.dsBorder
    implicitHeight: compact ? 68 : 74

    ColumnLayout {
        anchors.fill: parent
        spacing: 2

        Text {
            Layout.fillWidth: true
            text: I18n.t(root.label)
            color: Colors.dsTextSubtle
            font.family: FontSystem.contentFontFamily
            font.pixelSize: Typography.uiBodySm
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: root.value
            color: Colors.dsText
            font.family: FontSystem.getContentFontBold.name
            font.pixelSize: compact ? Typography.uiTitleSm : Typography.uiTitle
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            visible: root.hint.length > 0
            text: I18n.t(root.hint)
            color: Colors.dsTextMuted
            font.family: FontSystem.contentFontFamily
            font.pixelSize: Typography.uiCaption
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }
}
