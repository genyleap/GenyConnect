/*!
 * @file        CustomDnsSettingsSection.qml
 *
 * @author      Kambiz Asadzadeh
 * @since       04 Jun 2026
 * @copyright   Copyright (c) 2026 Genyleap.
 * @license     See LICENSE in repository root.
 */

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

    Layout.fillWidth: true
    spacing: root.compact ? 14 : 10

    Rectangle {
        id: customDnsCard
        Layout.fillWidth: true
        visible: root.settingsSection === "dns"
        Layout.maximumWidth: settingsFlick.width
        Layout.preferredHeight: customDnsColumn.implicitHeight + 28
        implicitHeight: customDnsColumn.implicitHeight + 28
        radius: Metrics.radiusLg
        color: Colors.dsSurfaceSoft
        border.width: 1
        border.color: Colors.dsBorderSoft

        ColumnLayout {
            id: customDnsColumn
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    radius: 14
                    color: Colors.dsPrimaryTint

                    Text {
                        anchors.centerIn: parent
                        text: "\uf0ac"
                        color: Colors.dsPrimarySolid
                        font.family: FontSystem.getAwesomeSolid.name
                        font.pixelSize: 18
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: I18n.t("Custom DNS (optional, TUN mode)")
                        color: Colors.dsText
                        font.family: FontSystem.getContentFontBold.name
                        font.pixelSize: Typography.uiTitle
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        Layout.fillWidth: true
                        text: I18n.t("Enter one resolver per line. Supports IPv4, IPv6, and DNS hostnames.")
                        wrapMode: Text.WordWrap
                        color: Colors.dsTextMuted
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: Typography.uiBody
                    }
                }
            }

            Controls.TextArea {
                id: customDnsTextArea
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                fillColor: root.themeColorToken("mainHex_ffffff", "mainHex_4d20334d")
                strokeColor: root.themeColorToken("mainHex_d8e2f0", "mainHex_4f6f95")
                focusColor: root.themeColorToken("mainHex_8bb8ff", "mainHex_6ba0ff")
                placeholderText: I18n.t("1.1.1.1\n8.8.8.8\ndns.google")
                text: root.customDnsDraft
                onTextChanged: {
                    root.customDnsDraft = text
                    root.customDnsDirty = text.trim() !== (vpnController.customDnsServers || "").trim()
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: root.width < 520 ? 1 : 4

                Repeater {
                    model: [
                        { "label": "Cloudflare", "server": "1.1.1.1" },
                        { "label": "Google", "server": "8.8.8.8" },
                        { "label": "Quad9", "server": "9.9.9.9" }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: root.width < 520 ? 1 : 152
                        Layout.preferredHeight: 44
                        radius: 14
                        color: root.dnsDraftContains(modelData.server)
                               ? root.themeColorToken("mainHex_eaf2ff", "mainHex_223753")
                               : root.themeColorToken("mainHex_ffffff", "mainHex_22324a")
                        border.width: 1
                        border.color: root.dnsDraftContains(modelData.server)
                                      ? root.themeColorToken("mainHex_8bb8ff", "mainHex_4f86e6")
                                      : root.themeColorToken("mainHex_d8e2f0", "mainHex_151c32")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: I18n.t(modelData.label)
                                color: root.themeColorToken("mainHex_43556f", "mainHex_d0ddf0")
                                font.family: FontSystem.getContentFontBold.name
                                font.pixelSize: Typography.uiBody
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Controls.Switch {
                                checked: root.dnsDraftContains(modelData.server)
                                onToggled: root.setDnsDraftContains(modelData.server, checked)
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    color: root.themeColorToken("mainHex_7c8ba1", "mainHex_9eb2cb")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                    text: {
                        const count = (root.customDnsDraft || "")
                        .split(/[\n,;]+/)
                        .map(function(entry) { return entry.trim() })
                        .filter(function(entry) { return entry.length > 0 }).length
                        return count > 0
                                ? I18n.t("Resolvers: %1", [I18n.ltr(count)])
                                : I18n.t("Resolvers: default")
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Controls.Button {
                    text: I18n.t("Reset")
                    implicitWidth: 86
                    implicitHeight: 34
                    Layout.fillWidth: false
                    enabled: root.customDnsDirty
                    onClicked: root.syncCustomDnsDraftFromController()
                }

                Item { Layout.fillWidth: true }

                Controls.Button {
                    text: I18n.t("Apply DNS")
                    implicitWidth: 106
                    implicitHeight: 34
                    Layout.fillWidth: false
                    enabled: root.customDnsDirty
                    onClicked: {
                        vpnController.customDnsServers = root.customDnsDraft
                        root.syncCustomDnsDraftFromController()
                    }
                }
            }
        }
    }

}
