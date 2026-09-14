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
                id: routingTargetField
                Accessible.name: I18n.t("Target Value")
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                text: root.routingRuleDraftValue
                placeholderText: {
                    const type = (root.routingRuleDraftType || "domain").toLowerCase()
                    if (type === "ip")
                        return I18n.t("Example: 185.143.233.0/24 or geoip:ir")
                    if (type === "app")
                        return I18n.t("Example: C:/Games/game.exe or /usr/bin/firefox")
                    if (type === "process")
                        return I18n.t("Example: telegram.exe or firefox")
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

            GridLayout {
                Layout.fillWidth: true
                columns: section.width < 420 ? 1 : 3
                columnSpacing: 8
                rowSpacing: 8

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
                text: I18n.t("Saved Rules")
                color: root.themeColorToken("mainHex_334155", "mainHex_d7e4f6")
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: 13
                font.bold: true
            }

            ListView {
                id: routingRuleListView
                Layout.fillWidth: true
                Layout.preferredHeight: count > 0 ? Math.max(120, Math.min(440, contentHeight)) : 90
                clip: true
                spacing: 6
                model: root.currentRoutingRules()

                delegate: Rectangle {
                    id: ruleCard
                    required property int index
                    required property var modelData
                    readonly property real scrollInset: routingRulesScrollBar.visible ? routingRulesScrollBar.width + Metrics.gap4 : 0
                    x: I18n.isRtl ? scrollInset : 0
                    width: Math.max(0, ListView.view.width - scrollInset)
                    implicitHeight: ruleContent.implicitHeight + 24
                    height: implicitHeight
                    radius: Metrics.radiusSm
                    color: Colors.dsSurface
                    border.color: modelData.available === false ? Colors.dsWarning : Colors.dsBorderSoft

                    ColumnLayout {
                        id: ruleContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Metrics.gap12
                        spacing: Metrics.gap8

                        Text {
                            Layout.fillWidth: true
                            text: I18n.localizeDigits(ruleCard.index + 1) + ". "
                                  + I18n.t(root.routingRuleTypeLabel(ruleCard.modelData.targetType))
                                  + " → " + I18n.t(root.routingRuleActionLabel(ruleCard.modelData.action))
                            color: Colors.dsText
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: Typography.uiBodyLg
                            font.weight: Font.DemiBold
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: I18n.ltr(ruleCard.modelData.targetValue || "")
                            textFormat: Text.PlainText
                            color: Colors.dsTextMuted
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: Typography.uiBody
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }

                        Text {
                            Layout.fillWidth: true
                            text: I18n.t("Scope: %1", [ruleCard.modelData.profileName || I18n.t("All Profiles")])
                                  + " • " + I18n.t(ruleCard.modelData.enabled === false ? "Disabled" : "Enabled")
                            color: Colors.dsTextMuted
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: Typography.uiBodySm
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: ruleCard.modelData.available === false
                            text: I18n.t(ruleCard.modelData.unavailableReason || "App/process routing is not supported on this platform runtime.")
                            color: Colors.dsWarning
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: Typography.uiBody
                            wrapMode: Text.WordWrap
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: Metrics.gap6
                            layoutDirection: I18n.isRtl ? Qt.RightToLeft : Qt.LeftToRight
                            LayoutMirroring.enabled: false
                            LayoutMirroring.childrenInherit: true

                            Controls.CircleIconButton {
                                diameter: 36
                                elevated: false
                                iconText: "\uf062"
                                iconFontFamily: root.faSolid
                                iconPixelSize: 13
                                accessibleName: I18n.t("Move up")
                                enabled: ruleCard.index > 0
                                onClicked: vpnController.moveRoutingRule(ruleCard.modelData.id || "", ruleCard.index - 1)
                            }
                            Controls.CircleIconButton {
                                diameter: 36
                                elevated: false
                                iconText: "\uf063"
                                iconFontFamily: root.faSolid
                                iconPixelSize: 13
                                accessibleName: I18n.t("Move down")
                                enabled: ruleCard.index < routingRuleListView.count - 1
                                onClicked: vpnController.moveRoutingRule(ruleCard.modelData.id || "", ruleCard.index + 1)
                            }
                            Controls.CircleIconButton {
                                diameter: 36
                                elevated: false
                                iconText: ruleCard.modelData.enabled === false ? "\uf04b" : "\uf04c"
                                iconFontFamily: root.faSolid
                                iconPixelSize: 13
                                accessibleName: I18n.t(ruleCard.modelData.enabled === false ? "Enable rule" : "Disable rule")
                                onClicked: vpnController.setRoutingRuleEnabled(ruleCard.modelData.id || "", ruleCard.modelData.enabled === false)
                            }
                            Controls.CircleIconButton {
                                diameter: 36
                                elevated: false
                                iconText: "\uf304"
                                iconFontFamily: root.faSolid
                                iconPixelSize: 13
                                accessibleName: I18n.t("Edit")
                                onClicked: {
                                    root.editRoutingRule(ruleCard.modelData)
                                    root.settingsFlick.contentY = 0
                                    routingTargetField.forceActiveFocus()
                                }
                            }
                            Controls.CircleIconButton {
                                diameter: 36
                                elevated: false
                                iconText: "\uf0c5"
                                iconFontFamily: root.faSolid
                                iconPixelSize: 13
                                accessibleName: I18n.t("Duplicate rule")
                                onClicked: vpnController.duplicateRoutingRule(ruleCard.modelData.id || "")
                            }
                            Controls.CircleIconButton {
                                diameter: 36
                                elevated: false
                                iconText: "\uf2ed"
                                iconFontFamily: root.faSolid
                                iconPixelSize: 13
                                iconColor: Colors.dsDanger
                                accessibleName: I18n.t("Delete rule")
                                onClicked: vpnController.removeRoutingRule(ruleCard.modelData.id || "")
                            }
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    id: routingRulesScrollBar
                    policy: ScrollBar.AsNeeded
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
                id: appCard
                required property var modelData
                readonly property real scrollInset: appsScrollBar.visible ? appsScrollBar.width + Metrics.gap4 : 0
                x: I18n.isRtl ? scrollInset : 0
                width: Math.max(0, ListView.view.width - scrollInset)
                height: appCardColumn.implicitHeight + 16
                radius: Metrics.radiusSm
                color: root.isAppSuggestionSelected(modelData) ? Colors.dsPrimaryTint : Colors.dsSurface
                border.color: root.isAppSuggestionSelected(modelData) ? Colors.dsPrimarySolid : Colors.dsBorderSoft

                ColumnLayout {
                    id: appCardColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Metrics.gap8
                    spacing: Metrics.gap8

                    T.ItemDelegate {
                        Layout.fillWidth: true
                        implicitHeight: appLabelColumn.implicitHeight + 12
                        padding: 6
                        checkable: true
                        checked: root.isAppSuggestionSelected(appCard.modelData)
                        enabled: vpnController.processRoutingSupported
                        Accessible.name: appCard.modelData.process || ""
                        Accessible.description: appCard.modelData.ruleTarget || ""
                        onClicked: root.toggleAppSuggestionSelection(appCard.modelData)
                        background: Rectangle {
                            radius: Metrics.radiusXs
                            color: "transparent"
                            border.width: parent.activeFocus ? 2 : 0
                            border.color: Colors.dsPrimarySolid
                        }
                        contentItem: RowLayout {
                            spacing: Metrics.gap8
                            Text {
                                text: root.isAppSuggestionSelected(appCard.modelData) ? "\uf14a" : "\uf0c8"
                                font.family: root.faSolid
                                font.pixelSize: 18
                                color: Colors.dsPrimarySolid
                            }
                            ColumnLayout {
                                id: appLabelColumn
                                Layout.fillWidth: true
                                spacing: Metrics.gap4
                                Text {
                                    Layout.fillWidth: true
                                    text: appCard.modelData.process || ""
                                    textFormat: Text.PlainText
                                    color: Colors.dsText
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: Typography.uiBodyLg
                                    font.weight: Font.DemiBold
                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: I18n.ltr(root.appSuggestionRuleKey(appCard.modelData))
                                    textFormat: Text.PlainText
                                    color: Colors.dsTextMuted
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: Typography.uiBodySm
                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Metrics.gap6
                        Repeater {
                            model: [ { name: "Direct", action: "direct" }, { name: "Tunnel", action: "proxy" }, { name: "Block", action: "block" } ]
                            delegate: Controls.Button {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                sizeType: "compact"
                                isDefault: false
                                text: I18n.t(modelData.name)
                                enabled: vpnController.processRoutingSupported
                                onClicked: vpnController.appendAppRule(modelData.action, root.appSuggestionRuleKey(appCard.modelData))
                            }
                        }
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {
                id: appsScrollBar
                policy: ScrollBar.AsNeeded
            }
        }
    }

}
