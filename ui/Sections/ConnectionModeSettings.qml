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
import QtQuick.Controls.Basic as T
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
                text: I18n.t("Connection Mode")
                color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 15
                font.bold: true
            }

            Text {
                text: vpnController.useSystemProxy
                      ? I18n.t("Global mode: %1 routes compatible apps through GenyConnect automatically.", [root.osNameText()])
                      : (vpnController.tunMode
                         ? I18n.t("TUN mode: %1 routes system traffic through Xray TUN without changing proxy settings.", [root.osNameText()])
                         : (vpnController.isMobile
                            ? I18n.t("Mobile mode: runtime uses platform VPN APIs and ignores desktop proxy helpers.")
                            : I18n.t("Clean mode: %1 proxy stays untouched. Only apps set to %2 use the tunnel.",
                                     [root.osNameText(), I18n.ltr("127.0.0.1:" + String(vpnController.socksPort))])))
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

                    delegate: T.ItemDelegate {
                        id: modeOption
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: Math.max(72, contentItem.implicitHeight + 24)
                        padding: 12
                        enabled: modelData.enabled
                        hoverEnabled: true
                        focusPolicy: Qt.StrongFocus
                        text: I18n.t(modelData.title)
                        Accessible.description: I18n.t(modelData.subtitle)
                        Accessible.role: Accessible.RadioButton
                        Accessible.checkable: true
                        Accessible.checked: modelData.checked
                        onClicked: modelData.apply()

                        background: Rectangle {
                            radius: Metrics.radiusSm
                            color: modeOption.modelData.checked || modeOption.down ? Colors.dsPrimaryTint
                                   : (modeOption.hovered ? Colors.dsSurfaceSoft : Colors.dsSurface)
                            border.width: modeOption.activeFocus || modeOption.modelData.checked ? 2 : 1
                            border.color: modeOption.activeFocus || modeOption.modelData.checked
                                          ? Colors.dsPrimarySolid : Colors.dsBorderSoft
                            opacity: modeOption.enabled ? 1 : 0.55
                        }

                        contentItem: RowLayout {
                            spacing: Metrics.gap12
                            Rectangle {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                radius: 10
                                color: "transparent"
                                border.width: 2
                                border.color: modeOption.modelData.checked ? Colors.dsPrimarySolid : Colors.dsTextSubtle
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 10
                                    height: 10
                                    radius: 5
                                    color: Colors.dsPrimarySolid
                                    visible: modeOption.modelData.checked
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                spacing: Metrics.gap4
                                Text {
                                    Layout.fillWidth: true
                                    text: modeOption.text
                                    color: Colors.dsText
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: Typography.uiBodyLg
                                    font.weight: Font.DemiBold
                                    wrapMode: Text.WordWrap
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: I18n.t(modeOption.modelData.subtitle)
                                    color: Colors.dsTextMuted
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: Typography.uiBody
                                    wrapMode: Text.WordWrap
                                }
                            }
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
            text: I18n.t("Auto-disable system proxy when disconnecting")
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
                text: I18n.t(vpnController.supportsSystemProxy ? "Kill Switch" : "Kill Switch (Unavailable)")
                color: root.themeColorToken("mainHex_334155", "mainHex_d7e4f6")
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: I18n.t("When disconnected, keep the OS proxy locked to GenyConnect so proxy-aware apps cannot fall back to direct traffic.")
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
        text: I18n.t("Global mode and Kill Switch require system proxy control, which is not available on this runtime. Use TUN Mode for full-device routing.")
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
            text: I18n.t("Auto measure profile latency")
            color: root.themeColorToken("mainHex_334155", "mainHex_d7e4f6")
            font.family: FontSystem.contentFontFamily
            font.pixelSize: 14
            wrapMode: Text.WordWrap
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.settingsSection === "connection"
        spacing: 8

        GridLayout {
            Layout.fillWidth: true
            columns: section.width < 460 ? 1 : 2
            columnSpacing: 12
            rowSpacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: I18n.t("Latency Measurement Mode")
                    color: root.themeColorToken("mainHex_334155", "mainHex_d7e4f6")
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: 14
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    text: I18n.t(vpnController.latencyMeasurementMode === "Endpoint Latency"
                          ? "Diagnostic mode: measures only the raw server endpoint and does not represent VPN route latency."
                          : (vpnController.latencyMeasurementMode === "Route Latency"
                             ? "Measures through the selected VPN/proxy path and represents real user experience."
                             : "Recommended: uses route latency when available, with endpoint latency only as a fallback."))
                    color: vpnController.latencyMeasurementMode === "Endpoint Latency"
                           ? root.themeColorToken("mainHex_a0682a", "mainHex_f4c56a")
                           : root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }

            Controls.ComboBox {
                id: latencyModeCombo
                Layout.fillWidth: true
                Layout.preferredWidth: 190
                Layout.maximumWidth: section.width < 460 ? Number.POSITIVE_INFINITY : 200
                Layout.preferredHeight: 40
                model: ["Auto (Recommended)", "Route Latency", "Endpoint Latency"]
                currentIndex: vpnController.latencyMeasurementMode === "Route Latency"
                              ? 1
                              : (vpnController.latencyMeasurementMode === "Endpoint Latency" ? 2 : 0)
                onActivated: function(activatedIndex) {
                    vpnController.latencyMeasurementMode = model[activatedIndex]
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: I18n.t("Auto: route first, endpoint fallback. Route Latency: real VPN/proxy path and Best Proxy ranking. Endpoint Latency: raw server troubleshooting only.")
            color: root.themeColorToken("mainHex_8a95a8", "mainHex_8ea0b8")
            font.family: FontSystem.contentFontFamily
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
    }

    Controls.Button {
        visible: root.settingsSection === "connection"
        text: I18n.t((vpnController.currentProfileGroup || "All").toLowerCase() === "all"
              ? "Measure Profiles Now"
              : "Measure Current Group")
        Layout.fillWidth: true
        onClicked: vpnController.pingAllProfiles()
    }

    Text {
        Layout.fillWidth: true
        visible: root.settingsSection === "connection"
        text: I18n.t(vpnController.tunMode
              ? (vpnController.isMobile
                 ? "Mobile TUN uses VPN service permissions and native runtime bridge setup."
                 : "TUN mode does not change OS proxy settings. If connect fails, run app with elevated privileges.")
              : (vpnController.useSystemProxy
                 ? "Recommended: keep this enabled to restore system proxy cleanly after tunnel disconnect."
                 : "In Clean mode this option is ignored because system proxy remains disabled."))
        color: root.themeColorToken("mainHex_7f8897", "mainHex_99abc4")
        font.family: FontSystem.contentFontFamily
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }

    Controls.Button {
        visible: root.settingsSection === "connection" && vpnController.supportsSystemProxy
        isDefault: false
        text: I18n.t("Reset System Proxy Now")
        Layout.fillWidth: true
        onClicked: vpnController.cleanSystemProxy()
    }

}
