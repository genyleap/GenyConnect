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

    color: root.themeColor("#eceff5", "#0f141d")
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
    readonly property color brandBlue: "#2f74ff"
    readonly property color brandCyan: "#11c5ff"
    readonly property color brandViolet: "#6b35ff"
    readonly property color brandInk: "#17284a"

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
        if (settingsSection === "usage")
            return "Data Usage"
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
                if (section === "usage")
                    root.usagePanelTab = "current"
            })
            return
        }
        settingsSection = section
        if (section === "routing") {
            root.appRuleSuggestions = vpnController.availableAppRuleItems()
            root.appRuleSearchQuery = ""
            root.clearAppSuggestionSelection()
        }
        if (section === "usage")
            root.usagePanelTab = "current"
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
            return "#f59e0b"
        if (vpnController.connectionState === ConnectionState.Connected)
            return "#16a34a"
        if (vpnController.connectionState === ConnectionState.Error)
            return "#ef4444"
        return "#9aa5b5"
    }

    function stateSoftColor() {
        if (vpnController.connectionState === ConnectionState.Connecting)
            return "#fff4dc"
        if (vpnController.connectionState === ConnectionState.Connected)
            return "#e8f8ee"
        if (vpnController.connectionState === ConnectionState.Error)
            return "#feeceb"
        return "#eef2f7"
    }

    function connectRingColor() {
        if (vpnController.connectionState === ConnectionState.Connecting)
            return root.brandBlue
        if (vpnController.connectionState === ConnectionState.Connected)
            return "#22c55e"
        if (vpnController.connectionState === ConnectionState.Error)
            return "#ef4444"
        return "#cfd5e3"
    }

    function connectCoreColor() {
        if (vpnController.connectionState === ConnectionState.Connected)
            return "#16a34a"
        if (vpnController.connectionState === ConnectionState.Error)
            return "#ef4444"
        if (vpnController.connectionState === ConnectionState.Connecting)
            return root.brandBlue
        return "#aeb6c7"
    }

    function statePanelColor() {
        if (vpnController.connectionState === ConnectionState.Connecting)
            return "#fffcf4"
        if (vpnController.connectionState === ConnectionState.Connected)
            return "#fbfffc"
        if (vpnController.connectionState === ConnectionState.Error)
            return "#fff7f8"
        return "#ffffff"
    }

    function stateBorderColor() {
        if (vpnController.connectionState === ConnectionState.Connecting)
            return "#f5d08a"
        if (vpnController.connectionState === ConnectionState.Connected)
            return "#bfe6cc"
        if (vpnController.connectionState === ConnectionState.Error)
            return "#f4b7bd"
        return "#dde5ef"
    }

    function stateGradientStart() {
        if (vpnController.connectionState === ConnectionState.Connecting)
            return "#fbbf24"
        if (vpnController.connectionState === ConnectionState.Connected)
            return "#22c55e"
        if (vpnController.connectionState === ConnectionState.Error)
            return "#f43f5e"
        return "#94a3b8"
    }

    function stateGradientEnd() {
        if (vpnController.connectionState === ConnectionState.Connecting)
            return "#d97706"
        if (vpnController.connectionState === ConnectionState.Connected)
            return "#15803d"
        if (vpnController.connectionState === ConnectionState.Error)
            return "#be123c"
        return "#64748b"
    }

    function stateShadowColor() {
        if (vpnController.connectionState === ConnectionState.Connecting)
            return "#d9770626"
        if (vpnController.connectionState === ConnectionState.Connected)
            return "#15803d26"
        if (vpnController.connectionState === ConnectionState.Error)
            return "#be123c24"
        return "#64748b20"
    }

    function speedGaugeStops() {
        return [0, 5, 10, 20, 50, 100, 200]
    }

    function speedGaugeMaxMbps() {
        const stops = speedGaugeStops()
        return stops.length > 0 ? stops[stops.length - 1] : 200.0
    }

    function speedGaugeValue() {
        const maxMbps = speedGaugeMaxMbps()
        if (vpnController.speedTestRunning)
            return Math.min(Math.max(vpnController.speedTestCurrentMbps, 0.0), maxMbps)
        if (vpnController.speedTestState === "Completed")
            return Math.min(Math.max(vpnController.speedTestDownloadMbps, 0.0), maxMbps)
        // Reset dial pointer to zero whenever test is not actively running.
        return 0.0
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
            if (vpnController.speedTestState === "Preparing")
                return "Preparing secure speed check..."
            if (vpnController.speedTestState === "Testing" && vpnController.speedTestPingMs >= 0)
                return "Testing download speed... (" + vpnController.speedTestPingMs + " ms latency)"
            if (vpnController.speedTestState === "Testing")
                return "Testing download speed..."
            return "Running..."
        }
        return ""
    }

    function speedTestSideStatusText() {
        if (vpnController.speedTestRunning)
            return ""
        if (vpnController.speedTestError.length > 0)
            return "Error: " + vpnController.speedTestError
        if (vpnController.speedTestState === "Completed")
            return vpnController.speedTestPingMs >= 0
                    ? ("Completed • Ping " + vpnController.speedTestPingMs + " ms")
                    : "Completed"
        if (vpnController.speedTestState === "Cancelled")
            return "Cancelled"
        return "Ready"
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
        const r1 = 0.97
        const g1 = 0.43
        const b1 = 0.39
        const r2 = 0.98
        const g2 = 0.73
        const b2 = 0.34
        const r3 = 0.24
        const g3 = 0.78
        const b3 = 0.49
        if (p < 0.5) {
            const t = p / 0.5
            return Qt.rgba(mix(r1, r2, t), mix(g1, g2, t), mix(b1, b2, t), 1.0)
        }
        const t2 = (p - 0.5) / 0.5
        return Qt.rgba(mix(r2, r3, t2), mix(g2, g3, t2), mix(b2, b3, t2), 1.0)
    }

    function gaugeAccentColor() {
        return gaugeColorAt(speedGaugeProgress())
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
            color: root.themeColor("#ffffff", "#131b27")
            border.width: 1
            border.color: root.themeColor("#d6dfec", "#30435d")
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
                color: root.themeColor("#d6dde8", "#304059")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    color: root.themeColor("#eaf2ff", "#223753")
                    border.width: 1
                    border.color: root.themeColor("#c8d9f7", "#4f86e6")

                    Text {
                        anchors.centerIn: parent
                        text: "↑"
                        color: root.themeColor("#2f6de2", "#86b6ff")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 15
                        font.bold: true
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Update Available"
                    color: root.themeColor("#1f2a3a", "#d8e1f0")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                    font.bold: true
                }
            }

            Text {
                Layout.fillWidth: true
                text: "GenyConnect " + updater.latestVersion + " is available. You're on " + updater.appVersion + "."
                color: root.themeColor("#667385", "#9bb0cb")
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
            color: root.themeColor("#ffffff", "#131b27")
            border.width: 1
            border.color: root.themeColor("#d7deea", "#30435d")
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
                color: root.themeColor("#d6dde8", "#304059")
            }

            Text {
                text: "VPN Conflict Detected"
                color: root.themeColor("#1f2a3a", "#d8e1f0")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 22
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: root.tunConflictPopupText
                color: root.themeColor("#5f6f86", "#9bb0cb")
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
            color: root.themeColor("#ffffff", "#131b27")
            border.width: 1
            border.color: root.themeColor("#dbe2ee", "#30435d")
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
                    color: root.themeColor("#d6dde8", "#304059")
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
                        backgroundColor: root.themeColor("#faf9ff", "#1a2b42")
                        borderColor: root.themeColor("#f0eef8", "#355173")
                        iconText: "\uf060"
                        iconFontFamily: root.faSolid
                        iconColor: root.themeColor("#050505", "#d8e1f0")
                        iconPixelSize: 15
                        onClicked: profilePopup.close()
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Server Location"
                        color: root.themeColor("#090909", "#e7eefb")
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
                        backgroundColor: root.themeColor("#ffffff", "#1a2b42")
                        borderColor: root.themeColor("#e8edf5", "#355173")
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
                    color: root.themeColor("#ffffff", "#5f233851")
                    border.width: 1
                    border.color: profileSearchField.activeFocus
                                  ? root.themeColor("#b7caee", "#6b98d5")
                                  : root.themeColor("#dfe6f1", "#496688")
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uf002"
                        color: root.themeColor("#9aa6ba", "#9db1ca")
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
                        placeholderTextColor: root.themeColor("#8c8f98", "#9cb0c8")
                        text: root.profileSearchQuery
                        color: root.themeColor("#1f2a3a", "#d8e1f0")
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
                        color: root.themeColor("#a0acbe", "#9fb4cd")
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
                        color: addProfileMouse.containsMouse ? "#2f6ff1" : "#3f7cf3"
                        border.width: 1
                        border.color: root.themeColor("#2f6ff1", "#3a7bff")
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Add Profile"
                            color: "#ffffff"
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
                               ? root.themeColor("#fff0f0", "#5f3b46")
                               : root.themeColor("#fff6f6", "#4d313b")
                        border.width: 1
                        border.color: root.themeColor("#f2cdcd", "#7d5062")
                        opacity: listView.count > 0 ? 1.0 : 0.55
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Delete All"
                            color: root.themeColor("#cb4f4f", "#ff8e8e")
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
                               ? root.themeColor("#f2f6fd", "#6a355172")
                               : root.themeColor("#f7f9fd", "#5a2d4462")
                        border.width: 1
                        border.color: root.themeColor("#d7dfec", "#3f5777")
                        opacity: listView.count > 0 ? 1.0 : 0.55
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: (vpnController.currentProfileGroup || "All").toLowerCase() === "all"
                                  ? "Ping All"
                                  : "Ping Group"
                            color: root.themeColor("#4b5d78", "#b0c3db")
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
                               ? root.themeColor("#f2f6fd", "#6a355172")
                               : root.themeColor("#f7f9fd", "#5a2d4462")
                        border.width: 1
                        border.color: root.themeColor("#d7dfec", "#3f5777")
                        opacity: vpnController.subscriptions.length > 0 ? 1.0 : 0.55
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: (vpnController.currentProfileGroup || "All") === "All"
                                  ? "Refresh Subs"
                                  : "Refresh Group"
                            color: root.themeColor("#4b5d78", "#b0c3db")
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
                    // ? "#2b6dcf"
                    // : ((text.toLowerCase().indexOf("fail") >= 0 || text.toLowerCase().indexOf("error") >= 0)
                    // ? "#bf4d4d"
                    // : "#6f7f95")
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
                               : root.themeColor("#ffffff", "#5a2b4462")
                        border.width: 1
                        border.color: root.compactProfileFilterSelected("All")
                                      ? root.brandBlue
                                      : root.themeColor("#e7e9ee", "#4f6b8b")
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "All"
                            color: root.compactProfileFilterSelected("All")
                                   ? "#ffffff"
                                   : root.themeColor("#111111", "#e2ecf9")
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
                               : root.themeColor("#ffffff", "#5a2b4462")
                        border.width: 1
                        border.color: root.compactProfileFilterSelected("Free")
                                      ? root.brandCyan
                                      : root.themeColor("#e7e9ee", "#4f6b8b")
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Free"
                            color: root.compactProfileFilterSelected("Free")
                                   ? "#ffffff"
                                   : root.themeColor("#111111", "#e2ecf9")
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
                               : root.themeColor("#ffffff", "#5a2b4462")
                        border.width: 1
                        border.color: root.compactProfileFilterSelected("Premium")
                                      ? root.brandViolet
                                      : root.themeColor("#e7e9ee", "#4f6b8b")
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Premium"
                            color: root.compactProfileFilterSelected("Premium")
                                   ? "#ffffff"
                                   : root.themeColor("#111111", "#e2ecf9")
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
                        color: root.themeColor("#6b778a", "#9cb0c8")
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
                        color: root.themeColor("#eef4ff", "#223753")
                        border.width: 1
                        border.color: root.themeColor("#d8e4f8", "#3f5777")

                        Text {
                            id: visibleProfilesText
                            anchors.centerIn: parent
                            text: "Visible " + vpnController.filteredProfileCount
                            color: root.themeColor("#5f6f86", "#9bb0cb")
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
                        color: root.themeColor("#f7f9fd", "#1f2f46")
                        border.width: 1
                        border.color: root.themeColor("#dce4f2", "#3f5777")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Text {
                                text: "Enabled"
                                color: root.themeColor("#5f6f86", "#9bb0cb")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 12
                            }

                            Controls.Switch {
                                checked: root.profileGroupEnabled(groupFilterCombo.groupNameAt(groupFilterCombo.currentIndex))
                                onToggled: vpnController.setProfileGroupEnabled(groupFilterCombo.groupNameAt(groupFilterCombo.currentIndex), checked)
                            }

                            Text {
                                text: "Exclusive"
                                color: root.themeColor("#5f6f86", "#9bb0cb")
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
                                color: root.themeColor("#ffffff", "#22324a")
                                border.width: 1
                                border.color: root.themeColor("#d5deec", "#3f5777")

                                TextField {
                                    id: groupBadgeField
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    padding: 0
                                    clip: true
                                    placeholderText: "Badge"
                                    text: root.profileGroupBadgeText(groupFilterCombo.groupNameAt(groupFilterCombo.currentIndex))
                                    color: root.themeColor("#3b4a61", "#d0ddf0")
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
                                color: root.themeColor("#4d6691", "#9fc3f2")
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
                        color: vpnController.autoPingProfiles ? "#e8f7ef" : "#eef2f8"
                        border.width: 1
                        border.color: vpnController.autoPingProfiles ? "#b9e3c8" : "#d9e0ed"
                        width: autoPingText.implicitWidth + 18

                        Text {
                            id: autoPingText
                            anchors.centerIn: parent
                            text: vpnController.autoPingProfiles ? "Auto Ping ON" : "Auto Ping OFF"
                            color: vpnController.autoPingProfiles ? "#278c59" : "#7b8799"
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 11
                            font.bold: false
                        }
                    }

                    Rectangle {
                        radius: 11
                        height: 24
                        color: root.themeColor("#f3f6fb", "#20314b")
                        border.width: 1
                        border.color: root.themeColor("#d9e0ed", "#3f5777")
                        width: subsText.implicitWidth + 18

                        Text {
                            id: subsText
                            anchors.centerIn: parent
                            text: "Subs " + subscriptionsInCurrentGroup() + "/" + vpnController.subscriptions.length
                            color: root.themeColor("#667487", "#9bb0cb")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 11
                            font.bold: false
                        }
                    }

                    Rectangle {
                        radius: 11
                        height: 24
                        color: root.themeColor("#edf5ff", "#213655")
                        border.width: 1
                        border.color: root.themeColor("#d9e6fb", "#47638c")
                        width: groupText.implicitWidth + 18

                        Text {
                            id: groupText
                            anchors.centerIn: parent
                            text: "Group " + (vpnController.currentProfileGroup || "All")
                            color: root.themeColor("#5f7290", "#9cb2cf")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 11
                            font.bold: false
                        }
                    }

                    Rectangle {
                        radius: 11
                        height: 24
                        color: root.themeColor("#f3f6fb", "#20314b")
                        border.width: 1
                        border.color: root.themeColor("#d9e0ed", "#3f5777")
                        width: profilesText.implicitWidth + 18

                        Text {
                            id: profilesText
                            anchors.centerIn: parent
                            text: "Profiles " + vpnController.profileCount
                            color: root.themeColor("#667487", "#9bb0cb")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 11
                            font.bold: false
                        }
                    }

                    Rectangle {
                        radius: 11
                        height: 24
                        color: root.themeColor("#f3f6fb", "#20314b")
                        border.width: 1
                        border.color: root.themeColor("#d9e0ed", "#3f5777")
                        width: bestText.implicitWidth + 18

                        Text {
                            id: bestText
                            anchors.centerIn: parent
                            text: "Best " + (vpnController.bestPingMs >= 0 ? (vpnController.bestPingMs + " ms") : "--")
                            color: root.themeColor("#667487", "#9bb0cb")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 11
                            font.bold: false
                        }
                    }

                    Rectangle {
                        radius: 11
                        height: 24
                        color: root.themeColor("#f3f6fb", "#20314b")
                        border.width: 1
                        border.color: root.themeColor("#d9e0ed", "#3f5777")
                        width: worstText.implicitWidth + 18

                        Text {
                            id: worstText
                            anchors.centerIn: parent
                            text: "Worst " + (vpnController.worstPingMs >= 0 ? (vpnController.worstPingMs + " ms") : "--")
                            color: root.themeColor("#667487", "#9bb0cb")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 11
                            font.bold: false
                        }
                    }

                    Rectangle {
                        radius: 11
                        height: 24
                        color: root.themeColor("#fff5e9", "#3b311d")
                        border.width: 1
                        border.color: root.themeColor("#f4d9b1", "#866333")
                        width: scoreText.implicitWidth + 18

                        Text {
                            id: scoreText
                            anchors.centerIn: parent
                            text: "Score " + root.profileScoreStars()
                            color: root.themeColor("#9c6b1f", "#f4c56a")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 11
                            font.bold: false
                        }
                    }
                }

                Rectangle {
                    id: listContainer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Math.min(Math.max(listView.contentHeight, 100), 300)
                    radius: root.compact ? 0 : 16
                    color: root.themeColor("#ffffff", "#4d1f324a")
                    border.width: root.compact ? 0 : 1
                    border.color: root.themeColor("#e4eaf4", "#4e6a8b")

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
                                       ? root.themeColor("#eef3ff", "#8a35527a")
                                       : (hoverArea.containsMouse
                                          ? root.themeColor("#f8fbff", "#7a2b4461")
                                          : root.themeColor("#ffffff", "#66263c56"))
                                border.width: 1
                                border.color: selected
                                              ? root.themeColor(root.brandBlue, "#6ba0ff")
                                              : root.themeColor("#e7edf6", "#4e6a8b")
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
                                    color: root.themeColor("#f3f6fb", "#20314b")
                                    border.width: 1
                                    border.color: root.themeColor("#dde4ef", "#3f5777")

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
                                        color: root.themeColor("#202634", "#d7e4f6")
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
                                                activeColor: pingMs >= 0 ? (pingMs < 250 ? "#36d984" : (pingMs < 500 ? "#dfbf22" : "#ef4444")) : "#9aa4b6"
                                                inactiveColor: "#d9dee8"
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
                                            color: pingMs >= 0 ? (pingMs < 250 ? "#36d984" : (pingMs < 500 ? "#d0ad19" : "#ef4444")) : "#9aa4b6"
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
                                            color: root.themeColor("#edf2ff", "#263a58")

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
                                        color: root.themeColor("#8c95a4", "#9fb4cd")
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
                                        color: root.themeColor("#7b889d", "#9eb3cc")
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
                                               ? root.themeColor("#fff5e8", "#5b3f22")
                                               : root.themeColor("#eff5ff", "#274062")
                                        border.width: 1
                                        border.color: pinging
                                                      ? root.themeColor("#f9d9a8", "#9c7a44")
                                                      : root.themeColor("#d8e4f8", "#4f6f95")

                                        Text {
                                            anchors.centerIn: parent
                                            text: pingText
                                            color: pinging
                                                   ? root.themeColor("#d18b22", "#f0bf6b")
                                                   : (pingMs >= 0
                                                      ? root.themeColor("#2b6dcf", "#8ab6ff")
                                                      : root.themeColor("#9aa4b6", "#9fb4cd"))
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
                                               ? root.themeColor("#edf4ff", "#314f73")
                                               : root.themeColor("#f7f9fd", "#273c58")
                                        border.width: 1
                                        border.color: root.themeColor("#dbe3ef", "#3f5777")

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.iconPing
                                            font.family: root.faSolid
                                            font.pixelSize: 12
                                            color: root.themeColor("#5e6f89", "#9fb4cd")
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
                                               ? root.themeColor("#fff0f0", "#5f3b46")
                                               : root.themeColor("#fff6f6", "#4d313b")
                                        border.width: 1
                                        border.color: root.themeColor("#f2cdcd", "#7d5062")

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.iconTrash
                                            font.family: root.faSolid
                                            font.pixelSize: 12
                                            color: root.themeColor("#cb4f4f", "#ff8e8e")
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
                                        color: pinging ? root.brandBlue : root.themeColor("#7c8ca5", "#9eb2cb")
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
                                        color: root.themeColor("#cb4f4f", "#ff8e8e")
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
                                        color: selected ? "#36d984" : "#dfbf22"
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
                        color: root.themeColor("#8f9bad", "#9eb3cc")
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
            color: root.themeColor("#ffffff", "#131b27")
            border.width: 1
            border.color: root.themeColor("#d8dde8", "#283345")
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
                color: root.themeColor("#d6dde8", "#304059")
            }

            Text {
                text: "Delete all profiles?"
                color: root.themeColor("#1f2530", "#d8e1f0")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 24
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: "This removes all imported profiles from GenyConnect. This action cannot be undone."
                color: root.themeColor("#6a778b", "#9eb3cc")
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
            color: root.themeColor("#ffffff", "#131b27")
            border.width: 1
            border.color: root.themeColor("#d8dde8", "#283345")
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
                color: root.themeColor("#d6dde8", "#304059")
            }

            Text {
                text: "Edit Profile"
                color: root.themeColor("#1f2530", "#d8e1f0")
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
                color: root.themeColor("#7c8697", "#9bb0cb")
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
            color: root.themeColor("#ffffff", "#131b27")
            border.width: 1
            border.color: root.themeColor("#d8dde8", "#283345")
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
                    color: root.themeColor("#d6dde8", "#304059")
                    visible: !root.compact
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: root.compact ? 12 : 8

                    Controls.CircleIconButton {
                        visible: root.compact
                        diameter: 38
                        elevated: false
                        backgroundColor: root.themeColor("#faf9ff", "#1b2738")
                        borderColor: root.themeColor("#f0eef8", "#34445b")
                        iconText: "\uf060"
                        iconFontFamily: root.faSolid
                        iconColor: root.themeColor("#050505", "#d8e1f0")
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
                        color: root.themeColor((root.compact ? "#090909" : "#1f2530"), "#d8e1f0")
                    }
                    Item { Layout.fillWidth: true }
                    Controls.CircleIconButton {
                        visible: !root.compact
                        diameter: 34
                        iconText: "×"
                        iconPixelSize: 20
                        iconColor: root.themeColor("#8d96a5", "#9db0ca")
                        backgroundColor: root.themeColor("#f7f8fb", "#1b2738")
                        borderColor: root.themeColor("#e1e5ed", "#34445b")
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

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }
                    ScrollBar.horizontal: ScrollBar {
                        policy: ScrollBar.AlwaysOff
                    }

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
                                spacing: 14

                                Repeater {
                                    model: [
                                        { "title": "Interface", "icon": "\uf53f", "action": "interface" },
                                        { "title": "App Updates", "icon": "\uf2f1", "action": "updates" },
                                        { "title": "Connection Mode", "icon": "\uf6ff", "action": "connection" },
                                        { "title": "Routing Rules", "icon": "\uf542", "action": "routing" },
                                        { "title": "Custom DNS", "icon": "\uf1eb", "action": "dns" },
                                        { "title": "Data Usage", "icon": "\uf201", "action": "usage" },
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
                                        color: root.themeColor("#ffffff", "#182538")
                                        border.width: 1
                                        border.color: root.themeColor("#edf0f6", "#314159")

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 16
                                            spacing: 14

                                            Rectangle {
                                                Layout.preferredWidth: 42
                                                Layout.preferredHeight: 42
                                                radius: 21
                                                color: root.themeColor("#eef0ff", "#223149")

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.icon
                                                    color: root.themeColor("#3147d0", "#8ab2ff")
                                                    font.family: root.faSolid
                                                    font.pixelSize: 17
                                                }
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.title
                                                color: root.themeColor("#090909", "#e7eefb")
                                                font.family: FontSystem.getContentFontBold.name
                                                font.pixelSize: 16
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: "\uf054"
                                                color: root.themeColor("#050505", "#d5e3f8")
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
                            color: root.themeColor("#f7f9fc", "#1a2432")
                            border.width: 1
                            border.color: root.themeColor("#e0e6f0", "#2f3d52")

                            ColumnLayout {
                                id: interfaceColumn
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                Text {
                                    text: "Dashboard Stats"
                                    color: root.themeColor("#2a3240", "#d5deeb")
                                    font.family: FontSystem.getContentFontBold.name
                                    font.pixelSize: 16
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Choose the unit used by live transfer-rate indicators. Auto selects the most readable unit."
                                    color: root.themeColor("#7c8697", "#93a2b8")
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
                                        color: root.themeColor("#334155", "#c8d3e2")
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
                                    color: root.themeColor("#8a95a8", "#8ea0b8")
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
                                        color: root.themeColor("#334155", "#c8d3e2")
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
                                    color: root.themeColor("#8a95a8", "#8ea0b8")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: root.themeColor("#e3e8f1", "#30435d")
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Total Traffic Units"
                                        color: root.themeColor("#334155", "#c8d3e2")
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
                            color: root.themeColor("#f7f9fc", "#1a2638")
                            border.width: 1
                            border.color: root.themeColor("#e0e6f0", "#30435d")

                            ColumnLayout {
                                id: termsColumn
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Terms And Conditions"
                                    color: root.themeColor("#2a3240", "#d7e4f6")
                                    font.family: FontSystem.getContentFontBold.name
                                    font.pixelSize: 16
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Use GenyConnect only with profiles and networks you are authorized to access. You are responsible for complying with local laws, service terms, and network policies."
                                    color: root.themeColor("#667385", "#9bb0cb")
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
                            color: root.themeColor("#f7f9fc", "#1a2638")
                            border.width: 1
                            border.color: root.themeColor("#e0e6f0", "#30435d")

                            ColumnLayout {
                                id: shareColumn
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Share App"
                                    color: root.themeColor("#2a3240", "#d7e4f6")
                                    font.family: FontSystem.getContentFontBold.name
                                    font.pixelSize: 16
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Share the GenyConnect repository or website with someone who needs the app."
                                    color: root.themeColor("#667385", "#9bb0cb")
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
                            color: root.themeColor("#f7f9fc", "#1a2638")
                            border.width: 1
                            border.color: root.themeColor("#e0e6f0", "#30435d")

                            ColumnLayout {
                                id: aboutSettingsColumn
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "GenyConnect"
                                    color: root.themeColor("#2a3240", "#d7e4f6")
                                    font.family: FontSystem.getContentFontBold.name
                                    font.pixelSize: 16
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Version " + updater.appVersion + "\nxray-core " + vpnController.xrayVersion + "\nDeveloper: Genyleap LLC\n\nGenyConnect is open source. Donations and community support help keep development active."
                                    color: root.themeColor("#667385", "#9bb0cb")
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
                            color: root.themeColor("#f7f9fc", "#1a2638")
                            border.width: 1
                            border.color: root.themeColor("#e0e6f0", "#30435d")

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
                                        color: root.themeColor("#2a3240", "#d7e4f6")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 15
                                        font.bold: true
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: "Current " + updater.appVersion
                                        color: root.themeColor("#677385", "#9bb0cb")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 13
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: updater.status
                                    color: updater.error.length > 0
                                           ? root.themeColor("#c44a4a", "#ff8e8e")
                                           : (updater.updateAvailable
                                              ? root.themeColor("#1f7a51", "#55d793")
                                              : root.themeColor("#5f6f88", "#9bb0cb"))
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: updater.updateAvailable && updater.latestVersion.length > 0
                                    text: "Latest " + updater.latestVersion
                                    color: root.themeColor("#7f8897", "#99abc4")
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
                            color: root.themeColor("#f7f9fc", "#1a2638")
                            border.width: 1
                            border.color: root.themeColor("#e0e6f0", "#30435d")
                            implicitHeight: 64

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "xray-core"
                                    color: root.themeColor("#667081", "#9ab0ca")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 14
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "Version " + vpnController.xrayVersion
                                    color: root.themeColor("#2a3240", "#d7e4f6")
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
                            color: root.themeColor("#f7f9fc", "#1a2638")
                            border.width: 1
                            border.color: root.themeColor("#e0e6f0", "#30435d")

                            ColumnLayout {
                                id: modeColumn
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                Text {
                                    text: "Connection Mode"
                                    color: root.themeColor("#2a3240", "#d7e4f6")
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
                                    color: root.themeColor("#7c8697", "#9bb0cb")
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
                                                   ? root.themeColor("#edf4ff", "#274062")
                                                   : root.themeColor("#ffffff", "#22324a")
                                            border.width: 1
                                            border.color: modelData.checked
                                                          ? root.themeColor("#6da2ff", "#4f86e6")
                                                          : root.themeColor("#d9e0ec", "#3a5470")

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
                                                                  ? root.themeColor("#2f6ff1", "#7eb1ff")
                                                                  : root.themeColor("#9aa6ba", "#90a6c2")

                                                    Rectangle {
                                                        visible: modelData.checked
                                                        anchors.centerIn: parent
                                                        width: 8
                                                        height: 8
                                                        radius: 4
                                                        color: root.themeColor("#2f6ff1", "#7eb1ff")
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 1

                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: modelData.title
                                                        color: root.themeColor("#2a3240", "#d7e4f6")
                                                        font.family: FontSystem.contentFontFamily
                                                        font.pixelSize: 13
                                                        font.bold: true
                                                    }

                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: modelData.subtitle
                                                        color: root.themeColor("#7c8697", "#9bb0cb")
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
                                color: root.themeColor("#334155", "#d7e4f6")
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
                                    color: root.themeColor("#334155", "#d7e4f6")
                                    font.family: FontSystem.getContentFontBold.name
                                    font.pixelSize: 14
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "When disconnected, keep the OS proxy locked to GenyConnect so proxy-aware apps cannot fall back to direct traffic."
                                    color: root.themeColor("#7c8697", "#9bb0cb")
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
                                color: root.themeColor("#334155", "#d7e4f6")
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
                                checked: vpnController.autoPingProfiles
                                onToggled: vpnController.autoPingProfiles = checked
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Auto ping profile endpoints"
                                color: root.themeColor("#334155", "#d7e4f6")
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
                            color: root.themeColor("#7f8897", "#99abc4")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "usage"
                            implicitHeight: usageColumn.implicitHeight + 24
                            radius: 12
                            color: root.themeColor("#f8fbff", "#172437")
                            border.width: 1
                            border.color: root.themeColor("#e1e8f2", "#30435d")

                            ColumnLayout {
                                id: usageColumn
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 12
                                spacing: 12

                                Text {
                                    Layout.fillWidth: true
                                    text: "Data Usage"
                                    color: root.themeColor("#334155", "#d7e4f6")
                                    font.family: FontSystem.getContentFontBold.name
                                    font.pixelSize: 14
                                    font.bold: true
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Repeater {
                                        model: [
                                            { "key": "current", "label": "Current" },
                                            { "key": "recent", "label": "Recent" }
                                        ]

                                        delegate: Rectangle {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 32
                                            radius: 8
                                            color: root.usagePanelTab === modelData.key
                                                   ? root.themeColor("#2f6ff1", "#3a7bff")
                                                   : root.themeColor("#ffffff", "#1f2f46")
                                            border.width: 1
                                            border.color: root.usagePanelTab === modelData.key
                                                          ? root.themeColor("#2f6ff1", "#3a7bff")
                                                          : root.themeColor("#d7e2f0", "#395170")

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                color: root.usagePanelTab === modelData.key
                                                       ? "#ffffff"
                                                       : root.themeColor("#425874", "#b6c8df")
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
                                    implicitHeight: usageCurrentColumn.implicitHeight

                                    ColumnLayout {
                                        id: usageCurrentColumn
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        spacing: 10

                                        Text {
                                            Layout.fillWidth: true
                                            text: "Current profile archive"
                                            color: root.themeColor("#334155", "#d7e4f6")
                                            font.family: FontSystem.getContentFontBold.name
                                            font.pixelSize: 13
                                            font.bold: true
                                        }

                                        GridLayout {
                                            Layout.fillWidth: true
                                            columns: root.compact ? 2 : 3
                                            columnSpacing: 8
                                            rowSpacing: 8

                                            Repeater {
                                                model: [
                                                    { "label": "Hour", "value": vpnController.currentProfileUsageHour },
                                                    { "label": "Day", "value": vpnController.currentProfileUsageDay },
                                                    { "label": "Week", "value": vpnController.currentProfileUsageWeek },
                                                    { "label": "Month", "value": vpnController.currentProfileUsageMonth },
                                                    { "label": "Total", "value": (vpnController.currentProfileUsageSummary().totalText || "0 B") },
                                                    { "label": "Latest", "value": (vpnController.latestRecordedUsage || "0 B") }
                                                ]

                                                delegate: Rectangle {
                                                    required property var modelData
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 58
                                                    radius: 8
                                                    color: root.themeColor("#ffffff", "#22324a")
                                                    border.width: 1
                                                    border.color: root.themeColor("#e5ebf4", "#39526f")

                                                    Column {
                                                        anchors.centerIn: parent
                                                        spacing: 3
                                                        Text {
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            text: modelData.label
                                                            color: root.themeColor("#7b8798", "#9ab0ca")
                                                            font.family: FontSystem.contentFontFamily
                                                            font.pixelSize: 11
                                                        }
                                                        Controls.NumberFlowText {
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            text: modelData.value
                                                            color: root.themeColor("#1f2937", "#edf4ff")
                                                            fontSize: 14
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
                                                           ? root.themeColor("#2f6ff1", "#3a7bff")
                                                           : root.themeColor("#ffffff", "#1f2f46")
                                                    border.width: 1
                                                    border.color: root.usageHistoryPeriod === modelData
                                                                  ? root.themeColor("#2f6ff1", "#3a7bff")
                                                                  : root.themeColor("#d5dfed", "#395170")

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                                        color: root.usageHistoryPeriod === modelData
                                                               ? "#ffffff"
                                                               : root.themeColor("#4b5d75", "#b6c8df")
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
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 176
                                            clip: true
                                            spacing: 6
                                            model: root.currentUsageHistoryModel()

                                            delegate: Rectangle {
                                                required property var modelData
                                                width: ListView.view.width
                                                height: 42
                                                radius: 8
                                                color: root.themeColor("#ffffff", "#22324a")
                                                border.width: 1
                                                border.color: root.themeColor("#e7edf5", "#3a5470")

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 10
                                                    anchors.rightMargin: 10
                                                    spacing: 10

                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: modelData.key || ""
                                                        color: root.themeColor("#334155", "#d2def0")
                                                        font.family: FontSystem.contentFontFamily
                                                        font.pixelSize: 12
                                                        elide: Text.ElideRight
                                                    }
                                                    Text {
                                                        text: "Down " + (modelData.rxText || "0 B")
                                                        color: root.themeColor("#64748b", "#a4b6cd")
                                                        font.family: FontSystem.contentFontFamily
                                                        font.pixelSize: 12
                                                    }
                                                    Text {
                                                        text: "Up " + (modelData.txText || "0 B")
                                                        color: root.themeColor("#64748b", "#a4b6cd")
                                                        font.family: FontSystem.contentFontFamily
                                                        font.pixelSize: 12
                                                    }
                                                    Text {
                                                        text: modelData.totalText || "0 B"
                                                        color: root.themeColor(root.brandBlue, "#7fb0ff")
                                                        font.family: FontSystem.getContentFontBold.name
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    visible: root.usagePanelTab === "recent"
                                    implicitHeight: usageRecentColumn.implicitHeight

                                    ColumnLayout {
                                        id: usageRecentColumn
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        spacing: 10

                                        Text {
                                            Layout.fillWidth: true
                                            text: "Recent connections"
                                            color: root.themeColor("#334155", "#d7e4f6")
                                            font.family: FontSystem.getContentFontBold.name
                                            font.pixelSize: 13
                                            font.bold: true
                                        }

                                        ListView {
                                            id: usageSessionsList
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: usageSessionsList.count > 0 ? 286 : 90
                                            clip: true
                                            spacing: 6
                                            model: root.currentUsageSessionsModel()

                                            delegate: Rectangle {
                                                required property var modelData
                                                width: ListView.view.width
                                                height: 40
                                                radius: 8
                                                color: root.themeColor("#ffffff", "#22324a")
                                                border.width: 1
                                                border.color: root.themeColor("#e7edf5", "#3a5470")

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 10
                                                    anchors.rightMargin: 10
                                                    spacing: 10

                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: (modelData.startedAt || "") + " - " + (modelData.endedAt || "")
                                                        color: root.themeColor("#334155", "#d2def0")
                                                        font.family: FontSystem.contentFontFamily
                                                        font.pixelSize: 12
                                                        elide: Text.ElideRight
                                                    }
                                                    Text {
                                                        text: "Down " + (modelData.rxText || "0 B")
                                                        color: root.themeColor("#64748b", "#a4b6cd")
                                                        font.family: FontSystem.contentFontFamily
                                                        font.pixelSize: 12
                                                    }
                                                    Text {
                                                        text: "Up " + (modelData.txText || "0 B")
                                                        color: root.themeColor("#64748b", "#a4b6cd")
                                                        font.family: FontSystem.contentFontFamily
                                                        font.pixelSize: 12
                                                    }
                                                    Text {
                                                        text: modelData.totalText || "0 B"
                                                        color: root.themeColor(root.brandBlue, "#7fb0ff")
                                                        font.family: FontSystem.getContentFontBold.name
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                    }
                                                }
                                            }

                                            Text {
                                                anchors.fill: parent
                                                visible: usageSessionsList.count === 0
                                                verticalAlignment: Text.AlignVCenter
                                                horizontalAlignment: Text.AlignHCenter
                                                text: vpnController.connected
                                                      ? "Session in progress. Disconnect to record it here."
                                                      : "No recorded sessions yet."
                                                color: root.themeColor("#8a95a8", "#9eb1c9")
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 12
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 32
                                        radius: 7
                                        color: root.themeColor("#ffffff", "#1f2f46")
                                        border.width: 1
                                        border.color: root.themeColor("#d7e2f0", "#395170")

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Refresh"
                                            color: root.themeColor("#2f6ff1", "#86b6ff")
                                            font.family: FontSystem.contentFontFamily
                                            font.pixelSize: 12
                                            font.bold: true
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.usageRefreshNonce += 1
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 32
                                        radius: 7
                                        color: root.themeColor("#ffffff", "#1f2f46")
                                        border.width: 1
                                        border.color: root.themeColor("#d7e2f0", "#395170")

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Clear Current"
                                            color: root.themeColor("#41536c", "#b8c9de")
                                            font.family: FontSystem.contentFontFamily
                                            font.pixelSize: 12
                                            font.bold: true
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                vpnController.clearCurrentProfileUsage()
                                                root.usageRefreshNonce += 1
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 32
                                        radius: 7
                                        color: root.themeColor("#ffffff", "#2a2834")
                                        border.width: 1
                                        border.color: root.themeColor("#f0ced1", "#6a3f4f")

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Clear All"
                                            color: root.themeColor("#bf3f50", "#ff7d92")
                                            font.family: FontSystem.contentFontFamily
                                            font.pixelSize: 12
                                            font.bold: true
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                vpnController.clearAllProfileUsage()
                                                root.usageRefreshNonce += 1
                                            }
                                        }
                                    }
                                }
                            }
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
                                color: root.themeColor("#334155", "#d7e4f6")
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
                            color: root.themeColor("#e4e8ef", "#30435d")
                        }

                        Text {
                            visible: root.settingsSection === "routing"
                            text: "Routing Rules"
                            color: root.themeColor("#667081", "#9ab0ca")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 14
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "routing"
                            text: "Use comma or new line between values. Domain formats: example.com, full:example.com, domain:example.com, regexp:.*\\\\.example\\\\.com$, geosite:category-ads-all."
                            wrapMode: Text.Wrap
                            color: root.themeColor("#8a95a8", "#9eb2cb")
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
                            color: root.themeColor("#f8fbff", "#172437")
                            border.width: 1
                            border.color: root.themeColor("#d7e4f5", "#355070")

                            ColumnLayout {
                                id: customDnsColumn
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    Layout.fillWidth: true
                                    text: "Custom DNS (optional, TUN mode)"
                                    color: root.themeColor("#3b4e67", "#d0ddf0")
                                    font.family: FontSystem.getContentFontBold.name
                                    font.pixelSize: 13
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Enter one resolver per line. Supports IPv4, IPv6, and DNS hostnames."
                                    wrapMode: Text.Wrap
                                    color: root.themeColor("#7c8ba1", "#9eb2cb")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 12
                                }

                                Controls.TextArea {
                                    id: customDnsTextArea
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 86
                                    fillColor: root.themeColor("#ffffff", "#4d20334d")
                                    strokeColor: root.themeColor("#d8e2f0", "#4f6f95")
                                    focusColor: root.themeColor("#8bb8ff", "#6ba0ff")
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
                                                   ? root.themeColor("#eaf2ff", "#223753")
                                                   : root.themeColor("#ffffff", "#22324a")
                                            border.width: 1
                                            border.color: root.dnsDraftContains(modelData.server)
                                                          ? root.themeColor("#8bb8ff", "#4f86e6")
                                                          : root.themeColor("#d8e2f0", "#3f5777")

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 8
                                                spacing: 8

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.label
                                                    color: root.themeColor("#43556f", "#d0ddf0")
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
                                        color: root.themeColor("#7c8ba1", "#9eb2cb")
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
                                   ? root.themeColor("#8a95a8", "#9eb2cb")
                                   : root.themeColor("#d97706", "#ffb454")
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
                                color: root.themeColor("#334155", "#d7e4f6")
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
                                color: root.themeColor("#f7f9fd", "#1f2f46")
                                border.width: 1
                                border.color: appRuleSearchField.activeFocus
                                              ? root.themeColor("#b9ccee", "#5f87c2")
                                              : root.themeColor("#d9e1ef", "#3a5470")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: root.iconSearch
                                        color: root.themeColor("#8da0ba", "#9eb4d0")
                                        font.family: root.faSolid
                                        font.pixelSize: 12
                                    }

                                    TextField {
                                        id: appRuleSearchField
                                        Layout.fillWidth: true
                                        padding: 0
                                        text: root.appRuleSearchQuery
                                        placeholderText: "Search running apps"
                                        color: root.themeColor("#1f2a3a", "#edf4ff")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 12
                                        selectedTextColor: "#ffffff"
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
                                color: root.themeColor("#6b7b92", "#9eb2cb")
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
                            color: root.themeColor("#f8fbff", "#172437")
                            border.width: 1
                            border.color: root.themeColor("#dfe7f2", "#355070")

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
                                           ? root.themeColor("#edf4ff", "#274062")
                                           : root.themeColor("#ffffff", "#22324a")
                                    border.width: 1
                                    border.color: root.isAppSuggestionSelected(modelData.process || "")
                                                 ? root.themeColor("#b8d0ff", "#578dcf")
                                                 : root.themeColor("#e1e9f4", "#3d5876")

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
                                                   ? root.themeColor("#dbe8ff", "#335178")
                                                   : root.themeColor("#eff4fb", "#2a3f5b")
                                            border.width: 1
                                            border.color: root.isAppSuggestionSelected(modelData.process || "")
                                                         ? root.themeColor("#9db9f9", "#659bdf")
                                                         : root.themeColor("#d4dfef", "#496384")

                                            Text {
                                                anchors.centerIn: parent
                                                text: root.appSuggestionInitial(modelData.process || "")
                                                color: root.themeColor("#40618f", "#9fc3f2")
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
                                                color: root.themeColor("#334155", "#d2def0")
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 12
                                                elide: Text.ElideMiddle
                                            }

                                            Text {
                                                width: parent.width
                                                text: modelData.source ? ("Source: " + modelData.source) : ""
                                                visible: text.length > 0
                                                color: root.themeColor("#95a3b8", "#a4b6cd")
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 10
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 54
                                            Layout.preferredHeight: 24
                                            radius: 6
                                            color: root.themeColor("#f3f7ff", "#20314b")
                                            border.width: 1
                                            border.color: root.themeColor("#d4e1f8", "#4c6990")
                                            opacity: vpnController.processRoutingSupported ? 1.0 : 0.6

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Direct"
                                                color: root.themeColor("#3862a9", "#8bb7ff")
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
                                            color: root.themeColor("#e9f1ff", "#1b2f4c")
                                            border.width: 1
                                            border.color: root.themeColor("#c3d8ff", "#4770af")
                                            opacity: vpnController.processRoutingSupported ? 1.0 : 0.6

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Tunnel"
                                                color: root.themeColor("#2f6ff1", "#86b6ff")
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
                                            color: root.themeColor("#fff0f0", "#3b2631")
                                            border.width: 1
                                            border.color: root.themeColor("#ffd0d0", "#7d5062")
                                            opacity: vpnController.processRoutingSupported ? 1.0 : 0.6

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Block"
                                                color: root.themeColor("#ca3b3b", "#ff8da0")
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
            color: root.themeColor("#ffffff", "#131b27")
            border.width: 1
            border.color: root.themeColor("#d8dde8", "#283345")
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
                    color: root.themeColor("#d6dde8", "#304059")
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "About"
                        font.family: FontSystem.getContentFontBold.name
                        font.weight: Font.Bold
                        font.pixelSize: 24
                        color: root.themeColor("#1f2530", "#d8e1f0")
                    }
                    Item { Layout.fillWidth: true }
                    Controls.CircleIconButton {
                        diameter: 34
                        iconText: "×"
                        iconPixelSize: 20
                        iconColor: root.themeColor("#8d96a5", "#9db0ca")
                        backgroundColor: root.themeColor("#f7f8fb", "#1b2738")
                        borderColor: root.themeColor("#e1e5ed", "#34445b")
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
                            color: root.themeColor("#f7f9fc", "#1a2638")
                            border.width: 1
                            border.color: root.themeColor("#e0e6f0", "#30435d")
                            implicitHeight: 64

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "GenyConnect"
                                    color: root.themeColor("#667081", "#9ab0ca")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 14
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "Version " + updater.appVersion
                                    Layout.maximumWidth: aboutPopup.width * 0.48
                                    elide: Text.ElideRight
                                    color: root.themeColor("#2a3240", "#d7e4f6")
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
                            color: root.themeColor("#f7f9fc", "#1a2638")
                            border.width: 1
                            border.color: root.themeColor("#e0e6f0", "#30435d")
                            implicitHeight: 64

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Developer"
                                    color: root.themeColor("#667081", "#9ab0ca")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 14
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "Genyleap LLC"
                                    Layout.maximumWidth: aboutPopup.width * 0.48
                                    elide: Text.ElideRight
                                    color: root.themeColor("#2a3240", "#d7e4f6")
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
                            color: root.themeColor("#f7f9fc", "#1a2638")
                            border.width: 1
                            border.color: root.themeColor("#e0e6f0", "#30435d")
                            implicitHeight: 64

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Website"
                                    color: root.themeColor("#667081", "#9ab0ca")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 14
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "https://genyleap.com"
                                    Layout.maximumWidth: aboutPopup.width * 0.52
                                    elide: Text.ElideMiddle
                                    color: root.themeColor("#2a3240", "#9ec1ff")
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
                            color: root.themeColor("#f7f9fc", "#1a2638")
                            border.width: 1
                            border.color: root.themeColor("#e0e6f0", "#30435d")
                            implicitHeight: 64

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Repository"
                                    color: root.themeColor("#667081", "#9ab0ca")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 14
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "https://github.com/genyleap/genyconnect"
                                    Layout.maximumWidth: aboutPopup.width * 0.52
                                    elide: Text.ElideMiddle
                                    color: root.themeColor("#2a3240", "#9ec1ff")
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
                            color: root.themeColor("#f7f9fc", "#1a2638")
                            border.width: 1
                            border.color: root.themeColor("#e0e6f0", "#30435d")
                            implicitHeight: 64

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Creator's Telegram"
                                    color: root.themeColor("#667081", "#9ab0ca")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 14
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "https://t.me/compezeth"
                                    Layout.maximumWidth: aboutPopup.width * 0.52
                                    elide: Text.ElideMiddle
                                    color: root.themeColor("#2a3240", "#9ec1ff")
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
                            color: root.themeColor("#f7f9fc", "#1a2638")
                            border.width: 1
                            border.color: root.themeColor("#e0e6f0", "#30435d")
                            implicitHeight: 64

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Support Email"
                                    color: root.themeColor("#667081", "#9ab0ca")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 14
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "support@genyleap.com"
                                    Layout.maximumWidth: aboutPopup.width * 0.52
                                    elide: Text.ElideMiddle
                                    color: root.themeColor("#2a3240", "#9ec1ff")
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
            color: root.themeColor("#ffffff", "#131b27")
            border.width: 1
            border.color: root.themeColor("#d8dde8", "#283345")
            clip: true
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.compact ? 12 : 16
            spacing: 10
            clip: true

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 42
                Layout.preferredHeight: 4
                radius: 2
                color: root.themeColor("#d6dde8", "#304059")
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
                    color: root.themeColor("#1f2530", "#d8e1f0")
                    elide: Text.ElideRight
                }

                Controls.CircleIconButton {
                    diameter: 32
                    iconText: root.iconTrash
                    iconFontFamily: root.faSolid
                    iconPixelSize: 12
                    iconColor: vpnController.recentLogs.length > 0
                               ? root.themeColor("#d35b5b", "#ff8e8e")
                               : root.themeColor("#a8b2c0", "#8ea1ba")
                    enabled: vpnController.recentLogs.length > 0
                    onClicked: vpnController.clearLogs()
                }

                Controls.CircleIconButton {
                    diameter: 32
                    iconText: root.iconCopy
                    iconFontFamily: root.faSolid
                    iconPixelSize: 12
                    iconColor: vpnController.loggingEnabled && vpnController.recentLogs.length > 0
                               ? root.themeColor("#64748b", "#a4b6cd")
                               : root.themeColor("#a8b2c0", "#8ea1ba")
                    enabled: vpnController.loggingEnabled && vpnController.recentLogs.length > 0
                    onClicked: vpnController.copyLogsToClipboard()
                }

                Controls.CircleIconButton {
                    diameter: 32
                    iconText: root.iconClose
                    iconFontFamily: root.faSolid
                    iconPixelSize: 12
                    iconColor: root.themeColor("#94a3b8", "#a2b5ce")
                    onClicked: logsPopup.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !vpnController.loggingEnabled
                radius: 16
                color: root.themeColor("#f7f9fc", "#1a2638")
                border.width: 1
                border.color: root.themeColor("#e1e6ee", "#30435d")
                clip: true

                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 32, 280)
                    spacing: 12

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.iconHistory
                        color: root.themeColor("#9aa8bb", "#9db1ca")
                        font.family: root.faSolid
                        font.pixelSize: 28
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Logging is disabled"
                        color: root.themeColor("#2a3240", "#d7e4f6")
                        font.family: FontSystem.getContentFontBold.name
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Enable xray logs in Settings to capture connection history."
                        color: root.themeColor("#8b95a5", "#9cb0c8")
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
                    color: root.themeColor("#1f2530", "#e7eefb")
                    background: Rectangle {
                        color: root.themeColor("#f7f9fc", "#1a2638")
                        border.color: root.themeColor("#e1e6ee", "#30435d")
                        border.width: 1
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
            color: root.themeColor("#ffffff", "#131b27")
            border.width: 1
            border.color: root.themeColor("#d8dde8", "#283345")
            clip: true
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.compact ? 12 : 16
            spacing: 10
            clip: true

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 42
                Layout.preferredHeight: 4
                radius: 2
                color: root.themeColor("#d6dde8", "#304059")
                visible: !root.compact
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Controls.CircleIconButton {
                    visible: root.compact
                    diameter: 38
                    elevated: false
                    backgroundColor: root.themeColor("#faf9ff", "#1b2738")
                    borderColor: root.themeColor("#f0eef8", "#34445b")
                    iconText: "\uf060"
                    iconFontFamily: root.faSolid
                    iconColor: root.themeColor("#050505", "#d8e1f0")
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
                        iconColor: root.themeColor("#a0a8b5", "#8ea1ba")
                        iconPixelSize: 14
                        onClicked: settingsPopup.open()
                    }

                    Controls.CircleIconButton {
                        visible: !root.compact
                        diameter: 34
                        iconText: root.iconClose
                        iconFontFamily: root.faSolid
                        iconColor: root.themeColor("#95a0b3", "#8ea1ba")
                        iconPixelSize: 14
                        onClicked: speedTestPopup.close()
                    }
                }
            }

            Item {
                id: speedTestCenterArea
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: 190
                Layout.minimumHeight: 170

                Item {
                    id: speedDial
                    anchors.centerIn: parent
                    width: Math.min(Math.min(speedTestCenterArea.width * 0.72, speedTestCenterArea.height * 0.98), 210)
                    height: width

                    readonly property int tickCount: 96
                    readonly property real startDeg: -140
                    readonly property real sweepDeg: 280
                    readonly property real centerX: width * 0.5
                    readonly property real centerY: height * 0.5
                    readonly property real outerRadius: width * 0.5 - 10
                    readonly property real innerRadius: width * 0.38
                    readonly property var scaleLabels: root.speedGaugeStops()

                    Rectangle {
                        id: dialPulseOuter
                        width: speedDial.outerRadius * 2 + 16
                        height: width
                        radius: width * 0.5
                        anchors.centerIn: parent
                        color: "transparent"
                        border.width: 2
                        border.color: Qt.rgba(root.gaugeAccentColor().r, root.gaugeAccentColor().g, root.gaugeAccentColor().b, 0.28)
                        opacity: vpnController.speedTestRunning ? 0.30 : 0.0
                        scale: vpnController.speedTestRunning ? 1.0 : 0.95
                        z: 0

                        SequentialAnimation on scale {
                            running: vpnController.speedTestRunning
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.98; to: 1.05; duration: 700; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 1.05; to: 0.98; duration: 700; easing.type: Easing.InOutQuad }
                        }
                        SequentialAnimation on opacity {
                            running: vpnController.speedTestRunning
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.30; to: 0.10; duration: 700; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 0.10; to: 0.30; duration: 700; easing.type: Easing.InOutQuad }
                        }
                    }

                    Rectangle {
                        id: dialPulseInner
                        width: speedDial.outerRadius * 2 - 8
                        height: width
                        radius: width * 0.5
                        anchors.centerIn: parent
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(root.gaugeAccentColor().r, root.gaugeAccentColor().g, root.gaugeAccentColor().b, 0.18)
                        opacity: vpnController.speedTestRunning ? 0.22 : 0.0
                        scale: vpnController.speedTestRunning ? 1.0 : 0.96
                        z: 0

                        SequentialAnimation on scale {
                            running: vpnController.speedTestRunning
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.02; to: 0.97; duration: 880; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 0.97; to: 1.02; duration: 880; easing.type: Easing.InOutQuad }
                        }
                        SequentialAnimation on opacity {
                            running: vpnController.speedTestRunning
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.22; to: 0.08; duration: 880; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 0.08; to: 0.22; duration: 880; easing.type: Easing.InOutQuad }
                        }
                    }

                    Repeater {
                        model: speedDial.tickCount
                        delegate: Rectangle {
                            required property int index
                            readonly property real ratio: speedDial.tickCount > 1 ? index / (speedDial.tickCount - 1) : 0.0
                            readonly property real angleDeg: speedDial.startDeg + (ratio * speedDial.sweepDeg)
                            readonly property real angleRad: angleDeg * Math.PI / 180.0
                            readonly property bool activeTick: ratio <= root.speedGaugeProgress()
                            width: 2
                            height: index % 3 === 0 ? 10 : 6
                            radius: 1
                            color: activeTick ? root.gaugeColorAt(ratio) : root.themeColor("#dbe3ef", "#415a7a")
                            antialiasing: true
                            x: speedDial.centerX + Math.cos(angleRad) * (speedDial.outerRadius - height * 0.5) - width * 0.5
                            y: speedDial.centerY + Math.sin(angleRad) * (speedDial.outerRadius - height * 0.5) - height * 0.5
                            rotation: angleDeg + 90
                            Behavior on color {
                                ColorAnimation { duration: 240 }
                            }
                        }
                    }

                    Rectangle {
                        width: speedDial.innerRadius * 2
                        height: width
                        radius: width * 0.5
                        anchors.centerIn: parent
                        color: root.themeColor("#f8fafc", "#1f2f46")
                        border.width: 1
                        border.color: root.themeColor("#e1e7f0", "#405979")
                    }

                    Repeater {
                        model: speedDial.scaleLabels.length
                        delegate: Text {
                            visible: false
                            required property int index
                            readonly property real ratio: speedDial.scaleLabels.length > 1
                                                          ? (index / (speedDial.scaleLabels.length - 1))
                                                          : 0.0
                            readonly property real angle: (speedDial.startDeg + ratio * speedDial.sweepDeg) * Math.PI / 180.0
                            readonly property real radiusValue: speedDial.innerRadius - 30
                            text: speedDial.scaleLabels[index]
                            color: root.themeColor("#7f8898", "#9db2cc")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 12
                            x: speedDial.centerX + Math.cos(angle) * radiusValue - width * 0.5
                            y: speedDial.centerY + Math.sin(angle) * radiusValue - height * 0.5
                        }
                    }

                    Item {
                        id: needle
                        visible: false
                        width: speedDial.innerRadius * 0.88
                        height: 34
                        x: speedDial.centerX
                        y: speedDial.centerY - height * 0.5
                        rotation: speedDial.startDeg + (root.speedGaugeProgress() * speedDial.sweepDeg)
                        transformOrigin: Item.Left
                        z: 30

                        Behavior on rotation {
                            NumberAnimation {
                                duration: 520
                                easing.type: Easing.InOutCubic
                            }
                        }

                        Canvas {
                            id: needleCanvas
                            anchors.fill: parent
                            antialiasing: true

                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()

                            onPaint: {
                                const ctx = getContext("2d")
                                ctx.reset()

                                const w = width
                                const h = height
                                const cy = h * 0.5
                                const pivotX = 10
                                const pivotR = 7
                                const tipX = w - 2
                                const halfBase = 5

                                // Needle soft shadow
                                ctx.beginPath()
                                ctx.fillStyle = "rgba(37,49,72,0.22)"
                                ctx.moveTo(pivotX + 5, cy - halfBase + 2)
                                ctx.lineTo(tipX - 1, cy + 2)
                                ctx.lineTo(pivotX + 5, cy + halfBase + 2)
                                ctx.closePath()
                                ctx.fill()

                                // Needle body (triangle)
                                const grad = ctx.createLinearGradient(pivotX, cy, tipX, cy)
                                grad.addColorStop(0.0, "#ff5d83")
                                grad.addColorStop(1.0, "#ee3e69")
                                ctx.fillStyle = grad
                                ctx.beginPath()
                                ctx.moveTo(pivotX + 3, cy - halfBase)
                                ctx.lineTo(tipX, cy)
                                ctx.lineTo(pivotX + 3, cy + halfBase)
                                ctx.closePath()
                                ctx.fill()

                                // Rounded base cap
                                ctx.beginPath()
                                ctx.fillStyle = "#f04a73"
                                ctx.arc(pivotX, cy, pivotR, 0, Math.PI * 2)
                                ctx.fill()

                                // Center white hole
                                ctx.beginPath()
                                ctx.fillStyle = "#ffffff"
                                ctx.arc(pivotX, cy, 3.3, 0, Math.PI * 2)
                                ctx.fill()
                            }
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                            height: 24
                            radius: 12
                            color: "#ff6f94"
                            opacity: vpnController.speedTestRunning ? 0.22 : 0.0
                            antialiasing: true
                            z: -2
                            scale: vpnController.speedTestRunning ? 1.0 : 0.86

                            SequentialAnimation on opacity {
                                running: vpnController.speedTestRunning
                                loops: Animation.Infinite
                                NumberAnimation { from: 0.30; to: 0.12; duration: 360; easing.type: Easing.InOutQuad }
                                NumberAnimation { from: 0.12; to: 0.30; duration: 420; easing.type: Easing.InOutQuad }
                            }
                            SequentialAnimation on scale {
                                running: vpnController.speedTestRunning
                                loops: Animation.Infinite
                                NumberAnimation { from: 0.88; to: 1.06; duration: 360; easing.type: Easing.InOutQuad }
                                NumberAnimation { from: 1.06; to: 0.88; duration: 420; easing.type: Easing.InOutQuad }
                            }
                        }
                    }

                    RectangularShadow {
                        anchors.fill: n1
                        visible: false
                        offset.x: -10
                        offset.y: -5
                        radius: n1.radius
                        blur: 16
                        spread: 0
                        color: Colors.lightShadow
                    }

                    Rectangle {
                        id: n1
                        visible: false
                        width: 48
                        height: 48
                        radius: width
                        anchors.centerIn: parent
                        color: "#fcfcfc"
                        border.width: 1
                        border.color: "#f1f1f1"
                        z: 35

                        Rectangle {
                            width: 16
                            height: 16
                            radius: width
                            anchors.centerIn: parent
                            color: "#2a3342"
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: speedDial.innerRadius * 1.58
                        height: width
                        radius: width * 0.5
                        color: root.themeColor("#ffffff", "#22324a")
                        border.width: 1
                        border.color: root.themeColor("#e2e8f2", "#456081")
                        z: 45
                    }

                    Column {
                        anchors.centerIn: parent
                        width: speedDial.innerRadius * 1.45
                        spacing: 0
                        z: 60

                        Text {
                            text: root.speedGaugePrefixText() + root.speedGaugeNumberText()
                            color: root.themeColor("#1f2530", "#edf4ff")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 30
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                        }

                        Text {
                            text: root.speedGaugeUnitText()
                            color: root.themeColor("#8f97a6", "#9db1ca")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 16
                            font.weight: Font.Light
                            font.bold: false
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                        }

                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: vpnController.speedTestRunning ? speedTestStatusText() : speedTestSideStatusText()
                color: vpnController.speedTestError.length > 0
                       ? root.themeColor("#d14545", "#ff8e8e")
                       : (vpnController.speedTestRunning
                          ? root.themeColor("#6a7890", "#9db2cc")
                          : root.themeColor("#5f6f88", "#9bb0cb"))
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            GridLayout {
                Layout.fillWidth: true
                columns: root.compact ? 2 : 4
                columnSpacing: 8
                rowSpacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 56
                    radius: 14
                    color: vpnController.speedTestState === "Completed" || vpnController.speedTestRunning
                           ? root.themeColor("#eaf2ff", "#223753")
                           : root.themeColor("#f5f8fc", "#1f2f46")
                    border.width: 1
                    border.color: root.themeColor("#dce4ef", "#3f5777")

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            text: "Latency"
                            color: root.themeColor("#6f7d92", "#9cb0c8")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 13
                        }
                        Text {
                            text: vpnController.speedTestPingMs >= 0 ? (vpnController.speedTestPingMs + " ms") : "--"
                            color: root.themeColor("#1f2530", "#edf4ff")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 56
                    radius: 14
                    color: vpnController.speedTestState === "Completed" || vpnController.speedTestRunning
                           ? root.themeColor("#eaf2ff", "#223753")
                           : root.themeColor("#f5f8fc", "#1f2f46")
                    border.width: 1
                    border.color: root.themeColor("#dce4ef", "#3f5777")

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            text: "Download"
                            color: root.themeColor("#6f7d92", "#9cb0c8")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 13
                        }
                        Text {
                            text: vpnController.speedTestDownloadMbps > 0 ? vpnController.speedTestDownloadMbps.toFixed(2) + " Mbps" : "--"
                            color: root.themeColor("#1f2530", "#edf4ff")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 56
                    radius: 14
                    color: vpnController.speedTestState === "Completed" || vpnController.speedTestRunning
                           ? root.themeColor("#eaf2ff", "#223753")
                           : root.themeColor("#f5f8fc", "#1f2f46")
                    border.width: 1
                    border.color: root.themeColor("#dce4ef", "#3f5777")

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            text: "Throughput"
                            color: root.themeColor("#6f7d92", "#9cb0c8")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 13
                        }
                        Text {
                            text: vpnController.speedTestDownloadMbps > 0
                                  ? (vpnController.speedTestDownloadMbps / 8.0).toFixed(2) + " MB/s"
                                  : "--"
                            color: root.themeColor("#1f2530", "#edf4ff")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 56
                    radius: 14
                    color: vpnController.speedTestRunning || vpnController.speedTestState === "Completed"
                           ? root.themeColor("#eaf2ff", "#223753")
                           : root.themeColor("#f5f8fc", "#1f2f46")
                    border.width: 1
                    border.color: root.themeColor("#dce4ef", "#3f5777")

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            text: "Progress"
                            color: root.themeColor("#6f7d92", "#9cb0c8")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 13
                        }
                        Text {
                            text: Math.round(Math.max(0, Math.min(vpnController.speedTestProgress, 1.0)) * 100) + "%"
                            color: root.themeColor("#1f2530", "#edf4ff")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Test Size:"
                    color: root.themeColor("#64748b", "#9db2cc")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 13
                }

                Repeater {
                    model: [5, 10, 25]

                    delegate: Rectangle {
                        required property int modelData
                        Layout.preferredWidth: 62
                        Layout.preferredHeight: 30
                        radius: 8
                        color: vpnController.speedTestSelectedSizeMb === modelData
                               ? root.themeColor("#2f6ff1", "#3a7bff")
                               : root.themeColor("#f5f8fc", "#1f2f46")
                        border.width: 1
                        border.color: vpnController.speedTestSelectedSizeMb === modelData
                                      ? root.themeColor("#2f6ff1", "#3a7bff")
                                      : root.themeColor("#dbe3ef", "#3f5777")

                        Text {
                            anchors.centerIn: parent
                            text: modelData + " MB"
                            color: vpnController.speedTestSelectedSizeMb === modelData
                                   ? "#ffffff"
                                   : root.themeColor("#495971", "#b7cae2")
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

                Item { Layout.fillWidth: true }
            }

            Controls.PrimaryActionButton {
                Layout.alignment: Qt.AlignHCenter
                width: 172
                height: 48
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
                    color: root.themeColor("#1f2430", "#d7e4f6")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    text: infoIpText()
                    color: root.themeColor("#8f97a6", "#9eb2cb")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                }

                Rectangle { width: 1; height: 26; color: root.themeColor("#d4d9e3", "#405979") }

                Text {
                    text: "Proxy:"
                    color: root.themeColor("#1f2430", "#d7e4f6")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    text: speedTestProxyText()
                    color: root.themeColor("#8f97a6", "#9eb2cb")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                }

                Rectangle { width: 1; height: 26; color: root.themeColor("#d4d9e3", "#405979") }

                Text {
                    text: "Provider:"
                    color: root.themeColor("#1f2430", "#d7e4f6")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    text: speedTestProviderText()
                    color: root.themeColor("#8f97a6", "#9eb2cb")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                }

                Rectangle { width: 1; height: 26; color: root.themeColor("#d4d9e3", "#405979") }

                Text {
                    text: "OS:"
                    color: root.themeColor("#1f2430", "#d7e4f6")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    text: osNameText()
                    color: root.themeColor("#8f97a6", "#9eb2cb")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: speedTestPopup.showHistory ? 86 : 42
                radius: 16
                color: root.themeColor("#f7f9fc", "#1a2638")
                border.width: 1
                border.color: root.themeColor("#dde4ef", "#355070")

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: "Latest Results"
                        color: root.themeColor("#3f4d63", "#d7e4f6")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: speedTestPopup.showHistory

                        ListView {
                            anchors.fill: parent
                            clip: true
                            spacing: 2
                            model: vpnController.speedTestHistory
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
                                    color: root.themeColor("#586780", "#b0c3db")
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
                            color: root.themeColor("#8a95a8", "#9eb2cb")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 13
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
            color: root.themeColor("#ffffff", "#131b27")
            border.width: 1
            border.color: root.themeColor("#d8dde8", "#283345")
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
                color: root.themeColor("#d6dde8", "#304059")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Import Profiles"
                    font.family: FontSystem.getContentFontBold.name
                    font.weight: Font.Bold
                    font.pixelSize: 23
                    color: root.themeColor("#1f2530", "#d8e1f0")
                }

                Item { Layout.fillWidth: true }

                Controls.CircleIconButton {
                    diameter: 32
                    elevated: false
                    iconText: root.iconClose
                    iconFontFamily: root.faSolid
                    iconPixelSize: 13
                    backgroundColor: root.themeColor("#f7f9fc", "#1f2f46")
                    borderColor: root.themeColor("#d8e1ef", "#4d6a8d")
                    iconColor: root.themeColor("#94a3b8", "#a2b5ce")
                    enabled: !vpnController.subscriptionBusy
                    onClicked: importPopup.close()
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Paste vmess/vless, batch text, base64 payload, or an https subscription URL."
                color: root.themeColor("#6f7f95", "#9eb2cb")
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
                    color: root.themeColor("#f7f9fd", "#1f2f46")
                    border.width: 1
                    border.color: subscriptionGroupField.activeFocus
                                  ? root.themeColor("#b9ccee", "#5f87c2")
                                  : root.themeColor("#d9e1ef", "#3a5470")

                    TextField {
                        id: subscriptionGroupField
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        padding: 0
                        text: root.subscriptionGroupDraft
                        placeholderText: "Group name"
                        color: root.themeColor("#1f2a3a", "#edf4ff")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 13
                        selectedTextColor: "#ffffff"
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
                    backgroundColor: root.themeColor("#f4f8ff", "#1f2f46")
                    borderColor: root.themeColor("#d8e4f8", "#4d6a8d")
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
                    backgroundColor: root.themeColor("#fff6f6", "#3b2631")
                    borderColor: root.themeColor("#f0d5d5", "#7d5062")
                    iconColor: root.themeColor("#cb4f4f", "#ff8e8e")
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
                    color: root.themeColor("#6b778a", "#9cb0c8")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                }

                Rectangle {
                    Layout.preferredWidth: 76
                    Layout.preferredHeight: 32
                    radius: 16
                    color: root.profileGroupBadgeText(subscriptionGroupField.text).length === 0
                           ? root.themeColor("#eaf2ff", "#223753")
                           : root.themeColor("#ffffff", "#22324a")
                    border.width: 1
                    border.color: root.profileGroupBadgeText(subscriptionGroupField.text).length === 0
                                  ? root.brandBlue
                                  : root.themeColor("#dfe7f2", "#3f5777")

                    Text {
                        anchors.centerIn: parent
                        text: "None"
                        color: root.profileGroupBadgeText(subscriptionGroupField.text).length === 0
                               ? root.brandBlue
                               : root.themeColor("#667487", "#9bb0cb")
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
                           ? root.themeColor("#eaf2ff", "#223753")
                           : root.themeColor("#ffffff", "#22324a")
                    border.width: 1
                    border.color: root.profileGroupBadgeText(subscriptionGroupField.text).toLowerCase() === "free"
                                  ? root.brandBlue
                                  : root.themeColor("#dfe7f2", "#3f5777")

                    Text {
                        anchors.centerIn: parent
                        text: "Free"
                        color: root.profileGroupBadgeText(subscriptionGroupField.text).toLowerCase() === "free"
                               ? root.brandBlue
                               : root.themeColor("#667487", "#9bb0cb")
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
                           ? root.themeColor("#efeaff", "#2a2450")
                           : root.themeColor("#ffffff", "#22324a")
                    border.width: 1
                    border.color: root.profileGroupBadgeText(subscriptionGroupField.text).toLowerCase() === "premium"
                                  ? root.themeColor(root.brandViolet, "#7568d5")
                                  : root.themeColor("#dfe7f2", "#3f5777")

                    Text {
                        anchors.centerIn: parent
                        text: "Premium"
                        color: root.profileGroupBadgeText(subscriptionGroupField.text).toLowerCase() === "premium"
                               ? root.themeColor(root.brandViolet, "#b8acff")
                               : root.themeColor("#667487", "#9bb0cb")
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
                           ? root.themeColor("#e8f7ef", "#173c2f")
                           : root.themeColor("#fff0f0", "#3b2631")
                    border.width: 1
                    border.color: root.profileGroupEnabled(subscriptionGroupField.text)
                                  ? root.themeColor("#b7e4cb", "#3f8569")
                                  : root.themeColor("#f2c6c6", "#7d5062")

                    Text {
                        id: groupStateText
                        anchors.centerIn: parent
                        text: root.profileGroupEnabled(subscriptionGroupField.text) ? "Group Enabled" : "Group Disabled"
                        color: root.profileGroupEnabled(subscriptionGroupField.text)
                               ? root.themeColor("#2c8b57", "#5adf97")
                               : root.themeColor("#bf4d4d", "#ff8e8e")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 11
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: 12
                    color: root.themeColor("#f7f9fd", "#1f2f46")
                    border.width: 1
                    border.color: root.themeColor("#dce4f2", "#3f5777")

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
                            color: root.themeColor("#ffffff", "#22324a")
                            border.width: 1
                            border.color: root.themeColor("#d5deec", "#3f5777")

                            TextField {
                                id: importGroupBadgeField
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                padding: 0
                                clip: true
                                placeholderText: "Badge"
                                text: root.profileGroupBadgeText(subscriptionGroupField.text)
                                color: root.themeColor("#3b4a61", "#d0ddf0")
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
                            color: root.themeColor("#4d6691", "#9fc3f2")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Groups: " + root.importSelectableGroups().length
                    color: root.themeColor("#90a0b5", "#9fb4cd")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 11
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: 10
                color: root.themeColor("#eef4ff", "#223753")
                border.width: 1
                border.color: root.themeColor("#d2def4", "#3f5777")

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: "Import Target Group:"
                        color: root.themeColor("#5f6f86", "#9bb0cb")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 12
                    }

                    Text {
                        Layout.fillWidth: true
                        text: importPopup.targetGroupName
                        color: root.themeColor("#2c5eaf", "#8ab6ff")
                        font.family: FontSystem.getContentFontBold.name
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: root.width >= 620
                        text: "All pasted profiles/subscriptions will be saved here."
                        color: root.themeColor("#7d8ea7", "#9eb2cb")
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
                color: root.themeColor("#f7f9fd", "#1f2f46")
                border.width: 1
                border.color: root.themeColor("#d8e1ef", "#3f5777")

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Manage Groups"
                            color: root.themeColor("#5f6f86", "#9bb0cb")
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
                                   ? root.themeColor("#eaf2ff", "#223753")
                                   : root.themeColor("#ffffff", "#22324a")
                            border.width: selectedGroup ? 2 : 1
                            border.color: selectedGroup
                                          ? root.themeColor("#3d7ae6", "#5f95f2")
                                          : root.themeColor("#dee6f3", "#3f5777")

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
                                        color: root.themeColor("#2b3648", "#d7e4f6")
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
                                    color: root.themeColor("#3b4a61", "#d0ddf0")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 12
                                    background: Rectangle {
                                        radius: 8
                                        color: root.themeColor("#f8fbff", "#22324a")
                                        border.width: 1
                                        border.color: root.themeColor("#d5deec", "#3f5777")
                                    }
                                    onEditingFinished: vpnController.setProfileGroupBadge(groupName, text)
                                }

                                Controls.CircleIconButton {
                                    diameter: 24
                                    iconText: root.iconTrash
                                    iconFontFamily: root.faSolid
                                    iconPixelSize: 10
                                    iconColor: root.themeColor("#cb4f4f", "#ff8e8e")
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
                fillColor: root.themeColor("#f8fbff", "#8a18283d")
                strokeColor: root.themeColor("#d8e2f0", "#3f587a")
                focusColor: root.themeColor("#8bb8ff", "#6ba0ff")
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
                           ? root.themeColor("#2b6dcf", "#8ab6ff")
                           : (root.importStatusKind === "success"
                              ? root.themeColor("#2c8b57", "#5adf97")
                              : (root.importStatusKind === "error"
                                 ? root.themeColor("#c65050", "#ff8e8e")
                                 : root.themeColor("#6f7f95", "#9eb2cb")))
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
                    iconColor: root.themeColor("#a0a8b5", "#8ea1ba")
                    iconPixelSize: 18
                    onClicked: settingsPopup.open()
                }

                Controls.CircleIconButton {
                    diameter: 46
                    iconText: root.iconInfo
                    iconFontFamily: root.faSolid
                    iconColor: root.themeColor("#a0a8b5", "#8ea1ba")
                    iconPixelSize: 18
                    onClicked: aboutPopup.open()
                }

                Controls.CircleIconButton {
                    diameter: 46
                    iconText: root.iconHistory
                    iconFontFamily: root.faSolid
                    iconColor: root.themeColor("#a0a8b5", "#8ea1ba")
                    iconPixelSize: 18
                    onClicked: logsPopup.open()
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
                color: root.themeColor("#ffffff", "#1a2638")
                border.width: 1
                z: 2
                    border.color: vpnController.connected
                                  ? root.themeColor("#c8ead8", "#3f8569")
                                  : (vpnController.busy
                                     ? root.themeColor("#f7ddaa", "#7e6633")
                                     : Colors.borderDeactivated)
                Behavior on border.color { ColorAnimation { duration: Animations.fast } }

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 8
                    radius: Colors.radius
                    color: root.themeColor("#1f5ed8", "#376de0")
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
                                border.width: 1
                                border.color: root.themeColor("#dee3ec", "#3a4f69")

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
                                color: root.themeColor("#9ea6b5", "#9fb4cd")
                                font.family: root.faSolid
                                font.pixelSize: 14
                            }
                        }
                    }

                    Rectangle {
                        width: 1
                        Layout.fillHeight: true
                        color: root.themeColor("#e6ebf3", "#334b67")
                    }

                    Rectangle {
                        id: inlineConnectButton
                        Layout.preferredWidth: compact ? 228 : 250
                        Layout.fillHeight: true
                        radius: Colors.innerRadius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#2f6ff1" }
                            GradientStop { position: 1.0; color: "#2d65d8" }
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
                                color: "#ffffff"
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
                                color: "#ffffff"
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
                color: root.themeColor("#ffffff", "#1a2638")
                border.width: 1
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
                        border.width: 1
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
                                    color: root.themeColor("#6f7f96", "#9fb4cd")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: Typography.h6
                                }
                                Text {
                                    text: root.stateText()
                                    color: root.themeColor("#1f2a37", "#d7e4f6")
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
                        color: root.themeColor("#e6ebf3", "#334b67")
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Colors.innerRadius
                        color: root.themeColor("#eaf2ff", "#223753")
                        border.width: 1
                        border.color: root.themeColor("#d7e4fb", "#3f5777")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: "↓"
                                color: root.themeColor("#2874f0", "#8ab6ff")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 18
                                font.bold: true
                            }

                            ColumnLayout {
                                spacing: 1
                                Text {
                                    text: "Receive"
                                    color: root.themeColor("#6682ad", "#9fc3f2")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: Typography.h6
                                }
                                Controls.NumberFlowText {
                                    text: root.downloadRateText()
                                    color: root.themeColor("#3f5e93", "#c7dbf8")
                                    fontSize: Typography.t3
                                    bold: true
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Controls.NumberFlowText {
                                text: downloadUsageText()
                                color: root.themeColor("#1f2b3d", "#edf4ff")
                                fontSize: Typography.h3
                            }

                            Item { Layout.preferredWidth: 15 }

                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Colors.innerRadius
                        color: root.themeColor("#ecfff3", "#173c2f")
                        border.width: 1
                        border.color: root.themeColor("#d8efdf", "#3f8569")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: "↑"
                                color: root.themeColor("#1ea768", "#5edc86")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 18
                                font.bold: true
                            }

                            ColumnLayout {
                                spacing: 1
                                Text {
                                    text: "Send"
                                    color: root.themeColor("#5f9478", "#9fceb7")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: Typography.h6
                                }
                                Controls.NumberFlowText {
                                    text: root.uploadRateText()
                                    color: root.themeColor("#2e7b58", "#bee9d3")
                                    fontSize: Typography.t3
                                    bold: true
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Controls.NumberFlowText {
                                text: uploadUsageText()
                                color: root.themeColor("#1f2b3d", "#edf4ff")
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
                    color: vpnController.connected ? "#e8faef" : "#f1edff"
                    border.width: 1
                    border.color: vpnController.connected ? "#bdeacb" : "#d9d0ff"

                    Text {
                        anchors.centerIn: parent
                        text: root.iconShield
                        color: vpnController.connected ? "#22a557" : root.brandViolet
                        font.family: root.faSolid
                        font.pixelSize: 10
                    }
                }

                Text {
                    text: root.infoIpLabel() + ":"
                    color: root.themeColor("#2a3140", "#d7e4f6")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                    font.bold: true
                }

                Text {
                    text: infoIpText()
                    color: root.themeColor("#8e98aa", "#9eb2cb")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 1
                height: 24
                color: root.themeColor("#d9dee8", "#3a4f69")
            }

            RowLayout {
                spacing: 6

                Text {
                    text: "Your Location:"
                    color: root.themeColor("#2a3140", "#d7e4f6")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 16
                    font.bold: true
                }

                Text {
                    text: infoLocationText()
                    color: root.themeColor("#8e98aa", "#9eb2cb")
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
                iconColor: root.themeColor("#97a0b0", "#9fb4cd")
                onClicked: settingsPopup.open()
            }

            Controls.CircleIconButton {
                diameter: 64
                iconText: root.iconSpeed
                iconFontFamily: root.faSolid
                iconPixelSize: 20
                iconColor: root.themeColor("#97a0b0", "#9fb4cd")
                onClicked: speedTestPopup.open()
            }

            Controls.CircleIconButton {
                diameter: 64
                iconText: root.iconImport
                iconFontFamily: root.faSolid
                iconPixelSize: 20
                iconColor: root.themeColor("#97a0b0", "#9fb4cd")
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
            color: root.themeColor("#ffffff", "#0f1622")
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.themeColor("#ffffff", "#101927") }
                GradientStop { position: 0.58; color: root.themeColor("#ffffff", "#101927") }
                GradientStop { position: 1.0; color: root.themeColor("#eef7ff", "#0b121d") }
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
            opacity: 0.15
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
                                         ? root.themeColor("#ecfaf3", "#102b1f")
                                         : root.themeColor("#edf7ff", "#1a2638")
                        borderColor: vpnController.loggingEnabled
                                     ? root.themeColor("#ccefdc", "#275641")
                                     : root.themeColor("#d9edff", "#2f425d")
                        iconText: vpnController.loggingEnabled ? root.iconFileLines : root.iconHistory
                        iconFontFamily: root.faSolid
                        iconColor: vpnController.loggingEnabled ? "#34c37b" : root.themeColor(root.brandBlue, "#84b2ff")
                        iconPixelSize: 15
                        onClicked: logsPopup.open()
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: 1
                        anchors.topMargin: 1
                        width: 9
                        height: 9
                        radius: 4.5
                        visible: vpnController.loggingEnabled
                        color: "#22b26a"
                        border.width: 1
                        border.color: root.themeColor("#ffffff", "#131f2d")
                    }
                }

                Text {
                    text: "<strong>GENY</strong>CONNECT"
                    color: root.themeColor(root.brandInk, "#e5edf9")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 15
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Speed"
                    color: root.themeColor(root.brandInk, "#e5edf9")
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: 15
                    font.bold: true
                }

                Rectangle {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    radius: 21
                    color: root.themeColor("#f0edff", "#221c36")
                    border.width: 1
                    border.color: root.themeColor("#d9d0ff", "#463472")

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
                color: root.themeColor("#050505", "#f1f5ff")
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
                color: root.themeColor("#f5f7fb", "#182230")
                border.width: 1
                border.color: root.themeColor("#e3e8f1", "#2f3d53")

                RowLayout {
                    id: ipPillRow
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        radius: 11
                        border.width: 1
                        color: vpnController.connected
                               ? root.themeColor("#e8faef", "#173323")
                               : root.themeColor("#f1edff", "#241f3d")
                        border.color: vpnController.connected
                                      ? root.themeColor("#bdeacb", "#376e52")
                                      : root.themeColor("#d9d0ff", "#4b3d73")

                        Text {
                            anchors.centerIn: parent
                            text: root.iconShield
                            color: vpnController.connected ? "#22a557" : root.themeColor(root.brandViolet, "#a88dff")
                            font.family: root.faSolid
                            font.pixelSize: 11
                        }
                    }

                    Text {
                        id: ipPillText
                        text: root.infoIpLabel() + " " + (vpnController.publicIpRefreshing ? "securing..." : root.infoIpText())
                        color: root.themeColor("#344053", "#c7d4e6")
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
                        color: root.themeColor("#557299", "#9ab2ce")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 11
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4

                        Controls.NumberFlowText {
                            text: root.latestUsageValuePart()
                            color: root.themeColor("#173f75", "#d2e1f6")
                            fontSize: 24
                            bold: true
                        }

                        Text {
                            text: root.latestUsageUnitPart()
                            color: root.themeColor("#244f86", "#a9c1de")
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
                            color: "#ffffff"
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
                           ? root.themeColor("#e7faef", "#6646a77c")
                           : (vpnController.busy
                              ? root.themeColor("#fff5d8", "#666f5b2e")
                              : root.themeColor("#f1f3f7", "#66557a9f"))
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
                               ? root.themeColor("#55c982", "#82e3bb")
                               : (vpnController.busy
                                  ? root.themeColor("#d3a722", "#f0c86e")
                                  : root.themeColor("#8993a4", "#c8d9ed"))
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
                color: root.themeColor("#f0f1f5", "#223147")
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

                    RowLayout {
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(142, parent.width - 24)
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: 14
                            color: root.themeColor("#e9fff2", "#173126")

                            Text {
                                anchors.centerIn: parent
                                text: "↓"
                                color: "#5edc86"
                                font.pixelSize: 20
                                font.bold: true
                            }
                        }

                        Column {
                            Layout.preferredWidth: 104
                            Layout.minimumWidth: 104
                            Layout.maximumWidth: 104
                            spacing: 4
                            Text {
                                width: parent.width
                                text: "Downlink"
                                color: root.themeColor("#1b1b1f", "#cbd9ec")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 13
                            }
                            Row {
                                width: parent.width
                                spacing: 4
                                Controls.NumberFlowText {
                                    id: downStatValueText
                                    width: 58
                                    text: root.formatSpeedValue(Math.max(0, downRateBytesPerSec), dashboardStatsSettings.speedUnit).value
                                    color: root.themeColor("#050505", "#eef4ff")
                                    fontSize: 18
                                    bold: true
                                    transformOrigin: Item.Center
                                }
                                Text {
                                    width: 42
                                    text: root.formatSpeedValue(Math.max(0, downRateBytesPerSec), dashboardStatsSettings.speedUnit).unit
                                    color: root.themeColor("#5b5d66", "#9db0c9")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: root.themeColor("#eef0f4", "#364b66")
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(142, parent.width - 24)
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: 14
                            color: root.themeColor("#fff9db", "#3a3215")

                            Text {
                                anchors.centerIn: parent
                                text: "↑"
                                color: "#dfc33f"
                                font.pixelSize: 20
                                font.bold: true
                            }
                        }

                        Column {
                            Layout.preferredWidth: 104
                            Layout.minimumWidth: 104
                            Layout.maximumWidth: 104
                            spacing: 4
                            Text {
                                width: parent.width
                                text: "Uplink"
                                color: root.themeColor("#1b1b1f", "#cbd9ec")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 13
                            }
                            Row {
                                width: parent.width
                                spacing: 4
                                Controls.NumberFlowText {
                                    id: upStatValueText
                                    width: 58
                                    text: root.formatSpeedValue(Math.max(0, upRateBytesPerSec), dashboardStatsSettings.speedUnit).value
                                    color: root.themeColor("#050505", "#eef4ff")
                                    fontSize: 18
                                    bold: true
                                    transformOrigin: Item.Center
                                }
                                Text {
                                    width: 42
                                    text: root.formatSpeedValue(Math.max(0, upRateBytesPerSec), dashboardStatsSettings.speedUnit).unit
                                    color: root.themeColor("#5b5d66", "#9db0c9")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: mobileLocationCard
                Layout.fillWidth: true
                Layout.preferredHeight: 78
                Layout.minimumHeight: 78
                Layout.maximumHeight: 78
                radius: 18
                color: mobileLocationMouse.containsMouse
                       ? root.themeColor("#fbfcff", "#1a2638")
                       : root.themeColor("#ffffff", "#142032")
                border.width: 1
                border.color: root.themeColor("#ebedf3", "#2e3d52")

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        radius: 21
                        color: root.themeColor("#f0f1ff", "#273650")

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
                            color: root.themeColor("#070707", "#edf3fe")
                            font.family: FontSystem.getContentFontBold.name
                            font.pixelSize: 16
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            Layout.preferredWidth: Math.min(serverBadgeText.implicitWidth + 20, 118)
                            Layout.preferredHeight: 21
                            radius: 11
                            color: root.themeColor("#edf2ff", "#263858")

                            Text {
                                id: serverBadgeText
                                anchors.centerIn: parent
                                text: vpnController.tunMode ? "TUN Server" : "Game Server"
                                color: root.themeColor(root.brandBlue, "#9ec1ff")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: selectedServerMeta
                            color: root.themeColor("#7385a0", "#97acc8")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 10
                            elide: Text.ElideMiddle
                        }
                    }

                    Text {
                        text: "\uf054"
                        color: root.themeColor("#050505", "#dce7f8")
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
            color: root.themeColor("#ffffff", "#121d2e")
            border.width: 1
            border.color: root.themeColor("#eff1f6", "#2a3950")

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 28
                color: root.themeColor("#ffffff", "#121d2e")
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
                        color: root.themeColor("#3147d0", "#3e6fff")

                        Text {
                            anchors.centerIn: parent
                            text: "\uf015"
                            color: "#ffffff"
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
                        color: root.themeColor("#050505", "#d7e4f6")
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
                        color: root.themeColor("#050505", "#d7e4f6")
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
        border.width: 1
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
                    color: root.themeColor("#4f627f", "#9eb2cb")
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: 12
                    font.bold: true
                }

                Text {
                    text: "<strong>Hour</strong> " + vpnController.currentProfileUsageHour
                    color: root.themeColor("#647891", "#9fb4cd")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                }

                Text {
                    text: "<strong>Day</strong> " + vpnController.currentProfileUsageDay
                    color: root.themeColor("#647891", "#9fb4cd")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                }

                Text {
                    text: "<strong>Week</strong> " + vpnController.currentProfileUsageWeek
                    color: root.themeColor("#647891", "#9fb4cd")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                }

                Text {
                    text: "<strong>Month</strong> " + vpnController.currentProfileUsageMonth
                    color: root.themeColor("#647891", "#9fb4cd")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                }

                Item { Layout.fillWidth: true }
            }

            Item { Layout.preferredWidth: 10; }
        }
    }
}
