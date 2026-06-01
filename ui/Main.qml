import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtCore

import GenyConnect 1.0

import "Core"
import "Controls" as Controls
import "Sections" as Sections

ApplicationWindow {

    id: root

    readonly property bool mobilePlatform: Qt.platform.os === "android" || Qt.platform.os === "ios"
    readonly property bool mobileLandscape: mobilePlatform && root.width > root.height

    readonly property bool compact: mobilePlatform || root.width < 620

    readonly property real reportedSafeTopInset: Number((SafeArea.margins && SafeArea.margins.top) || 0)
    readonly property real reportedSafeBottomInset: Number((SafeArea.margins && SafeArea.margins.bottom) || 0)
    readonly property real androidDensityScale: Math.max(1.0, (Screen.pixelDensity * 25.4) / 160.0)
    readonly property real androidFallbackSafeTopInset: 0
    readonly property real androidFallbackSafeBottomInset: (mobilePlatform && Qt.platform.os === "android" && reportedSafeBottomInset <= 0.5)
        ? Math.round(40 * androidDensityScale)
        : 0
    readonly property real safeTopInset: mobilePlatform
        ? Math.max((Qt.platform.os === "ios" ? 14 : androidFallbackSafeTopInset), reportedSafeTopInset)
        : 0
    readonly property real safeBottomInset: mobilePlatform
        ? Math.max((Qt.platform.os === "ios" ? 22 : androidFallbackSafeBottomInset), reportedSafeBottomInset)
        : 0

    readonly property real compactBottomNavVisualHeight: mobilePlatform
        ? (mobileLandscape ? 44 : 48)
        : 60
    readonly property real compactBottomNavInset: safeBottomInset
    readonly property real compactBottomNavHeight: compactBottomNavVisualHeight + compactBottomNavInset
    readonly property real compactBottomNavSafeFillHeight: mobilePlatform
        ? Math.max(mobileLandscape ? 4 : 8, compactBottomNavInset + (mobileLandscape ? 2 : 4))
        : Math.max(34, safeBottomInset + 18)
    readonly property real compactBottomNavTopMargin: mobilePlatform ? (mobileLandscape ? 0 : 2) : 0

    readonly property real compactContentBottomClearance: compactBottomNavHeight + (mobilePlatform ? (mobileLandscape ? 8 : 14) : 18)

    readonly property real compactAvailableHeight: Math.max(
        1,
        root.height - safeTopInset - compactContentBottomClearance
    )

    readonly property real compactHeightScale: compact
        ? Math.max(0.54, Math.min(1.0, compactAvailableHeight / 700.0))
        : 1.0

    // Android home geometry tokens to keep spacing proportional and avoid overlap.
    readonly property real mobileHomeScale: compact
        ? (mobilePlatform
           ? (mobileLandscape
              ? Math.max(0.60, Math.min(0.84, compactAvailableHeight / 560.0))
              : Math.max(0.72, Math.min(0.92, compactAvailableHeight / 760.0)))
           : Math.max(0.88, Math.min(1.08, compactAvailableHeight / 640.0)))
        : 1.0
    readonly property real mobileHomeTopMargin: safeTopInset + (mobilePlatform ? (mobileLandscape ? 5 : 6) : 10)
    readonly property real mobileHomeBottomMargin: mobilePlatform
        ? (mobileLandscape ? 6 : 8)
        : 10
    readonly property real mobileHomeHorizontalMargin: mobilePlatform ? (mobileLandscape ? 24 : 18) : 18
    readonly property real mobileHomeMapVerticalOffset: mobilePlatform
        ? (mobileLandscape
           ? Math.round(6 * mobileHomeScale)
           : Math.round(20 * mobileHomeScale))
        : Math.round(18 * mobileHomeScale)
    readonly property real mobileHomeMapWidthFactor: mobilePlatform ? (mobileLandscape ? 1.06 : 1.42) : 1.55
    readonly property real mobileHomeMapHeightFactor: mobilePlatform ? (mobileLandscape ? 0.52 : 0.66) : 0.82
    readonly property real mobileHomeMapOpacity: mobilePlatform ? (mobileLandscape ? 0.30 : 0.35) : 0.45
    readonly property real mobileHomeSectionGap: mobilePlatform
        ? (mobileLandscape
           ? Math.max(3, Math.round(4 * mobileHomeScale))
           : Math.max(6, Math.round(6 * mobileHomeScale)))
        : Math.max(4, Math.round(4 * mobileHomeScale))
    readonly property real mobileHomeHeaderHeight: Math.max(42, Math.round(44 * mobileHomeScale))
    readonly property real mobileHomeTimerHeight: Math.max(46, Math.round(56 * mobileHomeScale))
    readonly property real mobileHomeInfoPillHeight: mobilePlatform ? (mobileLandscape ? 52 : 58) : 52
    readonly property real mobileHomeUsageHeight: Math.max(50, Math.round(56 * mobileHomeScale))
    readonly property real mobileHomeHeroDiameter: mobilePlatform
        ? (mobileLandscape
           ? Math.max(104, Math.round(126 * mobileHomeScale))
           : Math.max(150, Math.round(180 * mobileHomeScale)))
        : Math.max(150, Math.round(176 * mobileHomeScale))
    readonly property real mobileHomeHeroExtraHeight: mobilePlatform
        ? (mobileLandscape
           ? Math.max(16, Math.round(22 * mobileHomeScale))
           : Math.max(30, Math.round(36 * mobileHomeScale)))
        : 20
    readonly property real mobileHomeHeroBlockHeight: mobileHomeHeroDiameter + mobileHomeHeroExtraHeight
    readonly property real mobileHomeStatusTopGap: mobilePlatform
        ? Math.max(12, Math.round(14 * mobileHomeScale))
        : Math.max(8, Math.round(10 * mobileHomeScale))
    readonly property real mobileHomeStatusChipHeight: mobilePlatform ? 34 : 32
    readonly property real mobileHomeStatusMinWidth: mobilePlatform
        ? Math.max(164, Math.round(188 * mobileHomeScale))
        : 0
    readonly property real mobileHomeStatsHeight: mobilePlatform
        ? (mobileLandscape ? Math.max(66, Math.round(74 * mobileHomeScale))
                           : Math.max(86, Math.round(94 * mobileHomeScale)))
        : Math.max(88, Math.round(96 * mobileHomeScale))
    readonly property real mobileHomeStatsToCardGap: mobilePlatform
        ? Math.max(14, Math.round(18 * mobileHomeScale))
        : Math.max(8, Math.round(12 * mobileHomeScale))
    readonly property real mobileHomeCardHeight: Math.max(56, Math.round(68 * mobileHomeScale))

    visible: true

    width: mobilePlatform ? Screen.width : 430

    height: mobilePlatform ? Screen.height : 760

    minimumWidth: mobilePlatform ? 0 : 430

    minimumHeight: mobilePlatform ? 0 : 760

    maximumWidth: mobilePlatform ? 16777215 : 430

    maximumHeight: mobilePlatform ? 16777215 : 760

    // visibility: mobilePlatform ? Window.FullScreen : Window.Windowed

    flags: mobilePlatform

           ? Qt.Window

           : Qt.Window

             | Qt.WindowTitleHint

             | Qt.WindowSystemMenuHint

             | Qt.WindowMinimizeButtonHint

             | Qt.WindowCloseButtonHint


    title: "GenyConnect (Build " + updater.appVersion + ") - " + osNameText()

    color: Colors.dsWindow
    font.family: FontSystem.contentFontFamily
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

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
    readonly property string iconHeart: "\uf004"
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
    readonly property string iconDna: "\uf471"
    readonly property color brandBlue: Colors.secondry
    readonly property color brandCyan: Colors.brandBlue
    readonly property color brandViolet: Colors.brandPurple
    readonly property color brandInk: Colors.gcTextStrong
    readonly property string appSiteUrl: "https://genyleap.com"
    readonly property string appRepoUrl: "https://github.com/genyleap/genyconnect"
    readonly property string appShareText: "GenyConnect is a cross-platform open-source network connection app."

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
    property real downRateBytesPerSec: 0
    property real upRateBytesPerSec: 0
    property real lastRxBytesSample: 0
    property real lastTxBytesSample: 0
    property double lastRateSampleMs: 0
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
    property double sessionClockLastMs: 0
    property string settingsSection: "main"
    property string pendingSettingsSection: ""
    property var settingsSectionStack: ["main"]
    property var appRuleSuggestions: []
    property var selectedAppRuleTargets: []
    property string appRuleSearchQuery: ""
    property bool appRuleSuggestionsLoading: false
    property var lanHostCandidates: []
    property bool lanAdvancedControlsExpanded: false
    property bool lanDetailMeaningExpanded: false
    property bool lanDetailTroubleshootingExpanded: false
    property bool lanDetailSecurityExpanded: false
    property bool lanDetailGatewayExpanded: false
    property string routingRuleDraftType: "domain"
    property string routingRuleDraftAction: "proxy"
    property string routingRuleDraftValue: ""
    property string routingRuleDraftProfileId: ""
    property bool routingRuleDraftEnabled: true
    property string routingRuleEditingId: ""
    property string routingRuleValidationText: ""
    property string usageHistoryPeriod: "day"
    property string usagePanelTab: "current"
    property int usageRefreshNonce: 0
    property string donationFeedbackText: ""
    property var donationConfig: ({})
    property var donationTokens: []
    property string donationSelectedToken: "GENY"
    property string donationSelectedAmountPreset: ""
    property string donationCustomAmount: ""
    property string donationValidationError: ""
    property string donationLastDeepLink: ""
    property var donationPendingPayload: ({})
    property var donationWalletTargets: []
    property bool donationSuggestionShown: false
    property var donationTokenPricesUsd: ({ "GENY": 0.000834818748987003, "USDC": 1.0 })
    property bool donationPriceLoading: false
    property string donationPriceError: ""
    property int donationPriceRequestNonce: 0
    property string settingsFeedbackText: ""
    property string lanStatusFeedbackText: ""
    property string lanSetupFeedbackText: ""
    property var profileQrMatrixData: ({ "ok": false, "size": 0, "rows": [], "text": "", "error": "" })
    property string profileQrPayloadText: ""
    property string profileQrCopyJsonText: ""
    property string profileQrProfileName: ""
    property real settingsPageShift: 0
    property real settingsPageOpacity: 1
    property string compactProfileFilter: "All"
    property int editProfileRow: -1
    property string editProfileName: ""
    property string editProfileGroup: ""
    property string editProfileConfigLink: ""
    property string editProfileOriginalConfigLink: ""
    property string editProfileError: ""
    property bool editProfileVlessSupported: false
    property var editProfileVlessForm: ({})
    property real speedGaugeDisplayMbps: 0.0
    property string speedGaugeRangePreset: "Auto"
    property var downRateHistoryMbps: []
    property var upRateHistoryMbps: []
    property int rateHistoryMaxPoints: 24
    property int homeProfilePingMs: -1
    readonly property int powerUiStatsIntervalMs: Math.max(500, Number((vpnController.powerPolicy || {}).uiStatsRefreshIntervalMs || 1000))
    readonly property int powerGaugeRefreshIntervalMs: Math.max(16, Number((vpnController.powerPolicy || {}).uiGaugeRefreshIntervalMs || 40))
    readonly property bool powerVisualAnimationsEnabled: (vpnController.visualPowerPolicy || {}).animationsEnabled !== false
    readonly property bool powerDecorativeAnimationsEnabled: (vpnController.visualPowerPolicy || {}).decorativeAnimationsEnabled !== false
    readonly property bool powerParticlesEnabled: (vpnController.visualPowerPolicy || {}).particlesEnabled === true
    readonly property bool powerEffectsEnabled: (vpnController.visualPowerPolicy || {}).effectsEnabled !== false
    readonly property bool powerPauseBackgroundUi: (vpnController.visualPowerPolicy || {}).pauseInBackground === true && !root.active
    readonly property string lanUiMode: root.lanModeKey()
    readonly property color lanUiAccent: root.lanModeAccent(root.lanUiMode)
    readonly property string lanUiEndpoint: root.lanProxyEndpoint(vpnController.httpPort)
    readonly property string lanUiModeLabelCompact: root.lanModeCompactLabel(root.lanUiMode)

    // Bridge context properties explicitly to avoid scope ambiguity when passing to extracted sections.
    readonly property var vpnControllerCtx: vpnController
    readonly property var updaterCtx: updater


    Sections.MainSurface {
        id: mainSurface
        anchors.fill: parent
        root: root
        vpnController: root.vpnControllerCtx
        updater: root.updaterCtx
        dashboardStatsSettings: dashboardStatsSettings
        interfaceThemeSettings: interfaceThemeSettings
        interfacePrivacySettings: interfacePrivacySettings
    }

    readonly property var updateNoticePopup: mainSurface.updateNoticePopup
    readonly property var donationSuggestPopup: mainSurface.donationSuggestPopup
    readonly property var tunConflictPopup: mainSurface.tunConflictPopup
    readonly property var profilePopup: mainSurface.profilePopup
    readonly property var clearProfilesPopup: mainSurface.clearProfilesPopup
    readonly property var editProfilePopup: mainSurface.editProfilePopup
    readonly property var settingsPopup: mainSurface.settingsPopup
    readonly property var profileQrPopup: mainSurface.profileQrPopup
    readonly property var walletPickerPopup: mainSurface.walletPickerPopup
    readonly property var aboutPopup: mainSurface.aboutPopup
    readonly property var dataUsagePopup: mainSurface.dataUsagePopup
    readonly property var logsPopup: mainSurface.logsPopup
    readonly property var speedTestPopup: mainSurface.speedTestPopup
    readonly property var importPopup: mainSurface.importPopup
    readonly property var settingsFlick: mainSurface.settingsFlickRef

    readonly property var speedUnitOptions: ["Auto", "bps", "Kbps", "Mbps", "Gbps", "B/s", "KB/s", "MB/s", "GB/s"]
    readonly property var trafficUnitOptions: ["Auto", "B", "KB", "MB", "GB", "TB"]
    readonly property var themeModeOptions: ["System", "Light", "Dark"]
    readonly property var ipPrivacyOptions: ["Show", "Partial Mask", "Hidden"]
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

    Settings {
        id: interfacePrivacySettings
        category: "Interface/Privacy"
        property string ipDisplayMode: "Show"
    }

    onClosing: function(closeEvent) {
        if (mobilePlatform) {
            const handled = root.handleMobileBackPressed()
            closeEvent.accepted = !handled
            return
        }
        if (allowCloseExit) {
            return
        }
        closeEvent.accepted = false
        root.hide()
    }

    onVisibleChanged: {
        if (visible)
            androidSystemBarsSyncTimer.restart()
    }

    onActiveChanged: {
        if (active)
            syncAndroidSystemBars()
    }

    onPowerUiStatsIntervalMsChanged: {
        root.rateSampleInitialized = false
        root.lastRateSampleMs = 0
    }

    onSettingsSectionChanged: {
        if (!settingsPopup || !settingsPopup.opened)
            return
        settingsPageShift = 0
        settingsPageOpacity = 0.0
        settingsSectionTransition.restart()
        if (settingsFlick)
            settingsFlick.contentY = 0
    }

    function handleMobileBackPressed() {
        if (!mobilePlatform)
            return false

        if (settingsPopup && settingsPopup.opened)
            return root.stepBackSettingsSection()

        const popupStack = [
            walletPickerPopup,
            speedTestPopup,
            logsPopup,
            dataUsagePopup,
            aboutPopup,
            importPopup,
            editProfilePopup,
            clearProfilesPopup,
            profilePopup,
            tunConflictPopup,
            donationSuggestPopup,
            updateNoticePopup
        ]

        for (let i = 0; i < popupStack.length; ++i) {
            const popup = popupStack[i]
            if (popup && popup.opened) {
                popup.close()
                return true
            }
        }

        if (root.closeTopOverlaySurface())
            return true

        vpnController.minimizeToBackground()
        return true
    }

    function stepBackSettingsSection() {
        if (!settingsPopup || !settingsPopup.opened)
            return false

        if (settingsSection === "main") {
            settingsPopup.close()
            return true
        }

        const stack = (settingsSectionStack || []).slice(0)
        const previous = stack.length > 0 ? stack.pop() : "main"
        settingsSectionStack = stack.length > 0 ? stack : ["main"]
        settingsSection = previous || "main"

        if (settingsSection === "routing") {
            root.refreshAppRuleSuggestions()
        } else if (settingsSection === "lan") {
            root.refreshLanHostCandidates()
        }
        return true
    }

    function closeTopOverlaySurface() {
        const overlay = Overlay.overlay
        if (!overlay || !overlay.children)
            return false

        const children = overlay.children
        for (let i = children.length - 1; i >= 0; --i) {
            const item = children[i]
            if (!item)
                continue

            const canClose = typeof item.close === "function"
            if (!canClose)
                continue

            const isOpen = (item.opened === true) || (item.visible === true)
            if (!isOpen)
                continue

            item.close()
            return true
        }
        return false
    }

    function themeColor(lightColor, darkColor) {
        return Colors.lightMode ? lightColor : darkColor
    }

    function powerModeGlyph(mode) {
        if (mode === "Save")
            return "\uf06c"
        if (mode === "High Performance")
            return "\uf06d"
        return "\uf0e7"
    }

    function powerModeAccent(mode) {
        if (mode === "Save")
            return Colors.dsSuccess
        if (mode === "High Performance")
            return Colors.dsWarning
        return Colors.dsPrimarySolid
    }

    function powerModeSummary(mode) {
        if (mode === "Save")
            return "Lower wakeups and calmer visuals for battery-sensitive sessions."
        if (mode === "High Performance")
            return "Faster refresh and richer feedback for latency-focused use."
        return "Balanced defaults close to the current GenyConnect behavior."
    }

    function homeConnectGlyph() {
        return powerModeGlyph(vpnController.powerMode || "Normal")
    }

    function powerMsText(value) {
        const ms = Math.max(0, Math.round(Number(value) || 0))
        if (ms >= 1000)
            return (ms / 1000.0).toFixed(ms % 1000 === 0 ? 0 : 1) + " s"
        return ms + " ms"
    }

    function powerDiagnosticValue(key, fallback) {
        const diagnostics = vpnController.powerDiagnostics || {}
        const value = diagnostics[key]
        if (value === undefined || value === null || value === "")
            return fallback
        return value
    }

    function powerBatteryText() {
        const status = String(powerDiagnosticValue("batteryStatus", ""))
        if (status.length > 0 && status !== "Unknown")
            return status
        const level = Number(powerDiagnosticValue("batteryLevel", -1))
        return level >= 0 ? (Math.round(level) + "%") : "Unknown"
    }

    function powerNetworkText() {
        const status = String(powerDiagnosticValue("networkStatus", ""))
        if (status.length > 0 && status !== "Unknown")
            return status
        const network = String(powerDiagnosticValue("networkType", "unknown"))
        if (network.length === 0 || network === "unknown")
            return "Unknown"
        return network.charAt(0).toUpperCase() + network.slice(1)
    }

    function powerAdaptiveInputsAvailable() {
        const diagnostics = vpnController.powerDiagnostics || {}
        const level = Number(diagnostics.batteryLevel)
        const network = String(diagnostics.networkType || "unknown")
        return level >= 0
                || network !== "unknown"
                || String(diagnostics.batteryStatus || "").length > 0
                || String(diagnostics.networkStatus || "").length > 0
                || diagnostics.batterySaver === true
                || diagnostics.charging === true
                || diagnostics.screenOn === false
                || diagnostics.backgrounded === true
    }

    function shortAddress(value, prefixCount, suffixCount) {
        const text = (value || "").trim()
        const head = Math.max(2, prefixCount || 6)
        const tail = Math.max(2, suffixCount || 4)
        if (text.length <= (head + tail + 1))
            return text
        return text.slice(0, head) + "..." + text.slice(text.length - tail)
    }

    function reloadDonationData() {
        donationConfig = vpnController.donationConfig()
        donationTokens = vpnController.donationTokenOptions()
        if (!donationTokenBySymbol(donationSelectedToken) && donationTokens.length > 0)
            donationSelectedToken = donationTokens[0].symbol
        if (donationSelectedAmountPreset === "Custom" && donationCustomAmount.trim().length === 0)
            donationCustomAmount = ""
        if (donationSelectedAmountPreset !== "Custom" && donationSelectedAmountPreset.trim().length === 0)
            donationSelectedAmountPreset = donationDefaultPresetForToken(donationSelectedToken)
        refreshDonationTokenPrice(donationSelectedToken)
    }

    function donationTokenBySymbol(symbol) {
        const key = (symbol || "").trim().toUpperCase()
        for (let i = 0; i < donationTokens.length; ++i) {
            const token = donationTokens[i]
            if ((token.symbol || "").toUpperCase() === key)
                return token
        }
        return null
    }

    function donationDefaultPresetForToken(symbol) {
        const token = donationTokenBySymbol(symbol)
        if (!token || !token.presetAmounts || token.presetAmounts.length === 0)
            return ""
        for (let i = 0; i < token.presetAmounts.length; ++i) {
            const preset = token.presetAmounts[i]
            if (preset !== "Custom")
                return preset
        }
        return token.presetAmounts[0]
    }

    function donationEffectiveAmountText() {
        if (donationSelectedAmountPreset === "Custom")
            return donationCustomAmount.trim()
        return (donationSelectedAmountPreset || "").trim()
    }

    function selectDonationToken(symbol) {
        donationSelectedToken = (symbol || "").trim().toUpperCase()
        donationSelectedAmountPreset = donationDefaultPresetForToken(donationSelectedToken)
        donationCustomAmount = ""
        donationValidationError = ""
        refreshDonationTokenPrice(donationSelectedToken)
    }

    function refreshDonationTokenPrice(symbol) {
        const key = (symbol || "").trim().toUpperCase()
        const token = donationTokenBySymbol(key)
        if (!token)
            return
        const requestNonce = ++donationPriceRequestNonce
        if (key === "USDC") {
            donationPriceTimeoutTimer.stop()
            setDonationTokenPrice(key, 1.0)
            donationPriceLoading = false
            donationPriceError = ""
            return
        }

        const priceUrl = (token.priceUrl || "").trim()
        const contractKey = (token.contract || "").trim().toLowerCase()
        if (priceUrl.length === 0 || contractKey.length === 0) {
            donationPriceTimeoutTimer.stop()
            donationPriceLoading = false
            return
        }

        donationPriceLoading = true
        donationPriceError = ""
        donationPriceTimeoutTimer.restart()
        const request = new XMLHttpRequest()
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE)
                return
            if (requestNonce !== donationPriceRequestNonce)
                return
            donationPriceTimeoutTimer.stop()
            donationPriceLoading = false
            if (request.status < 200 || request.status >= 300) {
                donationPriceError = "Price unavailable"
                return
            }
            try {
                const response = JSON.parse(request.responseText || "{}")
                const prices = (((response || {}).data || {}).attributes || {}).token_prices || {}
                const rawPrice = prices[contractKey]
                const parsedPrice = Number(rawPrice)
                if (!isFinite(parsedPrice) || parsedPrice <= 0) {
                    donationPriceError = "Price unavailable"
                    return
                }
                setDonationTokenPrice(key, parsedPrice)
                donationPriceError = ""
            } catch (error) {
                donationPriceError = "Price unavailable"
            }
        }
        request.open("GET", priceUrl)
        request.send()
    }

    function setDonationTokenPrice(symbol, price) {
        const nextPrices = {}
        const currentPrices = donationTokenPricesUsd || {}
        for (const key in currentPrices)
            nextPrices[key] = currentPrices[key]
        nextPrices[(symbol || "").trim().toUpperCase()] = price
        donationTokenPricesUsd = nextPrices
    }

    function donationEstimatedUsd() {
        const amount = Number(donationEffectiveAmountText())
        if (!isFinite(amount) || amount <= 0)
            return -1
        const key = (donationSelectedToken || "").trim().toUpperCase()
        const price = Number((donationTokenPricesUsd || {})[key])
        if (!isFinite(price) || price <= 0)
            return -1
        return amount * price
    }

    function donationEstimatedUsdText() {
        const value = donationEstimatedUsd()
        if (value < 0)
            return donationPriceLoading ? "Loading" : "≈ $ --"
        if (value >= 1000)
            return "≈ $" + value.toLocaleString(Qt.locale(), "f", 2)
        if (value >= 1)
            return "≈ $" + value.toFixed(2)
        return "≈ $" + value.toFixed(4)
    }

    function donationTargetVisible(target) {
        if (!target)
            return false
        if (Qt.platform.os !== "android")
            return target.id === "system"
        return target.visible !== false
    }

    function openDonationViaTarget(target) {
        if (!target)
            return
        const payload = donationPendingPayload || {}
        const mode = (target.mode || "").trim()
        const packageName = (target.packageName || "").trim()
        let opened = false

        if (mode === "chooser") {
            opened = vpnController.openUrlWithChooser(payload.deepLink || "", "Choose wallet app")
        } else if (mode === "swap") {
            if (packageName.length > 0 && Qt.platform.os === "android")
                opened = vpnController.openUrlInAndroidPackage(payload.uniswapUrl || "", packageName)
            if (!opened)
                opened = Qt.openUrlExternally(payload.uniswapUrl || "")
        } else {
            if (packageName.length > 0 && Qt.platform.os === "android")
                opened = vpnController.openUrlInAndroidPackage(payload.deepLink || "", packageName)
            if (!opened)
                opened = Qt.openUrlExternally(payload.deepLink || "")
        }

        walletPickerPopup.close()
        if (opened) {
            donationFeedbackText = mode === "swap"
                ? "Opened Uniswap. Complete swap/buy then send donation."
                : "Opened wallet. Complete donation transfer there."
        } else {
            donationFeedbackText = "Could not open selected wallet app. Copied receiver wallet and opened Uniswap fallback."
            vpnController.copyTextToClipboard(payload.receiverWallet || "")
            Qt.openUrlExternally(payload.uniswapUrl || "")
        }
        donationFeedbackTimer.restart()
    }

    function triggerDonation(preferWalletChooser) {
        donationValidationError = ""
        donationFeedbackText = ""

        const token = donationTokenBySymbol(donationSelectedToken)
        if (!token) {
            donationValidationError = "Select a donation token first."
            return
        }

        const payload = vpnController.buildDonationPayload(
            donationSelectedToken,
            donationEffectiveAmountText())
        if (!payload || payload.ok !== true) {
            donationValidationError = payload && payload.error ? payload.error : "Unable to prepare donation request."
            return
        }

        donationLastDeepLink = payload.deepLink || ""
        donationPendingPayload = payload
        if (Qt.platform.os === "android" && preferWalletChooser === true) {
            donationWalletTargets = vpnController.donationWalletTargets(
                payload.deepLink || "",
                payload.uniswapUrl || "")
            walletPickerPopup.open()
            return
        }

        let opened = false
        opened = Qt.openUrlExternally(donationLastDeepLink)
        if (opened) {
            donationFeedbackText = "Opened wallet deep link. Complete the transfer in your wallet."
        } else {
            donationFeedbackText = "Wallet deep link could not be opened. Copied receiver wallet and opened Uniswap fallback."
            vpnController.copyTextToClipboard(payload.receiverWallet || "")
            Qt.openUrlExternally(payload.uniswapUrl || "")
        }
        donationFeedbackTimer.restart()
    }

    function syncAndroidSystemBars() {
        if (Qt.platform.os !== "android")
            return
        vpnController.syncSystemBars(!Colors.lightMode)
    }

    function themeColorToken(lightToken, darkToken) {
        const key = lightToken + "|" + darkToken
        switch (key) {
        case "mainHex_ffffff|mainHex_090b14": return Colors.dsWindow
        case "mainHex_f7f9fc|mainHex_151c32": return Colors.dsSurfaceSoft
        case "mainHex_f7f9fd|mainHex_151c32": return Colors.dsSurfaceSoft
        case "mainHex_ffffff|mainHex_22324a": return Colors.dsSurface
        case "mainHex_f3f6fb|mainHex_20314b": return Colors.dsSurfaceSoft
        case "mainHex_eaf2ff|mainHex_223753": return Colors.dsPrimaryTint

        case "mainHex_e0e6f0|mainHex_30435d": return Colors.dsBorder
        case "mainHex_d8dde8|mainHex_151c32": return Colors.dsBorderSoft
        case "mainHex_d6dde8|mainHex_151c32": return Colors.dsBorderSoft
        case "mainHex_d9e0ed|mainHex_151c32": return Colors.dsBorderSoft
        case "mainHex_dfe7f2|mainHex_151c32": return Colors.dsBorderSoft
        case "mainHex_d5deec|mainHex_151c32": return Colors.dsBorderSoft

        case "mainHex_2a3240|mainHex_d7e4f6": return Colors.dsText
        case "mainHex_334155|mainHex_d7e4f6": return Colors.dsText
        case "mainHex_1f2530|mainHex_d8e1f0": return Colors.dsText
        case "mainHex_667487|mainHex_9bb0cb": return Colors.dsTextMuted
        case "mainHex_667081|mainHex_9ab0ca": return Colors.dsTextMuted
        case "mainHex_7c8697|mainHex_9bb0cb": return Colors.dsTextSubtle
        case "mainHex_8f97a6|mainHex_9eb2cb": return Colors.dsTextSubtle
        case "mainHex_647891|mainHex_9fb4cd": return Colors.dsTextMuted

        case "mainHex_2f6ff1|mainHex_3a7bff": return Colors.dsPrimarySolid
        case "mainHex_2a3240|mainHex_9ec1ff": return Colors.dsPrimarySolid
        case "mainHex_cb4f4f|mainHex_ff8e8e": return Colors.dsDanger
        }

        const light = Colors[lightToken]
        const dark = Colors[darkToken]
        if (light !== undefined && dark !== undefined)
            return Colors.lightMode ? light : dark
        if (dark !== undefined)
            return dark
        if (light !== undefined)
            return light
        return Colors.dsText
    }

    function stateText() {
        if (vpnController.connectionState === ConnectionState.Connecting)
            return "Connecting"
        if (vpnController.connectionState === ConnectionState.Connected) {
            if (vpnController.isMobile && !vpnController.runtimeTunActive)
                return "Proxy Connected"
            return "Connected"
        }
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

    function scrollFlickByWheel(flick, event) {
        if (!flick || !event)
            return
        const pixel = (event.pixelDelta && event.pixelDelta.y !== undefined) ? event.pixelDelta.y : 0
        const angle = (event.angleDelta && event.angleDelta.y !== undefined) ? event.angleDelta.y : 0
        const delta = pixel !== 0 ? pixel : (angle * 0.35)
        if (delta === 0)
            return
        const maxY = Math.max(0, flick.contentHeight - flick.height)
        if (maxY <= 0)
            return
        const next = Math.max(0, Math.min(maxY, flick.contentY - delta))
        if (Math.abs(next - flick.contentY) < 0.5)
            return
        flick.contentY = next
        event.accepted = true
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

    function appSuggestionRuleKey(itemOrName) {
        if (typeof itemOrName === "string")
            return (itemOrName || "").trim()
        const item = itemOrName || {}
        const target = (item.ruleTarget || "").trim()
        if (target.length > 0)
            return target
        return (item.process || "").trim()
    }

    function isAppSuggestionSelected(itemOrName) {
        const key = appSuggestionRuleKey(itemOrName).toLowerCase()
        if (key.length === 0)
            return false
        for (let i = 0; i < selectedAppRuleTargets.length; ++i) {
            if ((selectedAppRuleTargets[i] || "").toLowerCase() === key)
                return true
        }
        return false
    }

    function toggleAppSuggestionSelection(itemOrName) {
        const raw = appSuggestionRuleKey(itemOrName)
        const key = raw.toLowerCase()
        if (key.length === 0)
            return
        const current = selectedAppRuleTargets.slice(0)
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
        selectedAppRuleTargets = next
    }

    function clearAppSuggestionSelection() {
        selectedAppRuleTargets = []
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
            const target = (item.ruleTarget || "").toLowerCase()
            const bundleId = (item.bundleId || "").toLowerCase()
            if (process.indexOf(rawQuery) >= 0
                    || source.indexOf(rawQuery) >= 0
                    || target.indexOf(rawQuery) >= 0
                    || bundleId.indexOf(rawQuery) >= 0)
                filtered.push(item)
        }
        return filtered
    }

    function selectVisibleAppSuggestionItems() {
        const items = visibleAppRuleSuggestions()
        const next = []
        const seen = {}
        for (let i = 0; i < items.length; ++i) {
            const keyRaw = appSuggestionRuleKey(items[i])
            const key = keyRaw.toLowerCase()
            if (key.length === 0 || seen[key] === true)
                continue
            seen[key] = true
            next.push(keyRaw)
        }
        selectedAppRuleTargets = next
    }

    function appSuggestionInitial(itemOrName) {
        const cleaned = appSuggestionRuleKey(itemOrName)
        if (cleaned.length === 0)
            return "•"
        const base = cleaned.split(/[\\/]/).pop()
        const first = (base || cleaned).charAt(0)
        if (first >= "0" && first <= "9")
            return "#"
        return first.toUpperCase()
    }

    function appendSelectedAppRules(target) {
        const list = selectedAppRuleTargets.slice(0)
        for (let i = 0; i < list.length; ++i)
            vpnController.appendAppRule(target, list[i] || "")
        clearAppSuggestionSelection()
    }

    function refreshAppRuleSuggestions() {
        appRuleSearchQuery = ""
        clearAppSuggestionSelection()
        if (!vpnController.supportsPerAppRouting) {
            appRuleSuggestionsLoading = false
            appRuleSuggestions = []
            return
        }
        appRuleSuggestionsLoading = true
        vpnController.requestAvailableAppRuleItems()
    }

    function refreshLanHostCandidates() {
        lanHostCandidates = vpnController.availableLanHostAddresses() || []
    }

    function lanModeKey() {
        const raw = (vpnController.lanSharingMode || "console").toLowerCase()
        if (raw === "tv" || raw === "mobile" || raw === "laptop" || raw === "advanced")
            return raw
        return "console"
    }

    function lanModeLabel(mode) {
        const key = (mode || "").toLowerCase()
        if (key === "tv")
            return "Smart TV Mode"
        if (key === "mobile")
            return "Phone / Tablet Mode"
        if (key === "laptop")
            return "Laptop / Browser Mode"
        if (key === "advanced")
            return "Advanced Mode"
        return "Game Console Mode"
    }

    function lanModeCompactLabel(mode) {
        const key = (mode || "").toLowerCase()
        if (key === "tv")
            return "Smart TV"
        if (key === "mobile")
            return "Phone / Tablet"
        if (key === "laptop")
            return "Laptop / Browser"
        if (key === "advanced")
            return "Advanced"
        return "Game Console"
    }

    function lanModeGlyph(mode) {
        const key = (mode || "").toLowerCase()
        if (key === "tv")
            return "\uf26c"
        if (key === "mobile")
            return "\uf3cd"
        if (key === "laptop")
            return "\uf109"
        if (key === "advanced")
            return "\uf085"
        return "\uf11b"
    }

    function lanModeAccent(mode) {
        const key = (mode || "").toLowerCase()
        if (key === "tv")
            return Colors.dsSuccess
        if (key === "mobile")
            return Colors.dsWarning
        if (key === "laptop")
            return Colors.dsPrimarySolid
        if (key === "advanced")
            return Colors.dsDanger
        return Colors.dsPrimarySolid
    }

    function lanModeCardSummary(mode) {
        const key = (mode || "").toLowerCase()
        if (key === "tv")
            return "Best for proxy-ready streaming and TV apps."
        if (key === "mobile")
            return "Share with another phone or tablet nearby."
        if (key === "laptop")
            return "Great for browser and proxy-aware apps."
        if (key === "advanced")
            return "Manual controls and experimental gateway switch."
        return "Best for login, updates, and downloads."
    }

    function lanModeRecommendedMethod(mode) {
        const key = (mode || "").toLowerCase()
        if (key === "mobile")
            return "HTTP + SOCKS5"
        if (key === "laptop")
            return "HTTP + SOCKS5 + Mixed"
        if (key === "advanced")
            return "Manual"
        return "HTTP Proxy"
    }

    function lanModeDescription(mode) {
        const key = (mode || "").toLowerCase()
        if (key === "tv")
            return "For TV apps that support proxy settings."
        if (key === "mobile")
            return "For another Android or iOS device."
        if (key === "laptop")
            return "For desktop browsers and proxy-aware clients."
        if (key === "advanced")
            return "Manual bind, exposure, and gateway controls."
        return "For PlayStation, Xbox, and Nintendo Switch."
    }

    function lanModeWarning(mode) {
        const key = (mode || "").toLowerCase()
        if (key === "tv")
            return "Some apps may ignore proxy."
        if (key === "mobile")
            return "Some apps may bypass manual proxy."
        if (key === "laptop")
            return "Affects browser and proxy-aware apps."
        if (key === "advanced")
            return "0.0.0.0 exposes proxy to the whole LAN."
        return "Full game traffic may require Gateway mode."
    }

    function lanPrimaryProtocol(mode) {
        const key = (mode || "").toLowerCase()
        if (key === "mobile")
            return "SOCKS5"
        if (key === "laptop")
            return "Mixed"
        if (key === "advanced")
            return "Manual"
        return "HTTP"
    }

    function lanProtocolDisplay(mode) {
        const protocol = lanPrimaryProtocol(mode)
        if (protocol === "HTTP")
            return "HTTP Proxy"
        if (protocol === "Mixed")
            return "Mixed Proxy"
        return protocol
    }

    function lanGatewayPlatformSupported() {
        // Full gateway/hotspot remains experimental and runtime-dependent.
        // Keep it behind Advanced options and avoid presenting it as the default path.
        return vpnController.lanSharingSupported
               && Qt.platform.os !== "ios"
               && Qt.platform.os !== "android"
    }

    function lanProxyHost() {
        const host = (vpnController.effectiveLanSharingHost() || "").trim()
        if (host.length > 0)
            return host
        return "127.0.0.1"
    }

    function lanProxyEndpoint(port) {
        return lanProxyHost() + ":" + String(port || 0)
    }

    function refreshProfileQrMatrix() {
        const payload = String(root.profileQrPayloadText || "").trim()
        if (payload.length === 0) {
            root.profileQrMatrixData = ({ "ok": false, "size": 0, "rows": [], "text": "", "error": "No profile config available." })
            return false
        }
        root.profileQrMatrixData = vpnController.qrCodeMatrix(payload) || ({ "ok": false, "size": 0, "rows": [], "text": payload, "error": "QR generation failed." })
        return (root.profileQrMatrixData || {}).ok === true
    }

    function compactProfileJsonForQr(value, keyName) {
        if (value === null || value === undefined)
            return undefined

        const currentKey = String(keyName || "")
        const valueType = typeof value
        if (valueType === "string") {
            const text = value.trim()
            return text.length > 0 ? text : undefined
        }
        if (valueType === "number") {
            if (!isFinite(value))
                return undefined
            if ((currentKey === "wgMtu" || currentKey === "wgPersistentKeepalive") && Number(value) <= 0)
                return undefined
            return value
        }
        if (valueType === "boolean") {
            if (currentKey === "allowInsecure" && value === false)
                return undefined
            return value
        }
        if (Array.isArray(value)) {
            const outArray = []
            for (let i = 0; i < value.length; ++i) {
                const compactItem = compactProfileJsonForQr(value[i], currentKey)
                if (compactItem !== undefined)
                    outArray.push(compactItem)
            }
            return outArray.length > 0 ? outArray : undefined
        }
        if (valueType === "object") {
            const droppedKeys = {
                "id": true,
                "sourceId": true,
                "sourceName": true,
                "originalLink": true,
                "extra": true
            }
            const outObject = {}
            for (const childKey in value) {
                if (droppedKeys[childKey] === true)
                    continue
                const compactChild = compactProfileJsonForQr(value[childKey], childKey)
                if (compactChild !== undefined)
                    outObject[childKey] = compactChild
            }
            return Object.keys(outObject).length > 0 ? outObject : undefined
        }
        return undefined
    }

    function buildProfileQrPayload(rawPayload) {
        const exportPayload = String(rawPayload || "").trim()
        if (exportPayload.length === 0)
            return ({ "ok": false, "error": "Profile export failed." })

        function looksLikeShareLink(text) {
            return /^[A-Za-z][A-Za-z0-9+.-]*:\/\//.test(String(text || "").trim())
        }

        function normalizeShareLinkCandidate(text) {
            const raw = String(text || "").trim()
            if (raw.length === 0)
                return ""
            if (looksLikeShareLink(raw))
                return raw
            const decoded = safeDecodeUriPart(raw).trim()
            if (looksLikeShareLink(decoded))
                return decoded
            return ""
        }

        function buildVlessLinkFromExportJson(profileObject) {
            if (!profileObject || typeof profileObject !== "object" || Array.isArray(profileObject))
                return ""
            const protocol = String(profileObject.protocol || "").trim().toLowerCase()
            if (protocol !== "vless")
                return ""

            const formPayload = {
                "uuid": String(profileObject.userId || profileObject.id || "").trim(),
                "address": String(profileObject.address || "").trim(),
                "port": String(profileObject.port || "").trim(),
                "network": String(profileObject.network || "tcp").trim().toLowerCase(),
                "security": String(profileObject.security || "none").trim().toLowerCase(),
                "encryption": String(profileObject.encryption || "none").trim().toLowerCase(),
                "flow": String(profileObject.flow || "").trim(),
                "path": String(profileObject.path || "").trim(),
                "headerType": String(profileObject.headerType || "").trim().toLowerCase(),
                "host": String(profileObject.host || profileObject.hostHeader || "").trim(),
                "serviceName": String(profileObject.serviceName || "").trim(),
                "mode": String(profileObject.mode || profileObject.xhttpMode || "").trim().toLowerCase(),
                "extra": String(profileObject.extra || "").trim(),
                "sni": String(profileObject.sni || profileObject.hostHeader || "").trim(),
                "alpn": String(profileObject.alpn || "").trim(),
                "fingerprint": String(profileObject.fingerprint || "").trim(),
                "publicKey": String(profileObject.publicKey || "").trim(),
                "shortId": String(profileObject.shortId || "").trim(),
                "spiderX": String(profileObject.spiderX || "").trim(),
                "allowInsecure": profileObject.allowInsecure === true
            }
            const built = buildVlessLinkFromForm(formPayload, String(profileObject.name || "").trim())
            if (!built || built.ok !== true)
                return ""
            return normalizeShareLinkCandidate(String(built.link || ""))
        }

        let parsed = null
        try {
            parsed = JSON.parse(exportPayload)
        } catch (e) {
            parsed = null
        }
        if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
            const directLink = normalizeShareLinkCandidate(exportPayload)
            return ({
                "ok": true,
                "qrPayload": directLink.length > 0 ? directLink : exportPayload,
                "copyPayload": exportPayload
            })
        }

        const preferredLink = normalizeShareLinkCandidate(parsed.originalLink || parsed.link || parsed.uri)
        if (preferredLink.length > 0) {
            return ({
                "ok": true,
                "qrPayload": preferredLink,
                "copyPayload": JSON.stringify(parsed, null, 4)
            })
        }

        const rebuiltLink = buildVlessLinkFromExportJson(parsed)
        if (rebuiltLink.length > 0) {
            return ({
                "ok": true,
                "qrPayload": rebuiltLink,
                "copyPayload": JSON.stringify(parsed, null, 4)
            })
        }

        const compactObject = compactProfileJsonForQr(parsed, "root")
        if (!compactObject || typeof compactObject !== "object" || Array.isArray(compactObject))
            return ({ "ok": false, "error": "Profile JSON is empty after normalization." })

        return ({
            "ok": true,
            "qrPayload": JSON.stringify(compactObject),
            "copyPayload": JSON.stringify(compactObject, null, 4)
        })
    }

    function openProfileQrPopup(profileName, payload) {
        const normalized = buildProfileQrPayload(payload) || {}
        if (normalized.ok !== true) {
            root.showSettingsFeedback(normalized.error || "Profile export failed.")
            return
        }

        root.profileQrProfileName = String(profileName || "").trim()
        if (root.profileQrProfileName.length === 0)
            root.profileQrProfileName = "Profile"
        root.profileQrPayloadText = String(normalized.qrPayload || "").trim()
        root.profileQrCopyJsonText = String(normalized.copyPayload || root.profileQrPayloadText).trim()
        if (!root.refreshProfileQrMatrix()) {
            root.showSettingsFeedback((root.profileQrMatrixData || {}).error || "Unable to create profile QR code.")
            return
        }
        if (Number((root.profileQrMatrixData || {}).size || 0) > 120)
            root.showSettingsFeedback("QR is dense. If scan is hard, use Copy as JSON.")
        profileQrPopup.open()
    }

    function pad2(value) {
        const n = Number(value) || 0
        return n < 10 ? "0" + n : String(n)
    }

    function qrTimestamp() {
        const now = new Date()
        return String(now.getFullYear())
               + pad2(now.getMonth() + 1)
               + pad2(now.getDate())
               + "-"
               + pad2(now.getHours())
               + pad2(now.getMinutes())
               + pad2(now.getSeconds())
    }

    function localPathFromUrl(value) {
        let text = String(value || "")
        if (text.startsWith("file://"))
            text = text.substring(7)
        try {
            text = decodeURIComponent(text)
        } catch (e) {
        }
        if (Qt.platform.os === "windows" && text.length > 2 && text.charAt(0) === "/" && text.charAt(2) === ":")
            text = text.substring(1)
        return text
    }

    function profileQrExportDirectories() {
        const dirs = []
        function pushLocation(locationKind) {
            const path = localPathFromUrl(StandardPaths.writableLocation(locationKind))
            if (path.length > 0 && dirs.indexOf(path) < 0)
                dirs.push(path)
        }
        pushLocation(StandardPaths.DownloadLocation)
        pushLocation(StandardPaths.PicturesLocation)
        pushLocation(StandardPaths.DocumentsLocation)
        pushLocation(StandardPaths.HomeLocation)
        pushLocation(StandardPaths.TempLocation)
        return dirs
    }

    function saveProfileQrImage() {
        if (!profileQrCaptureCard || !profileQrCaptureCard.visible)
            return

        const dirs = profileQrExportDirectories()
        if (dirs.length === 0) {
            root.showSettingsFeedback("Could not resolve a writable folder for PNG export.")
            return
        }

        const profileSafe = (root.profileQrProfileName || "profile").replace(/[^A-Za-z0-9._-]+/g, "_")
        const fileName = "GenyConnect-Profile-QR-" + profileSafe + "-" + root.qrTimestamp() + ".png"
        function trySave(dirIndex) {
            if (dirIndex >= dirs.length) {
                root.showSettingsFeedback("Could not save profile QR PNG.")
                return
            }
            const filePath = dirs[dirIndex] + "/" + fileName
            profileQrCaptureCard.grabToImage(function(result) {
                let ok = false
                if (result) {
                    try {
                        ok = result.saveToFile(filePath)
                    } catch (e) {
                        ok = false
                    }
                }
                if (!ok && profileQrCanvas && typeof profileQrCanvas.save === "function") {
                    try {
                        ok = profileQrCanvas.save(filePath)
                    } catch (e2) {
                        ok = false
                    }
                }
                if (ok) {
                    vpnController.copyTextToClipboard(filePath)
                    root.showSettingsFeedback("Saved profile QR PNG: " + filePath)
                    return
                }
                trySave(dirIndex + 1)
            }, Qt.size(1280, 1280))
        }
        trySave(0)
    }

    function lanSetMode(mode) {
        vpnController.applyLanSharingPreset(mode || "console")
        refreshLanHostCandidates()
    }

    function usageProfileName(profileId) {
        const id = (profileId || "").trim()
        const options = vpnController.usageProfileOptions || []
        for (let i = 0; i < options.length; ++i) {
            const item = options[i] || {}
            if (((item.id || "").trim()) === id)
                return (item.name || "All Profiles")
        }
        if (id.length === 0)
            return "All Profiles"
        return "Deleted Profile"
    }

    function selectedUsageProfileLabel() {
        return usageProfileName(vpnController.selectedUsageProfileId || "")
    }

    function usageSummaryModel() {
        usageRefreshNonce
        const summary = vpnController.usageSummaryForProfile(vpnController.selectedUsageProfileId || "") || {}
        return [
            { "label": "Day", "value": summary.dayText || "0 B", "icon": "\uf073" },
            { "label": "Month", "value": summary.monthText || "0 B", "icon": "\uf783" },
            { "label": "Total", "value": summary.totalText || "0 B", "icon": root.iconUsage }
        ]
    }

    function usageCurrentStatsModel() {
        usageRefreshNonce
        const summary = vpnController.usageSummaryForProfile(vpnController.selectedUsageProfileId || "") || {}
        return [
            { "label": "Hour", "value": summary.hourText || "0 B" },
            { "label": "Week", "value": summary.weekText || "0 B" },
            { "label": "Download", "value": summary.totalRxText || "0 B" }
        ]
    }

    function currentRoutingRules() {
        return vpnController.routingRuleItems || []
    }

    function routingRuleActionLabel(action) {
        const value = (action || "").toLowerCase()
        if (value === "direct")
            return "Direct"
        if (value === "block")
            return "Block"
        return "VPN"
    }

    function routingRuleTypeLabel(targetType) {
        const value = (targetType || "").toLowerCase()
        if (value === "ip")
            return "IP/CIDR"
        if (value === "app")
            return "App"
        if (value === "process")
            return "Process"
        if (value === "protocol")
            return "Protocol"
        return "Domain"
    }

    function resetRoutingRuleDraft() {
        routingRuleEditingId = ""
        routingRuleDraftType = "domain"
        routingRuleDraftAction = "proxy"
        routingRuleDraftValue = ""
        routingRuleDraftProfileId = ""
        routingRuleDraftEnabled = true
        routingRuleValidationText = ""
    }

    function editRoutingRule(item) {
        const rule = item || {}
        routingRuleEditingId = (rule.id || "").trim()
        routingRuleDraftType = (rule.targetType || "domain").toLowerCase()
        routingRuleDraftAction = (rule.action || "proxy").toLowerCase()
        routingRuleDraftValue = rule.targetValue || ""
        routingRuleDraftProfileId = rule.profileId || ""
        routingRuleDraftEnabled = rule.enabled !== false
        routingRuleValidationText = ""
    }

    function saveRoutingRuleDraft() {
        const validation = vpnController.validateRoutingRule(
            routingRuleDraftType,
            routingRuleDraftValue,
            routingRuleDraftAction
        ) || {}
        if (validation.ok !== true) {
            routingRuleValidationText = validation.error || "Invalid routing rule."
            return false
        }
        const normalizedType = (validation.type || routingRuleDraftType || "").toLowerCase()
        const normalizedValue = (validation.value || routingRuleDraftValue || "").toString().toLowerCase()
        const normalizedProfile = (routingRuleDraftProfileId || "").trim().toLowerCase()
        const draftAction = (validation.action || routingRuleDraftAction || "").toLowerCase()
        const rules = root.currentRoutingRules() || []
        for (let i = 0; i < rules.length; ++i) {
            const item = rules[i] || {}
            const itemId = (item.id || "").trim()
            if (itemId.length > 0 && itemId === root.routingRuleEditingId)
                continue
            if (((item.targetType || "").toLowerCase()) !== normalizedType)
                continue
            if (((item.targetValue || "").toString().toLowerCase()) !== normalizedValue)
                continue
            if ((((item.profileId || "").trim().toLowerCase())) !== normalizedProfile)
                continue
            const itemAction = (item.action || "").toLowerCase()
            if (itemAction !== draftAction) {
                root.routingRuleValidationText = "Warning: a conflicting rule already exists. Rule order will decide the outcome."
                break
            }
        }
        if (routingRuleEditingId.length > 0) {
            const ok = vpnController.updateRoutingRule(
                routingRuleEditingId,
                routingRuleDraftType,
                routingRuleDraftValue,
                routingRuleDraftAction,
                routingRuleDraftProfileId,
                routingRuleDraftEnabled
            )
            if (!ok) {
                routingRuleValidationText = vpnController.lastError || "Failed to update rule."
                return false
            }
            routingRuleValidationText = ""
            resetRoutingRuleDraft()
            return true
        }

        const newId = vpnController.createRoutingRule(
            routingRuleDraftType,
            routingRuleDraftValue,
            routingRuleDraftAction,
            routingRuleDraftProfileId,
            routingRuleDraftEnabled
        )
        if ((newId || "").length === 0) {
            routingRuleValidationText = vpnController.lastError || "Failed to create rule."
            return false
        }
        routingRuleValidationText = ""
        resetRoutingRuleDraft()
        return true
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

    function maskedIpToken(sample) {
        const text = (sample || "").trim()
        if (text.indexOf(":") >= 0)
            return "****:****"
        return "*.*.*.*"
    }

    function partiallyMaskIpToken(token) {
        const text = (token || "").trim()
        if (text.length === 0)
            return text

        if (text.indexOf(":") >= 0) {
            const parts = text.split(":")
            if (parts.length <= 2)
                return text
            return parts.slice(0, 2).join(":") + ":****"
        }

        const octets = text.split(".")
        if (octets.length === 4)
            return octets[0] + "." + octets[1] + ".*.*"
        return text
    }

    function privacyMaskedIpText(value) {
        const text = (value || "").trim()
        const mode = interfacePrivacySettings.ipDisplayMode || "Show"
        if (text.length === 0 || mode === "Show")
            return text
        if (mode === "Hidden")
            return maskedIpToken(text)
        return partiallyMaskIpToken(text)
    }

    function privacyMaskedEndpointText(value) {
        const text = (value || "").trim()
        const mode = interfacePrivacySettings.ipDisplayMode || "Show"
        if (text.length === 0 || mode === "Show")
            return text
        if (mode === "Hidden")
            return "Endpoint hidden"

        let masked = text.replace(/\b(?:\d{1,3}\.){3}\d{1,3}\b/g, function(match) {
            return partiallyMaskIpToken(match)
        })
        masked = masked.replace(/\b[0-9a-fA-F]{1,4}(?::[0-9a-fA-F]{0,4}){2,7}\b/g, function(match) {
            return partiallyMaskIpToken(match)
        })
        return masked
    }

    function infoIpText() {
        const publicAddress = (vpnController.publicIpAddress || "").trim()
        if (publicAddress.length > 0)
            return privacyMaskedIpText(publicAddress)
        if (vpnController.connected) {
            const profileHint = (selectedServerMeta || "").trim()
            if (profileHint.length > 0)
                return privacyMaskedEndpointText(profileHint)
            return "IP unavailable"
        }
        if (vpnController.busy)
            return "Resolving..."
        return "Connect to view"
    }

    function infoIpLabel() {
        if (vpnController.isMobile && vpnController.connected && !vpnController.runtimeTunActive)
            return "Proxy IP"
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

    function currentProfilePingText() {
        const pingMs = root.homeProfilePingMs
        return pingMs >= 0 ? (pingMs + " ms") : "--"
    }

    function currentProfileSignalLevel() {
        const pingMs = root.homeProfilePingMs
        if (pingMs < 0)
            return 0
        if (pingMs < 180)
            return 4
        if (pingMs < 350)
            return 3
        if (pingMs < 650)
            return 2
        return 1
    }

    function currentProfileSignalColor() {
        const pingMs = root.homeProfilePingMs
        if (pingMs < 0)
            return root.themeColorToken("mainHex_9aa4b6", "mainHex_8fa3be")
        if (pingMs < 180)
            return Colors.mainHex_22b26a
        if (pingMs < 350)
            return root.themeColorToken("mainHex_2f74ff", "mainHex_7fb0ff")
        if (pingMs < 650)
            return Colors.mainHex_dfbf22
        return Colors.mainHex_ef4444
    }

    function refreshCurrentProfilePing() {
        const pingMs = vpnController.currentProfilePingMs()
        root.homeProfilePingMs = pingMs
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
        if (settingsSection === "power")
            return "Power Mode"
        if (settingsSection === "routing")
            return "Routing Rules"
        if (settingsSection === "lan")
            return "LAN Sharing"
        if (settingsSection === "dns")
            return "Custom DNS"
        if (settingsSection === "logs")
            return "Logs"
        if (settingsSection === "terms")
            return "Terms, Conditions & License"
        if (settingsSection === "share")
            return "Share App"
        if (settingsSection === "donate")
            return "Support GenyConnect"
        if (settingsSection === "about")
            return "About App"
        return "Settings"
    }

    function openSettingsSection(section) {
        const nextSection = (section || "").trim().length > 0 ? section : "main"
        if (root.contentItem && typeof root.contentItem.forceActiveFocus === "function")
            root.contentItem.forceActiveFocus()
        if (Qt.inputMethod && Qt.inputMethod.visible)
            Qt.inputMethod.hide()
        if (!settingsPopup.opened) {
            root.pendingSettingsSection = nextSection
            settingsPopup.open()
            return
        }

        if (settingsSection === nextSection)
            return

        if (nextSection === "main") {
            settingsSectionStack = ["main"]
        } else {
            const stack = (settingsSectionStack || []).slice(0)
            const current = settingsSection || "main"
            if (stack.length === 0)
                stack.push("main")
            if (stack[stack.length - 1] !== current)
                stack.push(current)
            settingsSectionStack = stack
        }

        settingsSection = nextSection
        if (nextSection === "routing") {
            root.refreshAppRuleSuggestions()
            root.resetRoutingRuleDraft()
        } else if (nextSection === "lan") {
            root.refreshLanHostCandidates()
        }
    }

    function showSettingsFeedback(text) {
        root.settingsFeedbackText = text || ""
        root.lanStatusFeedbackText = ""
        root.lanSetupFeedbackText = ""
        if (root.settingsFeedbackText.length > 0)
            settingsFeedbackTimer.restart()
    }

    function showLanStatusFeedback(text) {
        root.settingsFeedbackText = ""
        root.lanSetupFeedbackText = ""
        root.lanStatusFeedbackText = text || ""
        if (root.lanStatusFeedbackText.length > 0)
            lanFeedbackTimer.restart()
    }

    function showLanSetupFeedback(text) {
        root.settingsFeedbackText = ""
        root.lanStatusFeedbackText = ""
        root.lanSetupFeedbackText = text || ""
        if (root.lanSetupFeedbackText.length > 0)
            lanFeedbackTimer.restart()
    }

    function shareAppNow() {
        const payload = root.appShareText + "\n" + root.appSiteUrl + "\n" + root.appRepoUrl
        const shared = vpnController.shareText("GenyConnect", payload)
        if (!shared)
            vpnController.copyTextToClipboard(payload)
        showSettingsFeedback(shared
                             ? "Share sheet opened."
                             : "Share sheet unavailable. App details copied to clipboard.")
    }

    function currentUsageHistoryModel() {
        usageRefreshNonce
        return vpnController.usageHistoryForProfile(vpnController.selectedUsageProfileId || "", root.usageHistoryPeriod, 30)
    }

    function currentUsageSessionsModel() {
        usageRefreshNonce
        return vpnController.usageSessionsForProfile(vpnController.selectedUsageProfileId || "", 20)
    }

    function safeDecodeUriPart(value) {
        try {
            return decodeURIComponent((value || "").replace(/\+/g, "%20"))
        } catch (e) {
            return value || ""
        }
    }

    function safeEncodeUriPart(value) {
        return encodeURIComponent(value || "")
    }

    function parseVlessForm(linkText) {
        const link = (linkText || "").trim()
        if (!link.toLowerCase().startsWith("vless://"))
            return { "ok": false, "error": "Only VLESS profiles are editable with form mode." }

        const body = link.slice(8)
        const hashIndex = body.indexOf("#")
        const mainPart = hashIndex >= 0 ? body.slice(0, hashIndex) : body
        const fragment = hashIndex >= 0 ? body.slice(hashIndex + 1) : ""
        const queryIndex = mainPart.indexOf("?")
        const authorityPart = queryIndex >= 0 ? mainPart.slice(0, queryIndex) : mainPart
        const queryPart = queryIndex >= 0 ? mainPart.slice(queryIndex + 1) : ""

        const atIndex = authorityPart.lastIndexOf("@")
        if (atIndex <= 0 || atIndex >= authorityPart.length - 1)
            return { "ok": false, "error": "Invalid VLESS link format." }

        const uuid = authorityPart.slice(0, atIndex).trim()
        const hostPort = authorityPart.slice(atIndex + 1).trim()
        if (uuid.length === 0 || hostPort.length === 0)
            return { "ok": false, "error": "Invalid VLESS endpoint fields." }

        let address = hostPort
        let portText = "443"
        if (hostPort.startsWith("[")) {
            const closing = hostPort.indexOf("]")
            if (closing <= 1)
                return { "ok": false, "error": "Invalid IPv6 host format." }
            address = hostPort.slice(0, closing + 1)
            const remainder = hostPort.slice(closing + 1)
            if (remainder.startsWith(":"))
                portText = remainder.slice(1).trim()
        } else {
            const lastColon = hostPort.lastIndexOf(":")
            if (lastColon > 0 && lastColon < hostPort.length - 1) {
                address = hostPort.slice(0, lastColon).trim()
                portText = hostPort.slice(lastColon + 1).trim()
            } else {
                address = hostPort.trim()
            }
        }

        const knownKeys = {
            "type": true, "security": true, "encryption": true, "flow": true,
            "path": true, "host": true, "sni": true, "servername": true,
            "headertype": true, "servicename": true, "mode": true, "extra": true,
            "fp": true, "alpn": true, "pbk": true, "sid": true, "spx": true,
            "allowinsecure": true, "insecure": true
        }

        const params = {}
        const unknownPairs = []
        if (queryPart.length > 0) {
            const pairs = queryPart.split("&")
            for (let i = 0; i < pairs.length; i += 1) {
                const pair = pairs[i]
                if (!pair)
                    continue
                const eqIndex = pair.indexOf("=")
                const rawKey = eqIndex >= 0 ? pair.slice(0, eqIndex) : pair
                const rawValue = eqIndex >= 0 ? pair.slice(eqIndex + 1) : ""
                const key = safeDecodeUriPart(rawKey).trim()
                const value = safeDecodeUriPart(rawValue)
                const lowered = key.toLowerCase()
                if (knownKeys[lowered]) {
                    params[lowered] = value
                } else {
                    unknownPairs.push({ "key": rawKey, "value": rawValue })
                }
            }
        }

        let allowInsecureValue = params["allowinsecure"] || params["insecure"] || ""
        allowInsecureValue = allowInsecureValue.toString().trim().toLowerCase()
        const allowInsecure = (allowInsecureValue === "1" || allowInsecureValue === "true")

        return {
            "ok": true,
            "uuid": uuid,
            "address": address,
            "port": portText.length > 0 ? portText : "443",
            "network": (params["type"] || "tcp").toLowerCase(),
            "security": (params["security"] || "none").toLowerCase(),
            "encryption": (params["encryption"] || "none").toLowerCase(),
            "flow": params["flow"] || "",
            "path": params["path"] || "",
            "host": params["host"] || "",
            "sni": ((params["sni"] || params["servername"] || params["host"] || "")),
            "headerType": (params["headertype"] || "").toLowerCase(),
            "serviceName": params["servicename"] || "",
            "mode": (params["mode"] || "").toLowerCase(),
            "extra": params["extra"] || "",
            "fingerprint": params["fp"] || "",
            "alpn": params["alpn"] || "",
            "publicKey": params["pbk"] || "",
            "shortId": params["sid"] || "",
            "spiderX": params["spx"] || "",
            "allowInsecure": allowInsecure,
            "unknownPairs": unknownPairs,
            "fragment": safeDecodeUriPart(fragment)
        }
    }

    function buildVlessLinkFromForm(form, profileName) {
        const data = form || {}
        const uuid = (data.uuid || "").trim()
        const address = (data.address || "").trim()
        const portText = (data.port || "").toString().trim()
        const portValue = Number(portText)
        if (uuid.length === 0)
            return { "ok": false, "error": "UUID is missing from this profile." }
        if (address.length === 0)
            return { "ok": false, "error": "Address is required." }
        if (!Number.isFinite(portValue) || portValue < 1 || portValue > 65535 || Math.floor(portValue) !== portValue)
            return { "ok": false, "error": "Port must be a number between 1 and 65535." }

        const params = []
        function appendParam(key, value) {
            if ((value || "").toString().trim().length === 0)
                return
            params.push(safeEncodeUriPart(key) + "=" + safeEncodeUriPart((value || "").toString().trim()))
        }

        appendParam("encryption", (data.encryption || "none").toLowerCase())
        appendParam("type", (data.network || "tcp").toLowerCase())
        appendParam("security", (data.security || "none").toLowerCase())
        appendParam("flow", data.flow)
        appendParam("path", data.path)
        appendParam("headerType", (data.headerType || "").toLowerCase())
        appendParam("host", data.host)
        appendParam("serviceName", data.serviceName)
        appendParam("mode", (data.mode || "").toLowerCase())
        appendParam("extra", data.extra)
        const security = (data.security || "none").toLowerCase()
        const resolvedSni = (data.sni || "").toString().trim().length > 0
                            ? data.sni
                            : ((security === "tls" || security === "reality")
                               ? (data.host || "")
                               : "")
        appendParam("sni", resolvedSni)
        appendParam("alpn", data.alpn)
        appendParam("fp", data.fingerprint)
        appendParam("pbk", data.publicKey)
        appendParam("sid", data.shortId)
        appendParam("spx", data.spiderX)
        if (data.allowInsecure === true)
            appendParam("allowInsecure", "1")

        const unknownPairs = Array.isArray(data.unknownPairs) ? data.unknownPairs : []
        for (let i = 0; i < unknownPairs.length; i += 1) {
            const pair = unknownPairs[i]
            if (!pair || !pair.key)
                continue
            params.push(pair.value !== undefined && pair.value !== null && pair.value !== ""
                        ? String(pair.key) + "=" + String(pair.value)
                        : String(pair.key))
        }

        const encodedName = safeEncodeUriPart((profileName || "").trim())
        const queryText = params.join("&")
        const suffix = encodedName.length > 0 ? ("#" + encodedName) : ""
        return {
            "ok": true,
            "link": "vless://" + uuid + "@" + address + ":" + String(portValue) + (queryText.length > 0 ? ("?" + queryText) : "") + suffix
        }
    }

    function openEditProfile(row, displayName, groupName, originalLink) {
        editProfileRow = row
        editProfileName = (displayName || "").trim()
        editProfileGroup = normalizeImportGroupName(groupName || "General")
        editProfileConfigLink = (originalLink || "").trim()
        editProfileOriginalConfigLink = editProfileConfigLink
        editProfileError = ""
        const parsed = parseVlessForm(editProfileConfigLink)
        editProfileVlessSupported = parsed.ok === true
        editProfileVlessForm = parsed.ok ? parsed : ({})
        if (!parsed.ok)
            editProfileError = ""
        editProfilePopup.open()
    }

    function sheetWidth(maxWidth) {
        return root.width
    }

    function sheetHeight(maxHeight) {
        const reserved = root.compact ? (root.compactBottomNavHeight + 18) : 104
        return Math.min(root.height - reserved, maxHeight)
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

    function handleConnectAction() {
        if (vpnController.currentProfileIndex < 0 && !vpnController.connected && !vpnController.busy) {
            if (vpnController.profileCount > 0) {
                profilePopup.open()
            } else {
                importPopup.open()
                root.importStatusKind = "error"
                root.importStatusText = "Import or select a profile first."
            }
            return
        }
        vpnController.toggleConnection()
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
        androidSystemBarsSyncTimer.restart()
        if (mobilePlatform && contentItem && contentItem.Keys && contentItem.Keys.released) {
            contentItem.Keys.released.connect(function(event) {
                if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape) {
                    if (root.handleMobileBackPressed())
                        event.accepted = true
                }
            })
            if (typeof contentItem.forceActiveFocus === "function")
                contentItem.forceActiveFocus()
        }
        syncSelectedProfileFromController()
        refreshCurrentProfilePing()
        reloadDonationData()
    }

    onDarkThemeEnabledChanged: {
        Theme.mode = darkThemeEnabled ? Theme.Dark : Theme.Light
        androidSystemBarsSyncTimer.restart()
    }

    Timer {
        id: androidSystemBarsSyncTimer
        interval: 140
        repeat: false
        onTriggered: root.syncAndroidSystemBars()
    }

    Connections {
        target: Qt.application
        function onStateChanged() {
            if (Qt.application.state === Qt.ApplicationActive)
                androidSystemBarsSyncTimer.restart()
        }
    }

    Timer {
        id: donationFeedbackTimer
        interval: 2200
        repeat: false
        onTriggered: root.donationFeedbackText = ""
    }

    Timer {
        id: donationPriceRefreshTimer
        interval: 600000
        repeat: true
        running: true
        triggeredOnStart: false
        onTriggered: root.refreshDonationTokenPrice(root.donationSelectedToken)
    }

    Timer {
        id: donationPriceTimeoutTimer
        interval: 6500
        repeat: false
        onTriggered: {
            root.donationPriceLoading = false
            root.donationPriceError = "Price unavailable"
        }
    }

    Timer {
        id: settingsFeedbackTimer
        interval: 2400
        repeat: false
        onTriggered: root.settingsFeedbackText = ""
    }

    Timer {
        id: lanFeedbackTimer
        interval: 3000
        repeat: false
        onTriggered: {
            root.lanStatusFeedbackText = ""
            root.lanSetupFeedbackText = ""
        }
    }

    ParallelAnimation {
        id: settingsSectionTransition
        running: false

        NumberAnimation {
            target: root
            property: "settingsPageOpacity"
            to: 1
            duration: Animations.fast
            easing.type: Easing.OutQuad
        }
    }

    Timer {
        id: sessionClockTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            const nowMs = Date.now()
            if (vpnController.connected) {
                if (root.sessionClockLastMs <= 0)
                    root.sessionClockLastMs = nowMs
                const elapsedMs = Math.max(0, nowMs - root.sessionClockLastMs)
                const deltaSeconds = Math.floor(elapsedMs / 1000.0)
                if (deltaSeconds > 0) {
                    root.sessionSeconds += deltaSeconds
                    root.sessionClockLastMs += deltaSeconds * 1000.0
                }
            } else if (root.sessionSeconds !== 0 || root.sessionClockLastMs !== 0) {
                root.sessionSeconds = 0
                root.sessionClockLastMs = 0
            }
        }
    }

    Timer {
        id: trafficRateTimer
        interval: root.powerUiStatsIntervalMs
        repeat: true
        running: !root.powerPauseBackgroundUi
        onTriggered: {
            const nowMs = Date.now()
            const rx = Number(vpnController.rxBytes || 0)
            const tx = Number(vpnController.txBytes || 0)
            if (!rateSampleInitialized) {
                lastRxBytesSample = rx
                lastTxBytesSample = tx
                lastRateSampleMs = nowMs
                rateSampleInitialized = true
                downRateBytesPerSec = 0
                upRateBytesPerSec = 0
                return
            }

            const elapsedMs = Math.max(0, nowMs - lastRateSampleMs)
            if (elapsedMs < 100) {
                lastRxBytesSample = rx
                lastTxBytesSample = tx
                lastRateSampleMs = nowMs
                return
            }

            let rxDelta = rx - lastRxBytesSample
            let txDelta = tx - lastTxBytesSample
            if (!isFinite(rxDelta) || rxDelta < 0)
                rxDelta = Math.max(0, rx)
            if (!isFinite(txDelta) || txDelta < 0)
                txDelta = Math.max(0, tx)

            const elapsedSec = elapsedMs / 1000.0
            downRateBytesPerSec = Math.max(0, rxDelta / elapsedSec)
            upRateBytesPerSec = Math.max(0, txDelta / elapsedSec)
            lastRxBytesSample = rx
            lastTxBytesSample = tx
            lastRateSampleMs = nowMs

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
        interval: root.powerGaugeRefreshIntervalMs
        repeat: true
        running: !root.powerPauseBackgroundUi
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
            if (!vpnController.connected) {
                downRateBytesPerSec = 0
                upRateBytesPerSec = 0
                root.sessionSeconds = 0
                root.sessionClockLastMs = 0
            } else if (root.sessionClockLastMs <= 0) {
                root.sessionClockLastMs = Date.now()
            }
            root.rateSampleInitialized = false
            root.lastRateSampleMs = 0

            if (vpnController.connectionState === ConnectionState.Connected && !root.donationSuggestionShown) {
                root.donationSuggestionShown = true
                donationSuggestPopup.open()
            }
        }

        function onCurrentProfileIndexChanged() {
            root.syncSelectedProfileFromController()
            root.refreshCurrentProfilePing()
            if (vpnController.currentProfileIndex >= 0)
                vpnController.pingProfile(vpnController.currentProfileIndex)
        }

        function onProfileStatsChanged() {
            root.refreshCurrentProfilePing()
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

        function onAvailableAppRuleItemsReady(items) {
            root.appRuleSuggestionsLoading = false
            root.appRuleSuggestions = items || []
        }

        function onRuntimeCapabilitiesChanged() {
            if (!vpnController.supportsPerAppRouting) {
                root.appRuleSuggestionsLoading = false
                root.appRuleSuggestions = []
                root.clearAppSuggestionSelection()
            }
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
