import QtQuick
import QtQuick.Layouts
import GenyConnect 1.0

Rectangle {
    id: root

    property bool selected: false
    property string title: ""
    property string subtitle: ""
    property string badgeText: ""
    property string iconGlyph: ""
    property string iconFontFamily: FontSystem.getAwesomeSolid.name
    property url iconImageSource: ""
    property color iconBackground: Colors.dsPrimaryTint
    property color iconColor: Colors.dsPrimarySolid
    property string imageFallbackText: "G"
    readonly property bool compactWidth: width < 190
    readonly property string resolvedBadgeText: {
        if (root.badgeText.length === 0)
            return ""
        return root.compactWidth ? "Rec." : root.badgeText
    }

    signal clicked()

    radius: 18
    color: selected
           ? (Colors.lightMode ? Colors.dsPrimaryTint : "#121d35")
           : (Colors.lightMode ? Colors.dsSurface : "#080f1f")
    border.width: 1
    border.color: selected ? Colors.dsPrimarySolid : (Colors.lightMode ? Colors.dsBorder : "#26324a")
    implicitHeight: compactWidth ? 72 : 82
    clip: true

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: compactWidth ? 10 : 12
        anchors.rightMargin: compactWidth ? 8 : 12
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: compactWidth ? 7 : 10

        Rectangle {
            id: iconCircle
            Layout.preferredWidth: compactWidth ? 30 : 38
            Layout.preferredHeight: compactWidth ? 30 : 38
            Layout.alignment: Qt.AlignVCenter
            radius: width / 2
            color: root.iconBackground
            clip: true

            Image {
                id: tokenImage
                anchors.fill: parent
                source: root.iconImageSource
                visible: source.toString().length > 0 && status === Image.Ready
                fillMode: Image.PreserveAspectCrop
                asynchronous: false
                mipmap: true
                smooth: true
            }

            Text {
                anchors.centerIn: parent
                visible: root.iconImageSource.toString().length > 0
                         ? tokenImage.status === Image.Error
                         : root.iconGlyph.length > 0
                text: root.iconImageSource.toString().length > 0 ? root.imageFallbackText : root.iconGlyph
                font.family: root.iconImageSource.toString().length > 0
                             ? FontSystem.getContentFontBold.name
                             : root.iconFontFamily
                font.pixelSize: root.iconImageSource.toString().length > 0 ? 18 : 19
                color: root.iconColor
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: I18n.t(root.title)
                color: Colors.dsText
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: root.compactWidth ? 13 : 15
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: I18n.t(root.subtitle)
                color: Colors.dsTextMuted
                font.family: FontSystem.contentFontFamily
                font.pixelSize: root.compactWidth ? 11 : Typography.uiBody
                elide: Text.ElideRight
            }
        }

        Rectangle {
            id: badge
            visible: root.resolvedBadgeText.length > 0
            Layout.preferredWidth: root.compactWidth ? 46 : Math.min(92, Math.max(64, badgeLabel.implicitWidth + 14))
            Layout.preferredHeight: root.compactWidth ? 20 : 24
            Layout.alignment: Qt.AlignTop
            color: Colors.lightMode ? Colors.dsPrimaryTint : "#2a2053"
            border.width: 1
            border.color: Colors.lightMode ? Colors.dsPrimarySolid : "#6b55ff"
            radius: height / 2

            Text {
                id: badgeLabel
                anchors.centerIn: parent
                width: parent.width - 10
                text: I18n.t(root.resolvedBadgeText)
                color: Colors.lightMode ? Colors.dsPrimarySolid : "#c8bbff"
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: root.compactWidth ? 10 : 11
                font.bold: true
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
