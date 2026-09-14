import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts
import GenyConnect 1.0

T.ItemDelegate {
    id: control

    property string title: ""
    property string subtitle: ""
    property string glyph: ""
    property string glyphFontFamily: FontSystem.getAwesomeSolid.name
    property bool showChevron: true
    property bool compact: false

    text: title
    hoverEnabled: Qt.platform.os !== "android" && Qt.platform.os !== "ios"
    focusPolicy: Qt.StrongFocus
    leftPadding: compact ? Metrics.gap10 : Metrics.gap14
    rightPadding: leftPadding
    topPadding: compact ? Metrics.gap8 : Metrics.gap14
    bottomPadding: topPadding
    implicitHeight: Math.max(compact ? 56 : 64,
                             contentItem.implicitHeight + topPadding + bottomPadding)
    Accessible.name: title
    Accessible.description: subtitle

    background: Rectangle {
        radius: Metrics.radiusSm
        color: control.down ? Colors.dsPrimaryTint
                            : (control.hovered ? Colors.dsSurfaceSoft : "transparent")
        border.width: control.visualFocus ? 2 : 0
        border.color: Colors.dsPrimarySolid
    }

    contentItem: RowLayout {
        spacing: control.compact ? Metrics.gap10 : Metrics.gap12
        layoutDirection: I18n.isRtl ? Qt.RightToLeft : Qt.LeftToRight
        LayoutMirroring.enabled: false
        LayoutMirroring.childrenInherit: true

        Rectangle {
            Layout.preferredWidth: control.compact ? 32 : 36
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter
            radius: Metrics.radiusSm
            color: Colors.dsPrimaryTint

            Text {
                anchors.centerIn: parent
                text: control.glyph
                color: Colors.dsPrimarySolid
                font.family: control.glyphFontFamily
                font.pixelSize: 15
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: control.compact ? 2 : Metrics.gap4

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: control.title
                textFormat: Text.PlainText
                color: Colors.dsText
                font.family: FontSystem.contentFontFamily
                font.pixelSize: Typography.uiBodyLg
                font.weight: Font.DemiBold
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: I18n.isRtl ? Text.AlignRight : Text.AlignLeft
            }

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                visible: control.subtitle.length > 0
                text: control.subtitle
                textFormat: Text.PlainText
                color: Colors.dsTextMuted
                font.family: FontSystem.contentFontFamily
                font.pixelSize: Typography.uiBody
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: I18n.isRtl ? Text.AlignRight : Text.AlignLeft
            }
        }

        Text {
            visible: control.showChevron
            text: I18n.isRtl ? "\uf053" : "\uf054"
            color: Colors.dsTextSubtle
            font.family: FontSystem.getAwesomeSolid.name
            font.pixelSize: 11
        }
    }
}
