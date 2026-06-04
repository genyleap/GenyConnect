/*!
 * @file        CacheSettingsSection.qml
 *
 * @author      Kambiz Asadzadeh
 * @since       09 Feb 2026
 * @copyright   Copyright (c) 2026 Genyleap.
 * @license     See LICENSE in repository root.
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../Core"
import "../Controls" as Controls

Rectangle {
    id: cacheSection

    property bool busy: false
    property real progress: 0
    required property var root
    property string statusText: ""
    required property var vpnController

    Layout.fillWidth: true
    border.color: root.themeColorToken("mainHex_e0e6f0", "mainHex_30435d")
    border.width: 0
    color: root.themeColorToken("mainHex_f7f9fc", "mainHex_151c32")
    implicitHeight: cacheSettingsColumn.implicitHeight + 24
    radius: Colors.innerRadius

    Timer {
        id: networkCacheRunTimer

        interval: 90
        repeat: false

        onTriggered: {
            cacheSection.statusText = "Applying system network refresh...";
            cacheSection.progress = Math.max(cacheSection.progress, 0.22);
            const result = vpnController.clearNetworkCache();
            const message = (result && result.message) ? result.message : "Network cache action completed.";
            cacheSection.progress = 1.0;
            cacheSection.busy = false;
            cacheSection.statusText = message;
            root.showSettingsFeedback(message);
        }
    }
    Timer {
        id: networkCacheProgressTimer

        interval: 180
        repeat: true
        running: cacheSection.busy

        onTriggered: {
            if (!cacheSection.busy)
                return;
            cacheSection.progress = Math.min(0.88, cacheSection.progress + 0.07);
            if (cacheSection.progress > 0.62)
                cacheSection.statusText = "Waiting for the operating system...";
            else if (cacheSection.progress > 0.34)
                cacheSection.statusText = "Refreshing DNS and IP neighbor state...";
        }
    }
    ColumnLayout {
        id: cacheSettingsColumn

        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredHeight: 36
                Layout.preferredWidth: 36
                color: root.themeColorToken("mainHex_e9f1ff", "mainHex_20314b")
                radius: 18

                Text {
                    anchors.centerIn: parent
                    color: root.themeColorToken("mainHex_2f6ff1", "mainHex_8bb7ff")
                    font.family: root.faSolid
                    font.pixelSize: 14
                    text: "\uf1c0"
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                    font.bold: true
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: 16
                    text: "Network Cache"
                }
                Text {
                    Layout.fillWidth: true
                    color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                    text: "Clear the OS DNS resolver cache and IP neighbor cache for this device."
                    wrapMode: Text.WordWrap
                }
            }
        }
        Text {
            Layout.fillWidth: true
            color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
            font.family: FontSystem.contentFontFamily
            font.pixelSize: 12
            text: {
                if (Qt.platform.os === "windows")
                    return "Windows uses ipconfig and netsh and may show a UAC prompt.";
                if (Qt.platform.os === "osx")
                    return "macOS uses dscacheutil, mDNSResponder, and arp and may ask for administrator permission.";
                if (Qt.platform.os === "linux")
                    return "Linux uses resolvectl/systemd-resolve/nscd when available plus ip neigh flush all; pkexec or root may be required.";
                if (Qt.platform.os === "android")
                    return "Android refreshes GenyConnect's VPN network through VpnService and asks the framework to re-evaluate connectivity.";
                if (Qt.platform.os === "ios")
                    return "iOS does not expose global DNS or IP neighbor cache clearing to apps.";
                return "This platform has a dedicated runtime response when the action is run.";
            }
            wrapMode: Text.WordWrap
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 7
            visible: cacheSection.busy

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    color: root.themeColorToken("mainHex_2f6ff1", "mainHex_8bb7ff")
                    font.family: root.faSolid
                    font.pixelSize: 13
                    text: "\uf2f1"

                    RotationAnimation on rotation {
                        duration: 950
                        from: 0
                        loops: Animation.Infinite
                        running: cacheSection.busy
                        to: 360
                    }
                }
                Text {
                    Layout.fillWidth: true
                    color: root.themeColorToken("mainHex_52627a", "mainHex_aac0dc")
                    elide: Text.ElideRight
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                    maximumLineCount: 2
                    text: cacheSection.statusText.length > 0 ? cacheSection.statusText : "Preparing network cache cleanup..."
                    wrapMode: Text.WordWrap
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 5
                color: root.themeColorToken("mainHex_d6e2f4", "mainHex_233854")
                radius: 3

                Rectangle {
                    color: root.themeColorToken("mainHex_2f6ff1", "mainHex_7faeff")
                    height: parent.height
                    radius: parent.radius
                    width: parent.width * Math.max(0.04, Math.min(1.0, cacheSection.progress))

                    Behavior on width {
                        NumberAnimation {
                            duration: 160
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }
        }
        Controls.PrimaryButton {
            Layout.fillWidth: true
            compact: true
            enabled: !cacheSection.busy
            glyph: cacheSection.busy ? "" : "\uf2f1"
            text: cacheSection.busy ? "Clearing..." : "Clear Network Cache"

            onClicked: {
                root.settingsFeedbackText = "";
                cacheSection.busy = true;
                cacheSection.progress = 0.08;
                cacheSection.statusText = "Preparing network cache cleanup...";
                networkCacheRunTimer.restart();
            }
        }
        Text {
            Layout.fillWidth: true
            color: (vpnController.lastError || "").trim().length > 0 ? root.themeColorToken("mainHex_b42318", "mainHex_ff8a8a") : root.themeColorToken("mainHex_2c8b57", "mainHex_5adf97")
            font.family: FontSystem.contentFontFamily
            font.pixelSize: 12
            text: root.settingsFeedbackText
            visible: root.settingsFeedbackText.length > 0
            wrapMode: Text.WordWrap
        }
    }
}
