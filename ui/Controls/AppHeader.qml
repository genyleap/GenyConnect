import QtQuick
import QtQuick.Layouts
import GenyConnect 1.0

Item {
    id: root

    property string title: ""
    property bool compact: false
    property bool showBack: true
    property bool showTrailing: false
    property string trailingGlyph: ""
    property string backGlyph: "\uf060"
    property string iconFontFamily: FontSystem.getAwesomeSolid.name

    signal backClicked()
    signal trailingClicked()

    implicitHeight: compact ? 48 : 56

    RowLayout {
        anchors.fill: parent
        spacing: Metrics.gap10

        CircleIconButton {
            visible: root.showBack
            diameter: root.compact ? 38 : 42
            elevated: false
            iconText: root.backGlyph
            iconFontFamily: root.iconFontFamily
            iconPixelSize: root.compact ? 15 : 16
            backgroundColor: Colors.dsSurfaceSoft
            borderColor: Colors.dsBorderSoft
            iconColor: Colors.dsText
            onClicked: root.backClicked()
        }

        Text {
            Layout.fillWidth: true
            text: I18n.t(root.title)
            color: Colors.dsText
            font.family: FontSystem.getContentFontBold.name
            font.pixelSize: root.compact ? Typography.uiTitle : Typography.uiTitleLg
            font.bold: true
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        CircleIconButton {
            visible: root.showTrailing
            diameter: root.compact ? 38 : 42
            elevated: false
            iconText: root.trailingGlyph
            iconFontFamily: root.iconFontFamily
            iconPixelSize: root.compact ? 15 : 16
            backgroundColor: Colors.dsSurfaceSoft
            borderColor: Colors.dsBorderSoft
            iconColor: Colors.dsTextMuted
            onClicked: root.trailingClicked()
        }
    }
}
