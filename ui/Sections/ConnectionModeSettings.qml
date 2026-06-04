/*!
 * @file        ConnectionModeSettingsSection.qml
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
        Layout.fillWidth: true
        visible: root.settingsSection === "connection"
        Layout.maximumWidth: settingsFlick.width
        implicitHeight: modeColumn.implicitHeight + 24
        Layout.preferredHeight: implicitHeight
        radius: Colors.innerRadius
        color: root.themeColorToken("mainHex_f7f9fc", "mainHex_151c32")
        border.width: 0
        border.color: root.themeColorToken("mainHex_e0e6f0", "mainHex_30435d")

        ColumnLayout {
            id: modeColumn
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Text {
                text: "Connection Mode"
                color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 15
                font.bold: true
            }

            Text {
                text: vpnController.useSystemProxy
                      ? "Global mode: " + osNameText() + " routes compatible apps through GenyConnect automatically."
                      : (vpnController.tunMode
                         ? "TUN mode: " + osNameText() + " routes system traffic through Xray TUN without changing proxy settings."
                         : (vpnController.isMobile
                            ? "Mobile mode: runtime uses platform VPN APIs and ignores desktop proxy helpers."
                            : "Clean mode: " + osNameText() + " proxy stays untouched. Only apps set to 127.0.0.1:" + String(vpnController.socksPort) + " use the tunnel."))
                color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        {
                            "title": "Global Mode",
                            "subtitle": vpnController.supportsSystemProxy
                                        ? "Apply system proxy for compatible apps."
                                        : "Unavailable on this runtime (system proxy control is not supported).",
                            "checked": vpnController.supportsSystemProxy && vpnController.useSystemProxy && !vpnController.tunMode,
                            "enabled": vpnController.supportsSystemProxy,
                            "apply": function() {
                                vpnController.tunMode = false
                                vpnController.useSystemProxy = true
                                vpnController.autoDisableSystemProxyOnDisconnect = true
                            }
                        },
                        {
                            "title": "Clean Mode",
                            "subtitle": "Keep OS proxy unchanged and route manual proxy apps only.",
                            "checked": !vpnController.tunMode && (!vpnController.supportsSystemProxy || !vpnController.useSystemProxy),
                            "enabled": true,
                            "apply": function() {
                                vpnController.tunMode = false
                                vpnController.useSystemProxy = false
                                vpnController.autoDisableSystemProxyOnDisconnect = true
                            }
                        },
                        {
                            "title": "TUN Mode",
                            "subtitle": "Route system traffic through Xray TUN.",
                            "checked": vpnController.tunMode,
                            "enabled": vpnController.supportsTun,
                            "apply": function() {
                                vpnController.useSystemProxy = false
                                vpnController.tunMode = true
                            }
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.compact ? 66 : 56
                        radius: 8
                        opacity: modelData.enabled ? 1.0 : 0.58
                        color: modelData.checked
                               ? root.themeColorToken("mainHex_edf4ff", "mainHex_274062")
                               : root.themeColorToken("mainHex_ffffff", "mainHex_22324a")
                        border.width: 0
                        border.color: modelData.checked
                                      ? root.themeColorToken("mainHex_6da2ff", "mainHex_4f86e6")
                                      : root.themeColorToken("mainHex_d9e0ec", "mainHex_3a5470")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 18
                                Layout.preferredHeight: 18
                                radius: 9
                                color: "transparent"
                                border.width: 2
                                border.color: modelData.checked
                                              ? root.themeColorToken("mainHex_2f6ff1", "mainHex_7eb1ff")
                                              : root.themeColorToken("mainHex_9aa6ba", "mainHex_90a6c2")

                                Rectangle {
                                    visible: modelData.checked
                                    anchors.centerIn: parent
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: root.themeColorToken("mainHex_2f6ff1", "mainHex_7eb1ff")
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.title
                                    color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.subtitle
                                    color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 11
                                    wrapMode: root.compact ? Text.WordWrap : Text.NoWrap
                                    elide: root.compact ? Text.ElideNone : Text.ElideRight
                                    maximumLineCount: root.compact ? 2 : 1
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: modelData.enabled
                            cursorShape: modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: modelData.apply()
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.settingsSection === "connection"
        spacing: 10

        Controls.Switch {
            id: autoDisableSwitch
            checked: vpnController.autoDisableSystemProxyOnDisconnect
            enabled: vpnController.supportsSystemProxy && vpnController.useSystemProxy && !vpnController.tunMode
            onToggled: vpnController.autoDisableSystemProxyOnDisconnect = checked
        }

        Text {
            Layout.fillWidth: true
            text: "Auto-disable system proxy when disconnecting"
            color: root.themeColorToken("mainHex_334155", "mainHex_d7e4f6")
            font.family: FontSystem.contentFontFamily
            font.pixelSize: 14
            wrapMode: Text.WordWrap
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.settingsSection === "connection"
        spacing: 10

        Controls.Switch {
            checked: vpnController.killSwitchEnabled
            enabled: vpnController.supportsSystemProxy
            onToggled: vpnController.killSwitchEnabled = checked
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: vpnController.supportsSystemProxy ? "Kill Switch" : "Kill Switch (Unavailable)"
                color: root.themeColorToken("mainHex_334155", "mainHex_d7e4f6")
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: "When disconnected, keep the OS proxy locked to GenyConnect so proxy-aware apps cannot fall back to direct traffic."
                color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.settingsSection === "connection" && !vpnController.supportsSystemProxy
        text: "Global mode and Kill Switch require system proxy control, which is not available on this runtime. Use TUN Mode for full-device routing."
        color: root.themeColorToken("mainHex_a0682a", "mainHex_f4c56a")
        font.family: FontSystem.contentFontFamily
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.settingsSection === "connection"
        spacing: 10

        Controls.Switch {
            checked: vpnController.autoPingProfiles
            onToggled: vpnController.autoPingProfiles = checked
        }

        Text {
            Layout.fillWidth: true
            text: "Auto ping profile endpoints"
            color: root.themeColorToken("mainHex_334155", "mainHex_d7e4f6")
            font.family: FontSystem.contentFontFamily
            font.pixelSize: 14
            wrapMode: Text.WordWrap
        }
    }

    Controls.Button {
        visible: root.settingsSection === "connection"
        text: (vpnController.currentProfileGroup || "All").toLowerCase() === "all"
              ? "Ping Profiles Now"
              : "Ping Current Group"
        Layout.fillWidth: true
        onClicked: vpnController.pingAllProfiles()
    }

    Text {
        Layout.fillWidth: true
        visible: root.settingsSection === "connection"
        text: vpnController.tunMode
              ? (vpnController.isMobile
                 ? "Mobile TUN uses VPN service permissions and native runtime bridge setup."
                 : "TUN mode does not change OS proxy settings. If connect fails, run app with elevated privileges.")
              : (vpnController.useSystemProxy
                 ? "Recommended: keep this enabled to restore system proxy cleanly after tunnel disconnect."
                 : "In Clean mode this option is ignored because system proxy remains disabled.")
        color: root.themeColorToken("mainHex_7f8897", "mainHex_99abc4")
        font.family: FontSystem.contentFontFamily
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }

    Button {
        visible: root.settingsSection === "connection" && vpnController.supportsSystemProxy
        isDefault: false
        text: "Reset System Proxy Now"
        Layout.fillWidth: true
        onClicked: vpnController.cleanSystemProxy()
    }

}
