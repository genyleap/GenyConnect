/*!
 * @file        RoutingRulesSettingsSection.qml
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

    RowLayout {
        Layout.fillWidth: true
        visible: root.settingsSection === "routing"
        spacing: 10

        Controls.Switch {
            checked: vpnController.whitelistMode
            onToggled: vpnController.whitelistMode = checked
        }

        Text {
            text: I18n.t("Whitelist mode")
            color: root.themeColorToken("mainHex_334155", "mainHex_d7e4f6")
            font.family: FontSystem.contentFontFamily
            font.pixelSize: 14
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.settingsSection === "routing"
        text: {
            if (vpnController.tunMode)
                return I18n.t("TUN mode keeps unmatched traffic on VPN by default. Use Direct rules for explicit bypass targets.")
            return vpnController.whitelistMode
                   ? I18n.t("Whitelist mode is ON: unmatched traffic goes Direct, and only rules set to VPN/Tunnel use the VPN.")
                   : I18n.t("Whitelist mode is OFF: unmatched traffic goes through VPN, unless a rule sends it Direct or Block.")
        }
        wrapMode: Text.Wrap
        color: root.themeColorToken("mainHex_8a95a8", "mainHex_9eb2cb")
        font.family: FontSystem.contentFontFamily
        font.pixelSize: 12
    }

    Rectangle {
        Layout.fillWidth: true
        visible: root.settingsSection === "routing"
        height: 1
        color: root.themeColorToken("mainHex_e4e8ef", "mainHex_30435d")
    }

    Text {
        visible: root.settingsSection === "routing"
        text: I18n.t("Routing Rules")
        color: root.themeColorToken("mainHex_667081", "mainHex_9ab0ca")
        font.family: FontSystem.contentFontFamily
        font.pixelSize: 14
    }

    Text {
        Layout.fillWidth: true
        visible: root.settingsSection === "routing"
        text: I18n.t("Create rules with Target Type + Target Value + Action. Rules are evaluated from top to bottom.")
        wrapMode: Text.Wrap
        color: root.themeColorToken("mainHex_8a95a8", "mainHex_9eb2cb")
        font.family: FontSystem.contentFontFamily
        font.pixelSize: 12
    }

    Text {
        Layout.fillWidth: true
        visible: root.settingsSection === "routing"
        text: I18n.t("Tip: choose Action = Direct to bypass VPN for that target.")
        wrapMode: Text.Wrap
        color: root.themeColorToken("mainHex_8a95a8", "mainHex_9eb2cb")
        font.family: FontSystem.contentFontFamily
        font.pixelSize: 12
    }

    Rectangle {
        Layout.fillWidth: true
        visible: root.settingsSection === "routing"
        radius: 14
        color: root.themeColorToken("mainHex_f8fbff", "mainHex_171a2b")
        border.width: 1
        border.color: root.themeColorToken("mainHex_d7e4f5", "mainHex_2e4260")
        implicitHeight: routingRuleEditorColumn.implicitHeight + 20

        ColumnLayout {
            id: routingRuleEditorColumn
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: I18n.t(root.routingRuleEditingId.length > 0 ? "Edit Rule" : "Create Rule")
                color: root.themeColorToken("mainHex_334155", "mainHex_d7e4f6")
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: 13
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Controls.ComboBox {
                    id: routingTypeCombo
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    model: [
                        { "name": "Domain", "value": "domain" },
                        { "name": "IP/CIDR", "value": "ip" },
                        { "name": "App", "value": "app" },
                        { "name": "Process", "value": "process" },
                        { "name": "Protocol", "value": "protocol" }
                    ]
                    currentIndex: {
                        const wanted = (root.routingRuleDraftType || "domain").toLowerCase()
                        const list = model || []
                        for (let i = 0; i < list.length; ++i) {
                            if (((list[i] || {}).value || "").toLowerCase() === wanted)
                                return i
                        }
                        return 0
                    }
                    onActivated: function(activatedIndex) {
                        const item = model[activatedIndex] || {}
                        root.routingRuleDraftType = item.value || "domain"
                        root.routingRuleValidationText = ""
                    }
                }

                Controls.ComboBox {
                    id: routingActionCombo
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    model: [
                        { "name": "VPN", "value": "proxy" },
                        { "name": "Direct", "value": "direct" },
                        { "name": "Block", "value": "block" }
                    ]
                    currentIndex: {
                        const wanted = (root.routingRuleDraftAction || "proxy").toLowerCase()
                        const list = model || []
                        for (let i = 0; i < list.length; ++i) {
                            if (((list[i] || {}).value || "").toLowerCase() === wanted)
                                return i
                        }
                        return 0
                    }
                    onActivated: function(activatedIndex) {
                        const item = model[activatedIndex] || {}
                        root.routingRuleDraftAction = item.value || "proxy"
                        root.routingRuleValidationText = ""
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Controls.ComboBox {
                    id: routingProfileScopeCombo
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    model: vpnController.usageProfileOptions
                    currentIndex: {
                        const wanted = (root.routingRuleDraftProfileId || "").trim()
                        const list = model || []
                        for (let i = 0; i < list.length; ++i) {
                            if ((((list[i] || {}).id || "").trim()) === wanted)
                                return i
                        }
                        return 0
                    }
                    onActivated: function(activatedIndex) {
                        const item = model[activatedIndex] || {}
                        root.routingRuleDraftProfileId = item.id || ""
                    }
                }

                Controls.Switch {
                    checked: root.routingRuleDraftEnabled
                    onToggled: root.routingRuleDraftEnabled = checked
                }

                Text {
                    text: I18n.t(root.routingRuleDraftEnabled ? "Enabled" : "Disabled")
                    color: root.themeColorToken("mainHex_5f7088", "mainHex_9eb2cb")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                }
            }

            Controls.TextField {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                text: root.routingRuleDraftValue
                placeholderText: {
                    const type = (root.routingRuleDraftType || "domain").toLowerCase()
                    if (type === "ip")
                        return I18n.t("Example: 185.143.233.0/24 or geoip:ir")
                    if (type === "app")
                        return I18n.t("Example: C:/Games/game.exe or /Applications/Telegram.app/Contents/MacOS/Telegram")
                    if (type === "process")
                        return I18n.t("Example: telegram.exe or com.apple.Safari")
                    if (type === "protocol")
                        return I18n.t("Example: tcp,udp")
                    return I18n.t("Example: example.com or domain:example.com")
                }
                onTextEdited: {
                    root.routingRuleDraftValue = text
                    root.routingRuleValidationText = ""
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.routingRuleValidationText.length > 0
                text: I18n.t(root.routingRuleValidationText)
                color: root.themeColorToken("mainHex_c65050", "mainHex_ff8e8e")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Controls.Button {
                    Layout.fillWidth: true
                    text: I18n.t(root.routingRuleEditingId.length > 0 ? "Save Rule" : "Add Rule")
                    onClicked: root.saveRoutingRuleDraft()
                }

                Controls.Button {
                    text: I18n.t(root.routingRuleEditingId.length > 0 ? "Cancel" : "Validate")
                    implicitWidth: 88
                    onClicked: {
                        if (root.routingRuleEditingId.length > 0) {
                            root.resetRoutingRuleDraft()
                            return
                        }
                        const validation = vpnController.validateRoutingRule(
                            root.routingRuleDraftType,
                            root.routingRuleDraftValue,
                            root.routingRuleDraftAction
                        ) || {}
                        root.routingRuleValidationText = validation.ok === true
                                                        ? (validation.warning || "Rule is valid.")
                                                        : (validation.error || "Invalid rule.")
                    }
                }

                Controls.Button {
                    text: I18n.t("Clear All")
                    implicitWidth: 88
                    enabled: (root.currentRoutingRules() || []).length > 0
                    onClicked: vpnController.clearRoutingRules()
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        visible: root.settingsSection === "routing"
        radius: 14
        color: root.themeColorToken("mainHex_f8fbff", "mainHex_171a2b")
        border.width: 1
        border.color: root.themeColorToken("mainHex_d7e4f5", "mainHex_2e4260")
        implicitHeight: routingRuleListColumn.implicitHeight + 20

        ColumnLayout {
            id: routingRuleListColumn
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: I18n.t("Active Rules")
                color: root.themeColorToken("mainHex_334155", "mainHex_d7e4f6")
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: 13
                font.bold: true
            }

            ListView {
                id: routingRuleListView
                Layout.fillWidth: true
                Layout.preferredHeight: count > 0 ? Math.min(320, Math.max(140, count * 72)) : 90
                clip: true
                spacing: 6
                model: root.currentRoutingRules()

                delegate: Rectangle {
                    required property int index
                    required property var modelData
                    width: ListView.view.width
                    height: 66
                    radius: 10
                    color: root.themeColorToken("mainHex_ffffff", "mainHex_22324a")
                    border.width: 1
                    border.color: root.themeColorToken("mainHex_dbe3ef", "mainHex_3a5470")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: (index + 1) + ". " + I18n.t(root.routingRuleTypeLabel(modelData.targetType))
                                      + " → " + root.routingRuleActionLabel(modelData.action)
                                color: root.themeColorToken("mainHex_334155", "mainHex_d2def0")
                                font.family: FontSystem.getContentFontBold.name
                                font.pixelSize: 12
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.targetValue || ""
                                color: root.themeColorToken("mainHex_4f6078", "mainHex_9eb2cb")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 11
                                elide: Text.ElideMiddle
                            }

                            Text {
                                Layout.fillWidth: true
                                text: I18n.t("Scope: %1", [I18n.ltr(modelData.profileName || I18n.t("All Profiles"))])
                                      + " • " + (modelData.enabled === false ? "Disabled" : "Enabled")
                                color: root.themeColorToken("mainHex_7f8da2", "mainHex_a8bdd7")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }

                        Controls.Button {
                            Layout.fillWidth: false
                            sizeType: "compact"
                            text: "↑"
                            implicitWidth: 32
                            implicitHeight: 28
                            enabled: index > 0
                            onClicked: vpnController.moveRoutingRule(modelData.id || "", index - 1)
                        }

                        Controls.Button {
                            Layout.fillWidth: false
                            sizeType: "compact"
                            text: "↓"
                            implicitWidth: 32
                            implicitHeight: 28
                            enabled: index < routingRuleListView.count - 1
                            onClicked: vpnController.moveRoutingRule(modelData.id || "", index + 1)
                        }

                        Controls.Button {
                            Layout.fillWidth: false
                            sizeType: "compact"
                            text: I18n.t(modelData.enabled === false ? "Off" : "On")
                            implicitWidth: 44
                            implicitHeight: 28
                            onClicked: vpnController.setRoutingRuleEnabled(modelData.id || "", modelData.enabled === false)
                        }

                        Controls.Button {
                            Layout.fillWidth: false
                            sizeType: "compact"
                            text: I18n.t("Edit")
                            implicitWidth: 46
                            implicitHeight: 28
                            onClicked: root.editRoutingRule(modelData)
                        }

                        Controls.Button {
                            Layout.fillWidth: false
                            sizeType: "compact"
                            text: I18n.t("Dup")
                            implicitWidth: 42
                            implicitHeight: 28
                            onClicked: vpnController.duplicateRoutingRule(modelData.id || "")
                        }

                        Controls.Button {
                            Layout.fillWidth: false
                            sizeType: "compact"
                            text: I18n.t("Del")
                            implicitWidth: 42
                            implicitHeight: 28
                            onClicked: vpnController.removeRoutingRule(modelData.id || "")
                        }
                    }
                }

                Text {
                    anchors.fill: parent
                    visible: routingRuleListView.count === 0
                    text: I18n.t("No rules yet. Add your first rule above.\nExample: Domain example.com → Direct.")
                    color: root.themeColorToken("mainHex_8a95a8", "mainHex_9eb1c9")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.settingsSection === "routing"
        text: {
            if (!vpnController.supportsPerAppRouting) {
                return I18n.t("App/process routing is not supported on this platform runtime.")
            }
            if (Qt.platform.os === "android" || Qt.platform.os === "ios")
                return I18n.t("Mobile platforms currently support domain/IP/protocol rules. App-level routing visibility may be limited by OS/runtime constraints.")
            if (!vpnController.processRoutingSupported) {
                const detected = (vpnController.xrayVersion || "").trim()
                if (detected.length > 0)
                    return detected
                return I18n.t("Desktop app/process routing requires xray-core 26.1.23+ with process matching enabled.")
            }
            return I18n.t("App rules are supported on this runtime. Use absolute executable paths for the most reliable matching.")
        }
        wrapMode: Text.Wrap
        color: (!vpnController.processRoutingSupported && vpnController.supportsPerAppRouting)
               ? root.themeColorToken("mainHex_d97706", "mainHex_ffb454")
               : root.themeColorToken("mainHex_8a95a8", "mainHex_9eb2cb")
        font.family: FontSystem.contentFontFamily
        font.pixelSize: 12
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.settingsSection === "routing" && vpnController.supportsPerAppRouting
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: I18n.t("Running apps")
            color: root.themeColorToken("mainHex_334155", "mainHex_d7e4f6")
            font.family: FontSystem.getContentFontBold.name
            font.pixelSize: 13
            font.bold: true
        }

        Controls.Button {
            text: I18n.t(root.appRuleSuggestionsLoading ? "Loading..." : "Refresh")
            implicitWidth: 82
            implicitHeight: 32
            enabled: vpnController.processRoutingSupported && !root.appRuleSuggestionsLoading
            onClicked: {
                root.refreshAppRuleSuggestions()
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.settingsSection === "routing" && vpnController.supportsPerAppRouting
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: 10
            color: root.themeColorToken("mainHex_f7f9fd", "mainHex_151c32")
            border.width: 0
            border.color: appRuleSearchField.activeFocus
                          ? root.themeColorToken("mainHex_b9ccee", "mainHex_5f87c2")
                          : root.themeColorToken("mainHex_d9e1ef", "mainHex_3a5470")

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: root.iconSearch
                    color: root.themeColorToken("mainHex_8da0ba", "mainHex_9eb4d0")
                    font.family: root.faSolid
                    font.pixelSize: 12
                }

                TextField {
                    id: appRuleSearchField
                    Layout.fillWidth: true
                    padding: 0
                    text: root.appRuleSearchQuery
                    placeholderText: I18n.t("Search running apps")
                    color: root.themeColorToken("mainHex_1f2a3a", "mainHex_edf4ff")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                    selectedTextColor: Colors.mainHex_ffffff
                    selectionColor: root.brandBlue
                    selectByMouse: true
                    background: null
                    onTextEdited: root.appRuleSearchQuery = text
                }
            }
        }

        Controls.Button {
            text: I18n.t("Select visible")
            implicitWidth: 128
            implicitHeight: 32
            Layout.fillWidth: false
            enabled: vpnController.processRoutingSupported
                     && (root.visibleAppRuleSuggestions() || []).length > 0
            onClicked: root.selectVisibleAppSuggestionItems()
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.settingsSection === "routing" && vpnController.supportsPerAppRouting
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: root.appRuleSuggestionsLoading
                  ? "Loading running and installed apps..."
                  : ((root.selectedAppRuleTargets || []).length > 0
                  ? ((root.selectedAppRuleTargets || []).length + " selected")
                  : (((root.visibleAppRuleSuggestions() || []).length > 0)
                     ? "Select apps to apply rules"
                     : "No matching app found"))
            color: root.themeColorToken("mainHex_6b7b92", "mainHex_9eb2cb")
            font.family: FontSystem.contentFontFamily
            font.pixelSize: 12
        }

        RowLayout {
            Layout.fillWidth: true
            visible: !root.compact
            spacing: 8

            Item { Layout.fillWidth: true }

            Controls.Button {
                text: I18n.t("Clear")
                implicitWidth: 62
                implicitHeight: 30
                enabled: (root.selectedAppRuleTargets || []).length > 0
                onClicked: root.clearAppSuggestionSelection()
            }

            Controls.Button {
                text: I18n.t("Direct")
                implicitWidth: 72
                implicitHeight: 30
                enabled: vpnController.processRoutingSupported
                         && (root.selectedAppRuleTargets || []).length > 0
                onClicked: root.appendSelectedAppRules("direct")
            }

            Controls.Button {
                text: I18n.t("Tunnel")
                implicitWidth: 72
                implicitHeight: 30
                enabled: vpnController.processRoutingSupported
                         && (root.selectedAppRuleTargets || []).length > 0
                onClicked: root.appendSelectedAppRules("proxy")
            }

            Controls.Button {
                text: I18n.t("Block")
                implicitWidth: 72
                implicitHeight: 30
                enabled: vpnController.processRoutingSupported
                         && (root.selectedAppRuleTargets || []).length > 0
                onClicked: root.appendSelectedAppRules("block")
            }
        }

        Flow {
            id: routingRuleActionFlow
            Layout.fillWidth: true
            visible: root.compact
            spacing: 6

            Controls.Button {
                width: Math.max(66, Math.floor((routingRuleActionFlow.width - (routingRuleActionFlow.spacing * 3)) / 4))
                implicitHeight: 30
                text: I18n.t("Clear")
                enabled: (root.selectedAppRuleTargets || []).length > 0
                onClicked: root.clearAppSuggestionSelection()
            }

            Controls.Button {
                width: Math.max(66, Math.floor((routingRuleActionFlow.width - (routingRuleActionFlow.spacing * 3)) / 4))
                implicitHeight: 30
                text: I18n.t("Direct")
                enabled: vpnController.processRoutingSupported
                         && (root.selectedAppRuleTargets || []).length > 0
                onClicked: root.appendSelectedAppRules("direct")
            }

            Controls.Button {
                width: Math.max(66, Math.floor((routingRuleActionFlow.width - (routingRuleActionFlow.spacing * 3)) / 4))
                implicitHeight: 30
                text: I18n.t("Tunnel")
                enabled: vpnController.processRoutingSupported
                         && (root.selectedAppRuleTargets || []).length > 0
                onClicked: root.appendSelectedAppRules("proxy")
            }

            Controls.Button {
                width: Math.max(66, Math.floor((routingRuleActionFlow.width - (routingRuleActionFlow.spacing * 3)) / 4))
                implicitHeight: 30
                text: I18n.t("Block")
                enabled: vpnController.processRoutingSupported
                         && (root.selectedAppRuleTargets || []).length > 0
                onClicked: root.appendSelectedAppRules("block")
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        visible: root.settingsSection === "routing" && vpnController.supportsPerAppRouting
        Layout.preferredHeight: 240
        radius: 10
        color: root.themeColorToken("mainHex_f8fbff", "mainHex_171a2b")
        border.width: 0
        border.color: root.themeColorToken("mainHex_dfe7f2", "mainHex_151c32")

        ListView {
            anchors.fill: parent
            anchors.margins: 8
            clip: true
            spacing: 6
            model: root.visibleAppRuleSuggestions() || []

            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                height: 56
                radius: 8
                color: root.isAppSuggestionSelected(modelData)
                       ? root.themeColorToken("mainHex_edf4ff", "mainHex_274062")
                       : root.themeColorToken("mainHex_ffffff", "mainHex_22324a")
                border.width: 0
                border.color: root.isAppSuggestionSelected(modelData)
                             ? root.themeColorToken("mainHex_b8d0ff", "mainHex_578dcf")
                             : root.themeColorToken("mainHex_e1e9f4", "mainHex_3d5876")

                RowLayout {
                    z: 1
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 6

                    Rectangle {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        radius: 13
                        color: root.isAppSuggestionSelected(modelData)
                               ? root.themeColorToken("mainHex_dbe8ff", "mainHex_335178")
                               : root.themeColorToken("mainHex_eff4fb", "mainHex_2a3f5b")
                        border.width: 0
                        border.color: root.isAppSuggestionSelected(modelData)
                                     ? root.themeColorToken("mainHex_9db9f9", "mainHex_659bdf")
                                     : root.themeColorToken("mainHex_d4dfef", "mainHex_496384")

                        Text {
                            anchors.centerIn: parent
                            text: root.appSuggestionInitial(modelData)
                            color: root.themeColorToken("mainHex_40618f", "mainHex_9fc3f2")
                            font.family: FontSystem.getContentFontBold.name
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            width: parent.width
                            text: modelData.process || ""
                            color: root.themeColorToken("mainHex_334155", "mainHex_d2def0")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 12
                            elide: Text.ElideMiddle
                        }

                        Text {
                            width: parent.width
                            text: modelData.source ? I18n.t("Source: %1", [modelData.source]) : ""
                            visible: text.length > 0
                            color: root.themeColorToken("mainHex_95a3b8", "mainHex_a4b6cd")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: (modelData.ruleTarget || "").length > 0
                                  ? ("Match: " + modelData.ruleTarget)
                                  : ""
                            visible: text.length > 0
                                     && (modelData.ruleTarget || "") !== (modelData.process || "")
                            color: root.themeColorToken("mainHex_95a3b8", "mainHex_a4b6cd")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 10
                            elide: Text.ElideMiddle
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 54
                        Layout.preferredHeight: 24
                        radius: 6
                        color: root.themeColorToken("mainHex_f3f7ff", "mainHex_20314b")
                        border.width: 0
                        border.color: root.themeColorToken("mainHex_d4e1f8", "mainHex_4c6990")
                        opacity: vpnController.processRoutingSupported ? 1.0 : 0.6

                        Text {
                            anchors.centerIn: parent
                            text: I18n.t("Direct")
                            color: root.themeColorToken("mainHex_3862a9", "mainHex_8bb7ff")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: vpnController.processRoutingSupported
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: vpnController.appendAppRule("direct", root.appSuggestionRuleKey(modelData))
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 24
                        radius: 6
                        color: root.themeColorToken("mainHex_e9f1ff", "mainHex_1b2f4c")
                        border.width: 0
                        border.color: root.themeColorToken("mainHex_c3d8ff", "mainHex_4770af")
                        opacity: vpnController.processRoutingSupported ? 1.0 : 0.6

                        Text {
                            anchors.centerIn: parent
                            text: I18n.t("Tunnel")
                            color: root.themeColorToken("mainHex_2f6ff1", "mainHex_86b6ff")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: vpnController.processRoutingSupported
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: vpnController.appendAppRule("proxy", root.appSuggestionRuleKey(modelData))
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 50
                        Layout.preferredHeight: 24
                        radius: 6
                        color: root.themeColorToken("mainHex_fff0f0", "mainHex_3b2631")
                        border.width: 0
                        border.color: root.themeColorToken("mainHex_ffd0d0", "mainHex_7d5062")
                        opacity: vpnController.processRoutingSupported ? 1.0 : 0.6

                        Text {
                            anchors.centerIn: parent
                            text: I18n.t("Block")
                            color: root.themeColorToken("mainHex_ca3b3b", "mainHex_ff8da0")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: vpnController.processRoutingSupported
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: vpnController.appendAppRule("block", root.appSuggestionRuleKey(modelData))
                        }
                    }
                }

                MouseArea {
                    z: 0
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: root.toggleAppSuggestionSelection(modelData)
                }
            }
        }
    }

    Controls.TextArea {
        Layout.fillWidth: true
        visible: false
        Layout.preferredHeight: 74
        placeholderText: I18n.t("Tunnel Domains\nexample.com\ndomain:youtube.com\nregexp:.*\\\\.openai\\\\.com$")
        text: vpnController.proxyDomainRules
        onTextChanged: vpnController.proxyDomainRules = text
    }

    Controls.TextArea {
        Layout.fillWidth: true
        visible: false
        Layout.preferredHeight: 74
        placeholderText: I18n.t("Direct Domains\nfull:localhost\ngeosite:private\nexample.org")
        text: vpnController.directDomainRules
        onTextChanged: vpnController.directDomainRules = text
    }

    Controls.TextArea {
        Layout.fillWidth: true
        visible: false
        Layout.preferredHeight: 74
        placeholderText: I18n.t("Block Domains\ngeosite:category-ads-all\nregexp:.*ads.*")
        text: vpnController.blockDomainRules
        onTextChanged: vpnController.blockDomainRules = text
    }

    Controls.TextArea {
        Layout.fillWidth: true
        visible: false
        Layout.preferredHeight: 66
        enabled: vpnController.processRoutingSupported
        opacity: enabled ? 1.0 : 0.6
        placeholderText: I18n.t("Tunnel Apps\nTelegram\nchrome.exe\ncom.apple.Safari")
        text: vpnController.proxyAppRules
        onTextChanged: vpnController.proxyAppRules = text
    }

    Controls.TextArea {
        Layout.fillWidth: true
        visible: false
        Layout.preferredHeight: 66
        enabled: vpnController.processRoutingSupported
        opacity: enabled ? 1.0 : 0.6
        placeholderText: I18n.t("Direct Apps\nFinder\nexplorer.exe\nfirefox")
        text: vpnController.directAppRules
        onTextChanged: vpnController.directAppRules = text
    }

    Controls.TextArea {
        Layout.fillWidth: true
        visible: false
        Layout.preferredHeight: 66
        enabled: vpnController.processRoutingSupported
        opacity: enabled ? 1.0 : 0.6
        placeholderText: I18n.t("Block Apps\nsteam.exe\nDiscord\ncom.apple.Music")
        text: vpnController.blockAppRules
        onTextChanged: vpnController.blockAppRules = text
    }
}
