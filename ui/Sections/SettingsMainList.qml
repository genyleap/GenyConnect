/*!
 * @file        SettingsMainListSection.qml
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

    Layout.fillWidth: true
    spacing: root.compact ? 14 : 10

    Rectangle {
        Layout.fillWidth: true
        visible: root.settingsSection === "main"
        implicitHeight: compactSettingsList.implicitHeight
        color: "transparent"

        ColumnLayout {
            id: compactSettingsList
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 5

            Repeater {
                model: [
                    { "title": I18n.t("Interface"), "subtitle": I18n.t("Theme and language"), "icon": "\uf53f", "action": "interface" },
                    { "title": I18n.t("App Updates"), "icon": "\uf2f1", "action": "updates" },
                    { "title": I18n.t("Connection Mode"), "icon": "\uf6ff", "action": "connection" },
                    { "title": I18n.t("Cache Management"), "icon": "\uf1c0", "action": "cache" },
                    { "title": I18n.t("Power Mode"), "icon": "\uf0e7", "action": "power" },
                    { "title": I18n.t("Routing Rules"), "icon": "\uf542", "action": "routing" },
                    { "title": I18n.t("LAN Sharing"), "icon": "\uf1eb", "action": "lan" },
                    { "title": I18n.t("Custom DNS"), "icon": "\uf1eb", "action": "dns" },
                    { "title": I18n.t("Logs"), "icon": "\uf1da", "action": "logs" },
                    { "title": I18n.t("Terms & License"), "icon": "\uf15c", "action": "terms" },
                    { "title": I18n.t("Share App"), "icon": "\uf1e0", "action": "share" },
                    { "title": I18n.t("Donate $GENY"), "icon": "\uf4b9", "action": "donate" },
                    { "title": I18n.t("About App"), "icon": "\uf05a", "action": "about" }
                ]

                delegate: Rectangle {
                    required property var modelData
                    color: "transparent"
                    Layout.fillWidth: true
                    Layout.preferredHeight: rowControl.implicitHeight

                    Controls.SettingRow {
                        id: rowControl
                        anchors.left: parent.left
                        anchors.right: parent.right
                        compact: root.compact
                        title: modelData.title
                        subtitle: modelData.subtitle || ""
                        glyph: modelData.icon
                        glyphFontFamily: root.faSolid
                        onClicked: root.openSettingsSection(modelData.action)
                    }
                }
            }
        }
    }

}
