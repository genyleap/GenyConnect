/*!
 * @file        UpdatesSettingsSection.qml
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
    required property var updater

    Layout.fillWidth: true
    spacing: root.compact ? 14 : 10

    function localizedUpdateStatus(value) {
        const source = String(value || "")
        let match = source.match(/^You are up to date \((.+)\)\.$/)
        if (match)
            return I18n.t("You are up to date (%1).", [I18n.ltr(match[1])])
        match = source.match(/^Update available: (.+)$/)
        if (match)
            return I18n.t("Update available: %1", [I18n.ltr(match[1])])
        match = source.match(/^No published release yet\. Current version (.+)\.$/)
        if (match)
            return I18n.t("No published release yet. Current version %1.", [I18n.ltr(match[1])])
        return I18n.t(source)
    }

    Rectangle {
        Layout.fillWidth: true
        visible: root.settingsSection === "updates" && vpnController.supportsAutoUpdate
        Layout.maximumWidth: settingsFlick.width
        implicitHeight: updateColumn.implicitHeight + 24
        radius: Colors.innerRadius
        color: root.themeColorToken("mainHex_eff4fb", "mainHex_151c32")
        border.width: 1
        border.color: root.themeColorToken("mainHex_d7e4f6", "mainHex_30435d")

        ColumnLayout {
            id: updateColumn
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: I18n.t("App Updates")
                    color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: 15
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: I18n.t("Current %1", [I18n.ltr(updater.appVersion)])
                    color: root.themeColorToken("mainHex_677385", "mainHex_9bb0cb")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 13
                }
            }

            Text {
                Layout.fillWidth: true
                text: section.localizedUpdateStatus(updater.status)
                color: updater.error.length > 0
                       ? root.themeColorToken("mainHex_c44a4a", "mainHex_ff8e8e")
                       : (updater.updateAvailable
                          ? root.themeColorToken("mainHex_1f7a51", "mainHex_55d793")
                          : root.themeColorToken("mainHex_5f6f88", "mainHex_9bb0cb"))
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                visible: updater.updateAvailable && updater.latestVersion.length > 0
                text: I18n.t("Latest %1", [I18n.ltr(updater.latestVersion)])
                color: root.themeColorToken("mainHex_7f8897", "mainHex_99abc4")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 12
            }

            Rectangle {
                id: updateProgressTrack
                Layout.fillWidth: true
                Layout.preferredHeight: 8
                visible: updater.checking
                radius: 4
                color: root.themeColorToken("mainHex_dfe7f2", "mainHex_223147")
                border.width: 0
                clip: true

                readonly property real normalizedProgress: Math.max(0, Math.min(1, updater.downloadProgress))
                readonly property bool indeterminateMode: normalizedProgress <= 0.001 || normalizedProgress >= 0.999

                Rectangle {
                    id: updateProgressDeterminate
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    radius: parent.radius
                    visible: !parent.indeterminateMode
                    width: parent.width * parent.normalizedProgress
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: root.themeColorToken("mainHex_2f74ff", "mainHex_3f7cf3") }
                        GradientStop { position: 1.0; color: root.themeColorToken("mainHex_7b53ff", "mainHex_7f72ff") }
                    }
                }

                Rectangle {
                    id: updateProgressIndeterminate
                    width: Math.max(36, parent.width * 0.26)
                    height: parent.height
                    y: 0
                    x: -width
                    radius: parent.radius
                    visible: parent.indeterminateMode
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.2; color: root.themeColorToken("mainHex_2f74ff", "mainHex_3f7cf3") }
                        GradientStop { position: 0.8; color: root.themeColorToken("mainHex_7b53ff", "mainHex_7f72ff") }
                        GradientStop { position: 1.0; color: "transparent" }
                    }

                    NumberAnimation on x {
                        running: updater.checking && updateProgressIndeterminate.visible
                        from: -updateProgressIndeterminate.width
                        to: updateProgressTrack.width
                        duration: 1100
                        loops: Animation.Infinite
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 1
                columnSpacing: 8
                rowSpacing: 8

                Controls.Button {
                    text: I18n.t(updater.checking ? "Checking..." : "Check Now")
                    enabled: !updater.checking
                    Layout.fillWidth: true
                    onClicked: updater.checkForUpdates(true)
                }

                Controls.Button {
                    text: I18n.t(updater.downloadedFilePath.length > 0
                                 ? (root.mobilePlatform
                                    ? (updater.canInstallDownloadedUpdate ? "Install Update" : "Open Installer")
                                    : (updater.canInstallDownloadedUpdate ? "Install & Restart" : "Open Installer"))
                                 : "Download")
                    enabled: updater.updateAvailable && !updater.checking
                    Layout.fillWidth: true
                    onClicked: {
                        if (updater.downloadedFilePath.length > 0) {
                            if (updater.canInstallDownloadedUpdate) {
                                updater.installDownloadedUpdate()
                            } else {
                                updater.openDownloadedUpdate()
                            }
                        } else {
                            updater.downloadUpdate()
                        }
                    }
                }

                Controls.Button {
                    text: I18n.t("Release Page")
                    isDefault: false
                    visible: !root.mobilePlatform
                    enabled: !root.mobilePlatform && updater.releaseUrl.length > 0
                    Layout.fillWidth: true
                    onClicked: updater.openReleasePage()
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        visible: root.settingsSection === "updates" && !vpnController.supportsAutoUpdate && !root.mobilePlatform
        Layout.maximumWidth: settingsFlick.width
        implicitHeight: manualUpdateColumn.implicitHeight + 24
        radius: Colors.innerRadius
        color: root.themeColorToken("mainHex_eff4fb", "mainHex_151c32")
        border.width: 1
        border.color: root.themeColorToken("mainHex_d7e4f6", "mainHex_30435d")

        ColumnLayout {
            id: manualUpdateColumn
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: I18n.t("App Updates")
                color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: 15
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: I18n.t("Current %1", [I18n.ltr(updater.appVersion)])
                color: root.themeColorToken("mainHex_677385", "mainHex_9bb0cb")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 13
            }

            Text {
                Layout.fillWidth: true
                text: I18n.t("Auto-update is not available on this runtime build. Use the release page to get the latest APK or desktop package.")
                color: root.themeColorToken("mainHex_5f6f88", "mainHex_9bb0cb")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            Controls.Button {
                text: I18n.t("Release Page")
                Layout.fillWidth: true
                onClicked: updater.openReleasePage()
            }

            Controls.Button {
                text: I18n.t("Open Project")
                Layout.fillWidth: true
                isDefault: false
                onClicked: Qt.openUrlExternally("https://github.com/genyleap/genyconnect")
            }
        }
    }

}
