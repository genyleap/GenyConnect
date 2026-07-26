/*!
 * @file        InterfaceSettingsSection.qml
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
    required property var dashboardStatsSettings
    required property var interfaceThemeSettings
    required property var interfacePrivacySettings
    required property var interfaceLanguageSettings

    Layout.fillWidth: true
    spacing: root.compact ? 14 : 10

    Rectangle {
        Layout.fillWidth: true
        visible: root.settingsSection === "interface"
        implicitHeight: interfaceColumn.implicitHeight + 28
        radius: Colors.innerRadius
        color: root.themeColorToken("mainHex_f7f9fc", "mainHex_151c32")

        ColumnLayout {
            id: interfaceColumn
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Text {
                text: I18n.t("Language & Region")
                color: root.themeColorToken("mainHex_2a3240", "mainHex_d5deeb")
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: 16
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: I18n.t("Language")
                    color: root.themeColorToken("mainHex_334155", "mainHex_c8d3e2")
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: 14
                    font.bold: true
                }

                Controls.ComboBox {
                    id: languageCombo
                    Layout.preferredWidth: root.compact ? 156 : 180
                    Layout.preferredHeight: 40
                    model: I18n.languages
                    currentIndex: I18n.languageIndex(interfaceLanguageSettings.language)
                    onActivated: function(activatedIndex) {
                        interfaceLanguageSettings.language = I18n.languages[activatedIndex].code
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: I18n.t("Changes are applied immediately and saved for the next launch.")
                color: root.themeColorToken("mainHex_8a95a8", "mainHex_8ea0b8")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.themeColorToken("mainHex_e3e8f1", "mainHex_30435d")
            }

            Text {
                text: I18n.t("Dashboard Stats")
                color: root.themeColorToken("mainHex_2a3240", "mainHex_d5deeb")
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: 16
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: I18n.t("Choose visual behavior, privacy display, and the unit used by live transfer-rate indicators.")
                color: root.themeColorToken("mainHex_7c8697", "mainHex_93a2b8")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: I18n.t("Theme")
                    color: root.themeColorToken("mainHex_334155", "mainHex_c8d3e2")
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: 14
                    font.bold: true
                }

                Controls.ComboBox {
                    Layout.preferredWidth: 140
                    Layout.preferredHeight: 40
                    model: root.themeModeOptions
                    currentIndex: root.unitIndex(root.themeModeOptions, interfaceThemeSettings.mode)
                    onActivated: function(activatedIndex) {
                        interfaceThemeSettings.mode = root.themeModeOptions[activatedIndex]
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: I18n.t("System follows macOS/Windows appearance. Light keeps current look.")
                color: root.themeColorToken("mainHex_8a95a8", "mainHex_8ea0b8")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.themeColorToken("mainHex_e3e8f1", "mainHex_30435d")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: I18n.t("IP Privacy")
                    color: root.themeColorToken("mainHex_334155", "mainHex_c8d3e2")
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: 14
                    font.bold: true
                }

                Controls.ComboBox {
                    Layout.preferredWidth: 140
                    Layout.preferredHeight: 40
                    model: root.ipPrivacyOptions
                    currentIndex: root.unitIndex(root.ipPrivacyOptions, interfacePrivacySettings.ipDisplayMode)
                    onActivated: function(activatedIndex) {
                        interfacePrivacySettings.ipDisplayMode = root.ipPrivacyOptions[activatedIndex]
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: I18n.t(interfacePrivacySettings.ipDisplayMode === "Hidden"
                      ? "Home and status panels show *.*.*.* or Endpoint hidden instead of visible IP details."
                      : (interfacePrivacySettings.ipDisplayMode === "Partial Mask"
                         ? "Home and status panels keep enough context for troubleshooting while masking the precise address."
                         : "Visible IP and endpoint details are shown normally."))
                color: root.themeColorToken("mainHex_8a95a8", "mainHex_8ea0b8")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.themeColorToken("mainHex_e3e8f1", "mainHex_30435d")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: I18n.t("Speed Units")
                    color: root.themeColorToken("mainHex_334155", "mainHex_c8d3e2")
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: 14
                    font.bold: true
                }

                Controls.ComboBox {
                    Layout.preferredWidth: 140
                    Layout.preferredHeight: 40
                    model: root.speedUnitOptions
                    currentIndex: root.unitIndex(root.speedUnitOptions, dashboardStatsSettings.speedUnit)
                    onActivated: function(activatedIndex) {
                        dashboardStatsSettings.speedUnit = root.speedUnitOptions[activatedIndex]
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: I18n.t("Use lowercase b for bits and uppercase B for bytes.")
                color: root.themeColorToken("mainHex_8a95a8", "mainHex_8ea0b8")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.themeColorToken("mainHex_e3e8f1", "mainHex_30435d")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: I18n.t("Total Traffic Units")
                    color: root.themeColorToken("mainHex_334155", "mainHex_c8d3e2")
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: 14
                    font.bold: true
                }

                Controls.ComboBox {
                    Layout.preferredWidth: 140
                    Layout.preferredHeight: 40
                    model: root.trafficUnitOptions
                    currentIndex: root.unitIndex(root.trafficUnitOptions, dashboardStatsSettings.trafficUnit)
                    onActivated: function(activatedIndex) {
                        dashboardStatsSettings.trafficUnit = root.trafficUnitOptions[activatedIndex]
                    }
                }
            }
        }
    }

}
