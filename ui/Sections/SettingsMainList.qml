import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import GenyConnect 1.0
import "../Core"
import "../Controls" as Controls

ColumnLayout {
    id: section

    required property var root
    required property var vpnController
    property string searchText: ""
    readonly property bool compactLayout: root.mobilePlatform || root.compact || width < 420
    readonly property var groups: [
        { title: I18n.t("Connection"), items: [
            { title: I18n.t("Connection Mode"), subtitle: I18n.t(vpnController.tunMode ? "TUN Mode" : (vpnController.useSystemProxy ? "Global Mode" : "Clean Mode")), icon: "\uf6ff", action: "connection" },
            { title: I18n.t("Routing Rules"), subtitle: I18n.t("Choose which traffic uses the VPN."), icon: "\uf542", action: "routing" },
            { title: I18n.t("Custom DNS"), subtitle: I18n.t("Configure name resolution."), icon: "\uf0ac", action: "dns" },
            { title: I18n.t("LAN Sharing"), subtitle: I18n.t("Share your connection with local devices."), icon: "\uf1eb", action: "lan" }
        ] },
        { title: I18n.t("Application"), items: [
            { title: I18n.t("Interface"), subtitle: I18n.t("Theme and language"), icon: "\uf53f", action: "interface" },
            { title: I18n.t("Power Mode"), icon: "\uf0e7", action: "power" },
            { title: I18n.t("Cache Management"), icon: "\uf1c0", action: "cache" },
            { title: I18n.t("App Updates"), icon: "\uf2f1", action: "updates" },
            { title: I18n.t("Logs"), icon: "\uf1da", action: "logs" }
        ] },
        { title: I18n.t("Help & Support"), items: [
            { title: I18n.t("About App"), icon: "\uf05a", action: "about" },
            { title: I18n.t("Terms & License"), icon: "\uf15c", action: "terms" },
            { title: I18n.t("Share App"), icon: "\uf1e0", action: "share" },
            { title: I18n.t("Support GenyConnect"), icon: "\uf4b9", action: "donate" }
        ] }
    ]
    readonly property var filteredGroups: {
        const query = searchText.trim().toLocaleLowerCase()
        return groups.map(function(group) {
            return { title: group.title, items: group.items.filter(function(item) {
                return (group.title + " " + item.title + " " + (item.subtitle || ""))
                        .toLocaleLowerCase().indexOf(query) >= 0
            }) }
        }).filter(function(group) { return group.items.length > 0 })
    }

    Layout.fillWidth: true
    Layout.minimumWidth: 0
    spacing: compactLayout ? Metrics.gap12 : Metrics.gap20

    function resetSearch() { searchText = "" }

    Controls.TextField {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        implicitHeight: 44
        placeholderText: I18n.t("Search settings")
        Accessible.name: placeholderText
        text: section.searchText
        selectByMouse: true
        onTextChanged: section.searchText = text
    }

    Repeater {
        model: section.filteredGroups

        delegate: ColumnLayout {
            id: groupColumn
            required property var modelData
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: section.compactLayout ? Metrics.gap6 : Metrics.gap8

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.leftMargin: Metrics.gap4
                Layout.rightMargin: Metrics.gap4
                text: groupColumn.modelData.title
                color: Colors.dsTextMuted
                font.family: FontSystem.contentFontFamily
                font.pixelSize: Typography.uiBody
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
                LayoutMirroring.enabled: false
                horizontalAlignment: I18n.isRtl ? Text.AlignRight : Text.AlignLeft
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                implicitHeight: rows.implicitHeight + 8
                radius: Metrics.radiusMd
                color: Colors.dsSurface
                border.color: Colors.dsBorderSoft

                ColumnLayout {
                    id: rows
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 4
                    spacing: 0

                    Repeater {
                        model: groupColumn.modelData.items
                        delegate: Controls.SettingRow {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            compact: section.compactLayout
                            title: modelData.title
                            subtitle: modelData.subtitle || ""
                            glyph: modelData.icon
                            onClicked: section.root.openSettingsSection(modelData.action)
                        }
                    }
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        visible: section.filteredGroups.length === 0
        text: I18n.t("No matching settings")
        color: Colors.dsTextMuted
        font.family: FontSystem.contentFontFamily
        font.pixelSize: Typography.uiBodyLg
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }
}
