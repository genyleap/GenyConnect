/*!
 * @file        LogsSettingsSection.qml
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
    required property var logsPopup

    Layout.fillWidth: true
    spacing: root.compact ? 14 : 10

    Rectangle {
        Layout.fillWidth: true
        visible: root.settingsSection === "logs"
        radius: Metrics.radiusLg
        color: Colors.dsSurfaceSoft
        border.width: 1
        border.color: Colors.dsBorder
        implicitHeight: logsSettingsColumn.implicitHeight + 22

        ColumnLayout {
            id: logsSettingsColumn
            anchors.fill: parent
            anchors.margins: 11
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: I18n.t("Logs & Diagnostics")
                        color: Colors.dsText
                        font.family: FontSystem.getContentFontBold.name
                        font.pixelSize: Typography.uiTitle
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        Layout.fillWidth: true
                        text: vpnController.loggingEnabled
                              ? I18n.t("Captured lines: %1", [I18n.ltr(vpnController.recentLogs.length)])
                              : I18n.t("Enable logging to capture connection diagnostics.")
                        color: Colors.dsTextMuted
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: Typography.uiBody
                        wrapMode: Text.WordWrap
                    }
                }

                Controls.StatusPill {
                    text: I18n.t(vpnController.loggingEnabled ? "Enabled" : "Disabled")
                    pillColor: vpnController.loggingEnabled ? Colors.dsPrimarySolid : Colors.dsSurface
                    borderColor: vpnController.loggingEnabled ? Colors.dsPrimarySolid : Colors.dsBorder
                    textColor: vpnController.loggingEnabled ? Colors.dsPrimaryText : Colors.dsTextMuted

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: vpnController.loggingEnabled = !vpnController.loggingEnabled
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: root.compact ? 2 : 3
                columnSpacing: 8
                rowSpacing: 8

                Controls.PrimaryButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.columnSpan: root.compact ? 2 : 1
                    compact: true
                    text: I18n.t("Open Viewer")
                    onClicked: logsPopup.open()
                }

                Controls.OutlineButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    compact: true
                    text: I18n.t("Copy")
                    enabled: vpnController.loggingEnabled && vpnController.recentLogs.length > 0
                    onClicked: vpnController.copyLogsToClipboard()
                }

                Controls.OutlineButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    compact: true
                    text: I18n.t("Clear")
                    enabled: vpnController.recentLogs.length > 0
                    onClicked: vpnController.clearLogs()
                }
            }
        }
    }

}
