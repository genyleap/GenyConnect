import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtCore

import GenyConnect 1.0

import "Core"
import "Controls" as Controls

ApplicationWindow {
    id: root

    visible: true
    width: 430
    height: 760
    minimumWidth: 430
    maximumWidth: 430
    minimumHeight: 760
    maximumHeight: 760
    flags: Qt.Window | Qt.WindowTitleHint | Qt.WindowSystemMenuHint | Qt.WindowMinimizeButtonHint | Qt.WindowCloseButtonHint

    title: "GenyConnect (Build " + updater.appVersion + ") - " + osNameText()

    color: Colors.gcWindow
    font.family: FontSystem.contentFontFamily

    property bool compact: true
    readonly property string faSolid: FontSystem.getAwesomeSolid.name

    readonly property string iconGrid: "\uf00a"
    readonly property string iconShield: "\uf3ed"
    readonly property string iconGear: "\uf013"
    readonly property string iconSetting: "\uf1de"
    readonly property string iconInfo: "\uf05a"
    readonly property string iconHistory: "\uf1da"
    readonly property string iconClose: "\uf00d"
    readonly property string iconSpeed: "\uf625"
    readonly property string iconUsage: "\uf201"
    readonly property string iconPing: "\ue06f"
    readonly property string iconKeyboard: "\uf11c"
    readonly property string iconImport: "\uf56f"
    readonly property string iconChevronDown: "\uf078"
    readonly property string iconTrash: "\uf1f8"
    readonly property string iconPlus: "\uf067"
    readonly property string iconMinus: "\uf068"
    readonly property string iconCopy: "\uf0c5"
    readonly property string iconSearch: "\uf002"
    readonly property string iconFileLines: "\uf15c"
    readonly property color brandBlue: Colors.secondry
    readonly property color brandCyan: Colors.brandBlue
    readonly property color brandViolet: Colors.brandPurple
    readonly property color brandInk: Colors.gcTextStrong

    property string selectedServerLabel: vpnController.currentProfileIndex >= 0
                                         ? "Selected Profile"
                                         : "Select Location"
    property string selectedServerMeta: vpnController.currentProfileIndex >= 0
                                        ? "Profile is selected"
                                        : "Import and select a profile"
    property string selectedServerFlag: vpnController.currentProfileIndex >= 0 ? "🇺🇸" : "🌐"

    property string mapPrimarySource: "qrc:/ui/Resources/image/map.png"
    property string mapSecondarySource: "qrc:/images/map.png"
    property bool mapLoaded: false

    property string importDraft: ""
    property int downRateBytesPerSec: 0
    property int upRateBytesPerSec: 0
    property int lastRxBytesSample: 0
    property int lastTxBytesSample: 0
    property bool rateSampleInitialized: false
    property string tunConflictPopupText: ""
    property string tunConflictPopupSignature: ""
    property string profileSearchQuery: ""
    property string notifiedUpdateVersion: ""
    property string subscriptionGroupDraft: "General"
    property bool importWaitingForSubscription: false
    property string importStatusText: ""
    property string importStatusKind: "idle"
    property string customDnsDraft: ""
    property bool customDnsDirty: false
    property bool allowCloseExit: false
    property var profilePopupAnchor: null
    property int sessionSeconds: 0
    property string settingsSection: "main"
    property var appRuleSuggestions: []
    property var selectedAppRuleProcesses: []
    property string appRuleSearchQuery: ""
    property string usageHistoryPeriod: "day"
    property string usagePanelTab: "current"
    property int usageRefreshNonce: 0
    property string compactProfileFilter: "All"
    property int editProfileRow: -1
    property string editProfileName: ""
    property string editProfileGroup: ""
    property real speedGaugeDisplayMbps: 0.0
    property string speedGaugeRangePreset: "Auto"
    property var downRateHistoryMbps: []
    property var upRateHistoryMbps: []
    property int rateHistoryMaxPoints: 24

    readonly property var speedUnitOptions: ["Auto", "bps", "Kbps", "Mbps", "Gbps", "B/s", "KB/s", "MB/s", "GB/s"]
    readonly property var trafficUnitOptions: ["Auto", "B", "KB", "MB", "GB", "TB"]
    readonly property var themeModeOptions: ["System", "Light", "Dark"]
    readonly property bool systemPrefersDark: Qt.application.styleHints.colorScheme === Qt.ColorScheme.Dark
    readonly property bool darkThemeEnabled: interfaceThemeSettings.mode === "Dark"
                                         || (interfaceThemeSettings.mode === "System" && systemPrefersDark)
    Settings {
        id: dashboardStatsSettings
        category: "Interface/DashboardStats"
        property string speedUnit: "Auto"
        property string trafficUnit: "Auto"
    }

    Settings {
        id: interfaceThemeSettings
        category: "Interface/Theme"
        property string mode: "System"
    }

    onClosing: function(closeEvent) {
        if (allowCloseExit) {
            return
        }
        closeEvent.accepted = false
        root.hide()
    }

    function themeColor(lightColor, darkColor) {
        return darkThemeEnabled ? darkColor : lightColor
    }

    function themeColorToken(lightToken, darkToken) {
        const key = lightToken + "|" + darkToken
        switch (key) {
        case "mainHex_ffffff|mainHex_090b14": return Colors.gcSurface0
        case "mainHex_f7f9fc|mainHex_151c32": return Colors.gcSurface1
        case "mainHex_f7f9fd|mainHex_151c32": return Colors.gcSurface2
        case "mainHex_ffffff|mainHex_22324a": return Colors.gcSurfacePanel
        case "mainHex_f3f6fb|mainHex_20314b": return Colors.gcPanelSoft
        case "mainHex_eaf2ff|mainHex_223753": return Colors.gcPanelTint

        case "mainHex_e0e6f0|mainHex_30435d": return Colors.gcBorder0
        case "mainHex_d8dde8|mainHex_151c32": return Colors.gcBorder1
        case "mainHex_d6dde8|mainHex_151c32": return Colors.gcBorder2
        case "mainHex_d9e0ed|mainHex_151c32": return Colors.gcBorder3
        case "mainHex_dfe7f2|mainHex_151c32": return Colors.gcBorder4
        case "mainHex_d5deec|mainHex_151c32": return Colors.gcBorder5

        case "mainHex_2a3240|mainHex_d7e4f6": return Colors.gcTextStrong
        case "mainHex_334155|mainHex_d7e4f6": return Colors.gcTextPrimary
        case "mainHex_1f2530|mainHex_d8e1f0": return Colors.gcTextBody
        case "mainHex_667487|mainHex_9bb0cb": return Colors.gcTextMuted
        case "mainHex_667081|mainHex_9ab0ca": return Colors.gcTextMutedAlt
        case "mainHex_7c8697|mainHex_9bb0cb": return Colors.gcTextSubtle
        case "mainHex_8f97a6|mainHex_9eb2cb": return Colors.gcTextSubtleAlt
        case "mainHex_647891|mainHex_9fb4cd": return Colors.gcTextMeta

        case "mainHex_2f6ff1|mainHex_3a7bff": return Colors.secondry
        case "mainHex_2a3240|mainHex_9ec1ff": return Colors.secondry
        case "mainHex_cb4f4f|mainHex_ff8e8e": return Colors.gcDanger
        }

        const light = Colors[lightToken]
        const dark = Colors[darkToken]
        if (light !== undefined && dark !== undefined)
            return darkThemeEnabled ? dark : light
        if (dark !== undefined)
            return dark
        if (light !== undefined)
            return light
        return darkThemeEnabled ? Colors.gcTextPrimary : Colors.gcTextBody
    }

    function stateText() {
        if (vpnController.connectionState === ConnectionState.Connecting)
            return "Connecting"
        if (vpnController.connectionState === ConnectionState.Connected)
            return "Connected"
        if (vpnController.connectionState === ConnectionState.Error)
            return "Error"
        return "Disconnected"
    }

    function connectButtonText() {
        if (vpnController.connectionState === ConnectionState.Connecting)
            return "Connecting"
        if (vpnController.connectionState === ConnectionState.Connected)
            return "Disconnect"
        return "Connect"
    }

    function guessFlag(label) {
        const text = (label || "").toLowerCase()
        if (text.indexOf("us") >= 0 || text.indexOf("los angeles") >= 0 || text.indexOf("america") >= 0)
            return "🇺🇸"
        if (text.indexOf("uk") >= 0 || text.indexOf("london") >= 0 || text.indexOf("britain") >= 0)
            return "🇬🇧"
        if (text.indexOf("de") >= 0 || text.indexOf("germany") >= 0 || text.indexOf("berlin") >= 0)
            return "🇩🇪"
        if (text.indexOf("fr") >= 0 || text.indexOf("france") >= 0 || text.indexOf("paris") >= 0)
            return "🇫🇷"
        if (text.indexOf("it") >= 0 || text.indexOf("italy") >= 0 || text.indexOf("milan") >= 0)
            return "🇮🇹"
        if (text.indexOf("tr") >= 0 || text.indexOf("turkey") >= 0 || text.indexOf("istanbul") >= 0)
            return "🇹🇷"
        if (text.indexOf("ir") >= 0 || text.indexOf("iran") >= 0 || text.indexOf("tehran") >= 0)
            return "🇮🇷"
        return "🌐"
    }

    function flagAliases(flagEmoji) {
        if (flagEmoji === "🇺🇸")
            return ["us", "usa", "united states", "america", "los angeles", "new york"]
        if (flagEmoji === "🇬🇧")
            return ["uk", "united kingdom", "britain", "england", "london"]
        if (flagEmoji === "🇩🇪")
            return ["de", "germany", "berlin", "frankfurt"]
        if (flagEmoji === "🇫🇷")
            return ["fr", "france", "paris"]
        if (flagEmoji === "🇮🇹")
            return ["it", "italy", "milan", "rome"]
        if (flagEmoji === "🇹🇷")
            return ["tr", "turkey", "istanbul"]
        if (flagEmoji === "🇮🇷")
            return ["ir", "iran", "tehran"]
        return ["global", "world", "any"]
    }

    function normalizeProfileGroup(rawGroup) {
        const text = (rawGroup || "").trim()
        if (text.length === 0)
            return "General"
        if (text.toLowerCase() === "all")
            return "General"
        return text
    }

    function profileGroupVisible(groupName) {
        if (!profileGroupEnabled(groupName))
            return false
        if (profilePopup && profilePopup.opened && root.compact) {
            const filter = (compactProfileFilter || "All").trim().toLowerCase()
            if (filter === "all")
                return true
            return profileGroupBadgeText(groupName).trim().toLowerCase() === filter
        }
        const current = (vpnController.currentProfileGroup || "All").trim().toLowerCase()
        if (current.length === 0 || current === "all")
            return true
        return normalizeProfileGroup(groupName).toLowerCase() === current
    }

    function importSelectableGroups() {
        const rawGroups = vpnController.profileGroups || []
        const names = []
        const seen = {}
        for (let i = 0; i < rawGroups.length; ++i) {
            const name = (rawGroups[i] || "").trim()
            if (name.length === 0 || name.toLowerCase() === "all")
                continue
            const key = name.toLowerCase()
            if (seen[key] !== true) {
                seen[key] = true
                names.push(name)
            }
        }
        if (seen["general"] !== true)
            names.unshift("General")
        return names
    }

    function normalizeImportGroupName(rawGroup) {
        const typed = (rawGroup || "").trim()
        const fallback = "General"
        if (typed.length === 0 || typed.toLowerCase() === "all")
            return fallback

        const existing = importSelectableGroups()
        const key = typed.toLowerCase()
        for (let i = 0; i < existing.length; ++i) {
            const candidate = (existing[i] || "").trim()
            if (candidate.toLowerCase() === key)
                return candidate
        }
        return typed
    }

    function isProtectedGroup(groupName) {
        const name = (groupName || "").trim().toLowerCase()
        return name === "all" || name === "general"
    }

    function syncCustomDnsDraftFromController() {
        customDnsDraft = vpnController.customDnsServers || ""
        customDnsDirty = false
    }

    function customDnsEntries() {
        const raw = (customDnsDraft || "")
        .split(/[\n,;]+/)
        .map(function(entry) { return entry.trim() })
        .filter(function(entry) { return entry.length > 0 })

        const out = []
        const seen = {}
        for (let i = 0; i < raw.length; ++i) {
            const key = raw[i].toLowerCase()
            if (seen[key] === true)
                continue
            seen[key] = true
            out.push(raw[i])
        }
        return out
    }

    function dnsDraftContains(server) {
        const value = (server || "").trim().toLowerCase()
        if (value.length === 0)
            return false
        const items = customDnsEntries()
        for (let i = 0; i < items.length; ++i) {
            if (items[i].toLowerCase() === value)
                return true
        }
        return false
    }

    function setDnsDraftContains(server, enabled) {
        const value = (server || "").trim()
        if (value.length === 0)
            return

        const items = customDnsEntries()
        const lower = value.toLowerCase()
        const filtered = items.filter(function(entry) { return entry.toLowerCase() !== lower })

        if (enabled)
            filtered.push(value)

        customDnsDraft = filtered.join("\n")
        customDnsDirty = customDnsDraft.trim() !== (vpnController.customDnsServers || "").trim()
    }

    function appendDnsToDraft(server) {
        setDnsDraftContains(server, true)
    }

    function isAppSuggestionSelected(processName) {
        const key = (processName || "").trim().toLowerCase()
        if (key.length === 0)
            return false
        for (let i = 0; i < selectedAppRuleProcesses.length; ++i) {
            if ((selectedAppRuleProcesses[i] || "").toLowerCase() === key)
                return true
        }
        return false
    }

    function toggleAppSuggestionSelection(processName) {
        const raw = (processName || "").trim()
        const key = raw.toLowerCase()
        if (key.length === 0)
            return
        const current = selectedAppRuleProcesses.slice(0)
        const next = []
        let removed = false
        for (let i = 0; i < current.length; ++i) {
            const valueRaw = (current[i] || "").trim()
            const value = valueRaw.toLowerCase()
            if (!removed && value === key) {
                removed = true
                continue
            }
            next.push(valueRaw)
        }
        if (!removed)
            next.push(raw)
        selectedAppRuleProcesses = next
    }

    function clearAppSuggestionSelection() {
        selectedAppRuleProcesses = []
    }

    function visibleAppRuleSuggestions() {
        const items = appRuleSuggestions || []
        const rawQuery = (appRuleSearchQuery || "").trim().toLowerCase()
        if (rawQuery.length === 0)
            return items
        const filtered = []
        for (let i = 0; i < items.length; ++i) {
            const item = items[i] || {}
            const process = (item.process || "").toLowerCase()
            const source = (item.source || "").toLowerCase()
            if (process.indexOf(rawQuery) >= 0 || source.indexOf(rawQuery) >= 0)
                filtered.push(item)
        }
        return filtered
    }

    function selectVisibleAppSuggestionItems() {
        const items = visibleAppRuleSuggestions()
        const next = []
        const seen = {}
        for (let i = 0; i < items.length; ++i) {
            const process = ((items[i] || {}).process || "").trim()
            const key = process.toLowerCase()
            if (key.length === 0 || seen[key] === true)
                continue
            seen[key] = true
            next.push(process)
        }
        selectedAppRuleProcesses = next
    }

    function appSuggestionInitial(processName) {
        const cleaned = (processName || "").trim()
        if (cleaned.length === 0)
            return "•"
        const first = cleaned.charAt(0)
        if (first >= "0" && first <= "9")
            return "#"
        return first.toUpperCase()
    }

    function appendSelectedAppRules(target) {
        const list = selectedAppRuleProcesses.slice(0)
        for (let i = 0; i < list.length; ++i)
            vpnController.appendAppRule(target, list[i] || "")
        clearAppSuggestionSelection()
    }

    function findProfileGroupItem(groupName) {
        const normalized = normalizeProfileGroup(groupName).toLowerCase()
        const items = vpnController.profileGroupItems || []
        for (let i = 0; i < items.length; ++i) {
            const item = items[i]
            if (((item.name || "").toLowerCase()) === normalized)
                return item
        }
        return null
    }

    function profileGroupBadgeText(groupName) {
        const item = findProfileGroupItem(groupName)
        if (!item || !item.badge)
            return ""
        return (item.badge || "").trim()
    }

    function profileGroupEnabled(groupName) {
        const item = findProfileGroupItem(groupName)
        if (!item)
            return true
        return item.enabled !== false
    }

    function profileGroupExclusive(groupName) {
        const item = findProfileGroupItem(groupName)
        if (!item)
            return false
        return item.exclusive === true
    }

    function compactProfileFilterTarget(kind) {
        const requested = (kind || "All").trim()
        if (requested.toLowerCase() === "free")
            return "Free"
        if (requested.toLowerCase() === "premium")
            return "Premium"
        return "All"
    }

    function compactProfileFilterSelected(kind) {
        return (compactProfileFilter || "All").trim().toLowerCase()
                === compactProfileFilterTarget(kind).toLowerCase()
    }

    function selectCompactProfileFilter(kind) {
        compactProfileFilter = compactProfileFilterTarget(kind)
        if ((vpnController.currentProfileGroup || "All") !== "All")
            vpnController.currentProfileGroup = "All"
        Qt.callLater(root.positionProfilePopup)
    }

    function profileMatchesSearch(displayLabel, protocol, address, security, groupName, sourceName) {
        const rawQuery = (profileSearchQuery || "").trim()
        if (rawQuery.length === 0)
            return true

        const q = rawQuery.toLowerCase()
        const label = (displayLabel || "")
        const meta = ((protocol || "")
                      + " " + (address || "")
                      + " " + (security || "")
                      + " " + (groupName || "")
                      + " " + (sourceName || "")).toLowerCase()
        if (label.toLowerCase().indexOf(q) >= 0 || meta.indexOf(q) >= 0)
            return true

        const flag = guessFlag(label)
        if (rawQuery.indexOf(flag) >= 0 || flag.indexOf(rawQuery) >= 0)
            return true

        const aliases = flagAliases(flag)
        for (let i = 0; i < aliases.length; ++i) {
            if (aliases[i].indexOf(q) >= 0)
                return true
        }
        return false
    }

    function profileScoreStars() {
        const rounded = Math.max(0, Math.min(5, Math.round(vpnController.profileScore)))
        const full = "★★★★★".slice(0, rounded)
        const empty = "☆☆☆☆☆".slice(0, 5 - rounded)
        return full + empty
    }

    function subscriptionsInCurrentGroup() {
        const group = (vpnController.currentProfileGroup || "All").trim().toLowerCase()
        const items = vpnController.subscriptionItems || []
        if (group.length === 0 || group === "all") {
            let enabledCount = 0
            for (let i = 0; i < items.length; ++i) {
                if (profileGroupEnabled(items[i].group))
                    enabledCount += 1
            }
            return enabledCount
        }

        let count = 0
        for (let i = 0; i < items.length; ++i) {
            const itemGroup = normalizeProfileGroup(items[i].group).toLowerCase()
            if (itemGroup === group && profileGroupEnabled(items[i].group))
                count += 1
        }
        return count
    }

    function updateProfileSelection(label, protocol, address, port, security) {
        const cleanLabel = (label || "").trim()
        selectedServerLabel = cleanLabel.length > 0 ? cleanLabel : "Selected Profile"
        selectedServerFlag = guessFlag(selectedServerLabel)
        selectedServerMeta = (protocol || "").toUpperCase() + " " + (address || "") + ":" + port
        if ((security || "").length > 0)
            selectedServerMeta += " | " + security
    }

    function syncSelectedProfileFromController() {
        if (vpnController.currentProfileIndex < 0) {
            selectedServerLabel = "Select Location"
            selectedServerMeta = "Import and select a profile"
            selectedServerFlag = "🌐"
            return
        }

        const label = (vpnController.currentProfileLabel() || "").trim()
        const subtitle = (vpnController.currentProfileSubtitle() || "").trim()
        selectedServerLabel = label.length > 0 ? label : "Selected Profile"
        selectedServerMeta = subtitle.length > 0 ? subtitle : "Profile is selected"
        selectedServerFlag = guessFlag(selectedServerLabel)
    }

    function infoIpText() {
        const publicAddress = (vpnController.publicIpAddress || "").trim()
        if (publicAddress.length > 0)
            return publicAddress
        if (vpnController.connected)
            return "Resolving..."
        return "Connect to view"
    }

    function infoIpLabel() {
        return "Protected IP"
    }

    function infoLocationText() {
        return selectedServerLabel === "Select Location" ? "Milano, Italy" : selectedServerLabel
    }

    function selectedProfileDetailText() {
        if (vpnController.currentProfileIndex < 0)
            return "Choose a profile to view details"

        const group = (vpnController.currentProfileGroupLabel() || "General").trim()
        const pingMs = vpnController.currentProfilePingMs()
        const pingText = pingMs >= 0 ? (pingMs + " ms") : "--"
        return "Group: " + group + "  •  Ping: " + pingText
    }

    function downloadUsageText() {
        return formatTrafficValue(Math.max(0, vpnController.rxBytes), dashboardStatsSettings.trafficUnit).value
                + " " + formatTrafficValue(Math.max(0, vpnController.rxBytes), dashboardStatsSettings.trafficUnit).unit
    }

    function uploadUsageText() {
        return formatTrafficValue(Math.max(0, vpnController.txBytes), dashboardStatsSettings.trafficUnit).value
                + " " + formatTrafficValue(Math.max(0, vpnController.txBytes), dashboardStatsSettings.trafficUnit).unit
    }

    function downloadRateText() {
        const formatted = formatSpeedValue(Math.max(0, downRateBytesPerSec), dashboardStatsSettings.speedUnit)
        return formatted.value + " " + formatted.unit
    }

    function uploadRateText() {
        const formatted = formatSpeedValue(Math.max(0, upRateBytesPerSec), dashboardStatsSettings.speedUnit)
        return formatted.value + " " + formatted.unit
    }

    function latestUsageValuePart() {
        const raw = (vpnController.latestRecordedUsage || "0 B").trim()
        const spaceAt = raw.indexOf(" ")
        if (spaceAt <= 0)
            return raw
        return raw.slice(0, spaceAt)
    }

    function latestUsageUnitPart() {
        const raw = (vpnController.latestRecordedUsage || "0 B").trim()
        const spaceAt = raw.indexOf(" ")
        if (spaceAt <= 0 || spaceAt + 1 >= raw.length)
            return ""
        return raw.slice(spaceAt + 1)
    }

    function sessionTimeText() {
        const total = Math.max(0, sessionSeconds)
        const hours = Math.floor(total / 3600)
        const minutes = Math.floor((total % 3600) / 60)
        const seconds = total % 60
        function pad(v) { return v < 10 ? "0" + v : "" + v }
        return pad(hours) + ":" + pad(minutes) + ":" + pad(seconds)
    }

    function rateMbpsText(bytesPerSec) {
        const mbps = Math.max(0, bytesPerSec) * 8.0 / 1000000.0
        return mbps.toFixed(2)
    }

    function appendRateHistory(history, mbpsValue) {
        const next = (history || []).slice(0)
        next.push(Math.max(0.0, mbpsValue))
        while (next.length > rateHistoryMaxPoints)
            next.shift()
        return next
    }

    function unitIndex(options, value) {
        for (let i = 0; i < options.length; ++i) {
            if (options[i] === value)
                return i
        }
        return 0
    }

    function decimalsFor(value) {
        if (value >= 100)
            return 0
        if (value >= 10)
            return 1
        return 2
    }

    function formatSpeedValue(bytesPerSec, requestedUnit) {
        const bytes = Math.max(0, bytesPerSec)
        const unit = speedUnitOptions.indexOf(requestedUnit) >= 0 ? requestedUnit : "Auto"
        const bitUnits = ["bps", "Kbps", "Mbps", "Gbps"]
        const byteUnits = ["B/s", "KB/s", "MB/s", "GB/s"]
        let units = bitUnits
        let value = bytes * 8.0
        let index = 0

        if (unit !== "Auto") {
            const bitIndex = bitUnits.indexOf(unit)
            const byteIndex = byteUnits.indexOf(unit)
            if (bitIndex >= 0) {
                return { "value": (value / Math.pow(1000, bitIndex)).toFixed(decimalsFor(value / Math.pow(1000, bitIndex))), "unit": unit }
            }
            if (byteIndex >= 0) {
                value = bytes / Math.pow(1024, byteIndex)
                return { "value": value.toFixed(decimalsFor(value)), "unit": unit }
            }
        }

        while (index < units.length - 1 && value >= 1000) {
            value = value / 1000.0
            index += 1
        }
        return { "value": value.toFixed(decimalsFor(value)), "unit": units[index] }
    }

    function formatTrafficValue(bytesValue, requestedUnit) {
        const bytes = Math.max(0, bytesValue)
        const unit = trafficUnitOptions.indexOf(requestedUnit) >= 0 ? requestedUnit : "Auto"
        const units = ["B", "KB", "MB", "GB", "TB"]
        let value = bytes
        let index = 0

        if (unit !== "Auto") {
            index = Math.max(0, units.indexOf(unit))
            value = bytes / Math.pow(1024, index)
            return { "value": value.toFixed(index === 0 ? 0 : decimalsFor(value)), "unit": units[index] }
        }

        while (index < units.length - 1 && value >= 1024) {
            value = value / 1024.0
            index += 1
        }
        return { "value": value.toFixed(index === 0 ? 0 : decimalsFor(value)), "unit": units[index] }
    }

    function settingsTitle() {
        if (settingsSection === "interface")
            return "Interface"
        if (settingsSection === "updates")
            return "App Updates"
        if (settingsSection === "connection")
            return "Connection Mode"
        if (settingsSection === "routing")
            return "Routing Rules"
        if (settingsSection === "dns")
            return "Custom DNS"
        if (settingsSection === "logs")
            return "Logs"
        if (settingsSection === "terms")
            return "Terms And Conditions"
        if (settingsSection === "share")
            return "Share App"
        if (settingsSection === "about")
            return "About App"
        return "Settings"
    }

    function openSettingsSection(section) {
        if (!settingsPopup.opened) {
            settingsPopup.open()
            Qt.callLater(function() {
                root.settingsSection = section
                if (section === "routing") {
                    root.appRuleSuggestions = vpnController.availableAppRuleItems()
                    root.appRuleSearchQuery = ""
                    root.clearAppSuggestionSelection()
                }
            })
            return
        }
        settingsSection = section
        if (section === "routing") {
            root.appRuleSuggestions = vpnController.availableAppRuleItems()
            root.appRuleSearchQuery = ""
            root.clearAppSuggestionSelection()
        }
    }

    function currentUsageHistoryModel() {
        usageRefreshNonce
        return vpnController.currentProfileUsageHistory(root.usageHistoryPeriod, 30)
    }

    function currentUsageSessionsModel() {
        usageRefreshNonce
        return vpnController.currentProfileUsageSessions(20)
    }

    function openEditProfile(row, displayName, groupName) {
        editProfileRow = row
        editProfileName = (displayName || "").trim()
        editProfileGroup = normalizeImportGroupName(groupName || "General")
        editProfilePopup.open()
    }

    function sheetWidth(maxWidth) {
        return root.width
    }

    function sheetHeight(maxHeight) {
        return Math.min(root.height - 104, maxHeight)
    }

    function drawerY(sheet) {
        return Math.max(0, root.height - sheet)
    }

    function tunConflictGuidance(errorText) {
        const raw = (errorText || "").trim()
        if (raw.length === 0 || !vpnController.tunMode)
            return ""

        const text = raw.toLowerCase()
        const gatewayIssue = text.indexOf("default gateway") >= 0 && text.indexOf("tun") >= 0
        const routeIssue = text.indexOf("split default routes") >= 0 || text.indexOf("route validation") >= 0
        const vpnConflictHint = text.indexOf("another vpn") >= 0 || text.indexOf("already active") >= 0

        if (!gatewayIssue && !routeIssue && !vpnConflictHint)
            return ""

        return "Another VPN or system tunnel appears active. Please disconnect it first, then reconnect GenyConnect in TUN mode."
    }

    function statePrimaryColor() {
        if (vpnController.connectionState === ConnectionState.Connecting)
            return Colors.mainHex_f59e0b
        if (vpnController.connectionState === ConnectionState.Connected)
            return Colors.mainHex_16a34a
        if (vpnController.connectionState === ConnectionState.Error)
            return Colors.mainHex_ef4444
        return Colors.mainHex_9aa5b5
    }

    function stateSoftColor() {
        if (vpnController.connectionState === ConnectionState.Connecting)
            return Colors.mainHex_fff4dc
        if (vpnController.connectionState === ConnectionState.Connected)
            return Colors.mainHex_e8f8ee
        if (vpnController.connectionState === ConnectionState.Error)
            return Colors.mainHex_feeceb
        return Colors.mainHex_eef2f7
    }

    function connectRingColor() {
        if (vpnController.connectionState === ConnectionState.Connecting)
            return root.brandBlue
        if (vpnController.connectionState === ConnectionState.Connected)
            return Colors.mainHex_22c55e
        if (vpnController.connectionState === ConnectionState.Error)
            return Colors.mainHex_ef4444
        return Colors.mainHex_cfd5e3
    }

    function connectCoreColor() {
        if (vpnController.connectionState === ConnectionState.Connected)
            return Colors.mainHex_16a34a
        if (vpnController.connectionState === ConnectionState.Error)
            return Colors.mainHex_ef4444
        if (vpnController.connectionState === ConnectionState.Connecting)
            return root.brandBlue
        return Colors.mainHex_aeb6c7
    }

    function statePanelColor() {
        if (vpnController.connectionState === ConnectionState.Connecting)
            return Colors.mainHex_fffcf4
        if (vpnController.connectionState === ConnectionState.Connected)
            return Colors.mainHex_fbfffc
        if (vpnController.connectionState === ConnectionState.Error)
            return Colors.mainHex_fff7f8
        return Colors.mainHex_ffffff
    }

    function stateBorderColor() {
        if (vpnController.connectionState === ConnectionState.Connecting)
            return Colors.mainHex_f5d08a
        if (vpnController.connectionState === ConnectionState.Connected)
            return Colors.mainHex_bfe6cc
        if (vpnController.connectionState === ConnectionState.Error)
            return Colors.mainHex_f4b7bd
        return Colors.mainHex_dde5ef
    }

    function stateGradientStart() {
        if (vpnController.connectionState === ConnectionState.Connecting)
            return Colors.mainHex_fbbf24
        if (vpnController.connectionState === ConnectionState.Connected)
            return Colors.mainHex_22c55e
        if (vpnController.connectionState === ConnectionState.Error)
            return Colors.mainHex_f43f5e
        return Colors.mainHex_94a3b8
    }

    function stateGradientEnd() {
        if (vpnController.connectionState === ConnectionState.Connecting)
            return Colors.mainHex_d97706
        if (vpnController.connectionState === ConnectionState.Connected)
            return Colors.mainHex_15803d
        if (vpnController.connectionState === ConnectionState.Error)
            return Colors.mainHex_be123c
        return Colors.mainHex_64748b
    }

    function stateShadowColor() {
        if (vpnController.connectionState === ConnectionState.Connecting)
            return Colors.mainHex_d9770626
        if (vpnController.connectionState === ConnectionState.Connected)
            return Colors.mainHex_15803d26
        if (vpnController.connectionState === ConnectionState.Error)
            return Colors.mainHex_be123c24
        return Colors.mainHex_64748b20
    }

    function speedGaugeStops() {
        if (speedGaugeRangePreset === "Small")
            return [0, 5, 10, 20, 35, 50, 75, 100]
        if (speedGaugeRangePreset === "Medium")
            return [0, 10, 25, 50, 100, 200, 300, 500]
        if (speedGaugeRangePreset === "Large")
            return [0, 25, 50, 100, 200, 300, 500, 1000]

        const observed = Math.max(
                    0.0,
                    vpnController.speedTestCurrentMbps,
                    vpnController.speedTestDownloadMbps,
                    vpnController.speedTestUploadMbps,
                    vpnController.speedTestAverageMbps,
                    speedGaugeDisplayMbps)

        if (observed <= 100.0)
            return [0, 5, 10, 20, 35, 50, 75, 100]
        if (observed <= 500.0)
            return [0, 10, 25, 50, 100, 200, 300, 500]
        return [0, 25, 50, 100, 200, 300, 500, 1000]
    }

    function speedGaugeMaxMbps() {
        const stops = speedGaugeStops()
        return stops.length > 0 ? stops[stops.length - 1] : 200.0
    }

    function speedGaugeTargetValue() {
        const maxMbps = speedGaugeMaxMbps()
        if (vpnController.speedTestRunning) {
            const live = Math.min(Math.max(vpnController.speedTestCurrentMbps, 0.0), maxMbps)
            if (live > 0.05)
                return live
            // Keep the needle from hard-snapping to zero during phase transitions.
            return Math.min(Math.max(speedGaugeDisplayMbps * 0.95, 0.0), maxMbps)
        }
        if (vpnController.speedTestState === "Completed")
            return Math.min(Math.max(vpnController.speedTestAverageMbps, 0.0), maxMbps)
        return 0.0
    }

    function speedGaugeValue() {
        return Math.min(Math.max(speedGaugeDisplayMbps, 0.0), speedGaugeMaxMbps())
    }

    function speedGaugeProgress() {
        const stops = speedGaugeStops()
        const value = Math.max(0.0, Math.min(speedGaugeValue(), stops[stops.length - 1]))
        for (let i = 0; i < stops.length - 1; ++i) {
            if (value <= stops[i + 1]) {
                const span = stops[i + 1] - stops[i]
                const segmentProgress = span > 0 ? (value - stops[i]) / span : 0.0
                return Math.max(0.0, Math.min((i + segmentProgress) / (stops.length - 1), 1.0))
            }
        }
        return 1.0
    }

    function speedPhaseProgress() {
        if (vpnController.speedTestDurationSec <= 0)
            return 0.0
        return Math.max(0.0, Math.min(vpnController.speedTestElapsedSec / vpnController.speedTestDurationSec, 1.0))
    }

    function speedTestStatusText() {
        if (vpnController.speedTestRunning) {
            if (vpnController.speedTestPhase === "Latency")
                return "Measuring latency and jitter..."
            if (vpnController.speedTestPhase === "Download")
                return "Measuring live download throughput..."
            if (vpnController.speedTestPhase === "Upload")
                return "Measuring live upload throughput..."
            if (vpnController.speedTestState === "Analyzing")
                return "Analyzing connection quality..."
            if (vpnController.speedTestState === "Preparing")
                return "Preparing diagnostics..."
            return "Running..."
        }
        return ""
    }

    function speedTestSideStatusText() {
        if (vpnController.speedTestRunning)
            return ""
        if (vpnController.speedTestError.length > 0)
            return "Error: " + (vpnController.speedTestError === "Operation canceled"
                                 ? "Speed test timed out or endpoint did not respond."
                                 : vpnController.speedTestError)
        if (vpnController.speedTestState === "Completed")
            return vpnController.speedTestQualityScore >= 0
                    ? ("Completed • Quality " + vpnController.speedTestQualityScore + "/100")
                    : "Completed"
        if (vpnController.speedTestState === "Cancelled")
            return "Cancelled"
        return "Ready"
    }

    function speedTestHeroTitle() {
        if (vpnController.speedTestRunning) {
            if (vpnController.speedTestPhase === "Download")
                return "Live download"
            if (vpnController.speedTestPhase === "Upload")
                return "Live upload"
            if (vpnController.speedTestPhase === "Latency")
                return "Latency probe"
            return "Running test"
        }
        if (vpnController.speedTestState === "Completed")
            return "Overall average"
        return "Speed estimate"
    }

    function speedTestHeroValueText() {
        if (vpnController.speedTestRunning)
            return Math.max(vpnController.speedTestCurrentMbps, 0.0).toFixed(2)
        if (vpnController.speedTestState === "Completed")
            return Math.max(vpnController.speedTestAverageMbps, 0.0).toFixed(2)
        return "0.00"
    }

    function speedTestHeroCaption() {
        if (vpnController.speedTestRunning) {
            if (vpnController.speedTestPhase === "Download")
                return "Current tunnel download rate"
            if (vpnController.speedTestPhase === "Upload")
                return "Current tunnel upload rate"
            if (vpnController.speedTestPhase === "Latency")
                return "Collecting response-time baseline"
            return "Collecting measurements"
        }
        if (vpnController.speedTestState === "Completed")
            return "Mean of final download and upload results"
        return "Run a diagnostics pass through the active VPN"
    }

    function speedTestProgressText() {
        if (vpnController.speedTestState === "Completed")
            return vpnController.speedTestQualityScore >= 0
                    ? ("Quality " + vpnController.speedTestQualityScore + "/100")
                    : "Completed"
        if (vpnController.speedTestRunning)
            return "Progress " + Math.round(Math.max(0, Math.min(vpnController.speedTestProgress, 1.0)) * 100) + "%"
        return "--"
    }

    function speedTestPhaseBadgeText() {
        if (vpnController.speedTestRunning)
            return "Phase " + vpnController.speedTestPhase
        return vpnController.speedTestState === "Idle" ? "Ready" : vpnController.speedTestState
    }

    function speedTestFooterText() {
        const down = vpnController.speedTestDownloadMbps > 0 ? vpnController.speedTestDownloadMbps.toFixed(1) + " Mbps" : "--"
        const up = vpnController.speedTestUploadMbps > 0 ? vpnController.speedTestUploadMbps.toFixed(1) + " Mbps" : "--"
        return "DL " + down + "  |  UL " + up
    }

    function speedOverallDisplayText() {
        if (vpnController.speedTestState === "Completed")
            return Math.max(vpnController.speedTestAverageMbps, 0.0).toFixed(2) + " Mbps"
        return "--"
    }

    function speedMetricLabel(index) {
        switch (index) {
        case 0: return "Download"
        case 1: return "Upload"
        case 2: return "Latency"
        case 3: return "Jitter"
        case 4: return "Overall"
        case 5: return "Quality"
        default: return "--"
        }
    }

    function speedMetricValue(index) {
        switch (index) {
        case 0:
            return vpnController.speedTestDownloadMbps > 0 ? (vpnController.speedTestDownloadMbps.toFixed(2) + " Mbps") : "--"
        case 1:
            return vpnController.speedTestUploadMbps > 0 ? (vpnController.speedTestUploadMbps.toFixed(2) + " Mbps") : "--"
        case 2:
            return vpnController.speedTestPingMs >= 0 ? (vpnController.speedTestPingMs + " ms") : "--"
        case 3:
            return vpnController.speedTestJitterMs >= 0 ? (vpnController.speedTestJitterMs + " ms") : "--"
        case 4:
            return speedOverallDisplayText()
        case 5:
            return vpnController.speedTestQualityScore >= 0
                    ? (vpnController.speedTestQualityScore + "/100")
                    : (Math.round(Math.max(0, Math.min(vpnController.speedTestProgress, 1.0)) * 100) + "%")
        default:
            return "--"
        }
    }

    function speedGaugePrefixText() {
        return ""
    }

    function speedGaugeNumberText() {
        return speedGaugeValue().toFixed(1)
    }

    function speedGaugeUnitText() {
        return "Mbps"
    }

    function clamp01(v) {
        return Math.max(0.0, Math.min(v, 1.0))
    }

    function mix(a, b, t) {
        return a + (b - a) * t
    }

    function gaugeColorAt(progress) {
        const p = clamp01(progress)
        const r1 = 0.24
        const g1 = 0.56
        const b1 = 1.0
        const r2 = 0.46
        const g2 = 0.36
        const b2 = 1.0
        const r3 = 0.77
        const g3 = 0.24
        const b3 = 0.98
        if (p < 0.58) {
            const t = p / 0.58
            return Qt.rgba(mix(r1, r2, t), mix(g1, g2, t), mix(b1, b2, t), 1.0)
        }
        const t2 = (p - 0.58) / 0.42
        return Qt.rgba(mix(r2, r3, t2), mix(g2, g3, t2), mix(b2, b3, t2), 1.0)
    }

    function gaugeAccentColor() {
        return gaugeColorAt(speedGaugeProgress())
    }

    function homeSpeedQualityRatio() {
        if (vpnController.speedTestQualityScore >= 0)
            return clamp01(vpnController.speedTestQualityScore / 100.0)

        let ratio = 0.08
        if (vpnController.connectionState === ConnectionState.Connecting)
            ratio = 0.22
        if (vpnController.connected)
            ratio = 0.36

        const liveMbps = Math.max(0, downRateBytesPerSec, upRateBytesPerSec) * 8.0 / 1000000.0
        ratio = Math.max(ratio, clamp01(liveMbps / 120.0))
        return clamp01(ratio)
    }

    function homeSpeedQualityOpacity() {
        const ratio = homeSpeedQualityRatio()
        if (vpnController.connected || vpnController.busy)
            return 0.28 + (ratio * 0.72)
        return 0.16 + (ratio * 0.34)
    }

    function speedTestProviderText() {
        const version = (vpnController.xrayVersion || "").trim()
        if (version.length > 0 && version !== "Unknown" && version !== "Unavailable" && version !== "Not detected" && version !== "Detected")
            return "Xray " + version
        return "Xray-core"
    }

    function speedTestProxyText() {
        if (vpnController.connected)
            return "VPN SOCKS5 127.0.0.1:" + vpnController.socksPort
        return "VPN disconnected"
    }

    function osNameText() {
        const os = Qt.platform.os
        if (os === "osx")
            return "macOS"
        if (os === "windows")
            return "Windows"
        if (os === "linux")
            return "Linux"
        return os
    }

    function positionProfilePopup() {
        if (!profilePopup)
            return

        profilePopup.width = root.sheetWidth(430)
        profilePopup.height = root.compact ? root.height : root.sheetHeight(640)
        profilePopup.x = (root.width - profilePopup.width) * 0.5
        profilePopup.y = root.compact ? 0 : root.drawerY(profilePopup.height)
    }

    Component.onCompleted: {
        AppGlobals.appWindow = root
        AppGlobals.mainRect = root.contentItem
        Theme.mode = darkThemeEnabled ? Theme.Dark : Theme.Light
        syncSelectedProfileFromController()
    }

    onDarkThemeEnabledChanged: Theme.mode = darkThemeEnabled ? Theme.Dark : Theme.Light

    Timer {
        id: trafficRateTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            if (vpnController.connected || vpnController.busy) {
                root.sessionSeconds += 1
            } else {
                root.sessionSeconds = 0
            }

            const rx = vpnController.rxBytes
            const tx = vpnController.txBytes
            if (!rateSampleInitialized) {
                lastRxBytesSample = rx
                lastTxBytesSample = tx
                rateSampleInitialized = true
                downRateBytesPerSec = 0
                upRateBytesPerSec = 0
                return
            }

            downRateBytesPerSec = Math.max(0, rx - lastRxBytesSample)
            upRateBytesPerSec = Math.max(0, tx - lastTxBytesSample)
            lastRxBytesSample = rx
            lastTxBytesSample = tx

            if (!vpnController.connected && !vpnController.busy) {
                downRateBytesPerSec = 0
                upRateBytesPerSec = 0
            }

            const downMbpsSample = downRateBytesPerSec * 8.0 / 1000000.0
            const upMbpsSample = upRateBytesPerSec * 8.0 / 1000000.0
            downRateHistoryMbps = appendRateHistory(downRateHistoryMbps, downMbpsSample)
            upRateHistoryMbps = appendRateHistory(upRateHistoryMbps, upMbpsSample)
        }
    }

    Timer {
        id: speedGaugeSmoothingTimer
        interval: 40
        repeat: true
        running: true
        onTriggered: {
            const target = root.speedGaugeTargetValue()
            const delta = target - root.speedGaugeDisplayMbps
            if (Math.abs(delta) < 0.02) {
                root.speedGaugeDisplayMbps = target
                return
            }

            const riseAlpha = vpnController.speedTestRunning ? 0.13 : 0.18
            const fallAlpha = vpnController.speedTestRunning ? 0.08 : 0.16
            const alpha = delta >= 0 ? riseAlpha : fallAlpha
            root.speedGaugeDisplayMbps += delta * alpha
        }
    }

    Connections {
        target: vpnController
        function onConnectionStateChanged() {
            if (!vpnController.connected && !vpnController.busy) {
                downRateBytesPerSec = 0
                upRateBytesPerSec = 0
                root.sessionSeconds = 0
            }
            root.rateSampleInitialized = false
        }

        function onCurrentProfileIndexChanged() {
            root.syncSelectedProfileFromController()
        }

        function onLastErrorChanged() {
            const guidance = root.tunConflictGuidance(vpnController.lastError)
            if (guidance.length === 0)
                return

            const signature = guidance + "||" + (vpnController.lastError || "")
            if (signature === root.tunConflictPopupSignature)
                return

            root.tunConflictPopupSignature = signature
            root.tunConflictPopupText = guidance + "\n\nDetails: " + vpnController.lastError
            tunConflictPopup.open()
        }
    }

    Connections {
        target: updater
        function onChanged() {
            if (!updater.updateAvailable || updater.latestVersion.length === 0)
                return
            if (notifiedUpdateVersion === updater.latestVersion)
                return
            notifiedUpdateVersion = updater.latestVersion
            updateNoticePopup.open()
        }
    }

    Popup {
        id: updateNoticePopup
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 0
        width: root.sheetWidth(420)
        height: 172
        x: (root.width - width) * 0.5
        y: root.drawerY(height)
        z: 200

        enter: Transition {
            NumberAnimation {
                property: "y"
                from: root.height
                to: root.drawerY(updateNoticePopup.height)
                duration: Animations.fast * 1.15
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "y"
                to: root.height
                duration: Animations.fast * 0.9
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            radius: 16
            color: root.themeColorToken("mainHex_ffffff", "mainHex_090b14")
            border.width: 0
            border.color: root.themeColorToken("mainHex_d6dfec", "mainHex_30435d")
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 42
                Layout.preferredHeight: 4
                radius: 2
                color: root.themeColorToken("mainHex_d6dde8", "mainHex_151c32")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    color: root.themeColorToken("mainHex_eaf2ff", "mainHex_223753")
                    border.width: 0
                    border.color: root.themeColorToken("mainHex_c8d9f7", "mainHex_4f86e6")

                    Text {
                        anchors.centerIn: parent
                        text: "↑"
                        color: root.themeColorToken("mainHex_2f6de2", "mainHex_86b6ff")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 15
                        font.bold: true
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Update Available"
                    color: root.themeColorToken("mainHex_1f2a3a", "mainHex_d8e1f0")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                    font.bold: true
                }
            }

            Text {
                Layout.fillWidth: true
                text: "GenyConnect " + updater.latestVersion + " is available. You're on " + updater.appVersion + "."
                color: root.themeColorToken("mainHex_667385", "mainHex_9bb0cb")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Controls.Button {
                    implicitHeight: 32
                    implicitWidth: 86

                    text: "Later"
                    Layout.fillWidth: true
                    onClicked: updateNoticePopup.close()
                }

                Controls.Button {
                    implicitHeight: 32
                    implicitWidth: 86
                    text: "Open Updates"
                    Layout.fillWidth: true
                    onClicked: {
                        updateNoticePopup.close()
                        root.openSettingsSection("updates")
                    }
                }
            }
        }
    }

    Popup {
        id: tunConflictPopup
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: root.sheetWidth(430)
        height: root.sheetHeight(280)
        x: (root.width - width) * 0.5
        y: root.drawerY(height)
        padding: 0

        enter: Transition {
            NumberAnimation {
                property: "y"
                from: root.height
                to: root.drawerY(tunConflictPopup.height)
                duration: Animations.fast * 1.15
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "y"
                to: root.height
                duration: Animations.fast * 0.9
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            radius: 24
            color: root.themeColorToken("mainHex_ffffff", "mainHex_090b14")
            border.width: 0
            border.color: root.themeColorToken("mainHex_d7deea", "mainHex_30435d")
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.compact ? 12 : 16
            spacing: 10

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 42
                Layout.preferredHeight: 4
                radius: 2
                color: root.themeColorToken("mainHex_d6dde8", "mainHex_151c32")
            }

            Text {
                text: "VPN Conflict Detected"
                color: root.themeColorToken("mainHex_1f2a3a", "mainHex_d8e1f0")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 22
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: root.tunConflictPopupText
                color: root.themeColorToken("mainHex_5f6f86", "mainHex_9bb0cb")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Controls.Button {
                    Layout.fillWidth: true
                    text: "Open Logs"
                    onClicked: {
                        tunConflictPopup.close()
                        logsPopup.open()
                    }
                }

                Controls.Button {
                    Layout.fillWidth: true
                    text: "OK"
                    onClicked: tunConflictPopup.close()
                }
            }
        }
    }

    Popup {
        id: profilePopup

        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onAboutToShow: {
            root.profileSearchQuery = ""
            if (vpnController.autoPingProfiles)
                vpnController.pingAllProfiles()
        }
        onOpened: {
            profileSearchField.forceActiveFocus()
        }
        width: root.sheetWidth(430)
        height: root.compact ? root.height : root.sheetHeight(640)
        x: (root.width - width) * 0.5
        y: root.compact ? 0 : root.drawerY(height)
        padding: 0

        enter: Transition {
            NumberAnimation {
                property: "y"
                from: root.height
                to: root.compact ? 0 : root.drawerY(profilePopup.height)
                duration: Animations.fast * 1.15
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "y"
                to: root.height
                duration: Animations.fast * 0.9
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            radius: root.compact ? 0 : 22
            color: root.themeColorToken("mainHex_ffffff", "mainHex_090b14")
            border.width: 0
            border.color: root.themeColorToken("mainHex_dbe2ee", "mainHex_30435d")
        }

        contentItem: Item {
            id: profilePopupContent
            clip: true
            implicitHeight: 16
                            + searchBar.implicitHeight
                            + 8
                            + actionsRow.implicitHeight
                            + 8
                            + groupRow.implicitHeight
                            + (groupOptionsRow.visible ? (8 + groupOptionsRow.implicitHeight) : 0)
                            + 8
                            + statsFlow.implicitHeight
                            + 10
                            + Math.min(Math.max(listView.contentHeight, 96), 310)
                            + 16

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.compact ? 24 : 10
                spacing: root.compact ? 16 : 8

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 4
                    radius: 2
                    color: root.themeColorToken("mainHex_d6dde8", "mainHex_151c32")
                    visible: !root.compact
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    spacing: 12
                    visible: root.compact

                    Controls.CircleIconButton {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        diameter: 38
                        elevated: false
                        backgroundColor: root.themeColorToken("mainHex_faf9ff", "mainHex_1a2b42")
                        borderColor: root.themeColorToken("mainHex_f0eef8", "mainHex_355173")
                        iconText: "\uf060"
                        iconFontFamily: root.faSolid
                        iconColor: root.themeColorToken("mainHex_050505", "mainHex_d8e1f0")
                        iconPixelSize: 15
                        onClicked: profilePopup.close()
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Server Location"
                        color: root.themeColorToken("mainHex_090909", "mainHex_e7eefb")
                        font.family: FontSystem.getContentFontBold.name
                        font.pixelSize: 18
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Controls.CircleIconButton {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        diameter: 38
                        elevated: false
                        backgroundColor: root.themeColorToken("mainHex_ffffff", "mainHex_1a2b42")
                        borderColor: root.themeColorToken("mainHex_e8edf5", "mainHex_355173")
                        iconText: root.iconPlus
                        iconFontFamily: root.faSolid
                        iconColor: root.brandBlue
                        iconPixelSize: 14
                        onClicked: {
                            profilePopup.close()
                            importPopup.open()
                        }
                    }
                }

                Rectangle {
                    id: searchBar
                    Layout.fillWidth: true
                    implicitHeight: root.compact ? 52 : 58
                    radius: 14
                    color: root.themeColorToken("mainHex_ffffff", "mainHex_5f233851")
                    border.width: 0
                    border.color: profileSearchField.activeFocus
                                  ? root.themeColorToken("mainHex_b7caee", "mainHex_6b98d5")
                                  : root.themeColorToken("mainHex_dfe6f1", "mainHex_496688")
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uf002"
                        color: root.themeColorToken("mainHex_9aa6ba", "mainHex_9db1ca")
                        font.family: root.faSolid
                        font.pixelSize: 13
                    }

                    TextField {
                        id: profileSearchField
                        anchors.left: parent.left
                        anchors.right: clearSearchButton.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 34
                        anchors.rightMargin: 4
                        padding: 0
                        placeholderText: root.compact ? "Search location..." : "Search by profile, country, or IP"
                        placeholderTextColor: root.themeColorToken("mainHex_8c8f98", "mainHex_9cb0c8")
                        text: root.profileSearchQuery
                        color: root.themeColorToken("mainHex_1f2a3a", "mainHex_d8e1f0")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 14
                        background: null
                        onTextChanged: {
                            root.profileSearchQuery = text
                            Qt.callLater(root.positionProfilePopup)
                        }
                    }

                    Text {
                        id: clearSearchButton
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.profileSearchQuery.length > 0 ? root.iconClose : ""
                        color: root.themeColorToken("mainHex_a0acbe", "mainHex_9fb4cd")
                        font.family: root.faSolid
                        font.pixelSize: 12

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: root.profileSearchQuery.length > 0
                            onClicked: {
                                profileSearchField.clear()
                                profileSearchField.forceActiveFocus()
                            }
                        }
                    }
                }

                GridLayout {
                    id: actionsRow
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 8
                    visible: true

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 36
                        radius: 12
                        color: addProfileMouse.containsMouse ? Colors.mainHex_2f6ff1 : Colors.mainHex_3f7cf3
                        border.width: 0
                        border.color: root.themeColorToken("mainHex_2f6ff1", "mainHex_3a7bff")
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Add Profile"
                            color: Colors.mainHex_ffffff
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 13
                            font.bold: false
                        }

                        MouseArea {
                            id: addProfileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                profilePopup.close()
                                importPopup.open()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 36
                        radius: 12
                        color: clearAllMouse.containsMouse
                               ? root.themeColorToken("mainHex_fff0f0", "mainHex_5f3b46")
                               : root.themeColorToken("mainHex_fff6f6", "mainHex_4d313b")
                        border.width: 0
                        border.color: root.themeColorToken("mainHex_f2cdcd", "mainHex_7d5062")
                        opacity: listView.count > 0 ? 1.0 : 0.55
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Delete All"
                            color: root.themeColorToken("mainHex_cb4f4f", "mainHex_ff8e8e")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 13
                            font.bold: false
                        }

                        MouseArea {
                            id: clearAllMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: listView.count > 0
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: clearProfilesPopup.open()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 36
                        radius: 12
                        color: pingAllMouse.containsMouse
                               ? root.themeColorToken("mainHex_f2f6fd", "mainHex_6a355172")
                               : root.themeColorToken("mainHex_f7f9fd", "mainHex_5a2d4462")
                        border.width: 0
                        border.color: root.themeColorToken("mainHex_d7dfec", "mainHex_151c32")
                        opacity: listView.count > 0 ? 1.0 : 0.55
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: (vpnController.currentProfileGroup || "All").toLowerCase() === "all"
                                  ? "Ping All"
                                  : "Ping Group"
                            color: root.themeColorToken("mainHex_4b5d78", "mainHex_b0c3db")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 13
                            font.bold: false
                        }

                        MouseArea {
                            id: pingAllMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: listView.count > 0
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: vpnController.pingAllProfiles()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 36
                        radius: 12
                        color: refreshSubsMouse.containsMouse
                               ? root.themeColorToken("mainHex_f2f6fd", "mainHex_6a355172")
                               : root.themeColorToken("mainHex_f7f9fd", "mainHex_5a2d4462")
                        border.width: 0
                        border.color: root.themeColorToken("mainHex_d7dfec", "mainHex_151c32")
                        opacity: vpnController.subscriptions.length > 0 ? 1.0 : 0.55
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: (vpnController.currentProfileGroup || "All") === "All"
                                  ? "Refresh Subs"
                                  : "Refresh Group"
                            color: root.themeColorToken("mainHex_4b5d78", "mainHex_b0c3db")
                            opacity: vpnController.subscriptionBusy ? 0.5 : 1.0
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 13
                            font.bold: false
                        }

                        MouseArea {
                            id: refreshSubsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: vpnController.subscriptions.length > 0 && !vpnController.subscriptionBusy
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                const current = (vpnController.currentProfileGroup || "All")
                                if (current === "All") {
                                    vpnController.refreshSubscriptions()
                                } else {
                                    vpnController.refreshSubscriptionsByGroup(current)
                                }
                            }
                        }
                    }

                    // Item { Layout.fillWidth: true }

                    BusyIndicator {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        running: vpnController.subscriptionBusy
                        visible: vpnController.subscriptionBusy
                    }

                    Item { Layout.fillWidth: true; visible: false }

                    // Text {
                    // Layout.preferredWidth: Math.min(profilePopup.width * 0.45, 280)
                    // text: vpnController.subscriptionMessage
                    // visible: text.length > 0
                    // color: vpnController.subscriptionBusy
                    // ? Colors.mainHex_2b6dcf
                    // : ((text.toLowerCase().indexOf("fail") >= 0 || text.toLowerCase().indexOf("error") >= 0)
                    // ? Colors.mainHex_bf4d4d
                    // : Colors.mainHex_6f7f95)
                    // font.family: FontSystem.contentFontFamily
                    // font.pixelSize: 12
                    // elide: Text.ElideRight
                    // }
                }

                RowLayout {
                    id: compactProfileSegmentRow
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    spacing: 16
                    visible: root.compact

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: 18
                        color: root.compactProfileFilterSelected("All")
                               ? root.brandBlue
                               : root.themeColorToken("mainHex_ffffff", "mainHex_5a2b4462")
                        border.width: 0
                        border.color: root.compactProfileFilterSelected("All")
                                      ? root.brandBlue
                                      : root.themeColorToken("mainHex_e7e9ee", "mainHex_4f6b8b")
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "All"
                            color: root.compactProfileFilterSelected("All")
                                   ? Colors.mainHex_ffffff
                                   : root.themeColorToken("mainHex_111111", "mainHex_e2ecf9")
                            font.family: FontSystem.getContentFontBold.name
                            font.pixelSize: 13
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectCompactProfileFilter("All")
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: 18
                        color: root.compactProfileFilterSelected("Free")
                               ? root.brandCyan
                               : root.themeColorToken("mainHex_ffffff", "mainHex_5a2b4462")
                        border.width: 0
                        border.color: root.compactProfileFilterSelected("Free")
                                      ? root.brandCyan
                                      : root.themeColorToken("mainHex_e7e9ee", "mainHex_4f6b8b")
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Free"
                            color: root.compactProfileFilterSelected("Free")
                                   ? Colors.mainHex_ffffff
                                   : root.themeColorToken("mainHex_111111", "mainHex_e2ecf9")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 13
                            font.bold: root.compactProfileFilterSelected("Free")
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectCompactProfileFilter("Free")
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: 18
                        color: root.compactProfileFilterSelected("Premium")
                               ? root.brandViolet
                               : root.themeColorToken("mainHex_ffffff", "mainHex_5a2b4462")
                        border.width: 0
                        border.color: root.compactProfileFilterSelected("Premium")
                                      ? root.brandViolet
                                      : root.themeColorToken("mainHex_e7e9ee", "mainHex_4f6b8b")
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Premium"
                            color: root.compactProfileFilterSelected("Premium")
                                   ? Colors.mainHex_ffffff
                                   : root.themeColorToken("mainHex_111111", "mainHex_e2ecf9")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 13
                            font.bold: root.compactProfileFilterSelected("Premium")
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectCompactProfileFilter("Premium")
                        }
                    }
                }

                RowLayout {
                    id: groupRow
                    Layout.fillWidth: true
                    spacing: 8
                    visible: !root.compact

                    Text {
                        text: "Group"
                        color: root.themeColorToken("mainHex_6b778a", "mainHex_9cb0c8")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 12
                    }

                    Controls.ComboBox {
                        id: groupFilterCombo
                        Layout.preferredWidth: Math.min(profilePopup.width * 0.45, 320)
                        Layout.preferredHeight: 34
                        model: vpnController.profileGroupItems
                        leftPadding: 10
                        rightPadding: 30

                        function groupNameAt(i) {
                            const items = vpnController.profileGroupItems || []
                            if (i < 0 || i >= items.length)
                                return ""
                            const item = items[i]
                            return (item && item.name) ? item.name : ""
                        }

                        function syncIndexFromController() {
                            const groups = vpnController.profileGroupItems || []
                            const current = (vpnController.currentProfileGroup || "All").toLowerCase()
                            for (let i = 0; i < groups.length; ++i) {
                                const name = ((groups[i] && groups[i].name) ? groups[i].name : "").toLowerCase()
                                if (name === current) {
                                    if (currentIndex !== i)
                                        currentIndex = i
                                    return
                                }
                            }
                            if (groups.length > 0 && currentIndex !== 0)
                                currentIndex = 0
                        }

                        onActivated: {
                            const name = groupNameAt(currentIndex)
                            if (name.length > 0)
                                vpnController.currentProfileGroup = name
                            Qt.callLater(root.positionProfilePopup)
                        }

                        Component.onCompleted: syncIndexFromController()

                        Connections {
                            target: vpnController
                            function onProfileGroupsChanged() { groupFilterCombo.syncIndexFromController() }
                            function onProfileGroupOptionsChanged() { groupFilterCombo.syncIndexFromController() }
                            function onCurrentProfileGroupChanged() { groupFilterCombo.syncIndexFromController() }
                        }
                    }

                    Rectangle {
                        radius: 10
                        height: 30
                        width: visibleProfilesText.implicitWidth + 16
                        color: root.themeColorToken("mainHex_eef4ff", "mainHex_223753")
                        border.width: 0
                        border.color: root.themeColorToken("mainHex_d8e4f8", "mainHex_151c32")

                        Text {
                            id: visibleProfilesText
                            anchors.centerIn: parent
                            text: "Visible " + vpnController.filteredProfileCount
                            color: root.themeColorToken("mainHex_5f6f86", "mainHex_9bb0cb")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 11
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                RowLayout {
                    id: groupOptionsRow
                    Layout.fillWidth: true
                    spacing: 8
                    visible: !root.compact && (groupFilterCombo.groupNameAt(groupFilterCombo.currentIndex) || "All").toLowerCase() !== "all"

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        radius: 12
                        color: root.themeColorToken("mainHex_f7f9fd", "mainHex_151c32")
                        border.width: 0
                        border.color: root.themeColorToken("mainHex_dce4f2", "mainHex_151c32")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Text {
                                text: "Enabled"
                                color: root.themeColorToken("mainHex_5f6f86", "mainHex_9bb0cb")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 12
                            }

                            Controls.Switch {
                                checked: root.profileGroupEnabled(groupFilterCombo.groupNameAt(groupFilterCombo.currentIndex))
                                onToggled: vpnController.setProfileGroupEnabled(groupFilterCombo.groupNameAt(groupFilterCombo.currentIndex), checked)
                            }

                            Text {
                                text: "Exclusive"
                                color: root.themeColorToken("mainHex_5f6f86", "mainHex_9bb0cb")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 12
                            }

                            Controls.Switch {
                                checked: root.profileGroupExclusive(groupFilterCombo.groupNameAt(groupFilterCombo.currentIndex))
                                onToggled: vpnController.setProfileGroupExclusive(groupFilterCombo.groupNameAt(groupFilterCombo.currentIndex), checked)
                            }

                            Rectangle {
                                Layout.preferredWidth: 132
                                Layout.preferredHeight: 28
                                radius: 9
                                color: root.themeColorToken("mainHex_ffffff", "mainHex_22324a")
                                border.width: 0
                                border.color: root.themeColorToken("mainHex_d5deec", "mainHex_151c32")

                                TextField {
                                    id: groupBadgeField
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    padding: 0
                                    clip: true
                                    placeholderText: "Badge"
                                    text: root.profileGroupBadgeText(groupFilterCombo.groupNameAt(groupFilterCombo.currentIndex))
                                    color: root.themeColorToken("mainHex_3b4a61", "mainHex_d0ddf0")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 12
                                    background: null
                                    onEditingFinished: {
                                        vpnController.setProfileGroupBadge(groupFilterCombo.groupNameAt(groupFilterCombo.currentIndex), text)
                                    }
                                }
                            }

                            Text {
                                visible: root.profileGroupBadgeText(groupFilterCombo.groupNameAt(groupFilterCombo.currentIndex)).length > 0
                                text: "• " + root.profileGroupBadgeText(groupFilterCombo.groupNameAt(groupFilterCombo.currentIndex))
                                color: root.themeColorToken("mainHex_4d6691", "mainHex_9fc3f2")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 12
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }
                }

                Flow {
                    id: statsFlow
                    Layout.fillWidth: true
                    spacing: 6
                    visible: !root.compact

                    Rectangle {
                        radius: 11
                        height: 24
                        color: vpnController.autoPingProfiles ? Colors.mainHex_e8f7ef : Colors.mainHex_eef2f8
                        border.width: 0
                        border.color: vpnController.autoPingProfiles ? Colors.mainHex_b9e3c8 : Colors.mainHex_d9e0ed
                        width: autoPingText.implicitWidth + 18

                        Text {
                            id: autoPingText
                            anchors.centerIn: parent
                            text: vpnController.autoPingProfiles ? "Auto Ping ON" : "Auto Ping OFF"
                            color: vpnController.autoPingProfiles ? Colors.mainHex_278c59 : Colors.mainHex_7b8799
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 11
                            font.bold: false
                        }
                    }

                    Rectangle {
                        radius: 11
                        height: 24
                        color: root.themeColorToken("mainHex_f3f6fb", "mainHex_20314b")
                        border.width: 0
                        border.color: root.themeColorToken("mainHex_d9e0ed", "mainHex_151c32")
                        width: subsText.implicitWidth + 18

                        Text {
                            id: subsText
                            anchors.centerIn: parent
                            text: "Subs " + subscriptionsInCurrentGroup() + "/" + vpnController.subscriptions.length
                            color: root.themeColorToken("mainHex_667487", "mainHex_9bb0cb")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 11
                            font.bold: false
                        }
                    }

                    Rectangle {
                        radius: 11
                        height: 24
                        color: root.themeColorToken("mainHex_edf5ff", "mainHex_213655")
                        border.width: 0
                        border.color: root.themeColorToken("mainHex_d9e6fb", "mainHex_47638c")
                        width: groupText.implicitWidth + 18

                        Text {
                            id: groupText
                            anchors.centerIn: parent
                            text: "Group " + (vpnController.currentProfileGroup || "All")
                            color: root.themeColorToken("mainHex_5f7290", "mainHex_9cb2cf")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 11
                            font.bold: false
                        }
                    }

                    Rectangle {
                        radius: 11
                        height: 24
                        color: root.themeColorToken("mainHex_f3f6fb", "mainHex_20314b")
                        border.width: 0
                        border.color: root.themeColorToken("mainHex_d9e0ed", "mainHex_151c32")
                        width: profilesText.implicitWidth + 18

                        Text {
                            id: profilesText
                            anchors.centerIn: parent
                            text: "Profiles " + vpnController.profileCount
                            color: root.themeColorToken("mainHex_667487", "mainHex_9bb0cb")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 11
                            font.bold: false
                        }
                    }

                    Rectangle {
                        radius: 11
                        height: 24
                        color: root.themeColorToken("mainHex_f3f6fb", "mainHex_20314b")
                        border.width: 0
                        border.color: root.themeColorToken("mainHex_d9e0ed", "mainHex_151c32")
                        width: bestText.implicitWidth + 18

                        Text {
                            id: bestText
                            anchors.centerIn: parent
                            text: "Best " + (vpnController.bestPingMs >= 0 ? (vpnController.bestPingMs + " ms") : "--")
                            color: root.themeColorToken("mainHex_667487", "mainHex_9bb0cb")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 11
                            font.bold: false
                        }
                    }

                    Rectangle {
                        radius: 11
                        height: 24
                        color: root.themeColorToken("mainHex_f3f6fb", "mainHex_20314b")
                        border.width: 0
                        border.color: root.themeColorToken("mainHex_d9e0ed", "mainHex_151c32")
                        width: worstText.implicitWidth + 18

                        Text {
                            id: worstText
                            anchors.centerIn: parent
                            text: "Worst " + (vpnController.worstPingMs >= 0 ? (vpnController.worstPingMs + " ms") : "--")
                            color: root.themeColorToken("mainHex_667487", "mainHex_9bb0cb")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 11
                            font.bold: false
                        }
                    }

                    Rectangle {
                        radius: 11
                        height: 24
                        color: root.themeColorToken("mainHex_fff5e9", "mainHex_3b311d")
                        border.width: 0
                        border.color: root.themeColorToken("mainHex_f4d9b1", "mainHex_866333")
                        width: scoreText.implicitWidth + 18

                        Text {
                            id: scoreText
                            anchors.centerIn: parent
                            text: "Score " + root.profileScoreStars()
                            color: root.themeColorToken("mainHex_9c6b1f", "mainHex_f4c56a")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 11
                            font.bold: false
                        }
                    }
                }

                Item {
                    id: listContainer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Math.min(Math.max(listView.contentHeight, 100), 300)

                    ListView {
                        id: listView
                        anchors.fill: parent
                        anchors.margins: root.compact ? 0 : 6
                        clip: true
                        model: vpnController.profileModel
                        spacing: root.compact ? 10 : 0
                        boundsBehavior: Flickable.DragAndOvershootBounds
                        flickDeceleration: 2800
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AlwaysOff
                        }
                        onContentHeightChanged: Qt.callLater(root.positionProfilePopup)
                        onCountChanged: Qt.callLater(root.positionProfilePopup)

                        delegate: Item {
                            required property int index
                            required property string displayLabel
                            required property string protocol
                            required property string address
                            required property int port
                            required property string security
                            required property string groupName
                            required property string sourceName
                            required property string pingText
                            required property bool pinging
                            required property int pingMs

                            readonly property bool selected: index === vpnController.currentProfileIndex
                            readonly property string normalizedGroup: root.normalizeProfileGroup(groupName)
                            readonly property string groupBadge: root.profileGroupBadgeText(groupName)
                            readonly property bool groupExclusive: root.profileGroupExclusive(groupName)
                            readonly property bool matched: root.profileGroupVisible(groupName)
                                                            && root.profileMatchesSearch(displayLabel, protocol, address, security, groupName, sourceName)
                            width: listView.width
                            height: matched ? (root.compact ? 82 : 84) : 0
                            visible: matched

                            Rectangle {
                                id: rowBg
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.topMargin: root.compact ? 0 : 3
                                anchors.bottomMargin: root.compact ? 0 : 3
                                radius: 14
                                color: selected
                                       ? root.themeColorToken("mainHex_eef3ff", "mainHex_8a35527a")
                                       : (hoverArea.containsMouse
                                          ? root.themeColorToken("mainHex_f8fbff", "mainHex_7a2b4461")
                                          : root.themeColorToken("mainHex_ffffff", "mainHex_66263c56"))
                                border.width: 0
                                border.color: selected
                                              ? root.themeColor(root.brandBlue, Colors.mainHex_6ba0ff)
                                              : root.themeColorToken("mainHex_e7edf6", "mainHex_4e6a8b")
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Behavior on border.color { ColorAnimation { duration: 120 } }
                            }

                            MouseArea {
                                id: hoverArea
                                anchors.fill: rowBg
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    vpnController.currentProfileIndex = index
                                    root.updateProfileSelection(displayLabel, protocol, address, port, security)
                                    profilePopup.close()
                                }
                            }

                            RowLayout {
                                anchors.fill: rowBg
                                anchors.leftMargin: root.compact ? 18 : 12
                                anchors.rightMargin: root.compact ? 18 : 12
                                spacing: root.compact ? 14 : 10

                                Rectangle {
                                    Layout.preferredWidth: root.compact ? 40 : 38
                                    Layout.preferredHeight: root.compact ? 40 : 38
                                    radius: width / 2
                                    color: root.themeColorToken("mainHex_f3f6fb", "mainHex_20314b")
                                    border.width: 0
                                    border.color: root.themeColorToken("mainHex_dde4ef", "mainHex_151c32")

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.guessFlag(displayLabel)
                                        font.pixelSize: root.compact ? 22 : 21
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: root.compact ? 5 : 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: displayLabel
                                        font.family: FontSystem.getContentFontBold.name
                                        font.weight: Font.Bold
                                        font.pixelSize: root.compact ? 15 : 14
                                        color: root.themeColorToken("mainHex_202634", "mainHex_d7e4f6")
                                        elide: Text.ElideRight
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 1
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Item {
                                            visible: root.compact
                                            Layout.preferredWidth: 30
                                            Layout.preferredHeight: 22

                                            Controls.SignalBars {
                                                anchors.centerIn: parent
                                                level: pinging ? 2 : (pingMs >= 0 ? (pingMs < 250 ? 4 : (pingMs < 500 ? 2 : 1)) : 0)
                                                activeColor: pingMs >= 0 ? (pingMs < 250 ? Colors.mainHex_36d984 : (pingMs < 500 ? Colors.mainHex_dfbf22 : Colors.mainHex_ef4444)) : Colors.mainHex_9aa4b6
                                                inactiveColor: Colors.mainHex_d9dee8
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: vpnController.pingProfile(index)
                                            }
                                        }

                                        Text {
                                            visible: root.compact
                                            text: pinging ? "..." : (pingMs >= 0 ? (pingMs + " ms") : "--")
                                            color: pingMs >= 0 ? (pingMs < 250 ? Colors.mainHex_36d984 : (pingMs < 500 ? Colors.mainHex_d0ad19 : Colors.mainHex_ef4444)) : Colors.mainHex_9aa4b6
                                            font.family: FontSystem.getContentFontBold.name
                                            font.pixelSize: 13
                                            font.bold: true

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: vpnController.pingProfile(index)
                                            }
                                        }

                                        Rectangle {
                                            visible: root.compact
                                            Layout.preferredWidth: compactBadgeText.implicitWidth + 22
                                            Layout.preferredHeight: 22
                                            radius: 12
                                            color: root.themeColorToken("mainHex_edf2ff", "mainHex_263a58")

                                            Text {
                                                id: compactBadgeText
                                                anchors.centerIn: parent
                                                text: groupBadge.length > 0 ? groupBadge : (vpnController.tunMode ? "TUN Server" : "Game Server")
                                                color: root.brandBlue
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Item { Layout.fillWidth: true }
                                    }

                                    Text {
                                        visible: !root.compact
                                        text: protocol.toUpperCase() + " " + address + ":" + port + ((security || "").length ? " | " + security : "")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 12
                                        color: root.themeColorToken("mainHex_8c95a4", "mainHex_9fb4cd")
                                        elide: Text.ElideRight
                                        wrapMode: Text.NoWrap
                                        maximumLineCount: 1
                                    }

                                    Text {
                                        visible: !root.compact
                                        text: (sourceName || "Manual import")
                                              + " • " + normalizedGroup
                                              + (groupExclusive ? " • Exclusive" : "")
                                              + (groupBadge.length > 0 ? " • " + groupBadge : "")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 11
                                        color: root.themeColorToken("mainHex_7b889d", "mainHex_9eb3cc")
                                        elide: Text.ElideRight
                                    }
                                }

                                RowLayout {
                                    visible: !root.compact
                                    Layout.preferredWidth: 256
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 6

                                    Item { Layout.fillWidth: true; }

                                    Rectangle {
                                        Layout.preferredWidth: 64
                                        Layout.fillWidth: false
                                        Layout.preferredHeight: 30
                                        radius: 10
                                        color: pinging
                                               ? root.themeColorToken("mainHex_fff5e8", "mainHex_5b3f22")
                                               : root.themeColorToken("mainHex_eff5ff", "mainHex_274062")
                                        border.width: 0
                                        border.color: pinging
                                                      ? root.themeColorToken("mainHex_f9d9a8", "mainHex_9c7a44")
                                                      : root.themeColorToken("mainHex_d8e4f8", "mainHex_4f6f95")

                                        Text {
                                            anchors.centerIn: parent
                                            text: pingText
                                            color: pinging
                                                   ? root.themeColorToken("mainHex_d18b22", "mainHex_f0bf6b")
                                                   : (pingMs >= 0
                                                      ? root.themeColorToken("mainHex_2b6dcf", "mainHex_8ab6ff")
                                                      : root.themeColorToken("mainHex_9aa4b6", "mainHex_9fb4cd"))
                                            font.family: FontSystem.contentFontFamily
                                            font.pixelSize: 12
                                            font.bold: false
                                        }
                                    }

                                    Rectangle {
                                        width: 30
                                        height: 30
                                        visible: !root.compact
                                        radius: 15
                                        color: pingButtonMouse.containsMouse
                                               ? root.themeColorToken("mainHex_edf4ff", "mainHex_314f73")
                                               : root.themeColorToken("mainHex_f7f9fd", "mainHex_273c58")
                                        border.width: 0
                                        border.color: root.themeColorToken("mainHex_dbe3ef", "mainHex_151c32")

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.iconPing
                                            font.family: root.faSolid
                                            font.pixelSize: 12
                                            color: root.themeColorToken("mainHex_5e6f89", "mainHex_9fb4cd")
                                        }

                                        MouseArea {
                                            id: pingButtonMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: vpnController.pingProfile(index)
                                        }
                                    }

                                    Rectangle {
                                        width: 30
                                        height: 30
                                        visible: !root.compact
                                        radius: 15
                                        color: removeButtonMouse.containsMouse
                                               ? root.themeColorToken("mainHex_fff0f0", "mainHex_5f3b46")
                                               : root.themeColorToken("mainHex_fff6f6", "mainHex_4d313b")
                                        border.width: 0
                                        border.color: root.themeColorToken("mainHex_f2cdcd", "mainHex_7d5062")

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.iconTrash
                                            font.family: root.faSolid
                                            font.pixelSize: 12
                                            color: root.themeColorToken("mainHex_cb4f4f", "mainHex_ff8e8e")
                                        }

                                        MouseArea {
                                            id: removeButtonMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (vpnController.removeProfile(index)) {
                                                    root.syncSelectedProfileFromController()
                                                    Qt.callLater(root.positionProfilePopup)
                                                }
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    visible: root.compact
                                    Layout.preferredWidth: 98
                                    spacing: 8

                                    Text {
                                        Layout.preferredWidth: 20
                                        text: root.iconPing
                                        color: pinging ? root.brandBlue : root.themeColorToken("mainHex_7c8ca5", "mainHex_9eb2cb")
                                        font.family: root.faSolid
                                        font.pixelSize: 13
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: vpnController.pingProfile(index)
                                        }
                                    }

                                    Text {
                                        Layout.preferredWidth: 20
                                        text: "\uf044"
                                        color: root.brandViolet
                                        font.family: root.faSolid
                                        font.pixelSize: 13
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.openEditProfile(index, displayLabel, groupName)
                                        }
                                    }

                                    Text {
                                        Layout.preferredWidth: 20
                                        text: root.iconTrash
                                        color: root.themeColorToken("mainHex_cb4f4f", "mainHex_ff8e8e")
                                        font.family: root.faSolid
                                        font.pixelSize: 13
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (vpnController.removeProfile(index)) {
                                                    root.syncSelectedProfileFromController()
                                                    Qt.callLater(root.positionProfilePopup)
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.preferredWidth: 20
                                        text: selected ? "\uf00c" : (groupBadge.length > 0 ? "\uf521" : "")
                                        color: selected ? Colors.mainHex_36d984 : Colors.mainHex_dfbf22
                                        font.family: root.faSolid
                                        font.pixelSize: selected ? 17 : 15
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        id: emptyState
                        anchors.centerIn: parent
                        visible: listView.count === 0 || (listView.count > 0 && listView.contentHeight < 2)
                        text: listView.count === 0
                              ? "No profiles. Import one first."
                              : "No matching profile found."
                        color: root.themeColorToken("mainHex_8f9bad", "mainHex_9eb3cc")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 14
                    }
                }
            }
        }
    }

    Popup {
        id: clearProfilesPopup
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: root.sheetWidth(420)
        height: Math.min(root.height - 58, 232)
        x: (root.width - width) * 0.5
        y: root.drawerY(height)
        padding: 0

        enter: Transition {
            NumberAnimation {
                property: "y"
                from: root.height
                to: root.drawerY(clearProfilesPopup.height)
                duration: Animations.fast * 1.15
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "y"
                to: root.height
                duration: Animations.fast * 0.9
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            radius: 20
            color: root.themeColorToken("mainHex_ffffff", "mainHex_090b14")
            border.width: 0
            border.color: root.themeColorToken("mainHex_d8dde8", "mainHex_151c32")
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 42
                Layout.preferredHeight: 4
                radius: 2
                color: root.themeColorToken("mainHex_d6dde8", "mainHex_151c32")
            }

            Text {
                text: "Delete all profiles?"
                color: root.themeColorToken("mainHex_1f2530", "mainHex_d8e1f0")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 24
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: "This removes all imported profiles from GenyConnect. This action cannot be undone."
                color: root.themeColorToken("mainHex_6a778b", "mainHex_9eb3cc")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Controls.Button {
                    Layout.fillWidth: true
                    text: "Cancel"
                    onClicked: clearProfilesPopup.close()
                }

                Controls.Button {
                    Layout.fillWidth: true
                    text: "Delete All"
                    onClicked: {
                        const removed = vpnController.removeAllProfiles()
                        clearProfilesPopup.close()
                        if (removed > 0) {
                            root.syncSelectedProfileFromController()
                            Qt.callLater(root.positionProfilePopup)
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: editProfilePopup
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: root.sheetWidth(420)
        height: Math.min(root.height - 58, 294)
        x: (root.width - width) * 0.5
        y: root.drawerY(height)
        padding: 0

        enter: Transition {
            NumberAnimation {
                property: "y"
                from: root.height
                to: root.drawerY(editProfilePopup.height)
                duration: Animations.fast * 1.15
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "y"
                to: root.height
                duration: Animations.fast * 0.9
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            topRightRadius: 24
            topLeftRadius: 24
            color: root.themeColorToken("mainHex_ffffff", "mainHex_090b14")
            border.width: 0
            border.color: root.themeColorToken("mainHex_d8dde8", "mainHex_151c32")
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 42
                Layout.preferredHeight: 4
                radius: 2
                color: root.themeColorToken("mainHex_d6dde8", "mainHex_151c32")
            }

            Text {
                text: "Edit Profile"
                color: root.themeColorToken("mainHex_1f2530", "mainHex_d8e1f0")
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: 22
                font.bold: true
            }

            TextField {
                id: editProfileNameField
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                text: root.editProfileName
                placeholderText: "Profile name"
                selectByMouse: true
                onTextEdited: root.editProfileName = text
            }

            TextField {
                id: editProfileGroupField
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                text: root.editProfileGroup
                placeholderText: "Group"
                selectByMouse: true
                onTextEdited: root.editProfileGroup = text
            }

            Text {
                Layout.fillWidth: true
                text: "Endpoint settings still come from the imported link. Re-import a link to change protocol, address, port, or security."
                color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Controls.Button {
                    Layout.fillWidth: true
                    text: "Cancel"
                    onClicked: editProfilePopup.close()
                }

                Controls.Button {
                    Layout.fillWidth: true
                    text: "Save"
                    onClicked: {
                        if (vpnController.updateProfileBasics(
                                    root.editProfileRow,
                                    editProfileNameField.text,
                                    editProfileGroupField.text)) {
                            editProfilePopup.close()
                            root.syncSelectedProfileFromController()
                            Qt.callLater(root.positionProfilePopup)
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: settingsPopup
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: {
            root.settingsSection = "main"
            root.syncCustomDnsDraftFromController()
        }
        width: root.sheetWidth(430)
        height: root.compact ? root.height : root.sheetHeight(620)
        x: (root.width - width) * 0.5
        y: root.compact ? 0 : root.drawerY(height)
        padding: 0

        enter: Transition {
            NumberAnimation {
                property: "y"
                from: root.height
                to: root.compact ? 0 : root.drawerY(settingsPopup.height)
                duration: Animations.fast * 1.15
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "y"
                to: root.height
                duration: Animations.fast * 0.9
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            radius: root.compact ? 0 : 24
            color: root.themeColorToken("mainHex_f8fbff", "mainHex_090b14")
            border.width: 0
            border.color: root.themeColorToken("mainHex_d8dde8", "mainHex_151c32")
            clip: true
        }

        contentItem: Item {
            anchors.fill: parent
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.compact ? 12 : 16
                spacing: root.compact ? 16 : 10

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 4
                    radius: 2
                    color: root.themeColorToken("mainHex_d6dde8", "mainHex_151c32")
                    visible: !root.compact
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: root.compact ? 12 : 8

                    Controls.CircleIconButton {
                        visible: root.compact
                        diameter: 38
                        elevated: false
                        backgroundColor: root.themeColorToken("mainHex_faf9ff", "mainHex_151c32")
                        borderColor: root.themeColorToken("mainHex_f0eef8", "mainHex_151c32")
                        iconText: "\uf060"
                        iconFontFamily: root.faSolid
                        iconColor: root.themeColorToken("mainHex_050505", "mainHex_d8e1f0")
                        iconPixelSize: 15
                        onClicked: {
                            if (root.settingsSection === "main") {
                                settingsPopup.close()
                            } else {
                                root.settingsSection = "main"
                            }
                        }
                    }

                    Text {
                        text: root.settingsTitle()
                        font.family: FontSystem.getContentFontBold.name
                        font.weight: Font.Bold
                        font.pixelSize: root.compact ? 18 : 24
                        color: root.themeColor((root.compact ? Colors.mainHex_090909 : Colors.mainHex_1f2530), Colors.mainHex_d8e1f0)
                    }
                    Item { Layout.fillWidth: true }
                    Controls.CircleIconButton {
                        visible: !root.compact
                        diameter: 34
                        iconText: "×"
                        iconPixelSize: 20
                        iconColor: root.themeColorToken("mainHex_8d96a5", "mainHex_9db0ca")
                        backgroundColor: root.themeColorToken("mainHex_f7f8fb", "mainHex_151c32")
                        borderColor: root.themeColorToken("mainHex_e1e5ed", "mainHex_151c32")
                        onClicked: settingsPopup.close()
                    }
                }

                Flickable {
                    id: settingsFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: settingsContent.implicitHeight
                    boundsBehavior: Flickable.DragAndOvershootBounds
                    flickableDirection: Flickable.VerticalFlick

                    ColumnLayout {
                        id: settingsContent
                        width: settingsFlick.width
                        spacing: root.compact ? 14 : 10
                        clip: true

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
                                        { "title": "Interface", "icon": "\uf53f", "action": "interface" },
                                        { "title": "App Updates", "icon": "\uf2f1", "action": "updates" },
                                        { "title": "Connection Mode", "icon": "\uf6ff", "action": "connection" },
                                        { "title": "Routing Rules", "icon": "\uf542", "action": "routing" },
                                        { "title": "Custom DNS", "icon": "\uf1eb", "action": "dns" },
                                        { "title": "Logs", "icon": "\uf1da", "action": "logs" },
                                        { "title": "Terms And Conditions", "icon": "\uf15c", "action": "terms" },
                                        { "title": "Share App", "icon": "\uf1e0", "action": "share" },
                                        { "title": "About App", "icon": "\uf05a", "action": "about" }
                                    ]

                                    delegate: Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 76
                                        radius: 15
                                        color: root.themeColorToken("mainHex_55f2f2f2", "mainHex_55182538")

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 16
                                            spacing: 14

                                            Rectangle {
                                                Layout.preferredWidth: 42
                                                Layout.preferredHeight: 42
                                                radius: 21
                                                color: root.themeColorToken("mainHex_eef0ff", "mainHex_223149")

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.icon
                                                    color: root.themeColorToken("mainHex_3147d0", "mainHex_8ab2ff")
                                                    font.family: root.faSolid
                                                    font.pixelSize: 17
                                                }
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.title
                                                color: root.themeColorToken("mainHex_090909", "mainHex_e7eefb")
                                                font.family: FontSystem.getContentFontBold.name
                                                font.pixelSize: 16
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: "\uf054"
                                                color: root.themeColorToken("mainHex_050505", "mainHex_d5e3f8")
                                                font.family: root.faSolid
                                                font.pixelSize: 16
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.settingsSection = modelData.action
                                        }
                                    }
                                }
                            }
                        }

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
                                    text: "Dashboard Stats"
                                    color: root.themeColorToken("mainHex_2a3240", "mainHex_d5deeb")
                                    font.family: FontSystem.getContentFontBold.name
                                    font.pixelSize: 16
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Choose the unit used by live transfer-rate indicators. Auto selects the most readable unit."
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
                                        text: "Theme"
                                        color: root.themeColorToken("mainHex_334155", "mainHex_c8d3e2")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 14
                                    }

                                    Controls.ComboBox {
                                        Layout.preferredWidth: 140
                                        Layout.preferredHeight: 40
                                        model: root.themeModeOptions
                                        currentIndex: root.unitIndex(root.themeModeOptions, interfaceThemeSettings.mode)
                                        onActivated: interfaceThemeSettings.mode = root.themeModeOptions[currentIndex]
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "System follows macOS/Windows appearance. Light keeps current look."
                                    color: root.themeColorToken("mainHex_8a95a8", "mainHex_8ea0b8")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Speed Units"
                                        color: root.themeColorToken("mainHex_334155", "mainHex_c8d3e2")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 14
                                    }

                                    Controls.ComboBox {
                                        Layout.preferredWidth: 140
                                        Layout.preferredHeight: 40
                                        model: root.speedUnitOptions
                                        currentIndex: root.unitIndex(root.speedUnitOptions, dashboardStatsSettings.speedUnit)
                                        onActivated: dashboardStatsSettings.speedUnit = root.speedUnitOptions[currentIndex]
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Use lowercase b for bits and uppercase B for bytes."
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
                                        text: "Total Traffic Units"
                                        color: root.themeColorToken("mainHex_334155", "mainHex_c8d3e2")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 14
                                    }

                                    Controls.ComboBox {
                                        Layout.preferredWidth: 140
                                        Layout.preferredHeight: 40
                                        model: root.trafficUnitOptions
                                        currentIndex: root.unitIndex(root.trafficUnitOptions, dashboardStatsSettings.trafficUnit)
                                        onActivated: dashboardStatsSettings.trafficUnit = root.trafficUnitOptions[currentIndex]
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "terms"
                            implicitHeight: termsColumn.implicitHeight + 28
                            radius: Colors.innerRadius
                            color: root.themeColorToken("mainHex_f7f9fc", "mainHex_151c32")
                            border.width: 0
                            border.color: root.themeColorToken("mainHex_e0e6f0", "mainHex_30435d")

                            ColumnLayout {
                                id: termsColumn
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Terms And Conditions"
                                    color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                    font.family: FontSystem.getContentFontBold.name
                                    font.pixelSize: 16
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Use GenyConnect only with profiles and networks you are authorized to access. You are responsible for complying with local laws, service terms, and network policies."
                                    color: root.themeColorToken("mainHex_667385", "mainHex_9bb0cb")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "share"
                            implicitHeight: shareColumn.implicitHeight + 28
                            radius: Colors.innerRadius
                            color: root.themeColorToken("mainHex_f7f9fc", "mainHex_151c32")
                            border.width: 0
                            border.color: root.themeColorToken("mainHex_e0e6f0", "mainHex_30435d")

                            ColumnLayout {
                                id: shareColumn
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Share App"
                                    color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                    font.family: FontSystem.getContentFontBold.name
                                    font.pixelSize: 16
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Share the GenyConnect repository or website with someone who needs the app."
                                    color: root.themeColorToken("mainHex_667385", "mainHex_9bb0cb")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                }

                                Controls.Button {
                                    text: "Open Repository"
                                    Layout.fillWidth: true
                                    onClicked: Qt.openUrlExternally("https://github.com/genyleap/genyconnect")
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "about"
                            implicitHeight: aboutSettingsColumn.implicitHeight + 28
                            radius: Colors.innerRadius
                            color: root.themeColorToken("mainHex_f7f9fc", "mainHex_151c32")
                            border.width: 0
                            border.color: root.themeColorToken("mainHex_e0e6f0", "mainHex_30435d")

                            ColumnLayout {
                                id: aboutSettingsColumn
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "GenyConnect"
                                    color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                    font.family: FontSystem.getContentFontBold.name
                                    font.pixelSize: 16
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Version " + updater.appVersion + "\nxray-core " + vpnController.xrayVersion + "\nDeveloper: Genyleap LLC\n\nGenyConnect is open source. Donations and community support help keep development active."
                                    color: root.themeColorToken("mainHex_667385", "mainHex_9bb0cb")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                }

                                Controls.Button {
                                    text: "Open Project"
                                    Layout.fillWidth: true
                                    onClicked: Qt.openUrlExternally("https://github.com/genyleap/genyconnect")
                                }

                                Controls.Button {
                                    text: "Support Development"
                                    Layout.fillWidth: true
                                    onClicked: Qt.openUrlExternally("https://github.com/genyleap/genyconnect#support-development")
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "updates"
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
                                        text: "App Updates"
                                        color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 15
                                        font.bold: true
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: "Current " + updater.appVersion
                                        color: root.themeColorToken("mainHex_677385", "mainHex_9bb0cb")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 13
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: updater.status
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
                                    text: "Latest " + updater.latestVersion
                                    color: root.themeColorToken("mainHex_7f8897", "mainHex_99abc4")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 12
                                }

                                ProgressBar {
                                    Layout.fillWidth: true
                                    visible: updater.checking
                                    from: 0
                                    to: 1
                                    value: updater.downloadProgress
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 1
                                    columnSpacing: 8
                                    rowSpacing: 8

                                    Controls.Button {
                                        text: updater.checking ? "Checking..." : "Check Now"
                                        enabled: !updater.checking
                                        Layout.fillWidth: true
                                        onClicked: updater.checkForUpdates(true)
                                    }

                                    Controls.Button {
                                        text: updater.downloadedFilePath.length > 0
                                              ? (updater.canInstallDownloadedUpdate ? "Install & Restart" : "Open Installer")
                                              : "Download"
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
                                        text: "Release Page"
                                        isDefault: false
                                        enabled: updater.releaseUrl.length > 0
                                        Layout.fillWidth: true
                                        onClicked: updater.openReleasePage()
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "about"
                            Layout.maximumWidth: settingsFlick.width
                            radius: Colors.innerRadius
                            color: root.themeColorToken("mainHex_f7f9fc", "mainHex_151c32")
                            border.width: 0
                            border.color: root.themeColorToken("mainHex_e0e6f0", "mainHex_30435d")
                            implicitHeight: 64

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "xray-core"
                                    color: root.themeColorToken("mainHex_667081", "mainHex_9ab0ca")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 14
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "Version " + vpnController.xrayVersion
                                    color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                            }
                        }

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
                                             : "Clean mode: " + osNameText() + " proxy stays untouched. Only apps set to 127.0.0.1:10808 use the tunnel.")
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
                                                "subtitle": "Apply system proxy for compatible apps.",
                                                "checked": vpnController.useSystemProxy && !vpnController.tunMode,
                                                "enabled": !vpnController.useSystemProxy || vpnController.tunMode,
                                                "apply": function() {
                                                    vpnController.tunMode = false
                                                    vpnController.useSystemProxy = true
                                                    vpnController.autoDisableSystemProxyOnDisconnect = true
                                                }
                                            },
                                            {
                                                "title": "Clean Mode",
                                                "subtitle": "Keep OS proxy unchanged and route manual proxy apps only.",
                                                "checked": !vpnController.useSystemProxy && !vpnController.tunMode,
                                                "enabled": vpnController.useSystemProxy || vpnController.tunMode,
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
                                                "enabled": !vpnController.tunMode,
                                                "apply": function() {
                                                    vpnController.useSystemProxy = false
                                                    vpnController.tunMode = true
                                                }
                                            }
                                        ]

                                        delegate: Rectangle {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 56
                                            radius: 8
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
                                                        elide: Text.ElideRight
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                enabled: modelData.enabled
                                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
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
                                enabled: vpnController.useSystemProxy && !vpnController.tunMode
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
                                onToggled: vpnController.killSwitchEnabled = checked
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: "Kill Switch"
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

                        RowLayout {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "logs"
                            spacing: 10

                            Controls.Switch {
                                checked: vpnController.loggingEnabled
                                onToggled: vpnController.loggingEnabled = checked
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Enable xray logs"
                                color: root.themeColorToken("mainHex_334155", "mainHex_d7e4f6")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                            }
                        }

                        Controls.Button {
                            visible: root.settingsSection === "logs"
                            text: "Open Logs Viewer"
                            Layout.fillWidth: true
                            onClicked: logsPopup.open()
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
                                  ? "TUN mode does not change OS proxy settings. If connect fails, run app with elevated privileges."
                                  : (vpnController.useSystemProxy
                                     ? "Recommended: keep this enabled to restore system proxy cleanly after tunnel disconnect."
                                     : "In Clean mode this option is ignored because system proxy remains disabled.")
                            color: root.themeColorToken("mainHex_7f8897", "mainHex_99abc4")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "routing"
                            spacing: 10

                            Controls.Switch {
                                checked: vpnController.whitelistMode
                                onToggled: vpnController.whitelistMode = checked
                            }

                            Text {
                                text: "Whitelist mode"
                                color: root.themeColorToken("mainHex_334155", "mainHex_d7e4f6")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 14
                            }
                        }

                        Button {
                            visible: root.settingsSection === "connection"
                            isDefault: false
                            text: "Reset System Proxy Now"
                            Layout.fillWidth: true
                            onClicked: vpnController.cleanSystemProxy()
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "routing"
                            height: 1
                            color: root.themeColorToken("mainHex_e4e8ef", "mainHex_30435d")
                        }

                        Text {
                            visible: root.settingsSection === "routing"
                            text: "Routing Rules"
                            color: root.themeColorToken("mainHex_667081", "mainHex_9ab0ca")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 14
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "routing"
                            text: "Use comma or new line between values. Domain formats: example.com, full:example.com, domain:example.com, regexp:.*\\\\.example\\\\.com$, geosite:category-ads-all."
                            wrapMode: Text.Wrap
                            color: root.themeColorToken("mainHex_8a95a8", "mainHex_9eb2cb")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 12
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "routing"
                            Layout.preferredHeight: 74
                            placeholderText: "Tunnel Domains\nexample.com\ndomain:youtube.com\nregexp:.*\\\\.openai\\\\.com$"
                            text: vpnController.proxyDomainRules
                            onTextChanged: vpnController.proxyDomainRules = text
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "routing"
                            Layout.preferredHeight: 74
                            placeholderText: "Direct Domains\nfull:localhost\ngeosite:private\nexample.org"
                            text: vpnController.directDomainRules
                            onTextChanged: vpnController.directDomainRules = text
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "routing"
                            Layout.preferredHeight: 74
                            placeholderText: "Block Domains\ngeosite:category-ads-all\nregexp:.*ads.*"
                            text: vpnController.blockDomainRules
                            onTextChanged: vpnController.blockDomainRules = text
                        }

                        Rectangle {
                            id: customDnsCard
                            Layout.fillWidth: true
                            visible: root.settingsSection === "dns"
                            Layout.maximumWidth: settingsFlick.width
                            Layout.preferredHeight: customDnsColumn.implicitHeight + 20
                            implicitHeight: customDnsColumn.implicitHeight + 20
                            radius: 14
                            color: root.themeColorToken("mainHex_f8fbff", "mainHex_171a2b")
                            border.width: 0
                            border.color: root.themeColorToken("mainHex_d7e4f5", "mainHex_151c32")

                            ColumnLayout {
                                id: customDnsColumn
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    Layout.fillWidth: true
                                    text: "Custom DNS (optional, TUN mode)"
                                    color: root.themeColorToken("mainHex_3b4e67", "mainHex_d0ddf0")
                                    font.family: FontSystem.getContentFontBold.name
                                    font.pixelSize: 13
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Enter one resolver per line. Supports IPv4, IPv6, and DNS hostnames."
                                    wrapMode: Text.Wrap
                                    color: root.themeColorToken("mainHex_7c8ba1", "mainHex_9eb2cb")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 12
                                }

                                Controls.TextArea {
                                    id: customDnsTextArea
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 86
                                    fillColor: root.themeColorToken("mainHex_ffffff", "mainHex_4d20334d")
                                    strokeColor: root.themeColorToken("mainHex_d8e2f0", "mainHex_4f6f95")
                                    focusColor: root.themeColorToken("mainHex_8bb8ff", "mainHex_6ba0ff")
                                    placeholderText: "1.1.1.1\n8.8.8.8\ndns.google"
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
                                            Layout.preferredHeight: 38
                                            radius: 12
                                            color: root.dnsDraftContains(modelData.server)
                                                   ? root.themeColorToken("mainHex_eaf2ff", "mainHex_223753")
                                                   : root.themeColorToken("mainHex_ffffff", "mainHex_22324a")
                                            border.width: 0
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
                                                    text: modelData.label
                                                    color: root.themeColorToken("mainHex_43556f", "mainHex_d0ddf0")
                                                    font.family: FontSystem.contentFontFamily
                                                    font.pixelSize: 12
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
                                            return count > 0 ? ("Resolvers: " + count) : "Resolvers: default"
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Controls.Button {
                                        text: "Reset"
                                        implicitWidth: 86
                                        implicitHeight: 34
                                        Layout.fillWidth: false
                                        enabled: root.customDnsDirty
                                        onClicked: root.syncCustomDnsDraftFromController()
                                    }

                                    Item { Layout.fillWidth: true }

                                    Controls.Button {
                                        text: "Apply DNS"
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

                        Text {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "routing"
                            text: vpnController.processRoutingSupported
                                  ? "App rules are supported on this xray-core build."
                                  : (Qt.platform.os === "osx"
                                     ? "macOS note: process-name app rules are not supported by xray-core. Use domain/IP rules here, or switch to Network Extension app-based routing architecture."
                                     : "App rules require xray-core 26.1.23+ (current build does not support process routing).")
                            wrapMode: Text.Wrap
                            color: vpnController.processRoutingSupported
                                   ? root.themeColorToken("mainHex_8a95a8", "mainHex_9eb2cb")
                                   : root.themeColorToken("mainHex_d97706", "mainHex_ffb454")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 12
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "routing"
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: "Running apps"
                                color: root.themeColorToken("mainHex_334155", "mainHex_d7e4f6")
                                font.family: FontSystem.getContentFontBold.name
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Controls.Button {
                                text: "Refresh"
                                implicitWidth: 82
                                implicitHeight: 32
                                enabled: vpnController.processRoutingSupported
                                onClicked: {
                                    root.appRuleSuggestions = vpnController.availableAppRuleItems()
                                    root.appRuleSearchQuery = ""
                                    root.clearAppSuggestionSelection()
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "routing"
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
                                        placeholderText: "Search running apps"
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
                                text: "Select visible"
                                implicitWidth: 104
                                implicitHeight: 32
                                Layout.fillWidth: false
                                enabled: vpnController.processRoutingSupported
                                         && (root.visibleAppRuleSuggestions() || []).length > 0
                                onClicked: root.selectVisibleAppSuggestionItems()
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "routing"
                            spacing: 8

                            Text {
                                text: (root.selectedAppRuleProcesses || []).length > 0
                                      ? ((root.selectedAppRuleProcesses || []).length + " selected")
                                      : (((root.visibleAppRuleSuggestions() || []).length > 0)
                                         ? "Select apps to apply rules"
                                         : "No matching app found")
                                color: root.themeColorToken("mainHex_6b7b92", "mainHex_9eb2cb")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 12
                            }

                            Item { Layout.fillWidth: true }

                            Controls.Button {
                                text: "Clear"
                                implicitWidth: 62
                                implicitHeight: 30
                                enabled: (root.selectedAppRuleProcesses || []).length > 0
                                onClicked: root.clearAppSuggestionSelection()
                            }

                            Controls.Button {
                                text: "Direct"
                                implicitWidth: 72
                                implicitHeight: 30
                                enabled: vpnController.processRoutingSupported
                                         && (root.selectedAppRuleProcesses || []).length > 0
                                onClicked: root.appendSelectedAppRules("direct")
                            }

                            Controls.Button {
                                text: "Tunnel"
                                implicitWidth: 72
                                implicitHeight: 30
                                enabled: vpnController.processRoutingSupported
                                         && (root.selectedAppRuleProcesses || []).length > 0
                                onClicked: root.appendSelectedAppRules("proxy")
                            }

                            Controls.Button {
                                text: "Block"
                                implicitWidth: 72
                                implicitHeight: 30
                                enabled: vpnController.processRoutingSupported
                                         && (root.selectedAppRuleProcesses || []).length > 0
                                onClicked: root.appendSelectedAppRules("block")
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "routing"
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
                                    height: 46
                                    radius: 8
                                    color: root.isAppSuggestionSelected(modelData.process || "")
                                           ? root.themeColorToken("mainHex_edf4ff", "mainHex_274062")
                                           : root.themeColorToken("mainHex_ffffff", "mainHex_22324a")
                                    border.width: 0
                                    border.color: root.isAppSuggestionSelected(modelData.process || "")
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
                                            color: root.isAppSuggestionSelected(modelData.process || "")
                                                   ? root.themeColorToken("mainHex_dbe8ff", "mainHex_335178")
                                                   : root.themeColorToken("mainHex_eff4fb", "mainHex_2a3f5b")
                                            border.width: 0
                                            border.color: root.isAppSuggestionSelected(modelData.process || "")
                                                         ? root.themeColorToken("mainHex_9db9f9", "mainHex_659bdf")
                                                         : root.themeColorToken("mainHex_d4dfef", "mainHex_496384")

                                            Text {
                                                anchors.centerIn: parent
                                                text: root.appSuggestionInitial(modelData.process || "")
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
                                                text: modelData.source ? ("Source: " + modelData.source) : ""
                                                visible: text.length > 0
                                                color: root.themeColorToken("mainHex_95a3b8", "mainHex_a4b6cd")
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 10
                                                elide: Text.ElideRight
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
                                                text: "Direct"
                                                color: root.themeColorToken("mainHex_3862a9", "mainHex_8bb7ff")
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 11
                                                font.bold: true
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                enabled: vpnController.processRoutingSupported
                                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                onClicked: vpnController.appendAppRule("direct", modelData.process || "")
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
                                                text: "Tunnel"
                                                color: root.themeColorToken("mainHex_2f6ff1", "mainHex_86b6ff")
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 11
                                                font.bold: true
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                enabled: vpnController.processRoutingSupported
                                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                onClicked: vpnController.appendAppRule("proxy", modelData.process || "")
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
                                                text: "Block"
                                                color: root.themeColorToken("mainHex_ca3b3b", "mainHex_ff8da0")
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 11
                                                font.bold: true
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                enabled: vpnController.processRoutingSupported
                                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                onClicked: vpnController.appendAppRule("block", modelData.process || "")
                                            }
                                        }
                                    }

                                    MouseArea {
                                        z: 0
                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton
                                        onClicked: root.toggleAppSuggestionSelection(modelData.process || "")
                                    }
                                }
                            }
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "routing"
                            Layout.preferredHeight: 66
                            enabled: vpnController.processRoutingSupported
                            opacity: enabled ? 1.0 : 0.6
                            placeholderText: "Tunnel Apps\nTelegram\nchrome.exe\ncom.apple.Safari"
                            text: vpnController.proxyAppRules
                            onTextChanged: vpnController.proxyAppRules = text
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "routing"
                            Layout.preferredHeight: 66
                            enabled: vpnController.processRoutingSupported
                            opacity: enabled ? 1.0 : 0.6
                            placeholderText: "Direct Apps\nFinder\nexplorer.exe\nfirefox"
                            text: vpnController.directAppRules
                            onTextChanged: vpnController.directAppRules = text
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "routing"
                            Layout.preferredHeight: 66
                            enabled: vpnController.processRoutingSupported
                            opacity: enabled ? 1.0 : 0.6
                            placeholderText: "Block Apps\nsteam.exe\nDiscord\ncom.apple.Music"
                            text: vpnController.blockAppRules
                            onTextChanged: vpnController.blockAppRules = text
                        }
                    }

                }
            }
        }
    }

    Popup {
        id: aboutPopup
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: root.sheetWidth(430)
        height: root.sheetHeight(540)
        x: (root.width - width) * 0.5
        y: root.drawerY(height)
        padding: 0

        enter: Transition {
            NumberAnimation {
                property: "y"
                from: root.height
                to: root.drawerY(aboutPopup.height)
                duration: Animations.fast * 1.15
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "y"
                to: root.height
                duration: Animations.fast * 0.9
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            radius: 24
            color: root.themeColorToken("mainHex_ffffff", "mainHex_090b14")
            border.width: 0
            border.color: root.themeColorToken("mainHex_d8dde8", "mainHex_151c32")
        }

        contentItem: Item {
            anchors.fill: parent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.compact ? 12 : 16
                spacing: 10

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 4
                    radius: 2
                    color: root.themeColorToken("mainHex_d6dde8", "mainHex_151c32")
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "About"
                        font.family: FontSystem.getContentFontBold.name
                        font.weight: Font.Bold
                        font.pixelSize: 24
                        color: root.themeColorToken("mainHex_1f2530", "mainHex_d8e1f0")
                    }
                    Item { Layout.fillWidth: true }
                    Controls.CircleIconButton {
                        diameter: 34
                        iconText: "×"
                        iconPixelSize: 20
                        iconColor: root.themeColorToken("mainHex_8d96a5", "mainHex_9db0ca")
                        backgroundColor: root.themeColorToken("mainHex_f7f8fb", "mainHex_151c32")
                        borderColor: root.themeColorToken("mainHex_e1e5ed", "mainHex_151c32")
                        onClicked: aboutPopup.close()
                    }
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ColumnLayout {
                        width: aboutPopup.width - 32
                        spacing: 10

                        // --- App Info ---
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 14
                            color: root.themeColorToken("mainHex_f7f9fc", "mainHex_151c32")
                            border.width: 0
                            border.color: root.themeColorToken("mainHex_e0e6f0", "mainHex_30435d")
                            implicitHeight: 64

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "GenyConnect"
                                    color: root.themeColorToken("mainHex_667081", "mainHex_9ab0ca")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 14
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "Version " + updater.appVersion
                                    Layout.maximumWidth: aboutPopup.width * 0.48
                                    elide: Text.ElideRight
                                    color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 14
                                    font.bold: false
                                }
                            }
                        }

                        // --- Developer ---
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 14
                            color: root.themeColorToken("mainHex_f7f9fc", "mainHex_151c32")
                            border.width: 0
                            border.color: root.themeColorToken("mainHex_e0e6f0", "mainHex_30435d")
                            implicitHeight: 64

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Developer"
                                    color: root.themeColorToken("mainHex_667081", "mainHex_9ab0ca")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 14
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "Genyleap LLC"
                                    Layout.maximumWidth: aboutPopup.width * 0.48
                                    elide: Text.ElideRight
                                    color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 14
                                    font.bold: false
                                }
                            }
                        }

                        // --- Website ---
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 14
                            color: root.themeColorToken("mainHex_f7f9fc", "mainHex_151c32")
                            border.width: 0
                            border.color: root.themeColorToken("mainHex_e0e6f0", "mainHex_30435d")
                            implicitHeight: 64

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Website"
                                    color: root.themeColorToken("mainHex_667081", "mainHex_9ab0ca")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 14
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "https://genyleap.com"
                                    Layout.maximumWidth: aboutPopup.width * 0.52
                                    elide: Text.ElideMiddle
                                    color: root.themeColorToken("mainHex_2a3240", "mainHex_9ec1ff")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 14
                                    font.bold: false
                                    font.underline: true

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Qt.openUrlExternally("https://genyleap.com")
                                    }
                                }

                            }
                        }

                        // --- GitHub ---
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 14
                            color: root.themeColorToken("mainHex_f7f9fc", "mainHex_151c32")
                            border.width: 0
                            border.color: root.themeColorToken("mainHex_e0e6f0", "mainHex_30435d")
                            implicitHeight: 64

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Repository"
                                    color: root.themeColorToken("mainHex_667081", "mainHex_9ab0ca")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 14
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "https://github.com/genyleap/genyconnect"
                                    Layout.maximumWidth: aboutPopup.width * 0.52
                                    elide: Text.ElideMiddle
                                    color: root.themeColorToken("mainHex_2a3240", "mainHex_9ec1ff")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 14
                                    font.bold: false
                                    font.underline: true

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Qt.openUrlExternally("https://github.com/genyleap/genyconnect")
                                    }
                                }
                            }
                        }

                        // --- Creator ---
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 14
                            color: root.themeColorToken("mainHex_f7f9fc", "mainHex_151c32")
                            border.width: 0
                            border.color: root.themeColorToken("mainHex_e0e6f0", "mainHex_30435d")
                            implicitHeight: 64

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Creator's Telegram"
                                    color: root.themeColorToken("mainHex_667081", "mainHex_9ab0ca")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 14
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "https://t.me/compezeth"
                                    Layout.maximumWidth: aboutPopup.width * 0.52
                                    elide: Text.ElideMiddle
                                    color: root.themeColorToken("mainHex_2a3240", "mainHex_9ec1ff")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 14
                                    font.bold: false
                                    font.underline: true

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Qt.openUrlExternally("https://t.me/compezeth")
                                    }
                                }
                            }
                        }

                        // --- Email ---
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 14
                            color: root.themeColorToken("mainHex_f7f9fc", "mainHex_151c32")
                            border.width: 0
                            border.color: root.themeColorToken("mainHex_e0e6f0", "mainHex_30435d")
                            implicitHeight: 64

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Support Email"
                                    color: root.themeColorToken("mainHex_667081", "mainHex_9ab0ca")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 14
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "support@genyleap.com"
                                    Layout.maximumWidth: aboutPopup.width * 0.52
                                    elide: Text.ElideMiddle
                                    color: root.themeColorToken("mainHex_2a3240", "mainHex_9ec1ff")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 14
                                    font.bold: false
                                    font.underline: true

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Qt.openUrlExternally("mailto:support@genyleap.com")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: dataUsagePopup

        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: {
            root.usagePanelTab = "current"
            root.usageRefreshNonce += 1
        }
        width: root.sheetWidth(430)
        height: root.compact ? root.height : root.sheetHeight(650)
        x: (root.width - width) * 0.5
        y: root.compact ? 0 : root.drawerY(height)
        padding: 0

        enter: Transition {
            NumberAnimation {
                property: "y"
                from: root.height
                to: root.compact ? 0 : root.drawerY(dataUsagePopup.height)
                duration: Animations.fast * 1.15
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "y"
                to: root.height
                duration: Animations.fast * 0.9
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            radius: root.compact ? 0 : 24
            color: root.themeColorToken("mainHex_ffffff", "mainHex_090b14")
            border.width: 0
            border.color: root.themeColorToken("mainHex_d8dde8", "mainHex_151c32")
            clip: true
        }

        contentItem: Flickable {
            id: usagePopupFlick
            anchors.fill: parent
            clip: true
            contentWidth: width
            readonly property int panelPadding: root.compact ? 10 : 14
            contentHeight: usagePopupContent.implicitHeight + (panelPadding * 2)
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: usagePopupContent
                x: usagePopupFlick.panelPadding
                y: usagePopupFlick.panelPadding
                width: usagePopupFlick.width - (usagePopupFlick.panelPadding * 2)
                spacing: 8

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 4
                    radius: 2
                    color: root.themeColorToken("mainHex_d6dde8", "mainHex_151c32")
                    visible: !root.compact
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Controls.CircleIconButton {
                        visible: root.compact
                        diameter: 38
                        elevated: false
                        backgroundColor: root.themeColorToken("mainHex_faf9ff", "mainHex_151c32")
                        borderColor: root.themeColorToken("mainHex_f0eef8", "mainHex_151c32")
                        iconText: "\uf060"
                        iconFontFamily: root.faSolid
                        iconColor: root.themeColorToken("mainHex_050505", "mainHex_d8e1f0")
                        iconPixelSize: 15
                        onClicked: dataUsagePopup.close()
                    }

                    Text {
                        text: "Data Usage"
                        color: root.themeColorToken("mainHex_1f2530", "mainHex_d8e1f0")
                        font.family: FontSystem.getContentFontBold.name
                        font.weight: Font.Bold
                        font.pixelSize: 23
                    }

                    Item { Layout.fillWidth: true }

                    Controls.CircleIconButton {
                        visible: !root.compact
                        diameter: 34
                        iconText: root.iconClose
                        iconFontFamily: root.faSolid
                        iconColor: root.themeColorToken("mainHex_95a0b3", "mainHex_8ea1ba")
                        iconPixelSize: 14
                        onClicked: dataUsagePopup.close()
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: 8
                    rowSpacing: 8

                    Repeater {
                        model: [
                            { "label": "Day", "value": vpnController.currentProfileUsageDay },
                            { "label": "Month", "value": vpnController.currentProfileUsageMonth },
                            { "label": "Total", "value": (vpnController.currentProfileUsageSummary().totalText || "0 B") }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 58
                            radius: 10
                            color: root.themeColorToken("mainHex_f3f8ff", "mainHex_22324a")
                            border.width: 1
                            border.color: root.themeColorToken("mainHex_d7e4f6", "mainHex_39526f")

                            Column {
                                anchors.centerIn: parent
                                spacing: 2
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.label
                                    color: root.themeColorToken("mainHex_7b8798", "mainHex_9ab0ca")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 11
                                }
                                Controls.NumberFlowText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.value
                                    color: root.themeColorToken("mainHex_1f2937", "mainHex_edf4ff")
                                    fontSize: 15
                                    bold: true
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { "key": "current", "label": "Current Profile" },
                            { "key": "recent", "label": "Recent Sessions" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            radius: 8
                            color: root.usagePanelTab === modelData.key
                                   ? root.themeColorToken("mainHex_2f6ff1", "mainHex_3a7bff")
                                   : root.themeColorToken("mainHex_eff4fb", "mainHex_151c32")
                            border.width: 1
                            border.color: root.usagePanelTab === modelData.key
                                          ? root.themeColorToken("mainHex_2f6ff1", "mainHex_3a7bff")
                                          : root.themeColorToken("mainHex_d7e2f0", "mainHex_395170")

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: root.usagePanelTab === modelData.key
                                       ? Colors.mainHex_ffffff
                                       : root.themeColorToken("mainHex_425874", "mainHex_b6c8df")
                                font.family: FontSystem.getContentFontBold.name
                                font.pixelSize: 12
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.usagePanelTab = modelData.key
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    visible: root.usagePanelTab === "current"
                    implicitHeight: usageCurrentColumnPopup.implicitHeight

                    ColumnLayout {
                        id: usageCurrentColumnPopup
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 8

                        GridLayout {
                            Layout.fillWidth: true
                            columns: root.compact ? 2 : 3
                            columnSpacing: 8
                            rowSpacing: 8

                            Repeater {
                                model: [
                                    { "label": "Hour", "value": vpnController.currentProfileUsageHour },
                                    { "label": "Week", "value": vpnController.currentProfileUsageWeek },
                                    { "label": "Latest", "value": (vpnController.latestRecordedUsage || "0 B") }
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 52
                                    radius: 8
                                    color: root.themeColorToken("mainHex_f3f8ff", "mainHex_22324a")
                                    border.width: 1
                                    border.color: root.themeColorToken("mainHex_d7e4f6", "mainHex_39526f")

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 1
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.label
                                            color: root.themeColorToken("mainHex_7b8798", "mainHex_9ab0ca")
                                            font.family: FontSystem.contentFontFamily
                                            font.pixelSize: 10
                                        }
                                        Controls.NumberFlowText {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.value
                                            color: root.themeColorToken("mainHex_1f2937", "mainHex_edf4ff")
                                            fontSize: 13
                                            bold: true
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: ["hour", "day", "week", "month"]

                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 30
                                    radius: 7
                                    color: root.usageHistoryPeriod === modelData
                                           ? root.themeColorToken("mainHex_2f6ff1", "mainHex_3a7bff")
                                           : root.themeColorToken("mainHex_eff4fb", "mainHex_151c32")
                                    border.width: 1
                                    border.color: root.usageHistoryPeriod === modelData
                                                  ? root.themeColorToken("mainHex_2f6ff1", "mainHex_3a7bff")
                                                  : root.themeColorToken("mainHex_d5dfed", "mainHex_395170")

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                        color: root.usageHistoryPeriod === modelData
                                               ? Colors.mainHex_ffffff
                                               : root.themeColorToken("mainHex_4b5d75", "mainHex_b6c8df")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 11
                                        font.bold: root.usageHistoryPeriod === modelData
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.usageHistoryPeriod = modelData
                                            root.usageRefreshNonce += 1
                                        }
                                    }
                                }
                            }
                        }

                        ListView {
                            id: usageHistoryListPopup
                            Layout.fillWidth: true
                            Layout.preferredHeight: count > 0 ? Math.min(176, Math.max(84, count * 44)) : 52
                            clip: true
                            spacing: 6
                            model: root.currentUsageHistoryModel()

                            delegate: Rectangle {
                                required property var modelData
                                width: ListView.view.width
                                height: 42
                                radius: 8
                                color: root.themeColorToken("mainHex_f7f9fd", "mainHex_22324a")
                                border.width: 1
                                border.color: root.themeColorToken("mainHex_dbe3ef", "mainHex_3a5470")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        Layout.preferredWidth: root.compact ? 88 : 106
                                        text: modelData.key || ""
                                        color: root.themeColorToken("mainHex_334155", "mainHex_d2def0")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: "Down " + (modelData.rxText || "0 B")
                                        color: root.themeColorToken("mainHex_64748b", "mainHex_a4b6cd")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: "Up " + (modelData.txText || "0 B")
                                        color: root.themeColorToken("mainHex_64748b", "mainHex_a4b6cd")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: modelData.totalText || "0 B"
                                        color: root.themeColor(root.brandBlue, Colors.mainHex_7fb0ff)
                                        font.family: FontSystem.getContentFontBold.name
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                }
                            }

                            Text {
                                anchors.fill: parent
                                visible: usageHistoryListPopup.count === 0
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: "No usage history yet."
                                color: root.themeColorToken("mainHex_8a95a8", "mainHex_9eb1c9")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 12
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    visible: root.usagePanelTab === "recent"
                    implicitHeight: usageRecentColumnPopup.implicitHeight

                    ColumnLayout {
                        id: usageRecentColumnPopup
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 8

                        ListView {
                            id: usageSessionsListPopup
                            Layout.fillWidth: true
                            Layout.preferredHeight: usageSessionsListPopup.count > 0 ? 286 : 90
                            clip: true
                            spacing: 6
                            model: root.currentUsageSessionsModel()

                            delegate: Rectangle {
                                required property var modelData
                                width: ListView.view.width
                                height: 40
                                radius: 8
                                color: root.themeColorToken("mainHex_f7f9fd", "mainHex_22324a")
                                border.width: 1
                                border.color: root.themeColorToken("mainHex_dbe3ef", "mainHex_3a5470")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        Layout.fillWidth: true
                                        text: (modelData.startedAt || "") + " - " + (modelData.endedAt || "")
                                        color: root.themeColorToken("mainHex_334155", "mainHex_d2def0")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: modelData.totalText || "0 B"
                                        color: root.themeColor(root.brandBlue, Colors.mainHex_7fb0ff)
                                        font.family: FontSystem.getContentFontBold.name
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                }
                            }

                            Text {
                                anchors.fill: parent
                                visible: usageSessionsListPopup.count === 0
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: vpnController.connected
                                      ? "Session in progress. Disconnect to record it here."
                                      : "No recorded sessions yet."
                                color: root.themeColorToken("mainHex_8a95a8", "mainHex_9eb1c9")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 12
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Controls.Button {
                        text: "Refresh"
                        implicitWidth: 86
                        implicitHeight: 34
                        Layout.fillWidth: true
                        onClicked: root.usageRefreshNonce += 1
                    }

                    Controls.Button {
                        text: "Clear Current"
                        implicitWidth: 106
                        implicitHeight: 34
                        Layout.fillWidth: true
                        onClicked: {
                            vpnController.clearCurrentProfileUsage()
                            root.usageRefreshNonce += 1
                        }
                    }

                    Controls.Button {
                        text: "Clear All"
                        implicitWidth: 96
                        implicitHeight: 34
                        Layout.fillWidth: true
                        onClicked: {
                            vpnController.clearAllProfileUsage()
                            root.usageRefreshNonce += 1
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: logsPopup

        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: root.sheetWidth(430)
        height: root.sheetHeight(520)
        x: (root.width - width) * 0.5
        y: root.drawerY(height)
        padding: 0

        enter: Transition {
            NumberAnimation {
                property: "y"
                from: root.height
                to: root.drawerY(logsPopup.height)
                duration: Animations.fast * 1.15
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "y"
                to: root.height
                duration: Animations.fast * 0.9
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            topRightRadius: 24
            topLeftRadius: 24
            color: root.themeColorToken("mainHex_ffffff", "mainHex_090b14")
            border.width: 0
            border.color: root.themeColorToken("mainHex_d8dde8", "mainHex_151c32")
            clip: true
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.compact ? 10 : 14
            spacing: 8
            clip: true

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 42
                Layout.preferredHeight: 4
                radius: 2
                color: root.themeColorToken("mainHex_d6dde8", "mainHex_151c32")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "Connection History"
                    font.family: FontSystem.getContentFontBold.name
                    font.weight: Font.Bold
                    font.pixelSize: 20
                    color: root.themeColorToken("mainHex_1f2530", "mainHex_d8e1f0")
                    elide: Text.ElideRight
                }

                Controls.CircleIconButton {
                    diameter: 32
                    iconText: root.iconTrash
                    iconFontFamily: root.faSolid
                    iconPixelSize: 12
                    iconColor: vpnController.recentLogs.length > 0
                               ? root.themeColorToken("mainHex_d35b5b", "mainHex_ff8e8e")
                               : root.themeColorToken("mainHex_a8b2c0", "mainHex_8ea1ba")
                    enabled: vpnController.recentLogs.length > 0
                    onClicked: vpnController.clearLogs()
                }

                Controls.CircleIconButton {
                    diameter: 32
                    iconText: root.iconCopy
                    iconFontFamily: root.faSolid
                    iconPixelSize: 12
                    iconColor: vpnController.loggingEnabled && vpnController.recentLogs.length > 0
                               ? root.themeColorToken("mainHex_64748b", "mainHex_a4b6cd")
                               : root.themeColorToken("mainHex_a8b2c0", "mainHex_8ea1ba")
                    enabled: vpnController.loggingEnabled && vpnController.recentLogs.length > 0
                    onClicked: vpnController.copyLogsToClipboard()
                }

                Controls.CircleIconButton {
                    diameter: 32
                    iconText: root.iconClose
                    iconFontFamily: root.faSolid
                    iconPixelSize: 12
                    iconColor: root.themeColorToken("mainHex_94a3b8", "mainHex_a2b5ce")
                    onClicked: logsPopup.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !vpnController.loggingEnabled
                radius: 16
                color: root.themeColorToken("mainHex_f7f9fc", "mainHex_151c32")
                border.width: 0
                border.color: root.themeColorToken("mainHex_e1e6ee", "mainHex_30435d")
                clip: true

                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 32, 280)
                    spacing: 12

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.iconHistory
                        color: root.themeColorToken("mainHex_9aa8bb", "mainHex_9db1ca")
                        font.family: root.faSolid
                        font.pixelSize: 28
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Logging is disabled"
                        color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                        font.family: FontSystem.getContentFontBold.name
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Enable xray logs in Settings to capture connection history."
                        color: root.themeColorToken("mainHex_8b95a5", "mainHex_9cb0c8")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                visible: vpnController.loggingEnabled

                TextArea {
                    id: logsTextArea
                    readOnly: true
                    wrapMode: TextEdit.NoWrap
                    selectByMouse: true
                    text: vpnController.recentLogs.join("\n")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                    color: root.themeColorToken("mainHex_1f2530", "mainHex_e7eefb")
                    background: Rectangle {
                        color: root.themeColorToken("mainHex_f7f9fc", "mainHex_151c32")
                        border.color: root.themeColorToken("mainHex_e1e6ee", "mainHex_30435d")
                        border.width: 0
                        radius: 12
                    }
                    onTextChanged: {
                        cursorPosition = length
                    }
                }
            }
        }
    }

    Popup {
        id: speedTestPopup

        property bool showHistory: true

        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: root.sheetWidth(430)
        height: root.compact ? root.height : root.sheetHeight(650)
        x: (root.width - width) * 0.5
        y: root.compact ? 0 : root.drawerY(height)
        padding: 0

        enter: Transition {
            NumberAnimation {
                property: "y"
                from: root.height
                to: root.compact ? 0 : root.drawerY(speedTestPopup.height)
                duration: Animations.fast * 1.15
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "y"
                to: root.height
                duration: Animations.fast * 0.9
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            radius: root.compact ? 0 : 24
            color: root.themeColorToken("mainHex_ffffff", "mainHex_090b14")
            border.width: 0
            border.color: root.themeColorToken("mainHex_d8dde8", "mainHex_151c32")
            clip: true
        }

        contentItem: Flickable {
            id: speedTestPopupFlick
            anchors.fill: parent
            clip: true
            contentWidth: width
            readonly property int panelPadding: root.compact ? 10 : 14
            contentHeight: speedTestPopupContent.implicitHeight + (panelPadding * 2)
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: speedTestPopupContent
                x: speedTestPopupFlick.panelPadding
                y: speedTestPopupFlick.panelPadding
                width: speedTestPopupFlick.width - (speedTestPopupFlick.panelPadding * 2)
                spacing: 8

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 42
                Layout.preferredHeight: 4
                radius: 2
                color: root.themeColorToken("mainHex_d6dde8", "mainHex_151c32")
                visible: !root.compact
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Controls.CircleIconButton {
                    visible: root.compact
                    diameter: 38
                    elevated: false
                    backgroundColor: root.themeColorToken("mainHex_faf9ff", "mainHex_151c32")
                    borderColor: root.themeColorToken("mainHex_f0eef8", "mainHex_151c32")
                    iconText: "\uf060"
                    iconFontFamily: root.faSolid
                    iconColor: root.themeColorToken("mainHex_050505", "mainHex_d8e1f0")
                    iconPixelSize: 15
                    onClicked: speedTestPopup.close()
                }

                Text {
                    text: "Speed Test"
                    color: Colors.textPrimary
                    font.family: FontSystem.getContentFontBold.name
                    font.weight: Font.Bold
                    font.pixelSize: 23
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    spacing: 10

                    Controls.CircleIconButton {
                        visible: !root.compact
                        diameter: 34
                        iconText: root.iconSetting
                        iconFontFamily: root.faSolid
                        iconColor: root.themeColorToken("mainHex_a0a8b5", "mainHex_8ea1ba")
                        iconPixelSize: 14
                        onClicked: settingsPopup.open()
                    }

                    Controls.CircleIconButton {
                        visible: !root.compact
                        diameter: 34
                        iconText: root.iconClose
                        iconFontFamily: root.faSolid
                        iconColor: root.themeColorToken("mainHex_95a0b3", "mainHex_8ea1ba")
                        iconPixelSize: 14
                        onClicked: speedTestPopup.close()
                    }
                }
            }

            Item {
                id: speedTestCenterArea
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: 200
                Layout.minimumHeight: 32

                Controls.SpeedTestGauge {
                    id: speedDial
                    anchors.centerIn: parent
                    width: Math.min(speedTestCenterArea.width - 18, 420)
                    height: Math.max(248, width * 0.66)
                    value: root.speedGaugeValue()
                    minimumValue: 0.0
                    maximumValue: root.speedGaugeMaxMbps()
                    unit: root.speedGaugeUnitText()
                    darkMode: root.darkThemeEnabled
                    useOwnBackground: false
                    particlesEnabled: vpnController.speedTestRunning
                    particleIntensity: vpnController.speedTestRunning ? 1.0 : 0.22
                    particleCount: root.compact ? 54 : 72
                    sparkCount: root.compact ? 10 : 14
                }
            }

            Text {
                Layout.fillWidth: true
                text: vpnController.speedTestRunning ? speedTestStatusText() : speedTestSideStatusText()
                color: vpnController.speedTestError.length > 0
                       ? root.themeColorToken("mainHex_d14545", "mainHex_ff8e8e")
                       : (vpnController.speedTestRunning
                          ? root.themeColorToken("mainHex_6a7890", "mainHex_9db2cc")
                          : root.themeColorToken("mainHex_5f6f88", "mainHex_9bb0cb"))
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.preferredHeight: 26
                    Layout.preferredWidth: 108
                    radius: 14
                    color: root.themeColorToken("mainHex_edf4ff", "mainHex_151c32")
                    border.width: 0
                    border.color: root.themeColorToken("mainHex_cadcf3", "mainHex_151c32")

                    Text {
                        anchors.centerIn: parent
                        text: root.speedTestPhaseBadgeText()
                        color: root.themeColorToken("mainHex_22456f", "mainHex_d7e9ff")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                Rectangle {
                    Layout.preferredHeight: 26
                    Layout.preferredWidth: 126
                    radius: 14
                    color: root.themeColorToken("mainHex_edf4ff", "mainHex_151c32")
                    border.width: 0
                    border.color: root.themeColorToken("mainHex_cadcf3", "mainHex_151c32")

                    Text {
                        anchors.centerIn: parent
                        text: root.speedTestProgressText()
                        color: root.themeColorToken("mainHex_22456f", "mainHex_d7e9ff")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    radius: 14
                    color: root.themeColorToken("mainHex_edf4ff", "mainHex_151c32")
                    border.width: 0
                    border.color: root.themeColorToken("mainHex_cadcf3", "mainHex_151c32")

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: root.speedTestFooterText()
                        elide: Text.ElideRight
                        color: root.themeColorToken("mainHex_22456f", "mainHex_d7e9ff")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 9
                        font.bold: true
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                Text {
                    text: "Gauge Range"
                    color: root.themeColorToken("mainHex_64748b", "mainHex_9db2cc")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                }

                Repeater {
                    model: ["Small", "Medium", "Large", "Auto"]

                    delegate: Rectangle {
                        required property string modelData
                        Layout.preferredWidth: modelData === "Medium" ? 72 : 62
                        Layout.preferredHeight: 26
                        radius: 8
                        color: root.speedGaugeRangePreset === modelData
                               ? root.themeColorToken("mainHex_2f6ff1", "mainHex_3a7bff")
                               : root.themeColorToken("mainHex_f5f8fc", "mainHex_151c32")
                        border.width: 0
                        border.color: root.speedGaugeRangePreset === modelData
                                      ? root.themeColorToken("mainHex_2f6ff1", "mainHex_3a7bff")
                                      : root.themeColorToken("mainHex_dbe3ef", "mainHex_151c32")

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: root.speedGaugeRangePreset === modelData
                                   ? Colors.mainHex_ffffff
                                   : root.themeColorToken("mainHex_495971", "mainHex_b7cae2")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 11
                            font.bold: root.speedGaugeRangePreset === modelData
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.speedGaugeRangePreset = modelData
                        }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 7

                Repeater {
                    model: 6

                    delegate: Rectangle {
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: index < 2 ? 72 : 60
                        radius: 16
                        color: (vpnController.speedTestState === "Completed" || vpnController.speedTestRunning)
                               ? root.themeColorToken("mainHex_f3f8ff", "mainHex_151c32")
                               : root.themeColorToken("mainHex_f9fbff", "mainHex_151c32")
                        border.width: 0
                        border.color: root.themeColorToken("mainHex_d1e0f2", "mainHex_151c32")

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: root.speedMetricLabel(index)
                                color: root.themeColorToken("mainHex_5d7ea3", "mainHex_89a8c8")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 12
                            }
                            Text {
                                text: root.speedMetricValue(index)
                                color: root.themeColorToken("mainHex_16365c", "mainHex_f2f7ff")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: index < 2 ? 19 : 17
                                font.bold: true
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Route stability " + ((vpnController.speedTestRunning || vpnController.speedTestState === "Completed")
                                                ? (vpnController.speedTestRouteStabilityPct + "%")
                                                : "--")
                    color: root.themeColorToken("mainHex_5d6d84", "mainHex_9db2cc")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 11
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Overall " + root.speedOverallDisplayText()
                    color: root.themeColorToken("mainHex_5d6d84", "mainHex_9db2cc")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 11
            }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 72
                implicitHeight: 72

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Test Size"
                        color: root.themeColorToken("mainHex_64748b", "mainHex_9db2cc")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 13
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10

                        Repeater {
                            model: [5, 10, 25]

                            delegate: Rectangle {
                                required property int modelData
                                width: 62
                                height: 32
                                radius: 10
                                color: vpnController.speedTestSelectedSizeMb === modelData
                                       ? root.themeColorToken("mainHex_2f6ff1", "mainHex_3a7bff")
                                       : root.themeColorToken("mainHex_f5f8fc", "mainHex_151c32")
                                border.width: 0
                                border.color: vpnController.speedTestSelectedSizeMb === modelData
                                              ? root.themeColorToken("mainHex_2f6ff1", "mainHex_3a7bff")
                                              : root.themeColorToken("mainHex_dbe3ef", "mainHex_151c32")

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData + " MB"
                                    color: vpnController.speedTestSelectedSizeMb === modelData
                                           ? Colors.mainHex_ffffff
                                           : root.themeColorToken("mainHex_495971", "mainHex_b7cae2")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 12
                                    font.bold: vpnController.speedTestSelectedSizeMb === modelData
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !vpnController.speedTestRunning
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: vpnController.speedTestSelectedSizeMb = modelData
                                }
                            }
                        }
                    }
                }
            }

            Controls.PrimaryActionButton {
                Layout.alignment: Qt.AlignHCenter
                width: 166
                height: 44
                text: vpnController.speedTestRunning ? "Cancel" : "Start Test"
                enabled: vpnController.speedTestRunning || vpnController.connectionState === ConnectionState.Connected
                onClicked: {
                    if (vpnController.speedTestRunning) {
                        vpnController.cancelSpeedTest()
                    } else {
                        vpnController.startSpeedTest()
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 14
                visible: speedTestPopup.width >= 560

                Text {
                    text: root.infoIpLabel() + ":"
                    color: root.themeColorToken("mainHex_1f2430", "mainHex_d7e4f6")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    text: infoIpText()
                    color: root.themeColorToken("mainHex_8f97a6", "mainHex_9eb2cb")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                }

                Rectangle { width: 1; height: 26; color: root.themeColorToken("mainHex_d4d9e3", "mainHex_151c32") }

                Text {
                    text: "Proxy:"
                    color: root.themeColorToken("mainHex_1f2430", "mainHex_d7e4f6")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    text: speedTestProxyText()
                    color: root.themeColorToken("mainHex_8f97a6", "mainHex_9eb2cb")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                }

                Rectangle { width: 1; height: 26; color: root.themeColorToken("mainHex_d4d9e3", "mainHex_151c32") }

                Text {
                    text: "Provider:"
                    color: root.themeColorToken("mainHex_1f2430", "mainHex_d7e4f6")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    text: speedTestProviderText()
                    color: root.themeColorToken("mainHex_8f97a6", "mainHex_9eb2cb")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                }

                Rectangle { width: 1; height: 26; color: root.themeColorToken("mainHex_d4d9e3", "mainHex_151c32") }

                Text {
                    text: "OS:"
                    color: root.themeColorToken("mainHex_1f2430", "mainHex_d7e4f6")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    text: osNameText()
                    color: root.themeColorToken("mainHex_8f97a6", "mainHex_9eb2cb")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                }
            }

            Rectangle {
                visible: true
                Layout.fillWidth: true
                Layout.preferredHeight: 82
                Layout.minimumHeight: 82
                radius: 16
                color: root.themeColorToken("mainHex_f7f9fc", "mainHex_151c32")
                border.width: 0
                border.color: root.themeColorToken("mainHex_dde4ef", "mainHex_151c32")

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: "Latest Results"
                        color: root.themeColorToken("mainHex_3f4d63", "mainHex_d7e4f6")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ListView {
                            anchors.fill: parent
                            clip: true
                            spacing: 2
                            model: vpnController.speedTestHistory
                            visible: vpnController.speedTestHistory.length > 0
                            boundsBehavior: Flickable.StopAtBounds

                            delegate: Item {
                                required property string modelData
                                width: ListView.view.width
                                height: 24

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 6
                                    text: modelData
                                    elide: Text.ElideRight
                                    color: root.themeColorToken("mainHex_586780", "mainHex_b0c3db")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 13
                                }
                            }

                            ScrollBar.vertical: ScrollBar { }
                        }

                        Text {
                            anchors.fill: parent
                            visible: vpnController.speedTestHistory.length === 0
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            text: "No completed tests yet."
                            color: root.themeColorToken("mainHex_8a95a8", "mainHex_9eb2cb")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 13
                        }
                    }
                }
            }
            }
        }
    }

    Popup {
        id: importPopup

        modal: true
        focus: true
        property string selectedManageGroup: ""
        readonly property bool hasExplicitGroup: ((subscriptionGroupField.text || "").trim().length > 0)
        readonly property string targetGroupName: root.normalizeImportGroupName(subscriptionGroupField.text || root.subscriptionGroupDraft)
        closePolicy: vpnController.subscriptionBusy
                     ? Popup.NoAutoClose
                     : (Popup.CloseOnEscape | Popup.CloseOnPressOutside)
        width: root.sheetWidth(430)
        height: root.sheetHeight(660)
        x: (root.width - width) * 0.5
        y: root.drawerY(height)
        padding: 0

        onAboutToShow: {
            const currentGroup = (vpnController.currentProfileGroup || "All")
            if (!root.subscriptionGroupDraft || root.subscriptionGroupDraft.trim().length === 0
                    || root.subscriptionGroupDraft.trim().toLowerCase() === "all") {
                root.subscriptionGroupDraft = currentGroup === "All" ? "General" : currentGroup
            }
            subscriptionGroupField.text = root.subscriptionGroupDraft
            selectedManageGroup = targetGroupName
            root.importWaitingForSubscription = false
            root.importStatusKind = "idle"
            root.importStatusText = ""
        }
        onClosed: root.importWaitingForSubscription = false

        enter: Transition {
            NumberAnimation {
                property: "y"
                from: root.height
                to: root.drawerY(importPopup.height)
                duration: Animations.fast * 1.15
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "y"
                to: root.height
                duration: Animations.fast * 0.9
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            topRightRadius: 24
            topLeftRadius: 24
            color: root.themeColorToken("mainHex_ffffff", "mainHex_090b14")
            border.width: 0
            border.color: root.themeColorToken("mainHex_d8dde8", "mainHex_151c32")
        }

        Connections {
            target: vpnController
            function onSubscriptionStateChanged() {
                if (!importPopup.visible || !root.importWaitingForSubscription || vpnController.subscriptionBusy)
                    return

                root.importWaitingForSubscription = false
                const msg = (vpnController.subscriptionMessage || "").trim()
                const lower = msg.toLowerCase()
                const success = lower.indexOf("imported") >= 0
                root.importStatusKind = success ? "success" : "error"
                root.importStatusText = msg.length > 0
                        ? msg
                        : (success ? "Import completed." : "Import failed.")
                if (success) {
                    root.importDraft = ""
                    importTextArea.text = ""
                }
            }
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.compact ? 12 : 16
            spacing: 10

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 42
                Layout.preferredHeight: 4
                radius: 2
                color: root.themeColorToken("mainHex_d6dde8", "mainHex_151c32")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Import Profiles"
                    font.family: FontSystem.getContentFontBold.name
                    font.weight: Font.Bold
                    font.pixelSize: 23
                    color: root.themeColorToken("mainHex_1f2530", "mainHex_d8e1f0")
                }

                Item { Layout.fillWidth: true }

                Controls.CircleIconButton {
                    diameter: 32
                    elevated: false
                    iconText: root.iconClose
                    iconFontFamily: root.faSolid
                    iconPixelSize: 13
                    backgroundColor: root.themeColorToken("mainHex_f7f9fc", "mainHex_151c32")
                    borderColor: root.themeColorToken("mainHex_d8e1ef", "mainHex_4d6a8d")
                    iconColor: root.themeColorToken("mainHex_94a3b8", "mainHex_a2b5ce")
                    enabled: !vpnController.subscriptionBusy
                    onClicked: importPopup.close()
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Paste vmess/vless, batch text, base64 payload, or an https subscription URL."
                color: root.themeColorToken("mainHex_6f7f95", "mainHex_9eb2cb")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: 12
                    color: root.themeColorToken("mainHex_f7f9fd", "mainHex_151c32")
                    border.width: 0
                    border.color: subscriptionGroupField.activeFocus
                                  ? root.themeColorToken("mainHex_b9ccee", "mainHex_5f87c2")
                                  : root.themeColorToken("mainHex_d9e1ef", "mainHex_3a5470")

                    TextField {
                        id: subscriptionGroupField
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        padding: 0
                        text: root.subscriptionGroupDraft
                        placeholderText: "Group name"
                        color: root.themeColorToken("mainHex_1f2a3a", "mainHex_edf4ff")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 13
                        selectedTextColor: Colors.mainHex_ffffff
                        selectionColor: root.brandBlue
                        selectByMouse: true
                        background: null
                        onTextEdited: {
                            root.subscriptionGroupDraft = text
                            importPopup.selectedManageGroup = root.normalizeImportGroupName(text)
                        }
                    }
                }

                Controls.CircleIconButton {
                    diameter: 32
                    elevated: false
                    iconText: root.iconPlus
                    iconFontFamily: root.faSolid
                    iconPixelSize: 12
                    backgroundColor: root.themeColorToken("mainHex_f4f8ff", "mainHex_151c32")
                    borderColor: root.themeColorToken("mainHex_d8e4f8", "mainHex_4d6a8d")
                    iconColor: root.brandBlue
                    enabled: !vpnController.subscriptionBusy
                    onClicked: {
                        const groupName = root.normalizeImportGroupName(subscriptionGroupField.text)
                        if (vpnController.ensureProfileGroup(groupName)) {
                            const lower = groupName.toLowerCase()
                            if (lower === "free" || lower === "premium")
                                vpnController.setProfileGroupBadge(groupName, lower === "free" ? "Free" : "Premium")
                            subscriptionGroupField.text = groupName
                            root.subscriptionGroupDraft = groupName
                            importPopup.selectedManageGroup = groupName
                            root.importStatusKind = "success"
                            root.importStatusText = "Group '" + groupName + "' is ready."
                        } else {
                            root.importStatusKind = "error"
                            root.importStatusText = "Group name is not valid."
                        }
                    }
                }

                Controls.CircleIconButton {
                    diameter: 32
                    elevated: false
                    iconText: root.iconMinus
                    iconFontFamily: root.faSolid
                    iconPixelSize: 12
                    backgroundColor: root.themeColorToken("mainHex_fff6f6", "mainHex_3b2631")
                    borderColor: root.themeColorToken("mainHex_f0d5d5", "mainHex_7d5062")
                    iconColor: root.themeColorToken("mainHex_cb4f4f", "mainHex_ff8e8e")
                    enabled: !vpnController.subscriptionBusy
                             && !root.isProtectedGroup(root.normalizeImportGroupName(subscriptionGroupField.text))
                    onClicked: {
                        const groupName = root.normalizeImportGroupName(subscriptionGroupField.text)
                        if (vpnController.removeProfileGroup(groupName)) {
                            subscriptionGroupField.text = "General"
                            root.subscriptionGroupDraft = "General"
                            importPopup.selectedManageGroup = "General"
                            root.importStatusKind = "success"
                            root.importStatusText = "Group '" + groupName + "' removed."
                        } else {
                            root.importStatusKind = "error"
                            root.importStatusText = "Cannot remove this group."
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Badge"
                    color: root.themeColorToken("mainHex_6b778a", "mainHex_9cb0c8")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                }

                Rectangle {
                    Layout.preferredWidth: 76
                    Layout.preferredHeight: 32
                    radius: 16
                    color: root.profileGroupBadgeText(subscriptionGroupField.text).length === 0
                           ? root.themeColorToken("mainHex_eaf2ff", "mainHex_223753")
                           : root.themeColorToken("mainHex_ffffff", "mainHex_22324a")
                    border.width: 0
                    border.color: root.profileGroupBadgeText(subscriptionGroupField.text).length === 0
                                  ? root.brandBlue
                                  : root.themeColorToken("mainHex_dfe7f2", "mainHex_151c32")

                    Text {
                        anchors.centerIn: parent
                        text: "None"
                        color: root.profileGroupBadgeText(subscriptionGroupField.text).length === 0
                               ? root.brandBlue
                               : root.themeColorToken("mainHex_667487", "mainHex_9bb0cb")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 12
                        font.bold: root.profileGroupBadgeText(subscriptionGroupField.text).length === 0
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const groupName = root.normalizeImportGroupName(subscriptionGroupField.text)
                            vpnController.ensureProfileGroup(groupName)
                            vpnController.setProfileGroupBadge(groupName, "")
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 76
                    Layout.preferredHeight: 32
                    radius: 16
                    color: root.profileGroupBadgeText(subscriptionGroupField.text).toLowerCase() === "free"
                           ? root.themeColorToken("mainHex_eaf2ff", "mainHex_223753")
                           : root.themeColorToken("mainHex_ffffff", "mainHex_22324a")
                    border.width: 0
                    border.color: root.profileGroupBadgeText(subscriptionGroupField.text).toLowerCase() === "free"
                                  ? root.brandBlue
                                  : root.themeColorToken("mainHex_dfe7f2", "mainHex_151c32")

                    Text {
                        anchors.centerIn: parent
                        text: "Free"
                        color: root.profileGroupBadgeText(subscriptionGroupField.text).toLowerCase() === "free"
                               ? root.brandBlue
                               : root.themeColorToken("mainHex_667487", "mainHex_9bb0cb")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 12
                        font.bold: root.profileGroupBadgeText(subscriptionGroupField.text).toLowerCase() === "free"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const groupName = root.normalizeImportGroupName(subscriptionGroupField.text)
                            vpnController.ensureProfileGroup(groupName)
                            vpnController.setProfileGroupBadge(groupName, "Free")
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 92
                    Layout.preferredHeight: 32
                    radius: 16
                    color: root.profileGroupBadgeText(subscriptionGroupField.text).toLowerCase() === "premium"
                           ? root.themeColorToken("mainHex_efeaff", "mainHex_2a2450")
                           : root.themeColorToken("mainHex_ffffff", "mainHex_22324a")
                    border.width: 0
                    border.color: root.profileGroupBadgeText(subscriptionGroupField.text).toLowerCase() === "premium"
                                  ? root.themeColor(root.brandViolet, Colors.mainHex_7568d5)
                                  : root.themeColorToken("mainHex_dfe7f2", "mainHex_151c32")

                    Text {
                        anchors.centerIn: parent
                        text: "Premium"
                        color: root.profileGroupBadgeText(subscriptionGroupField.text).toLowerCase() === "premium"
                               ? root.themeColor(root.brandViolet, Colors.mainHex_b8acff)
                               : root.themeColorToken("mainHex_667487", "mainHex_9bb0cb")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 12
                        font.bold: root.profileGroupBadgeText(subscriptionGroupField.text).toLowerCase() === "premium"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const groupName = root.normalizeImportGroupName(subscriptionGroupField.text)
                            vpnController.ensureProfileGroup(groupName)
                            vpnController.setProfileGroupBadge(groupName, "Premium")
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: root.width >= 620

                Rectangle {
                    radius: 10
                    height: 28
                    width: groupStateText.implicitWidth + 18
                    color: root.profileGroupEnabled(subscriptionGroupField.text)
                           ? root.themeColorToken("mainHex_e8f7ef", "mainHex_173c2f")
                           : root.themeColorToken("mainHex_fff0f0", "mainHex_3b2631")
                    border.width: 0
                    border.color: root.profileGroupEnabled(subscriptionGroupField.text)
                                  ? root.themeColorToken("mainHex_b7e4cb", "mainHex_3f8569")
                                  : root.themeColorToken("mainHex_f2c6c6", "mainHex_7d5062")

                    Text {
                        id: groupStateText
                        anchors.centerIn: parent
                        text: root.profileGroupEnabled(subscriptionGroupField.text) ? "Group Enabled" : "Group Disabled"
                        color: root.profileGroupEnabled(subscriptionGroupField.text)
                               ? root.themeColorToken("mainHex_2c8b57", "mainHex_5adf97")
                               : root.themeColorToken("mainHex_bf4d4d", "mainHex_ff8e8e")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 11
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: 12
                    color: root.themeColorToken("mainHex_f7f9fd", "mainHex_151c32")
                    border.width: 0
                    border.color: root.themeColorToken("mainHex_dce4f2", "mainHex_151c32")

                    RowLayout {
                        Layout.fillWidth: true
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Controls.Switch {
                            checked: root.profileGroupEnabled(subscriptionGroupField.text)
                            onToggled: {
                                const groupName = root.normalizeImportGroupName(subscriptionGroupField.text)
                                vpnController.setProfileGroupEnabled(groupName, checked)
                            }
                            title: "Enabled"
                        }

                        Controls.Switch {
                            checked: root.profileGroupExclusive(subscriptionGroupField.text)
                            onToggled: {
                                const groupName = root.normalizeImportGroupName(subscriptionGroupField.text)
                                vpnController.setProfileGroupExclusive(groupName, checked)
                            }
                            title: "Exclusive"
                        }

                        Rectangle {
                            Layout.preferredWidth: 128
                            Layout.preferredHeight: 28
                            radius: 9
                            color: root.themeColorToken("mainHex_ffffff", "mainHex_22324a")
                            border.width: 0
                            border.color: root.themeColorToken("mainHex_d5deec", "mainHex_151c32")

                            TextField {
                                id: importGroupBadgeField
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                padding: 0
                                clip: true
                                placeholderText: "Badge"
                                text: root.profileGroupBadgeText(subscriptionGroupField.text)
                                color: root.themeColorToken("mainHex_3b4a61", "mainHex_d0ddf0")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 12
                                background: null
                                onEditingFinished: {
                                    const groupName = root.normalizeImportGroupName(subscriptionGroupField.text)
                                    vpnController.setProfileGroupBadge(groupName, text)
                                }
                            }
                        }

                        Text {
                            visible: root.profileGroupBadgeText(subscriptionGroupField.text).length > 0
                            text: "• " + root.profileGroupBadgeText(subscriptionGroupField.text)
                            color: root.themeColorToken("mainHex_4d6691", "mainHex_9fc3f2")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Groups: " + root.importSelectableGroups().length
                    color: root.themeColorToken("mainHex_90a0b5", "mainHex_9fb4cd")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 11
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: 10
                color: root.themeColorToken("mainHex_eef4ff", "mainHex_223753")
                border.width: 0
                border.color: root.themeColorToken("mainHex_d2def4", "mainHex_151c32")

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: "Import Target Group:"
                        color: root.themeColorToken("mainHex_5f6f86", "mainHex_9bb0cb")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 12
                    }

                    Text {
                        Layout.fillWidth: true
                        text: importPopup.targetGroupName
                        color: root.themeColorToken("mainHex_2c5eaf", "mainHex_8ab6ff")
                        font.family: FontSystem.getContentFontBold.name
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: root.width >= 620
                        text: "All pasted profiles/subscriptions will be saved here."
                        color: root.themeColorToken("mainHex_7d8ea7", "mainHex_9eb2cb")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 11
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: root.width >= 620
                Layout.preferredHeight: 232
                radius: 12
                color: root.themeColorToken("mainHex_f7f9fd", "mainHex_151c32")
                border.width: 0
                border.color: root.themeColorToken("mainHex_d8e1ef", "mainHex_151c32")

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Manage Groups"
                            color: root.themeColorToken("mainHex_5f6f86", "mainHex_9bb0cb")
                            font.family: FontSystem.getContentFontBold.name
                            font.pixelSize: 12
                        }
                        Item { Layout.fillWidth: true }
                        Controls.Button {
                            Layout.fillWidth: false
                            implicitWidth: 130
                            implicitHeight: 28
                            isDefault: false
                            text: "Remove All Groups"
                            enabled: !vpnController.subscriptionBusy && root.importSelectableGroups().length > 1
                            onClicked: vpnController.removeAllProfileGroups()
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        model: vpnController.profileGroupItems
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Rectangle {
                            required property var modelData
                            readonly property string groupName: (typeof name !== "undefined" && name !== null
                                                                 && String(name).trim().length > 0)
                                                                ? String(name)
                                                                : ((modelData && modelData.name) ? String(modelData.name) : "")
                            readonly property bool groupEnabled: (typeof enabled !== "undefined")
                                                                 ? (enabled !== false)
                                                                 : !(modelData && modelData.enabled === false)
                            readonly property bool groupExclusive: (typeof exclusive !== "undefined")
                                                                   ? (exclusive === true)
                                                                   : (modelData && modelData.exclusive === true)
                            readonly property string groupBadge: (typeof badge !== "undefined" && badge !== null)
                                                                 ? String(badge)
                                                                 : ((modelData && modelData.badge) ? String(modelData.badge) : "")
                            readonly property bool selectedGroup: importPopup.selectedManageGroup.toLowerCase() === groupName.toLowerCase()

                            width: ListView.view.width - 16
                            height: groupName.toLowerCase() === "all" ? 0 : 64
                            visible: groupName.toLowerCase() !== "all"
                            radius: 10
                            color: selectedGroup
                                   ? root.themeColorToken("mainHex_eaf2ff", "mainHex_223753")
                                   : root.themeColorToken("mainHex_ffffff", "mainHex_22324a")
                            border.width: selectedGroup ? 2 : 1
                            border.color: selectedGroup
                                          ? root.themeColorToken("mainHex_3d7ae6", "mainHex_5f95f2")
                                          : root.themeColorToken("mainHex_dee6f3", "mainHex_151c32")

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                Item {
                                    Layout.preferredWidth: 128
                                    Layout.fillHeight: true
                                    implicitHeight: 28
                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            importPopup.selectedManageGroup = groupName
                                            subscriptionGroupField.text = groupName
                                            root.subscriptionGroupDraft = groupName
                                        }
                                    }

                                    Text {
                                        anchors.fill: parent
                                        text: groupName
                                        color: root.themeColorToken("mainHex_2b3648", "mainHex_d7e4f6")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                Controls.Switch {
                                    Layout.fillWidth: false
                                    title: "Enabled"
                                    checked: groupEnabled
                                    onToggled: vpnController.setProfileGroupEnabled(groupName, checked)
                                }

                                Controls.Switch {
                                    Layout.fillWidth: false
                                    title: "Exclusive"
                                    checked: groupExclusive
                                    enabled: groupEnabled
                                    onToggled: vpnController.setProfileGroupExclusive(groupName, checked)
                                }

                                Item { Layout.fillWidth: true }

                                TextField {
                                    Layout.fillWidth: true
                                    placeholderText: "Badge"
                                    text: groupBadge
                                    selectByMouse: true
                                    color: root.themeColorToken("mainHex_3b4a61", "mainHex_d0ddf0")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 12
                                    background: Rectangle {
                                        radius: 8
                                        color: root.themeColorToken("mainHex_f8fbff", "mainHex_22324a")
                                        border.width: 0
                                        border.color: root.themeColorToken("mainHex_d5deec", "mainHex_151c32")
                                    }
                                    onEditingFinished: vpnController.setProfileGroupBadge(groupName, text)
                                }

                                Controls.CircleIconButton {
                                    diameter: 24
                                    iconText: root.iconTrash
                                    iconFontFamily: root.faSolid
                                    iconPixelSize: 10
                                    iconColor: root.themeColorToken("mainHex_cb4f4f", "mainHex_ff8e8e")
                                    enabled: !root.isProtectedGroup(groupName)
                                    onClicked: vpnController.removeProfileGroup(groupName)
                                }
                            }

                        }

                        ScrollBar.vertical: ScrollBar { }
                    }
                }
            }

            Controls.TextArea {
                id: importTextArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 128
                fillColor: root.themeColorToken("mainHex_f8fbff", "mainHex_8a18283d")
                strokeColor: root.themeColorToken("mainHex_d8e2f0", "mainHex_3f587a")
                focusColor: root.themeColorToken("mainHex_8bb8ff", "mainHex_6ba0ff")
                placeholderText: "Paste vmess/vless, batch list, base64 subscription payload, or https subscription URL"
                text: root.importDraft
                onTextChanged: root.importDraft = text
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                BusyIndicator {
                    running: vpnController.subscriptionBusy
                    visible: vpnController.subscriptionBusy
                    implicitWidth: 18
                    implicitHeight: 18
                }

                Text {
                    Layout.fillWidth: true
                    text: vpnController.subscriptionBusy
                          ? (vpnController.subscriptionMessage.length > 0
                             ? vpnController.subscriptionMessage
                             : "Importing from subscription...")
                          : (root.importStatusText.length > 0
                             ? root.importStatusText
                             : (vpnController.subscriptionMessage.length > 0 ? vpnController.subscriptionMessage : ""))
                    color: vpnController.subscriptionBusy
                           ? root.themeColorToken("mainHex_2b6dcf", "mainHex_8ab6ff")
                           : (root.importStatusKind === "success"
                              ? root.themeColorToken("mainHex_2c8b57", "mainHex_5adf97")
                              : (root.importStatusKind === "error"
                                 ? root.themeColorToken("mainHex_c65050", "mainHex_ff8e8e")
                                 : root.themeColorToken("mainHex_6f7f95", "mainHex_9eb2cb")))
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            ProgressBar {
                Layout.fillWidth: true
                visible: vpnController.subscriptionBusy
                indeterminate: true
                value: vpnController.subscriptionBusy ? 0.5 : 0.0
            }

            RowLayout {
                Layout.fillWidth: true

                Controls.Button {
                    implicitWidth: 104
                    isDefault: false
                    text: vpnController.subscriptionBusy ? "Working..." : "Close"
                    Layout.fillWidth: false
                    enabled: !vpnController.subscriptionBusy
                    onClicked: importPopup.close()
                }

                Item { Layout.fillWidth: true }

                Controls.Button {
                    implicitWidth: 218
                    isDefault: true
                    text: vpnController.subscriptionBusy ? "Please wait..." : "Import"
                    Layout.fillWidth: false
                    enabled: !vpnController.subscriptionBusy && importPopup.hasExplicitGroup
                    onClicked: {
                        const raw = importTextArea.text.trim()
                        if (raw.length === 0) {
                            root.importStatusKind = "error"
                            root.importStatusText = "Paste a profile/subscription before importing."
                            return
                        }
                        const subGroup = importPopup.targetGroupName
                        root.subscriptionGroupDraft = subGroup
                        if ((subscriptionGroupField.text || "").trim() !== subGroup)
                            subscriptionGroupField.text = subGroup
                        const subGroupLower = subGroup.toLowerCase()
                        if (subGroupLower === "free" || subGroupLower === "premium") {
                            vpnController.ensureProfileGroup(subGroup)
                            vpnController.setProfileGroupBadge(subGroup, subGroupLower === "free" ? "Free" : "Premium")
                        }
                        const isSub = raw.startsWith("http://") || raw.startsWith("https://")
                        if (!isSub && subGroup.length > 0)
                            vpnController.currentProfileGroup = subGroup
                        if (isSub) {
                            const started = vpnController.addSubscription(raw, "", subGroup)
                            if (started) {
                                root.importWaitingForSubscription = true
                                root.importStatusKind = "busy"
                                root.importStatusText = "Downloading subscription and importing profiles..."
                            } else {
                                root.importStatusKind = "error"
                                root.importStatusText = (vpnController.lastError || "Failed to start subscription import.")
                            }
                            return
                        }

                        const imported = vpnController.importProfileBatch(raw)
                        if (imported > 0) {
                            root.importStatusKind = "success"
                            root.importStatusText = "Imported " + imported + " profile(s)."
                            root.importDraft = ""
                            importTextArea.text = ""
                        } else {
                            root.importStatusKind = "error"
                            root.importStatusText = vpnController.lastError || "No profiles were imported."
                        }
                    }
                }
            }
        }
    }

    Item {
        id: legacyWideDashboard
        visible: false
        anchors.fill: parent

        RowLayout {
            id: topBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 18
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 8

            Text {
                text: "<strong>GENY</strong>CONNECT"
                color: Colors.textPrimary
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: 24
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 10

                Controls.CircleIconButton {
                    diameter: 46
                    iconText: root.iconSetting
                    iconFontFamily: root.faSolid
                    iconColor: root.themeColorToken("mainHex_a0a8b5", "mainHex_8ea1ba")
                    iconPixelSize: 18
                    onClicked: settingsPopup.open()
                }

                Controls.CircleIconButton {
                    diameter: 46
                    iconText: root.iconInfo
                    iconFontFamily: root.faSolid
                    iconColor: root.themeColorToken("mainHex_a0a8b5", "mainHex_8ea1ba")
                    iconPixelSize: 18
                    onClicked: aboutPopup.open()
                }

                Controls.CircleIconButton {
                    diameter: 46
                    iconText: root.iconUsage
                    iconFontFamily: root.faSolid
                    iconColor: root.themeColorToken("mainHex_a0a8b5", "mainHex_8ea1ba")
                    iconPixelSize: 18
                    onClicked: dataUsagePopup.open()
                }
            }
        }

        Item {
            id: mapContainer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: topBar.bottom
            anchors.topMargin: 22
            anchors.bottom: actionRow.top
            anchors.bottomMargin: 20
            width: Math.min(parent.width - 90, 1060)

            Image {
                id: mapImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                smooth: true
                cache: true
                source: root.mapPrimarySource
                visible: root.mapLoaded

                onStatusChanged: {
                    if (status === Image.Ready) {
                        root.mapLoaded = true
                    } else if (status === Image.Error) {
                        if (source === root.mapPrimarySource) {
                            source = root.mapSecondarySource
                        } else {
                            root.mapLoaded = false
                        }
                    }
                }
            }

            Item {
                x: mapContainer.width * 0.57 - width * 0.5
                y: mapContainer.height * 0.43 - height * 0.5
                width: 26
                height: 26

                Repeater {
                    model: 3
                    delegate: Rectangle {
                        required property int index
                        width: 34 + index * 30
                        height: width
                        radius: width * 0.5
                        anchors.centerIn: parent
                        color: root.statePrimaryColor()
                        opacity: 0.0
                        scale: 0.6
                        Behavior on color { ColorAnimation { duration: 240 } }

                        SequentialAnimation on scale {
                            loops: Animation.Infinite
                            running: vpnController.connectionState !== ConnectionState.Disconnected
                            PauseAnimation { duration: index * 360 }
                            NumberAnimation {
                                from: 0.6
                                to: vpnController.connectionState === ConnectionState.Connected ? 2.5 : 2.1
                                duration: vpnController.connectionState === ConnectionState.Connecting ? 1300 : 2200
                                easing.type: Easing.OutCubic
                            }
                        }

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: vpnController.connectionState !== ConnectionState.Disconnected
                            PauseAnimation { duration: index * 360 }
                            NumberAnimation {
                                from: vpnController.connectionState === ConnectionState.Connecting ? 0.36 : 0.22
                                to: 0.0
                                duration: vpnController.connectionState === ConnectionState.Connecting ? 1300 : 2200
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                Rectangle {
                    id: currentLocation
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    radius: width
                    color: root.statePrimaryColor()
                    border.width: 2
                    border.color: Colors.primary

                    Behavior on color { ColorAnimation { duration: Animations.slow } }

                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        running: vpnController.connectionState === ConnectionState.Connecting
                        NumberAnimation { from: 1.0; to: 1.24; duration: 460; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.24; to: 1.0; duration: 460; easing.type: Easing.InOutQuad }
                    }

                    Rectangle {
                        width: 6
                        height: 6
                        radius: width
                        anchors.centerIn: parent
                    }
                }
            }
        }

        Item {
            id: actionRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: statusRow.top
            anchors.bottomMargin: 12

            width: 720
            height: 84

            RectangularShadow {
                anchors.fill: connectControlCard
                offset.x: 0
                offset.y: 0
                radius: connectControlCard.radius
                blur: 64
                spread: 3
                color: Colors.lightShadow
            }

            Rectangle {
                id: connectControlCard
                anchors.fill: parent
                height: 84
                radius: Colors.outerRadius
                color: root.themeColorToken("mainHex_ffffff", "mainHex_151c32")
                border.width: 0
                z: 2
                    border.color: vpnController.connected
                                  ? root.themeColorToken("mainHex_c8ead8", "mainHex_3f8569")
                                  : (vpnController.busy
                                     ? root.themeColorToken("mainHex_f7ddaa", "mainHex_7e6633")
                                     : Colors.borderDeactivated)
                Behavior on border.color { ColorAnimation { duration: Animations.fast } }

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 8
                    radius: Colors.radius
                    color: root.themeColorToken("mainHex_1f5ed8", "mainHex_376de0")
                    opacity: 0.08
                    z: -1
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    spacing: Colors.padding

                    Rectangle {
                        id: locationCard
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Colors.innerRadius
                        color: locationMouse.containsMouse ? Colors.backgroundItemActivated : Colors.background
                        border.width: locationMouse.containsMouse ? 1 : 0
                        border.color: Colors.borderActivated
                        Behavior on color { ColorAnimation { duration: 140 } }

                        MouseArea {
                            id: locationMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: profilePopup.open()
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Rectangle {
                                width: 44
                                height: 44
                                radius: Colors.innerRadius
                                color: Colors.backgroundItemActivated
                                border.width: 0
                                border.color: root.themeColorToken("mainHex_dee3ec", "mainHex_3a4f69")

                                Text {
                                    anchors.centerIn: parent
                                    text: selectedServerFlag
                                    font.pixelSize: 26
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: selectedServerLabel
                                color: Colors.primaryBack
                                font.family: FontSystem.getContentFontBold.name
                                font.weight: Font.Bold
                                font.pixelSize: 36 * 0.52
                                elide: Text.ElideRight
                            }

                            Controls.SignalBars {
                                level: vpnController.connected ? 4 : (vpnController.busy ? 2 : 1)
                            }

                            Text {
                                text: root.iconChevronDown
                                color: root.themeColorToken("mainHex_9ea6b5", "mainHex_9fb4cd")
                                font.family: root.faSolid
                                font.pixelSize: 14
                            }
                        }
                    }

                    Rectangle {
                        width: 1
                        Layout.fillHeight: true
                        color: root.themeColorToken("mainHex_e6ebf3", "mainHex_334b67")
                    }

                    Rectangle {
                        id: inlineConnectButton
                        Layout.preferredWidth: compact ? 228 : 250
                        Layout.fillHeight: true
                        radius: Colors.innerRadius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Colors.mainHex_2f6ff1 }
                            GradientStop { position: 1.0; color: Colors.mainHex_2d65d8 }
                        }
                        opacity: (vpnController.currentProfileIndex >= 0 || vpnController.connected || vpnController.busy) ? 1.0 : 0.55
                        scale: connectMouse.pressed ? 0.985 : 1.0
                        Behavior on scale { NumberAnimation { duration: 90 } }
                        Behavior on opacity { NumberAnimation { duration: 140 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Rectangle {
                                visible: vpnController.busy
                                width: 8
                                height: 8
                                radius: 4
                                color: Colors.mainHex_ffffff
                                opacity: 0.85

                                SequentialAnimation on opacity {
                                    running: vpnController.busy
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 0.35; to: 1.0; duration: 420; easing.type: Easing.InOutQuad }
                                    NumberAnimation { from: 1.0; to: 0.35; duration: 420; easing.type: Easing.InOutQuad }
                                }
                            }

                            Text {
                                text: connectButtonText()
                                color: Colors.mainHex_ffffff
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 40 * 0.58
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: connectMouse
                            anchors.fill: parent
                            enabled: vpnController.currentProfileIndex >= 0 || vpnController.connected || vpnController.busy
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: vpnController.toggleConnection()
                        }
                    }
                }
            }
        }

        Item {
            id: statusRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: infoRow.top
            anchors.bottomMargin: 48

            width: 720
            height: 94

            RectangularShadow {
                anchors.fill: statusCard
                offset.x: 0
                offset.y: 0
                radius: statusCard.radius
                blur: 64
                spread: 3
                color: Colors.lightShadow
            }

            Rectangle {
                id: statusCard
                anchors.fill: parent
                implicitHeight: 94
                radius: Colors.outerRadius
                color: root.themeColorToken("mainHex_ffffff", "mainHex_151c32")
                border.width: 0
                border.color: Colors.borderDeactivated
                Behavior on color { ColorAnimation { duration: 220 } }
                Behavior on border.color { ColorAnimation { duration: 220 } }
                z: 2

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.topMargin: 10
                    anchors.bottomMargin: 10
                    spacing: Colors.padding

                    Rectangle {
                        Layout.preferredWidth: root.compact ? 162 : 188
                        Layout.fillHeight: true
                        radius: Colors.innerRadius
                        color: root.stateSoftColor()
                        border.width: 0
                        border.color: root.statePrimaryColor()
                        Behavior on color { ColorAnimation { duration: 220 } }
                        Behavior on border.color { ColorAnimation { duration: 220 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: Colors.padding

                            Rectangle {
                                width: 10
                                height: 10
                                radius: 5
                                color: root.statePrimaryColor()
                                Behavior on color { ColorAnimation { duration: 220 } }

                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    running: vpnController.connectionState === ConnectionState.Connecting
                                    NumberAnimation { from: 1.0; to: 0.3; duration: 420 }
                                    NumberAnimation { from: 0.3; to: 1.0; duration: 420 }
                                }
                            }

                            ColumnLayout {
                                spacing: 1
                                Text {
                                    text: "Status"
                                    color: root.themeColorToken("mainHex_6f7f96", "mainHex_9fb4cd")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: Typography.h6
                                }
                                Text {
                                    text: root.stateText()
                                    color: root.themeColorToken("mainHex_1f2a37", "mainHex_d7e4f6")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: Typography.t2
                                    font.bold: true
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 1
                        Layout.fillHeight: true
                        color: root.themeColorToken("mainHex_e6ebf3", "mainHex_334b67")
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Colors.innerRadius
                        color: root.themeColorToken("mainHex_eaf2ff", "mainHex_223753")
                        border.width: 0
                        border.color: root.themeColorToken("mainHex_d7e4fb", "mainHex_151c32")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: "↓"
                                color: root.themeColorToken("mainHex_2874f0", "mainHex_8ab6ff")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 18
                                font.bold: true
                            }

                            ColumnLayout {
                                spacing: 1
                                Text {
                                    text: "Receive"
                                    color: root.themeColorToken("mainHex_6682ad", "mainHex_9fc3f2")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: Typography.h6
                                }
                                Controls.NumberFlowText {
                                    text: root.downloadRateText()
                                    color: root.themeColorToken("mainHex_3f5e93", "mainHex_c7dbf8")
                                    fontSize: Typography.t3
                                    bold: true
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Controls.NumberFlowText {
                                text: downloadUsageText()
                                color: root.themeColorToken("mainHex_1f2b3d", "mainHex_edf4ff")
                                fontSize: Typography.h3
                            }

                            Item { Layout.preferredWidth: 15 }

                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Colors.innerRadius
                        color: root.themeColorToken("mainHex_ecfff3", "mainHex_173c2f")
                        border.width: 0
                        border.color: root.themeColorToken("mainHex_d8efdf", "mainHex_3f8569")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: "↑"
                                color: root.themeColorToken("mainHex_1ea768", "mainHex_5edc86")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 18
                                font.bold: true
                            }

                            ColumnLayout {
                                spacing: 1
                                Text {
                                    text: "Send"
                                    color: root.themeColorToken("mainHex_5f9478", "mainHex_9fceb7")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: Typography.h6
                                }
                                Controls.NumberFlowText {
                                    text: root.uploadRateText()
                                    color: root.themeColorToken("mainHex_2e7b58", "mainHex_bee9d3")
                                    fontSize: Typography.t3
                                    bold: true
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Controls.NumberFlowText {
                                text: uploadUsageText()
                                color: root.themeColorToken("mainHex_1f2b3d", "mainHex_edf4ff")
                                fontSize: Typography.h3
                            }

                            Item { Layout.preferredWidth: 15 }

                        }
                    }
                }
            }
        }

        RowLayout {
            id: infoRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: quickActionsRow.top
            anchors.bottomMargin: 32
            width: 820
            spacing: 18

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 6

                Rectangle {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    radius: 10
                    color: vpnController.connected ? Colors.mainHex_e8faef : Colors.mainHex_f1edff
                    border.width: 0
                    border.color: vpnController.connected ? Colors.mainHex_bdeacb : Colors.mainHex_d9d0ff

                    Text {
                        anchors.centerIn: parent
                        text: root.iconShield
                        color: vpnController.connected ? Colors.mainHex_22a557 : root.brandViolet
                        font.family: root.faSolid
                        font.pixelSize: 10
                    }
                }

                Text {
                    text: root.infoIpLabel() + ":"
                    color: root.themeColorToken("mainHex_2a3140", "mainHex_d7e4f6")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                    font.bold: true
                }

                Text {
                    text: infoIpText()
                    color: root.themeColorToken("mainHex_8e98aa", "mainHex_9eb2cb")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 1
                height: 24
                color: root.themeColorToken("mainHex_d9dee8", "mainHex_3a4f69")
            }

            RowLayout {
                spacing: 6

                Text {
                    text: "Your Location:"
                    color: root.themeColorToken("mainHex_2a3140", "mainHex_d7e4f6")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                    font.bold: true
                }

                Text {
                    text: infoLocationText()
                    color: root.themeColorToken("mainHex_8e98aa", "mainHex_9eb2cb")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap
                    maximumLineCount: 1
                }

            }

            Item { Layout.fillWidth: true }
        }

        Row {
            id: quickActionsRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 128
            spacing: 20

            Controls.CircleIconButton {
                diameter: 64
                iconText: root.iconSetting
                iconFontFamily: root.faSolid
                iconPixelSize: 20
                iconColor: root.themeColorToken("mainHex_97a0b0", "mainHex_9fb4cd")
                onClicked: settingsPopup.open()
            }

            Controls.CircleIconButton {
                diameter: 64
                iconText: root.iconSpeed
                iconFontFamily: root.faSolid
                iconPixelSize: 20
                iconColor: root.themeColorToken("mainHex_97a0b0", "mainHex_9fb4cd")
                onClicked: speedTestPopup.open()
            }

            Controls.CircleIconButton {
                diameter: 64
                iconText: root.iconImport
                iconFontFamily: root.faSolid
                iconPixelSize: 20
                iconColor: root.themeColorToken("mainHex_97a0b0", "mainHex_9fb4cd")
                onClicked: importPopup.open()
            }
        }

        Item { Layout.fillHeight: true; }

    }

    Item {
        id: compactDashboard
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            color: root.themeColorToken("mainHex_ffffff", "mainHex_0f1622")
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.themeColorToken("mainHex_ffffff", "mainHex_101927") }
                GradientStop { position: 0.58; color: root.themeColorToken("mainHex_ffffff", "mainHex_101927") }
                GradientStop { position: 1.0; color: root.themeColorToken("mainHex_eef7ff", "mainHex_0b121d") }
            }
        }

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 34
            width: parent.width * 1.55
            height: parent.height * 0.74
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: 0.45
            source: root.mapPrimarySource
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            anchors.topMargin: 20
            anchors.bottomMargin: 104
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                spacing: 10

                Item {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36

                    Controls.CircleIconButton {
                        anchors.fill: parent
                        diameter: 36
                        elevated: false
                        backgroundColor: vpnController.loggingEnabled
                                         ? root.themeColorToken("mainHex_ecfaf3", "mainHex_102b1f")
                                         : root.themeColorToken("mainHex_edf7ff", "mainHex_151c32")
                        iconText: root.iconUsage
                        iconFontFamily: root.faSolid
                        iconColor: root.themeColor(root.brandBlue, Colors.mainHex_84b2ff)
                        iconPixelSize: 15
                        onClicked: dataUsagePopup.open()
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: 1
                        anchors.topMargin: 1
                        width: 9
                        height: 9
                        radius: 4.5
                        visible: false
                        color: Colors.mainHex_22b26a
                    }
                }

                Text {
                    text: "<strong>GENY</strong>CONNECT"
                    color: root.themeColor(root.brandInk, Colors.mainHex_e5edf9)
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 15
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Speed"
                    color: root.themeColor(root.brandInk, Colors.mainHex_e5edf9)
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: 15
                    font.bold: true
                }

                Rectangle {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    radius: 21
                    color: root.themeColorToken("mainHex_f0edff", "mainHex_221c36")

                    Text {
                        anchors.centerIn: parent
                        text: root.iconSpeed
                        color: root.brandViolet
                        font.family: root.faSolid
                        font.pixelSize: 17
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: speedTestPopup.open()
                    }
                }
            }

            Text {
                id: dashboardTimerText
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 54
                        text: vpnController.connected || vpnController.busy ? root.sessionTimeText() : "00:00:00"
                color: root.themeColorToken("mainHex_050505", "mainHex_f1f5ff")
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: 44
                font.bold: true
                transformOrigin: Item.Center

            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(ipPillRow.implicitWidth + 26, parent.width - 38)
                Layout.preferredHeight: 40
                radius: 23
                color: root.themeColorToken("mainHex_f5f7fb", "mainHex_182230")

                RowLayout {
                    id: ipPillRow
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        radius: 11
                        color: vpnController.connected
                               ? root.themeColorToken("mainHex_e8faef", "mainHex_173323")
                               : root.themeColorToken("mainHex_f1edff", "mainHex_241f3d")
                        Text {
                            anchors.centerIn: parent
                            text: root.iconShield
                            color: vpnController.connected ? Colors.mainHex_22a557 : root.themeColor(root.brandViolet, Colors.mainHex_a88dff)
                            font.family: root.faSolid
                            font.pixelSize: 11
                        }
                    }

                    Text {
                        id: ipPillText
                        text: root.infoIpLabel() + " " + (vpnController.publicIpRefreshing ? "securing..." : root.infoIpText())
                        color: root.themeColorToken("mainHex_344053", "mainHex_c7d4e6")
                        font.family: FontSystem.getContentFontBold.name
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideMiddle
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: vpnController.connected
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (enabled)
                            vpnController.refreshPublicIp()
                    }
                }
            }

            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(parent.width - 44, 276)
                Layout.preferredHeight: 56

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Last Usage"
                        color: root.themeColorToken("mainHex_557299", "mainHex_9ab2ce")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 11
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4

                        Controls.NumberFlowText {
                            text: root.latestUsageValuePart()
                            color: root.themeColorToken("mainHex_173f75", "mainHex_d2e1f6")
                            fontSize: 24
                            bold: true
                        }

                        Text {
                            text: root.latestUsageUnitPart()
                            color: root.themeColorToken("mainHex_244f86", "mainHex_a9c1de")
                            font.family: FontSystem.getContentFontBold.name
                            font.pixelSize: 18
                            font.bold: true
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 248
                Layout.minimumHeight: 248
                Layout.maximumHeight: 248

                Item {
                    id: heroPowerCluster
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 0
                    width: Math.min(parent.width, 210)
                    height: width

                    Repeater {
                        model: 4
                        delegate: Rectangle {
                            required property int index
                            anchors.centerIn: parent
                            width: 90 + (index * 30)
                            height: width
                            radius: width / 2
                            color: root.connectRingColor()
                            opacity: index === 0 ? 1.0 : (vpnController.connectionState === ConnectionState.Disconnected ? 0.12 : 0.16)
                            border.width: index === 3 ? 1 : 0
                            border.color: root.connectRingColor()
                            scale: vpnController.connectionState === ConnectionState.Connecting && index > 0 ? 1.04 : 1.0
                            Behavior on color { ColorAnimation { duration: 280 } }
                            Behavior on border.color { ColorAnimation { duration: 280 } }
                            Behavior on scale { NumberAnimation { duration: 520; easing.type: Easing.InOutQuad } }
                        }
                    }

                    Rectangle {
                        id: heroConnectButton
                        anchors.centerIn: parent
                        width: 108
                        height: 108
                        radius: 54
                        color: root.connectCoreColor()
                        opacity: (vpnController.currentProfileIndex >= 0 || vpnController.connected || vpnController.busy) ? 1.0 : 0.55
                        scale: heroConnectMouse.pressed ? 0.96 : 1.0
                        Behavior on color { ColorAnimation { duration: 280 } }
                        Behavior on scale { NumberAnimation { duration: 90 } }

                        Text {
                            anchors.centerIn: parent
                            text: "\uf0e7"
                            color: Colors.mainHex_ffffff
                            font.family: root.faSolid
                            font.pixelSize: 50
                        }

                        MouseArea {
                            id: heroConnectMouse
                            anchors.fill: parent
                            enabled: vpnController.currentProfileIndex >= 0 || vpnController.connected || vpnController.busy
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: vpnController.toggleConnection()
                        }
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: statusChipText.implicitWidth + 38
                    height: 32
                    radius: 16
                    color: vpnController.connected
                           ? root.themeColorToken("mainHex_e7faef", "mainHex_6646a77c")
                           : (vpnController.busy
                              ? root.themeColorToken("mainHex_fff5d8", "mainHex_666f5b2e")
                              : root.themeColorToken("mainHex_f1f3f7", "mainHex_66557a9f"))
                    scale: vpnController.busy ? 1.04 : 1.0
                    Behavior on color { ColorAnimation { duration: 260 } }
                    Behavior on border.color { ColorAnimation { duration: 260 } }
                    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }

                    SequentialAnimation on opacity {
                        running: vpnController.connectionState === ConnectionState.Connecting
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.72; to: 1.0; duration: 520; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.0; to: 0.72; duration: 520; easing.type: Easing.InOutQuad }
                    }

                    Text {
                        id: statusChipText
                        anchors.centerIn: parent
                        text: root.stateText()
                        color: vpnController.connected
                               ? root.themeColorToken("mainHex_55c982", "mainHex_82e3bb")
                               : (vpnController.busy
                                  ? root.themeColorToken("mainHex_d3a722", "mainHex_f0c86e")
                                  : root.themeColorToken("mainHex_8993a4", "mainHex_c8d9ed"))
                        font.family: FontSystem.getContentFontBold.name
                        font.pixelSize: 13
                        font.bold: true
                        Behavior on color { ColorAnimation { duration: 260 } }
                    }
                }
            }


            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: root.themeColorToken("mainHex_f0f1f5", "mainHex_223147")
                opacity: 0.8
            }


            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 68
                Layout.minimumHeight: 68
                Layout.maximumHeight: 68
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        anchors.topMargin: 6
                        anchors.bottomMargin: 6
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                radius: 13
                                color: root.themeColorToken("mainHex_e9fff2", "mainHex_173126")

                                Text {
                                    anchors.centerIn: parent
                                    text: "↓"
                                    color: Colors.mainHex_5edc86
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: "Downlink"
                                    color: root.themeColorToken("mainHex_1b1b1f", "mainHex_cbd9ec")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 12
                                }
                                Row {
                                    spacing: 4
                                    Controls.NumberFlowText {
                                        id: downStatValueText
                                        width: 58
                                        text: root.formatSpeedValue(Math.max(0, downRateBytesPerSec), dashboardStatsSettings.speedUnit).value
                                        color: root.themeColorToken("mainHex_050505", "mainHex_eef4ff")
                                        fontSize: 17
                                        bold: true
                                    }
                                    Text {
                                        width: 40
                                        text: root.formatSpeedValue(Math.max(0, downRateBytesPerSec), dashboardStatsSettings.speedUnit).unit
                                        color: root.themeColorToken("mainHex_5b5d66", "mainHex_9db0c9")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        Canvas {
                            id: downSparkline
                            Layout.fillWidth: true
                            Layout.preferredHeight: 22
                            Layout.minimumHeight: 22
                            antialiasing: true
                            property var samples: root.downRateHistoryMbps
                            onSamplesChanged: requestPaint()
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                            onPaint: {
                                const ctx = getContext("2d")
                                ctx.reset()

                                const pts = samples || []
                                if (pts.length < 2)
                                    return

                                let maxV = 0
                                for (let i = 0; i < pts.length; ++i)
                                    maxV = Math.max(maxV, Number(pts[i]) || 0)
                                maxV = Math.max(1.0, maxV * 1.12)

                                const w = width
                                const h = height
                                const padX = 1
                                const padY = 2
                                const drawW = Math.max(1, w - padX * 2)
                                const drawH = Math.max(1, h - padY * 2)

                                ctx.beginPath()
                                for (let i = 0; i < pts.length; ++i) {
                                    const x = padX + (drawW * i / (pts.length - 1))
                                    const y = padY + drawH - (drawH * (Number(pts[i]) || 0) / maxV)
                                    if (i === 0) ctx.moveTo(x, y)
                                    else ctx.lineTo(x, y)
                                }
                                ctx.lineWidth = 1
                                ctx.strokeStyle = Colors.mainHex_6f5cff
                                ctx.shadowColor = "rgba(111,92,255,0.45)"
                                ctx.shadowBlur = 4
                                ctx.stroke()

                                ctx.shadowBlur = 0
                                ctx.lineTo(padX + drawW, padY + drawH)
                                ctx.lineTo(padX, padY + drawH)
                                ctx.closePath()
                                const fill = ctx.createLinearGradient(0, padY, 0, padY + drawH)
                                fill.addColorStop(0.0, "rgba(122,88,255,0.22)")
                                fill.addColorStop(1.0, "rgba(122,88,255,0.03)")
                                ctx.fillStyle = fill
                                ctx.fill()
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: root.themeColorToken("mainHex_eef0f4", "mainHex_364b66")
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        anchors.topMargin: 6
                        anchors.bottomMargin: 6
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                radius: 13
                                color: root.themeColorToken("mainHex_fff9db", "mainHex_3a3215")

                                Text {
                                    anchors.centerIn: parent
                                    text: "↑"
                                    color: Colors.mainHex_dfc33f
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: "Uplink"
                                    color: root.themeColorToken("mainHex_1b1b1f", "mainHex_cbd9ec")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 12
                                }
                                Row {
                                    spacing: 4
                                    Controls.NumberFlowText {
                                        id: upStatValueText
                                        width: 58
                                        text: root.formatSpeedValue(Math.max(0, upRateBytesPerSec), dashboardStatsSettings.speedUnit).value
                                        color: root.themeColorToken("mainHex_050505", "mainHex_eef4ff")
                                        fontSize: 17
                                        bold: true
                                    }
                                    Text {
                                        width: 40
                                        text: root.formatSpeedValue(Math.max(0, upRateBytesPerSec), dashboardStatsSettings.speedUnit).unit
                                        color: root.themeColorToken("mainHex_5b5d66", "mainHex_9db0c9")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        Canvas {
                            id: upSparkline
                            Layout.fillWidth: true
                            Layout.preferredHeight: 22
                            Layout.minimumHeight: 22
                            antialiasing: true
                            property var samples: root.upRateHistoryMbps
                            onSamplesChanged: requestPaint()
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                            onPaint: {
                                const ctx = getContext("2d")
                                ctx.reset()

                                const pts = samples || []
                                if (pts.length < 2)
                                    return

                                let maxV = 0
                                for (let i = 0; i < pts.length; ++i)
                                    maxV = Math.max(maxV, Number(pts[i]) || 0)
                                maxV = Math.max(1.0, maxV * 1.12)

                                const w = width
                                const h = height
                                const padX = 1
                                const padY = 2
                                const drawW = Math.max(1, w - padX * 2)
                                const drawH = Math.max(1, h - padY * 2)

                                ctx.beginPath()
                                for (let i = 0; i < pts.length; ++i) {
                                    const x = padX + (drawW * i / (pts.length - 1))
                                    const y = padY + drawH - (drawH * (Number(pts[i]) || 0) / maxV)
                                    if (i === 0) ctx.moveTo(x, y)
                                    else ctx.lineTo(x, y)
                                }
                                ctx.lineWidth = 1
                                ctx.strokeStyle = Colors.mainHex_3db4ff
                                ctx.shadowColor = "rgba(61,180,255,0.45)"
                                ctx.shadowBlur = 4
                                ctx.stroke()

                                ctx.shadowBlur = 0
                                ctx.lineTo(padX + drawW, padY + drawH)
                                ctx.lineTo(padX, padY + drawH)
                                ctx.closePath()
                                const fill = ctx.createLinearGradient(0, padY, 0, padY + drawH)
                                fill.addColorStop(0.0, "rgba(61,180,255,0.20)")
                                fill.addColorStop(1.0, "rgba(61,180,255,0.03)")
                                ctx.fillStyle = fill
                                ctx.fill()
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 5;}

            Rectangle {
                id: mobileLocationCard
                Layout.fillWidth: true
                Layout.preferredHeight: 78
                Layout.minimumHeight: 78
                Layout.maximumHeight: 78
                radius: 18
                color: mobileLocationMouse.containsMouse
                       ? root.themeColorToken("mainHex_fbfcff", "mainHex_151c32")
                       : root.themeColorToken("mainHex_ffffff", "mainHex_142032")

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        radius: 21
                        color: root.themeColorToken("mainHex_f0f1ff", "mainHex_111425")

                        Text {
                            anchors.centerIn: parent
                            text: selectedServerFlag
                            font.pixelSize: 25
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: selectedServerLabel
                            color: root.themeColorToken("mainHex_070707", "mainHex_edf3fe")
                            font.family: FontSystem.getContentFontBold.name
                            font.pixelSize: 16
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            Layout.preferredWidth: Math.min(serverBadgeText.implicitWidth + 20, 118)
                            Layout.preferredHeight: 21
                            radius: 11
                            color: root.themeColorToken("mainHex_edf2ff", "mainHex_263858")

                            Text {
                                id: serverBadgeText
                                anchors.centerIn: parent
                                text: vpnController.tunMode ? "TUN Server" : "Game Server"
                                color: root.themeColor(root.brandBlue, Colors.mainHex_9ec1ff)
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: selectedServerMeta
                            color: root.themeColorToken("mainHex_7385a0", "mainHex_97acc8")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 10
                            elide: Text.ElideMiddle
                        }
                    }

                    Text {
                        text: "\uf054"
                        color: root.themeColorToken("mainHex_050505", "mainHex_dce7f8")
                        font.family: root.faSolid
                        font.pixelSize: 17
                    }
                }

                MouseArea {
                    id: mobileLocationMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.profilePopupAnchor = mobileLocationCard
                        profilePopup.open()
                    }
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 88
            radius: 28
            color: root.themeColorToken("mainHex_ffffff", "mainHex_121d2e")

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 28
                color: root.themeColorToken("mainHex_ffffff", "mainHex_121d2e")
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 44
                anchors.rightMargin: 44
                anchors.bottomMargin: 4

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Rectangle {
                        anchors.centerIn: parent
                        width: 42
                        height: 42
                        radius: 21
                        color: root.themeColorToken("mainHex_3147d0", "mainHex_3e6fff")

                        Text {
                            anchors.centerIn: parent
                            text: "\uf015"
                            color: Colors.mainHex_ffffff
                            font.family: root.faSolid
                            font.pixelSize: 15
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent
                        text: "\uf57d"
                        color: root.themeColorToken("mainHex_050505", "mainHex_d7e4f6")
                        font.family: root.faSolid
                        font.pixelSize: 25
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: profilePopup.open()
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent
                        text: "\uf013"
                        color: root.themeColorToken("mainHex_050505", "mainHex_d7e4f6")
                        font.family: root.faSolid
                        font.pixelSize: 24
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openSettingsSection("main")
                    }
                }
            }
        }
    }

    footer: Rectangle {
        id: footer
        width: parent.width
        height: root.compact ? 0 : 34
        visible: !root.compact
        color: Colors.pageground
        border.width: 0
        border.color: Colors.borderActivated

        RowLayout {
            anchors.fill: parent

            Item { Layout.preferredWidth: 10; }

            Text {
                text: "Build: v" + updater.appVersion
                color: Colors.textSecondary
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 11
                Behavior on color { ColorAnimation { duration: 220 } }
            }

            Text {
                text: " | Memory: " + vpnController.memoryUsageText
                visible: root.width >= 520
                color: Colors.textSecondary
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 11
            }

            Item { Layout.fillWidth: true }

            Row {
                spacing: 14
                visible: root.width >= 860

                Text {
                    text: "Current Profile Usage -->"
                    color: root.themeColorToken("mainHex_4f627f", "mainHex_9eb2cb")
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: 12
                    font.bold: true
                }

                Text {
                    text: "<strong>Hour</strong> " + vpnController.currentProfileUsageHour
                    color: root.themeColorToken("mainHex_647891", "mainHex_9fb4cd")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                }

                Text {
                    text: "<strong>Day</strong> " + vpnController.currentProfileUsageDay
                    color: root.themeColorToken("mainHex_647891", "mainHex_9fb4cd")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                }

                Text {
                    text: "<strong>Week</strong> " + vpnController.currentProfileUsageWeek
                    color: root.themeColorToken("mainHex_647891", "mainHex_9fb4cd")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                }

                Text {
                    text: "<strong>Month</strong> " + vpnController.currentProfileUsageMonth
                    color: root.themeColorToken("mainHex_647891", "mainHex_9fb4cd")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                }

                Item { Layout.fillWidth: true }
            }

            Item { Layout.preferredWidth: 10; }
        }
    }
}
