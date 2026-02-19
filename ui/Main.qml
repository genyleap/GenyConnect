import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import GenyConnect 1.0

import "Core"
import "Controls" as Controls

ApplicationWindow {
    id: root

    visible: true
    width: 1200
    height: 800
    minimumWidth: 1200
    minimumHeight: 800
    title: "GenyConnect (Build " +  updater.appVersion + ") - " + osNameText()

    color: "#eceff5"
    font.family: FontSystem.getContentFont.name

    property bool compact: width < 1080
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
    property string profileSearchQuery: ""
    property string notifiedUpdateVersion: ""
    property string subscriptionGroupDraft: "General"
    property bool importWaitingForSubscription: false
    property string importStatusText: ""
    property string importStatusKind: "idle"

    opacity: 0
    Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

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
        selectedServerMeta = (protocol || "").toUpperCase() + "  " + (address || "") + ":" + port
        if ((security || "").length > 0)
            selectedServerMeta += "  |  " + security
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
        const profileAddress = (vpnController.currentProfileAddress() || "").trim()
        if (profileAddress.length > 0)
            return profileAddress
        return "--"
    }

    function infoLocationText() {
        return selectedServerLabel === "Select Location" ? "Milano, Italy" : selectedServerLabel
    }

    function downloadUsageText() {
        return vpnController.formatBytes(vpnController.rxBytes)
    }

    function uploadUsageText() {
        return vpnController.formatBytes(vpnController.txBytes)
    }

    function downloadRateText() {
        return vpnController.formatBytes(downRateBytesPerSec) + "/s"
    }

    function uploadRateText() {
        return vpnController.formatBytes(upRateBytesPerSec) + "/s"
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

    function speedGaugeStops() {
        if (vpnController.speedTestPhase === "Ping")
            return [0, 50, 100, 200, 500, 1000, 2000]
        return [0, 5, 10, 20, 50, 100, 200]
    }

    function speedGaugeMaxMbps() {
        const stops = speedGaugeStops()
        return stops.length > 0 ? stops[stops.length - 1] : 200.0
    }

    function speedGaugeValue() {
        const maxMbps = speedGaugeMaxMbps()
        if (vpnController.speedTestRunning) {
            if (vpnController.speedTestPhase === "Ping") {
                if (vpnController.speedTestCurrentMbps > 0)
                    return Math.min(vpnController.speedTestCurrentMbps, maxMbps)
                if (vpnController.speedTestPingMs >= 0)
                    return Math.min(vpnController.speedTestPingMs, maxMbps)
                return Math.min(120.0, 18.0 + (speedPhaseProgress() * 102.0))
            }
            return Math.min(Math.max(vpnController.speedTestCurrentMbps, 0.0), maxMbps)
        }
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
            if (vpnController.speedTestPhase === "Ping")
                return "Measuring latency..."
            if (vpnController.speedTestPhase === "Download")
                return "Measuring download speed..."
            if (vpnController.speedTestPhase === "Upload")
                return "Measuring upload speed..."
            return "Running..."
        }
        return ""
    }

    function speedTestSideStatusText() {
        if (vpnController.speedTestRunning)
            return ""
        if (vpnController.speedTestError.length > 0)
            return "Error: " + vpnController.speedTestError
        if (vpnController.speedTestPhase === "Done")
            return "Completed"
        return "Ready"
    }

    function speedGaugePrefixText() {
        if (vpnController.speedTestPhase === "Ping")
            return "↔ "
        if (vpnController.speedTestPhase === "Upload" || vpnController.speedTestPhase === "Done")
            return "↑ "
        return "↓ "
    }

    function speedGaugeNumberText() {
        if (vpnController.speedTestPhase === "Ping") {
            if (vpnController.speedTestCurrentMbps > 0)
                return Math.round(vpnController.speedTestCurrentMbps) + ""
            if (vpnController.speedTestPingMs >= 0)
                return vpnController.speedTestPingMs + ""
            return Math.round(speedGaugeValue()) + ""
        }
        return speedGaugeValue().toFixed(1)
    }

    function speedGaugeUnitText() {
        if (vpnController.speedTestPhase === "Ping")
            return "ms"
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
        return "Direct (No proxy)"
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
        if (!locationCard || !profilePopup || !profilePopupContent)
            return

        const margin = 12
        const popupWidth = Math.max(420, Math.min(locationCard.width, root.width - (margin * 2)))
        const idealHeight = Math.min(profilePopupContent.implicitHeight, Math.floor(root.height * 0.68))
        const popupHeight = Math.max(220, idealHeight)

        const downPos = locationCard.mapToItem(root.contentItem, 0, locationCard.height + 8)
        const upPos = locationCard.mapToItem(root.contentItem, 0, -popupHeight - 8)

        let px = downPos.x
        let py = downPos.y

        if (px < margin)
            px = margin
        if (px + popupWidth > root.width - margin)
            px = root.width - popupWidth - margin

        if (py + popupHeight > root.height - margin && upPos.y >= margin)
            py = upPos.y

        if (py + popupHeight > root.height - margin)
            py = root.height - popupHeight - margin
        if (py < margin)
            py = margin

        profilePopup.width = popupWidth * 1.5
        profilePopup.height = popupHeight
        profilePopup.x = px
        profilePopup.y = py
    }

    Component.onCompleted: {
        opacity = 1
        AppGlobals.appWindow = root
        AppGlobals.mainRect = root.contentItem
        syncSelectedProfileFromController()
    }

    Timer {
        id: trafficRateTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
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
            }
            root.rateSampleInitialized = false
        }
        function onCurrentProfileIndexChanged() {
            root.syncSelectedProfileFromController()
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
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 0
        width: Math.min(420, root.width - 24)
        height: 128
        x: root.width - width - 16
        y: 16
        z: 200

        anchors.centerIn: Overlay.overlay
        transformOrigin: Item.Center

        scale: 0.9

        enter: Transition {
            NumberAnimation {
                property: "scale"
                from: 0.92
                to: 1.0
                duration: Animations.fast * 1.15
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.94
                duration: Animations.fast * 0.9
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            radius: 16
            color: "#ffffff"
            border.width: 1
            border.color: "#d6dfec"
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    color: "#eaf2ff"
                    border.width: 1
                    border.color: "#c8d9f7"

                    Text {
                        anchors.centerIn: parent
                        text: "↑"
                        color: "#2f6de2"
                        font.family: FontSystem.getContentFont.name
                        font.pixelSize: 15
                        font.bold: true
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Update Available"
                    color: "#1f2a3a"
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 16
                    font.bold: true
                }
            }

            Text {
                Layout.fillWidth: true
                text: "GenyConnect " + updater.latestVersion + " is available. You're on " + updater.appVersion + "."
                color: "#667385"
                font.family: FontSystem.getContentFont.name
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
                        settingsPopup.open()
                    }
                }
            }
        }
    }

    Popup {
        id: profilePopup

        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onAboutToShow: {
            root.profileSearchQuery = ""
            root.positionProfilePopup()
            if (vpnController.autoPingProfiles)
                vpnController.pingAllProfiles()
        }
        onOpened: {
            profileSearchField.forceActiveFocus()
            Qt.callLater(root.positionProfilePopup)
        }

        scale: 0.9

        enter: Transition {
            NumberAnimation {
                property: "scale"
                from: 0.92
                to: 1.0
                duration: Animations.fast * 1.15
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.94
                duration: Animations.fast * 0.9
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            radius: 22
            color: "#ffffff"
            border.width: 1
            border.color: "#dbe2ee"
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
                anchors.margins: 10
                spacing: 8

                Rectangle {
                    id: searchBar
                    Layout.fillWidth: true
                    implicitHeight: 58
                    radius: 14
                    color: "#f6f9fd"
                    border.width: 1
                    border.color: profileSearchField.activeFocus ? "#b7caee" : "#dfe6f1"
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uf002"
                        color: "#9aa6ba"
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
                        placeholderText: "Search by profile, country, or IP"
                        text: root.profileSearchQuery
                        color: "#1f2a3a"
                        font.family: FontSystem.getContentFont.name
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
                        color: "#a0acbe"
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

                RowLayout {
                    id: actionsRow
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 116
                        Layout.preferredHeight: 36
                        radius: 12
                        color: addProfileMouse.containsMouse ? "#2f6ff1" : "#3f7cf3"
                        border.width: 1
                        border.color: "#2f6ff1"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Add Profile"
                            color: "#ffffff"
                            font.family: FontSystem.getContentFont.name
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
                        Layout.preferredWidth: 106
                        Layout.preferredHeight: 36
                        radius: 12
                        color: clearAllMouse.containsMouse ? "#fff0f0" : "#fff6f6"
                        border.width: 1
                        border.color: "#f2cdcd"
                        opacity: listView.count > 0 ? 1.0 : 0.55
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Delete All"
                            color: "#cb4f4f"
                            font.family: FontSystem.getContentFont.name
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
                        Layout.preferredWidth: 96
                        Layout.preferredHeight: 36
                        radius: 12
                        color: pingAllMouse.containsMouse ? "#f2f6fd" : "#f7f9fd"
                        border.width: 1
                        border.color: "#d7dfec"
                        opacity: listView.count > 0 ? 1.0 : 0.55
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: (vpnController.currentProfileGroup || "All").toLowerCase() === "all"
                                  ? "Ping All"
                                  : "Ping Group"
                            color: "#4b5d78"
                            font.family: FontSystem.getContentFont.name
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
                        Layout.preferredWidth: 112
                        Layout.preferredHeight: 36
                        radius: 12
                        color: refreshSubsMouse.containsMouse ? "#f2f6fd" : "#f7f9fd"
                        border.width: 1
                        border.color: "#d7dfec"
                        opacity: vpnController.subscriptions.length > 0 ? 1.0 : 0.55
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: (vpnController.currentProfileGroup || "All") === "All"
                                  ? "Refresh Subs"
                                  : "Refresh Group"
                            color: "#4b5d78"
                            opacity: vpnController.subscriptionBusy ? 0.5 : 1.0
                            font.family: FontSystem.getContentFont.name
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

                    Item { Layout.fillWidth: true }


                    // Text {
                    //     Layout.preferredWidth: Math.min(profilePopup.width * 0.45, 280)
                    //     text: vpnController.subscriptionMessage
                    //     visible: text.length > 0
                    //     color: vpnController.subscriptionBusy
                    //            ? "#2b6dcf"
                    //            : ((text.toLowerCase().indexOf("fail") >= 0 || text.toLowerCase().indexOf("error") >= 0)
                    //               ? "#bf4d4d"
                    //               : "#6f7f95")
                    //     font.family: FontSystem.getContentFont.name
                    //     font.pixelSize: 12
                    //     elide: Text.ElideRight
                    // }
                }

                RowLayout {
                    id: groupRow
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Group"
                        color: "#6b778a"
                        font.family: FontSystem.getContentFont.name
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
                        color: "#eef4ff"
                        border.width: 1
                        border.color: "#d8e4f8"

                        Text {
                            id: visibleProfilesText
                            anchors.centerIn: parent
                            text: "Visible " + vpnController.filteredProfileCount
                            color: "#5f6f86"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 11
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                RowLayout {
                    id: groupOptionsRow
                    Layout.fillWidth: true
                    spacing: 8
                    visible: (groupFilterCombo.groupNameAt(groupFilterCombo.currentIndex) || "All").toLowerCase() !== "all"

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        radius: 12
                        color: "#f7f9fd"
                        border.width: 1
                        border.color: "#dce4f2"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Text {
                                text: "Enabled"
                                color: "#5f6f86"
                                font.family: FontSystem.getContentFont.name
                                font.pixelSize: 12
                            }

                            Switch {
                                checked: root.profileGroupEnabled(groupFilterCombo.groupNameAt(groupFilterCombo.currentIndex))
                                onToggled: vpnController.setProfileGroupEnabled(groupFilterCombo.groupNameAt(groupFilterCombo.currentIndex), checked)
                            }

                            Text {
                                text: "Exclusive"
                                color: "#5f6f86"
                                font.family: FontSystem.getContentFont.name
                                font.pixelSize: 12
                            }

                            Switch {
                                checked: root.profileGroupExclusive(groupFilterCombo.groupNameAt(groupFilterCombo.currentIndex))
                                onToggled: vpnController.setProfileGroupExclusive(groupFilterCombo.groupNameAt(groupFilterCombo.currentIndex), checked)
                            }

                            Rectangle {
                                Layout.preferredWidth: 132
                                Layout.preferredHeight: 28
                                radius: 9
                                color: "#ffffff"
                                border.width: 1
                                border.color: "#d5deec"

                                TextField {
                                    id: groupBadgeField
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    padding: 0
                                    clip: true
                                    placeholderText: "Badge"
                                    text: root.profileGroupBadgeText(groupFilterCombo.groupNameAt(groupFilterCombo.currentIndex))
                                    color: "#3b4a61"
                                    font.family: FontSystem.getContentFont.name
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
                                color: "#4d6691"
                                font.family: FontSystem.getContentFont.name
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
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 11
                            font.bold: false
                        }
                    }

                    Rectangle {
                        radius: 11
                        height: 24
                        color: "#f3f6fb"
                        border.width: 1
                        border.color: "#d9e0ed"
                        width: subsText.implicitWidth + 18

                        Text {
                            id: subsText
                            anchors.centerIn: parent
                            text: "Subs " + subscriptionsInCurrentGroup() + "/" + vpnController.subscriptions.length
                            color: "#667487"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 11
                            font.bold: false
                        }
                    }

                    Rectangle {
                        radius: 11
                        height: 24
                        color: "#edf5ff"
                        border.width: 1
                        border.color: "#d9e6fb"
                        width: groupText.implicitWidth + 18

                        Text {
                            id: groupText
                            anchors.centerIn: parent
                            text: "Group " + (vpnController.currentProfileGroup || "All")
                            color: "#5f7290"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 11
                            font.bold: false
                        }
                    }

                    Rectangle {
                        radius: 11
                        height: 24
                        color: "#f3f6fb"
                        border.width: 1
                        border.color: "#d9e0ed"
                        width: profilesText.implicitWidth + 18

                        Text {
                            id: profilesText
                            anchors.centerIn: parent
                            text: "Profiles " + vpnController.profileCount
                            color: "#667487"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 11
                            font.bold: false
                        }
                    }

                    Rectangle {
                        radius: 11
                        height: 24
                        color: "#f3f6fb"
                        border.width: 1
                        border.color: "#d9e0ed"
                        width: bestText.implicitWidth + 18

                        Text {
                            id: bestText
                            anchors.centerIn: parent
                            text: "Best " + (vpnController.bestPingMs >= 0 ? (vpnController.bestPingMs + " ms") : "--")
                            color: "#667487"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 11
                            font.bold: false
                        }
                    }

                    Rectangle {
                        radius: 11
                        height: 24
                        color: "#f3f6fb"
                        border.width: 1
                        border.color: "#d9e0ed"
                        width: worstText.implicitWidth + 18

                        Text {
                            id: worstText
                            anchors.centerIn: parent
                            text: "Worst " + (vpnController.worstPingMs >= 0 ? (vpnController.worstPingMs + " ms") : "--")
                            color: "#667487"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 11
                            font.bold: false
                        }
                    }

                    Rectangle {
                        radius: 11
                        height: 24
                        color: "#fff5e9"
                        border.width: 1
                        border.color: "#f4d9b1"
                        width: scoreText.implicitWidth + 18

                        Text {
                            id: scoreText
                            anchors.centerIn: parent
                            text: "Score " + root.profileScoreStars()
                            color: "#9c6b1f"
                            font.family: FontSystem.getContentFont.name
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
                    radius: 16
                    color: "#f9fbff"
                    border.width: 1
                    border.color: "#e4eaf4"

                    ListView {
                        id: listView
                        anchors.fill: parent
                        anchors.margins: 6
                        clip: true
                        model: vpnController.profileModel
                        spacing: 0
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
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
                            width: listView.width - 16
                            height: matched ? 84 : 0
                            visible: matched

                            Rectangle {
                                id: rowBg
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.topMargin: 3
                                anchors.bottomMargin: 3
                                radius: 14
                                color: selected ? "#eaf2ff" : (hoverArea.containsMouse ? "#f5f8fd" : "#ffffff")
                                border.width: 1
                                border.color: selected ? "#d2e0f8" : "#e7edf6"
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
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Rectangle {
                                    Layout.preferredWidth: 38
                                    Layout.preferredHeight: 38
                                    radius: 19
                                    color: "#f3f6fb"
                                    border.width: 1
                                    border.color: "#dde4ef"

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.guessFlag(displayLabel)
                                        font.pixelSize: 21
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: displayLabel
                                        font.family: FontSystem.getContentFontBold.name
                                        font.weight: Font.Bold
                                        font.pixelSize: 14
                                        color: "#202634"
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: protocol.toUpperCase() + " " + address + ":" + port + ((security || "").length ? " | " + security : "")
                                        font.family: FontSystem.getContentFont.name
                                        font.pixelSize: 12
                                        color: "#8c95a4"
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: (sourceName || "Manual import")
                                              + "  •  " + normalizedGroup
                                              + (groupExclusive ? "  •  Exclusive" : "")
                                              + (groupBadge.length > 0 ? "  •  " + groupBadge : "")
                                        font.family: FontSystem.getContentFont.name
                                        font.pixelSize: 11
                                        color: "#7b889d"
                                        elide: Text.ElideRight
                                    }
                                }

                                RowLayout {
                                    Layout.preferredWidth: 256
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 6

                                    Item { Layout.fillWidth: true; }

                                    Rectangle {
                                        Layout.preferredWidth: 64
                                        Layout.fillWidth: false
                                        Layout.preferredHeight: 30
                                        radius: 10
                                        color: pinging ? "#fff5e8" : "#eff5ff"
                                        border.width: 1
                                        border.color: pinging ? "#f9d9a8" : "#d8e4f8"

                                        Text {
                                            anchors.centerIn: parent
                                            text: pingText
                                            color: pinging ? "#d18b22" : (pingMs >= 0 ? "#2b6dcf" : "#9aa4b6")
                                            font.family: FontSystem.getContentFont.name
                                            font.pixelSize: 12
                                            font.bold: false
                                        }
                                    }

                                    Rectangle {
                                        width: 30
                                        height: 30
                                        radius: 15
                                        color: pingButtonMouse.containsMouse ? "#edf4ff" : "#f7f9fd"
                                        border.width: 1
                                        border.color: "#dbe3ef"

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.iconPing
                                            font.family: root.faSolid
                                            font.pixelSize: 12
                                            color: "#5e6f89"
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
                                        radius: 15
                                        color: removeButtonMouse.containsMouse ? "#fff0f0" : "#fff6f6"
                                        border.width: 1
                                        border.color: "#f2cdcd"

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.iconTrash
                                            font.family: root.faSolid
                                            font.pixelSize: 12
                                            color: "#cb4f4f"
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
                        color: "#8f9bad"
                        font.family: FontSystem.getContentFont.name
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
        width: Math.min(root.width - 40, 420)
        height: 210
        x: (root.width - width) * 0.5
        y: (root.height - height) * 0.5
        padding: 0

        anchors.centerIn: Overlay.overlay
        transformOrigin: Item.Center

        scale: 0.9

        enter: Transition {
            NumberAnimation {
                property: "scale"
                from: 0.92
                to: 1.0
                duration: Animations.fast * 1.15
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.94
                duration: Animations.fast * 0.9
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            radius: 20
            color: "#ffffff"
            border.width: 1
            border.color: "#d8dde8"
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10

            Text {
                text: "Delete all profiles?"
                color: "#1f2530"
                font.family: FontSystem.getContentFont.name
                font.pixelSize: 24
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: "This removes all imported profiles from GenyConnect. This action cannot be undone."
                color: "#6a778b"
                font.family: FontSystem.getContentFont.name
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
        id: settingsPopup
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: Math.min(root.width - 30, 550)
        height: Math.min(root.height - 60, 620)
        x: (root.width - width)
        y: (root.height - height)
        padding: 0

        anchors.centerIn: Overlay.overlay
        transformOrigin: Item.Center

        scale: 0.9

        enter: Transition {
            NumberAnimation {
                property: "scale"
                from: 0.92
                to: 1.0
                duration: Animations.fast * 1.15
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.94
                duration: Animations.fast * 0.9
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            radius: 24
            color: "#ffffff"
            border.width: 1
            border.color: "#d8dde8"
        }

        contentItem: Item {
            anchors.fill: parent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Layout.rightMargin: 64
                    Text {
                        text: "Settings"
                        font.family: FontSystem.getContentFontBold.name
                        font.weight: Font.Bold
                        font.pixelSize: 24
                        color: "#1f2530"
                    }
                    Item { Layout.fillWidth: true }
                    Controls.CircleIconButton {
                        diameter: 34
                        iconText: "×"
                        iconPixelSize: 20
                        iconColor: "#8d96a5"
                        backgroundColor: "#f7f8fb"
                        borderColor: "#e1e5ed"
                        onClicked: settingsPopup.close()
                    }
                    Item { Layout.fillWidth: true }
                }

                ScrollView {
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    ColumnLayout {
                        width: aboutPopup.width
                        spacing: 12

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: updateColumn.implicitHeight + 24
                            radius: Colors.innerRadius
                            color: "#f7f9fc"
                            border.width: 1
                            border.color: "#e0e6f0"

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
                                        color: "#2a3240"
                                        font.family: FontSystem.getContentFont.name
                                        font.pixelSize: 15
                                        font.bold: true
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: "Current " + updater.appVersion
                                        color: "#677385"
                                        font.family: FontSystem.getContentFont.name
                                        font.pixelSize: 13
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: updater.status
                                    color: updater.error.length > 0 ? "#c44a4a"
                                                                    : (updater.updateAvailable ? "#1f7a51" : "#5f6f88")
                                    font.family: FontSystem.getContentFont.name
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: updater.updateAvailable && updater.latestVersion.length > 0
                                    text: "Latest " + updater.latestVersion
                                    color: "#7f8897"
                                    font.family: FontSystem.getContentFont.name
                                    font.pixelSize: 12
                                }

                                ProgressBar {
                                    Layout.fillWidth: true
                                    visible: updater.checking
                                    from: 0
                                    to: 1
                                    value: updater.downloadProgress
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

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
                            radius: Colors.innerRadius
                            color: "#f7f9fc"
                            border.width: 1
                            border.color: "#e0e6f0"
                            implicitHeight: 64

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "xray-core"
                                    color: "#667081"
                                    font.family: FontSystem.getContentFont.name
                                    font.pixelSize: 14
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "Version " + vpnController.xrayVersion
                                    color: "#2a3240"
                                    font.family: FontSystem.getContentFont.name
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: modeColumn.implicitHeight + 24
                            Layout.preferredHeight: implicitHeight
                            radius: Colors.innerRadius
                            color: "#f7f9fc"
                            border.width: 1
                            border.color: "#e0e6f0"

                            ColumnLayout {
                                id: modeColumn
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                Text {
                                    text: "Connection Mode"
                                    color: "#2a3240"
                                    font.family: FontSystem.getContentFont.name
                                    font.pixelSize: 15
                                    font.bold: true
                                }

                                Text {
                                    text: vpnController.useSystemProxy
                                          ? "Global mode: " + osNameText() + " routes compatible apps through GenyConnect automatically."
                                          : (vpnController.tunMode
                                             ? "TUN mode: " + osNameText() + " routes system traffic through Xray TUN without changing proxy settings."
                                             : "Clean mode: " + osNameText() + " proxy stays untouched. Only apps set to 127.0.0.1:10808 use the tunnel.")
                                    color: "#7c8697"
                                    font.family: FontSystem.getContentFont.name
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 50
                                        radius: Colors.outerRadius
                                        color: (vpnController.useSystemProxy && !vpnController.tunMode) ? "#2f6ff1" : "#ffffff"
                                        border.width: 1
                                        border.color: (vpnController.useSystemProxy && !vpnController.tunMode) ? "#2f6ff1" : "#d9e0ec"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Global Mode"
                                            color: (vpnController.useSystemProxy && !vpnController.tunMode) ? "#ffffff" : "#344053"
                                            font.family: FontSystem.getContentFont.name
                                            font.pixelSize: 14
                                            font.bold: vpnController.useSystemProxy && !vpnController.tunMode
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: !vpnController.useSystemProxy || vpnController.tunMode
                                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: {
                                                vpnController.tunMode = false
                                                vpnController.useSystemProxy = true
                                                vpnController.autoDisableSystemProxyOnDisconnect = true
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 50
                                        radius: Colors.outerRadius
                                        color: (!vpnController.useSystemProxy && !vpnController.tunMode) ? "#2f6ff1" : "#ffffff"
                                        border.width: 1
                                        border.color: (!vpnController.useSystemProxy && !vpnController.tunMode) ? "#2f6ff1" : "#d9e0ec"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Clean Mode"
                                            color: (!vpnController.useSystemProxy && !vpnController.tunMode) ? "#ffffff" : "#344053"
                                            font.family: FontSystem.getContentFont.name
                                            font.pixelSize: 14
                                            font.bold: !vpnController.useSystemProxy && !vpnController.tunMode
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: vpnController.useSystemProxy || vpnController.tunMode
                                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: {
                                                vpnController.tunMode = false
                                                vpnController.useSystemProxy = false
                                                vpnController.autoDisableSystemProxyOnDisconnect = true
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 50
                                        radius: Colors.outerRadius
                                        color: vpnController.tunMode ? "#2f6ff1" : "#ffffff"
                                        border.width: 1
                                        border.color: vpnController.tunMode ? "#2f6ff1" : "#d9e0ec"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "TUN Mode"
                                            color: vpnController.tunMode ? "#ffffff" : "#344053"
                                            font.family: FontSystem.getContentFont.name
                                            font.pixelSize: 14
                                            font.bold: vpnController.tunMode
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: !vpnController.tunMode
                                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: {
                                                vpnController.useSystemProxy = false
                                                vpnController.tunMode = true
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Switch {
                                id: autoDisableSwitch
                                checked: vpnController.autoDisableSystemProxyOnDisconnect
                                enabled: vpnController.useSystemProxy && !vpnController.tunMode
                                onToggled: vpnController.autoDisableSystemProxyOnDisconnect = checked
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Auto-disable system proxy when disconnecting"
                                color: "#334155"
                                font.family: FontSystem.getContentFont.name
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Switch {
                                checked: vpnController.loggingEnabled
                                onToggled: vpnController.loggingEnabled = checked
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Enable xray logs"
                                color: "#334155"
                                font.family: FontSystem.getContentFont.name
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Switch {
                                checked: vpnController.autoPingProfiles
                                onToggled: vpnController.autoPingProfiles = checked
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Auto ping profile endpoints"
                                color: "#334155"
                                font.family: FontSystem.getContentFont.name
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                            }

                            Controls.Button {
                                text: (vpnController.currentProfileGroup || "All").toLowerCase() === "all"
                                      ? "Ping All Now"
                                      : "Ping Group Now"
                                Layout.fillWidth: false
                                onClicked: vpnController.pingAllProfiles()
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: vpnController.tunMode
                                  ? "TUN mode does not change OS proxy settings. If connect fails, run app with elevated privileges."
                                  : (vpnController.useSystemProxy
                                     ? "Recommended: keep this enabled to restore system proxy cleanly after tunnel disconnect."
                                     : "In Clean mode this option is ignored because system proxy remains disabled.")
                            color: "#7f8897"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Switch {
                                checked: vpnController.whitelistMode
                                onToggled: vpnController.whitelistMode = checked
                            }

                            Text {
                                text: "Whitelist mode"
                                color: "#334155"
                                font.family: FontSystem.getContentFont.name
                                font.pixelSize: 14
                            }
                        }

                        Button {
                            isDefault: false
                            text: "Reset System Proxy Now"
                            Layout.fillWidth: true
                            onClicked: vpnController.cleanSystemProxy()
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: "#e4e8ef"
                        }

                        Text {
                            text: "Routing Rules"
                            color: "#667081"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 14
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Use comma or new line between values. Domain formats: example.com, full:example.com, domain:example.com, regexp:.*\\\\.example\\\\.com$, geosite:category-ads-all."
                            wrapMode: Text.Wrap
                            color: "#8a95a8"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 12
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 74
                            placeholderText: "Tunnel Domains\nexample.com\ndomain:youtube.com\nregexp:.*\\\\.openai\\\\.com$"
                            text: vpnController.proxyDomainRules
                            onTextChanged: vpnController.proxyDomainRules = text
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 74
                            placeholderText: "Direct Domains\nfull:localhost\ngeosite:private\nexample.org"
                            text: vpnController.directDomainRules
                            onTextChanged: vpnController.directDomainRules = text
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 74
                            placeholderText: "Block Domains\ngeosite:category-ads-all\nregexp:.*ads.*"
                            text: vpnController.blockDomainRules
                            onTextChanged: vpnController.blockDomainRules = text
                        }

                        Text {
                            Layout.fillWidth: true
                            text: vpnController.processRoutingSupported
                                  ? "App rules are supported on this xray-core build."
                                  : "App rules require xray-core 26.1.23+ (current build does not support process routing)."
                            wrapMode: Text.Wrap
                            color: vpnController.processRoutingSupported ? "#8a95a8" : "#d97706"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 12
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 66
                            enabled: vpnController.processRoutingSupported
                            opacity: enabled ? 1.0 : 0.6
                            placeholderText: "Tunnel Apps\nTelegram\nchrome.exe\ncom.apple.Safari"
                            text: vpnController.proxyAppRules
                            onTextChanged: vpnController.proxyAppRules = text
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 66
                            enabled: vpnController.processRoutingSupported
                            opacity: enabled ? 1.0 : 0.6
                            placeholderText: "Direct Apps\nFinder\nexplorer.exe\nfirefox"
                            text: vpnController.directAppRules
                            onTextChanged: vpnController.directAppRules = text
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
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
        width: Math.min(root.width - 40, 510)
        height: Math.min(root.height - 30, 540)
        x: (root.width - width) * 0.5
        y: (root.height - height) * 0.5
        padding: 0

        anchors.centerIn: Overlay.overlay
        transformOrigin: Item.Center
        scale: 0.9

        enter: Transition {
            NumberAnimation {
                property: "scale"
                from: 0.92
                to: 1.0
                duration: Animations.fast * 1.15
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.94
                duration: Animations.fast * 0.9
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            radius: 24
            color: "#ffffff"
            border.width: 1
            border.color: "#d8dde8"
        }

        contentItem: Item {
            anchors.fill: parent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "About"
                        font.family: FontSystem.getContentFontBold.name
                        font.weight: Font.Bold
                        font.pixelSize: 24
                        color: "#1f2530"
                    }
                    Item { Layout.fillWidth: true }
                    Controls.CircleIconButton {
                        diameter: 34
                        iconText: "×"
                        iconPixelSize: 20
                        iconColor: "#8d96a5"
                        backgroundColor: "#f7f8fb"
                        borderColor: "#e1e5ed"
                        onClicked: aboutPopup.close()
                    }
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: false

                    ColumnLayout {
                        anchors.fill: parent
                        width: aboutPopup.width
                        spacing: 12

                        // --- App Info ---
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 14
                            color: "#f7f9fc"
                            border.width: 1
                            border.color: "#e0e6f0"
                            implicitHeight: 64

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "GenyConnect"
                                    color: "#667081"
                                    font.family: FontSystem.getContentFont.name
                                    font.pixelSize: 14
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "Version " + updater.appVersion
                                    color: "#2a3240"
                                    font.family: FontSystem.getContentFont.name
                                    font.pixelSize: 14
                                    font.bold: false
                                }
                            }
                        }

                        // --- Developer ---
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 14
                            color: "#f7f9fc"
                            border.width: 1
                            border.color: "#e0e6f0"
                            implicitHeight: 64

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Developer"
                                    color: "#667081"
                                    font.family: FontSystem.getContentFont.name
                                    font.pixelSize: 14
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "Genyleap LLC"
                                    color: "#2a3240"
                                    font.family: FontSystem.getContentFont.name
                                    font.pixelSize: 14
                                    font.bold: false
                                }
                            }
                        }

                        // --- Website ---
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 14
                            color: "#f7f9fc"
                            border.width: 1
                            border.color: "#e0e6f0"
                            implicitHeight: 64

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Website"
                                    color: "#667081"
                                    font.family: FontSystem.getContentFont.name
                                    font.pixelSize: 14
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "https://genyleap.com"
                                    color: "#2a3240"
                                    font.family: FontSystem.getContentFont.name
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
                            color: "#f7f9fc"
                            border.width: 1
                            border.color: "#e0e6f0"
                            implicitHeight: 64

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Repository"
                                    color: "#667081"
                                    font.family: FontSystem.getContentFont.name
                                    font.pixelSize: 14
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "https://github.com/genyleap/genyconnect"
                                    color: "#2a3240"
                                    font.family: FontSystem.getContentFont.name
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
                            color: "#f7f9fc"
                            border.width: 1
                            border.color: "#e0e6f0"
                            implicitHeight: 64

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Creator's Telegram"
                                    color: "#667081"
                                    font.family: FontSystem.getContentFont.name
                                    font.pixelSize: 14
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "https://t.me/compezeth"
                                    color: "#2a3240"
                                    font.family: FontSystem.getContentFont.name
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
                            color: "#f7f9fc"
                            border.width: 1
                            border.color: "#e0e6f0"
                            implicitHeight: 64

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Support Email"
                                    color: "#667081"
                                    font.family: FontSystem.getContentFont.name
                                    font.pixelSize: 14
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "support@genyleap.com"
                                    color: "#2a3240"
                                    font.family: FontSystem.getContentFont.name
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
        width: Math.min(root.width - 40, 760)
        height: Math.min(root.height - 80, 520)
        x: (root.width - width) * 0.5
        y: (root.height - height) * 0.5
        padding: 0

        anchors.centerIn: Overlay.overlay
        transformOrigin: Item.Center
        scale: 0.9

        enter: Transition {
            NumberAnimation {
                property: "scale"
                from: 0.92
                to: 1.0
                duration: Animations.fast * 1.15
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.94
                duration: Animations.fast * 0.9
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            radius: 24
            color: "#ffffff"
            border.width: 1
            border.color: "#d8dde8"
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Connection History"
                    font.family: FontSystem.getContentFontBold.name
                    font.weight: Font.Bold
                    font.pixelSize: 24
                    color: "#1f2530"
                }
                Item { Layout.fillWidth: true }
                Controls.Button {
                    text: "Copy"
                    Layout.fillWidth: false
                    enabled: vpnController.loggingEnabled && vpnController.recentLogs.length > 0
                    onClicked: vpnController.copyLogsToClipboard()
                }
            }

            Text {
                Layout.fillWidth: true
                visible: !vpnController.loggingEnabled
                text: "Logging is disabled. Enable it in Settings."
                color: "#8b95a5"
                font.family: FontSystem.getContentFont.name
                font.pixelSize: 14
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
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 12
                    color: "#1f2530"
                    background: Rectangle {
                        color: "#f7f9fc"
                        border.color: "#e1e6ee"
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

        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: root.width
        height: root.height
        x: 0
        y: 0
        padding: 0

        anchors.centerIn: Overlay.overlay
        transformOrigin: Item.Center
        scale: 1.0

        enter: Transition {
            NumberAnimation {
                property: "scale"
                from: 0.92
                to: 1.0
                duration: Animations.fast * 1.15
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.94
                duration: Animations.fast * 0.9
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            color: root.color
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Speed Test"
                    color: Colors.textPrimary
                    font.family: FontSystem.getContentFontBold.name
                    font.weight: Font.Bold
                    font.pixelSize: 24
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    spacing: 10

                    Controls.CircleIconButton {
                        diameter: 46
                        iconText: root.iconSetting
                        iconFontFamily: root.faSolid
                        iconColor: "#a0a8b5"
                        iconPixelSize: 18
                        onClicked: settingsPopup.open()
                    }


                    Controls.CircleIconButton {
                        diameter: 46
                        iconText: root.iconClose
                        iconFontFamily: root.faSolid
                        iconColor: "#95a0b3"
                        iconPixelSize: 18
                        onClicked: speedTestPopup.close()
                    }
                }
            }

            Item {
                id: speedTestCenterArea
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: Math.min(root.height * 0.46, 440)
                Layout.minimumHeight: 280

                Item {
                    id: speedDial
                    anchors.centerIn: parent
                    width: Math.min(Math.min(speedTestCenterArea.width * 0.50, speedTestCenterArea.height * 0.98), 430)
                    height: width

                    readonly property int tickCount: 180
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
                            height: index % 3 === 0 ? 12 : 8
                            radius: 1
                            color: activeTick ? root.gaugeColorAt(ratio) : "#dbe3ef"
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
                        color: "#f8fafc"
                        border.width: 1
                        border.color: "#e1e7f0"
                    }

                    Repeater {
                        model: speedDial.scaleLabels.length
                        delegate: Text {
                            required property int index
                            readonly property real ratio: speedDial.scaleLabels.length > 1
                                                          ? (index / (speedDial.scaleLabels.length - 1))
                                                          : 0.0
                            readonly property real angle: (speedDial.startDeg + ratio * speedDial.sweepDeg) * Math.PI / 180.0
                            readonly property real radiusValue: speedDial.innerRadius - 30
                            text: speedDial.scaleLabels[index]
                            color: "#7f8898"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 12
                            x: speedDial.centerX + Math.cos(angle) * radiusValue - width * 0.5
                            y: speedDial.centerY + Math.sin(angle) * radiusValue - height * 0.5
                        }
                    }

                    Item {
                        id: needle
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
                        offset.x: -10
                        offset.y: -5
                        radius: n1.radius
                        blur: 16
                        spread: 0
                        color: Colors.lightShadow
                    }

                    Rectangle {
                        id: n1
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

                    Column {
                        x: speedDial.centerX
                        y: speedDial.centerY - 48
                        anchors.left: parent.left
                        anchors.leftMargin: -220
                        width: speedDial.innerRadius * 0.62
                        spacing: 2
                        z: 6

                        Text {
                            text: root.speedGaugePrefixText() + root.speedGaugeNumberText()
                            color: "#1f2530"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 64
                            font.bold: true
                            horizontalAlignment: Text.AlignLeft
                            width: parent.width
                        }

                        Text {
                            text: root.speedGaugeUnitText()
                            color: "#8f97a6"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 32
                            font.weight: Font.Light
                            font.bold: false
                            horizontalAlignment: Text.AlignLeft
                            width: parent.width
                        }

                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: vpnController.speedTestRunning ? speedTestStatusText() : speedTestSideStatusText()
                color: vpnController.speedTestError.length > 0 ? "#d14545" : (vpnController.speedTestRunning ? "#6a7890" : "#5f6f88")
                font.family: FontSystem.getContentFont.name
                font.pixelSize: 14
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 170
                    Layout.preferredHeight: 56
                    radius: 14
                    color: vpnController.speedTestPhase === "Ping" ? "#eaf2ff" : "#f5f8fc"
                    border.width: 1
                    border.color: "#dce4ef"

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            text: "Ping"
                            color: "#6f7d92"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 13
                        }
                        Text {
                            text: vpnController.speedTestPingMs >= 0 ? (vpnController.speedTestPingMs + " ms") : "--"
                            color: "#1f2530"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 170
                    Layout.preferredHeight: 56
                    radius: 14
                    color: vpnController.speedTestPhase === "Download" ? "#eaf2ff" : "#f5f8fc"
                    border.width: 1
                    border.color: "#dce4ef"

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            text: "Download"
                            color: "#6f7d92"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 13
                        }
                        Text {
                            text: vpnController.speedTestDownloadMbps.toFixed(1) + " Mbps"
                            color: "#1f2530"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 170
                    Layout.preferredHeight: 56
                    radius: 14
                    color: vpnController.speedTestPhase === "Upload" || vpnController.speedTestPhase === "Done"
                           ? "#eaf2ff"
                           : "#f5f8fc"
                    border.width: 1
                    border.color: "#dce4ef"

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            text: "Upload"
                            color: "#6f7d92"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 13
                        }
                        Text {
                            text: vpnController.speedTestUploadMbps.toFixed(1) + " Mbps"
                            color: "#1f2530"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }
                }
            }

            Controls.PrimaryActionButton {
                Layout.alignment: Qt.AlignHCenter
                width: 172
                height: 48
                text: vpnController.speedTestRunning ? "Cancel" : "Start Test"
                enabled: vpnController.speedTestRunning || vpnController.connectionState !== ConnectionState.Connecting
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

                Text {
                    text: "VPN IP:"
                    color: "#1f2430"
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    text: infoIpText()
                    color: "#8f97a6"
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 16
                }

                Rectangle { width: 1; height: 26; color: "#d4d9e3" }

                Text {
                    text: "Proxy:"
                    color: "#1f2430"
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    text: speedTestProxyText()
                    color: "#8f97a6"
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 16
                }

                Rectangle { width: 1; height: 26; color: "#d4d9e3" }

                Text {
                    text: "Provider:"
                    color: "#1f2430"
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    text: speedTestProviderText()
                    color: "#8f97a6"
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 16
                }

                Rectangle { width: 1; height: 26; color: "#d4d9e3" }

                Text {
                    text: "OS:"
                    color: "#1f2430"
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    text: osNameText()
                    color: "#8f97a6"
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 16
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: speedTestPopup.showHistory ? 86 : 42
                radius: 16
                color: "#f7f9fc"
                border.width: 1
                border.color: "#dde4ef"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: "Latest Results"
                        color: "#3f4d63"
                        font.family: FontSystem.getContentFont.name
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
                                    color: "#586780"
                                    font.family: FontSystem.getContentFont.name
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
                            color: "#8a95a8"
                            font.family: FontSystem.getContentFont.name
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
        readonly property bool hasExplicitGroup: ((subscriptionGroupCombo.editText || "").trim().length > 0)
        readonly property string targetGroupName: root.normalizeImportGroupName(
                                                     (subscriptionGroupCombo.editText
                                                      || subscriptionGroupCombo.currentText
                                                      || root.subscriptionGroupDraft))
        closePolicy: vpnController.subscriptionBusy
                     ? Popup.NoAutoClose
                     : (Popup.CloseOnEscape | Popup.CloseOnPressOutside)
        width: Math.min(root.width - 40, 700)
        height: 630
        x: (root.width - width) * 0.5
        y: (root.height - height) * 0.5
        padding: 0

        anchors.centerIn: Overlay.overlay
        transformOrigin: Item.Center
        scale: 0.9
        onAboutToShow: {
            const currentGroup = (vpnController.currentProfileGroup || "All")
            if (!root.subscriptionGroupDraft || root.subscriptionGroupDraft.trim().length === 0
                    || root.subscriptionGroupDraft.trim().toLowerCase() === "all") {
                root.subscriptionGroupDraft = currentGroup === "All" ? "General" : currentGroup
            }
            subscriptionGroupCombo.editText = root.subscriptionGroupDraft
            selectedManageGroup = targetGroupName
            root.importWaitingForSubscription = false
            root.importStatusKind = "idle"
            root.importStatusText = ""
        }
        onClosed: root.importWaitingForSubscription = false

        enter: Transition {
            NumberAnimation {
                property: "scale"
                from: 0.92
                to: 1.0
                duration: Animations.fast * 1.15
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.94
                duration: Animations.fast * 0.9
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            radius: 24
            color: "#ffffff"
            border.width: 1
            border.color: "#d8dde8"
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
            anchors.margins: 18
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Import Profiles"
                    font.family: FontSystem.getContentFontBold.name
                    font.weight: Font.Bold
                    font.pixelSize: 24
                    color: "#1f2530"
                }

                Item { Layout.fillWidth: true }

                Controls.CircleIconButton {
                    diameter: 32
                    iconText: root.iconClose
                    iconFontFamily: root.faSolid
                    iconPixelSize: 13
                    iconColor: "#94a3b8"
                    enabled: !vpnController.subscriptionBusy
                    onClicked: importPopup.close()
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Paste vmess/vless, batch text, base64 payload, or an https subscription URL. Existing groups are reusable and customizable."
                color: "#6f7f95"
                font.family: FontSystem.getContentFont.name
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ComboBox {
                    id: subscriptionGroupCombo
                    Layout.fillWidth: true
                    editable: true
                    model: root.importSelectableGroups()
                    currentIndex: -1
                    leftPadding: 10
                    rightPadding: 34
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 13

                    contentItem: TextField {
                        id: subscriptionGroupEditor
                        text: subscriptionGroupCombo.editText
                        placeholderText: "Group name (type new or choose existing)"
                        color: "#1f2a3a"
                        font.family: FontSystem.getContentFont.name
                        font.pixelSize: 13
                        selectedTextColor: "#ffffff"
                        selectionColor: "#3f7cf3"
                        selectByMouse: true
                        leftPadding: 0
                        rightPadding: 0
                        topPadding: 0
                        bottomPadding: 0
                        background: null
                        onTextEdited: {
                            subscriptionGroupCombo.editText = text
                            root.subscriptionGroupDraft = text
                        }
                    }

                    indicator: Text {
                        text: root.iconChevronDown
                        font.family: root.faSolid
                        font.pixelSize: 11
                        color: "#93a2b7"
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    background: Rectangle {
                        radius: 12
                        color: "#f7f9fd"
                        border.width: 1
                        border.color: subscriptionGroupCombo.activeFocus ? "#b9ccee" : "#d9e1ef"
                    }

                    popup: Popup {
                        y: subscriptionGroupCombo.height + 6
                        width: subscriptionGroupCombo.width
                        implicitHeight: Math.min(contentItem.implicitHeight + 10, 220)
                        padding: 5
                        background: Rectangle {
                            radius: 12
                            color: "#ffffff"
                            border.width: 1
                            border.color: "#d9e2f0"
                        }
                        contentItem: ListView {
                            clip: true
                            model: subscriptionGroupCombo.popup.visible ? subscriptionGroupCombo.delegateModel : null
                            currentIndex: subscriptionGroupCombo.highlightedIndex
                            spacing: 2
                            ScrollBar.vertical: ScrollBar { }
                        }
                    }

                    delegate: ItemDelegate {
                        width: ListView.view.width
                        height: 34
                        text: modelData
                        font.family: FontSystem.getContentFont.name
                        font.pixelSize: 13
                        leftPadding: 10
                        background: Rectangle {
                            radius: 10
                            color: highlighted ? "#edf4ff" : "transparent"
                        }
                    }

                    onEditTextChanged: {
                        if (subscriptionGroupEditor.text !== editText) {
                            subscriptionGroupEditor.text = editText
                        }
                        root.subscriptionGroupDraft = editText
                    }
                    onActivated: {
                        if ((currentText || "").length > 0) {
                            editText = currentText
                            root.subscriptionGroupDraft = editText
                        }
                    }
                }

                Controls.CircleIconButton {
                    diameter: 32
                    iconText: root.iconPlus
                    iconFontFamily: root.faSolid
                    iconPixelSize: 12
                    iconColor: "#2b6dcf"
                    enabled: !vpnController.subscriptionBusy
                    onClicked: {
                        const groupName = root.normalizeImportGroupName(subscriptionGroupCombo.editText)
                        if (vpnController.ensureProfileGroup(groupName)) {
                            subscriptionGroupCombo.editText = groupName
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
                    iconText: root.iconMinus
                    iconFontFamily: root.faSolid
                    iconPixelSize: 12
                    iconColor: "#cb4f4f"
                    enabled: !vpnController.subscriptionBusy
                             && !root.isProtectedGroup(root.normalizeImportGroupName(subscriptionGroupCombo.editText))
                    onClicked: {
                        const groupName = root.normalizeImportGroupName(subscriptionGroupCombo.editText)
                        if (vpnController.removeProfileGroup(groupName)) {
                            subscriptionGroupCombo.editText = "General"
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

                Rectangle {
                    radius: 10
                    height: 28
                    width: groupStateText.implicitWidth + 18
                    color: root.profileGroupEnabled(subscriptionGroupCombo.editText) ? "#e8f7ef" : "#fff0f0"
                    border.width: 1
                    border.color: root.profileGroupEnabled(subscriptionGroupCombo.editText) ? "#b7e4cb" : "#f2c6c6"

                    Text {
                        id: groupStateText
                        anchors.centerIn: parent
                        text: root.profileGroupEnabled(subscriptionGroupCombo.editText) ? "Group Enabled" : "Group Disabled"
                        color: root.profileGroupEnabled(subscriptionGroupCombo.editText) ? "#2c8b57" : "#bf4d4d"
                        font.family: FontSystem.getContentFont.name
                        font.pixelSize: 11
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: 12
                    color: "#f7f9fd"
                    border.width: 1
                    border.color: "#dce4f2"

                    RowLayout {
                        Layout.fillWidth: true
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Switch {
                            checked: root.profileGroupEnabled(subscriptionGroupCombo.editText)
                            onToggled: {
                                const groupName = root.normalizeImportGroupName(subscriptionGroupCombo.editText)
                                vpnController.setProfileGroupEnabled(groupName, checked)
                            }
                            text: "Enabled"
                        }

                        Switch {
                            checked: root.profileGroupExclusive(subscriptionGroupCombo.editText)
                            onToggled: {
                                const groupName = root.normalizeImportGroupName(subscriptionGroupCombo.editText)
                                vpnController.setProfileGroupExclusive(groupName, checked)
                            }
                            text: "Exclusive"
                        }

                        Rectangle {
                            Layout.preferredWidth: 128
                            Layout.preferredHeight: 28
                            radius: 9
                            color: "#ffffff"
                            border.width: 1
                            border.color: "#d5deec"

                            TextField {
                                id: importGroupBadgeField
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                padding: 0
                                clip: true
                                placeholderText: "Badge"
                                text: root.profileGroupBadgeText(subscriptionGroupCombo.editText)
                                color: "#3b4a61"
                                font.family: FontSystem.getContentFont.name
                                font.pixelSize: 12
                                background: null
                                onEditingFinished: {
                                    const groupName = root.normalizeImportGroupName(subscriptionGroupCombo.editText)
                                    vpnController.setProfileGroupBadge(groupName, text)
                                }
                            }
                        }

                        Text {
                            visible: root.profileGroupBadgeText(subscriptionGroupCombo.editText).length > 0
                            text: "• " + root.profileGroupBadgeText(subscriptionGroupCombo.editText)
                            color: "#4d6691"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Groups: " + root.importSelectableGroups().length
                    color: "#90a0b5"
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 11
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: 10
                color: "#eef4ff"
                border.width: 1
                border.color: "#d2def4"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: "Import Target Group:"
                        color: "#5f6f86"
                        font.family: FontSystem.getContentFont.name
                        font.pixelSize: 12
                    }

                    Text {
                        Layout.fillWidth: true
                        text: importPopup.targetGroupName
                        color: "#2c5eaf"
                        font.family: FontSystem.getContentFontBold.name
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    Text {
                        text: "All pasted profiles/subscriptions will be saved here."
                        color: "#7d8ea7"
                        font.family: FontSystem.getContentFont.name
                        font.pixelSize: 11
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 232
                radius: 12
                color: "#f7f9fd"
                border.width: 1
                border.color: "#d8e1ef"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Manage Groups"
                            color: "#5f6f86"
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
                            color: selectedGroup ? "#eaf2ff" : "#ffffff"
                            border.width: selectedGroup ? 2 : 1
                            border.color: selectedGroup ? "#3d7ae6" : "#dee6f3"

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
                                            subscriptionGroupCombo.editText = groupName
                                            root.subscriptionGroupDraft = groupName
                                        }
                                    }

                                    Text {
                                        anchors.fill: parent
                                        text: groupName
                                        color: "#2b3648"
                                        font.family: FontSystem.getContentFont.name
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                Switch {
                                    Layout.fillWidth: false
                                    text: "Enabled"
                                    checked: groupEnabled
                                    onToggled: vpnController.setProfileGroupEnabled(groupName, checked)
                                }

                                Switch {
                                    Layout.fillWidth: false
                                    text: "Exclusive"
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
                                    color: "#3b4a61"
                                    font.family: FontSystem.getContentFont.name
                                    font.pixelSize: 12
                                    background: Rectangle {
                                        radius: 8
                                        color: "#f8fbff"
                                        border.width: 1
                                        border.color: "#d5deec"
                                    }
                                    onEditingFinished: vpnController.setProfileGroupBadge(groupName, text)
                                }


                                Controls.CircleIconButton {
                                    diameter: 24
                                    iconText: root.iconTrash
                                    iconFontFamily: root.faSolid
                                    iconPixelSize: 10
                                    iconColor: "#cb4f4f"
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
                           ? "#2b6dcf"
                           : (root.importStatusKind === "success"
                              ? "#2c8b57"
                              : (root.importStatusKind === "error" ? "#c65050" : "#6f7f95"))
                    font.family: FontSystem.getContentFont.name
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
                    implicitWidth: 128
                    isDefault: false
                    text: vpnController.subscriptionBusy ? "Working..." : "Close"
                    Layout.fillWidth: false
                    enabled: !vpnController.subscriptionBusy
                    onClicked: importPopup.close()
                }

                Item { Layout.fillWidth: true }

                Controls.Button {
                    implicitWidth: 256
                    isDefault: true
                    text: vpnController.subscriptionBusy ? "Please wait..." : "Import / Add Subscription"
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
                        if ((subscriptionGroupCombo.editText || "").trim() !== subGroup)
                            subscriptionGroupCombo.editText = subGroup
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

            // Controls.CircleIconButton {
            //     diameter: 62
            //     iconText: ""
            //     iconPixelSize: 0

            //     Rectangle {
            //         anchors.fill: parent
            //         radius: width * 0.5
            //         color: "transparent"
            //         clip: true

            //         Image {
            //             anchors.fill: parent
            //             anchors.margins: 6
            //             source: "qrc:/ui/Resources/image/avatar.svg"
            //             fillMode: Image.PreserveAspectCrop
            //             smooth: true
            //         }
            //     }
            // }


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
                    iconColor: "#a0a8b5"
                    iconPixelSize: 18
                    onClicked: settingsPopup.open()
                }

                Controls.CircleIconButton {
                    diameter: 46
                    iconText: root.iconInfo
                    iconFontFamily: root.faSolid
                    iconColor: "#a0a8b5"
                    iconPixelSize: 18
                    onClicked: aboutPopup.open()
                }

                Controls.CircleIconButton {
                    diameter: 46
                    iconText: root.iconHistory
                    iconFontFamily: root.faSolid
                    iconColor: "#a0a8b5"
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

            Controls.WorldMapDots {
                anchors.fill: parent
                visible: !root.mapLoaded
                centerMarkerXRatio: 0.53
                centerMarkerYRatio: 0.47
                sideMarkerXRatio: 0.17
                sideMarkerYRatio: 0.56
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

            width: compact ? parent.width - 40 : 720
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
                color: "#ffffff"
                border.width: 1
                z: 2
                border.color: vpnController.connected
                              ? "#c8ead8"
                              : (vpnController.busy ? "#f7ddaa" : Colors.borderDeactivated)
                Behavior on border.color { ColorAnimation { duration: Animations.fast } }

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 8
                    radius: Colors.radius
                    color: "#1f5ed8"
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
                                border.color: "#dee3ec"

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
                                color: "#9ea6b5"
                                font.family: root.faSolid
                                font.pixelSize: 14
                            }
                        }
                    }

                    Rectangle {
                        width: 1
                        Layout.fillHeight: true
                        color: "#e6ebf3"
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
                                font.family: FontSystem.getContentFont.name
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
            anchors.bottomMargin: 25

            width: compact ? parent.width - 40 : 720
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
                color: "#ffffff"
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
                                    color: "#6f7f96"
                                    font.family: FontSystem.getContentFont.name
                                    font.pixelSize: Typography.h6
                                }
                                Text {
                                    text: root.stateText()
                                    color: "#1f2a37"
                                    font.family: FontSystem.getContentFont.name
                                    font.pixelSize: Typography.t2
                                    font.bold: true
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 1
                        Layout.fillHeight: true
                        color: "#e6ebf3"
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Colors.innerRadius
                        color: "#eaf2ff"
                        border.width: 1
                        border.color: "#d7e4fb"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: "↓"
                                color: "#2874f0"
                                font.family: FontSystem.getContentFont.name
                                font.pixelSize: 18
                                font.bold: true
                            }

                            ColumnLayout {
                                spacing: 1
                                Text {
                                    text: "Receive"
                                    color: "#6682ad"
                                    font.family: FontSystem.getContentFont.name
                                    font.pixelSize: Typography.h6
                                }
                                Text {
                                    text: root.downloadRateText()
                                    color: "#3f5e93"
                                    font.family: FontSystem.getContentFont.name
                                    font.pixelSize: Typography.t3
                                    font.bold: true
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: downloadUsageText()
                                color: "#1f2b3d"
                                font.family: FontSystem.getContentFont.name
                                font.pixelSize: Typography.h2
                                font.bold: false
                            }

                            Item { Layout.preferredWidth: 5 }

                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Colors.innerRadius
                        color: "#ecfff3"
                        border.width: 1
                        border.color: "#d8efdf"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: "↑"
                                color: "#1ea768"
                                font.family: FontSystem.getContentFont.name
                                font.pixelSize: 18
                                font.bold: true
                            }

                            ColumnLayout {
                                spacing: 1
                                Text {
                                    text: "Send"
                                    color: "#5f9478"
                                    font.family: FontSystem.getContentFont.name
                                    font.pixelSize: Typography.h6
                                }
                                Text {
                                    text: root.uploadRateText()
                                    color: "#2e7b58"
                                    font.family: FontSystem.getContentFont.name
                                    font.pixelSize: Typography.t3
                                    font.bold: true
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: uploadUsageText()
                                color: "#1f2b3d"
                                font.family: FontSystem.getContentFont.name
                                font.pixelSize: Typography.h2
                                font.bold: false
                            }

                            Item { Layout.preferredWidth: 5 }

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
            width: compact ? parent.width - 40 : 820
            spacing: 18

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 6

                Text {
                    text: "Your IP:"
                    color: "#2a3140"
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 16
                    font.bold: true
                }

                Text {
                    text: infoIpText()
                    color: "#8e98aa"
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 16
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 1
                height: 24
                color: "#d9dee8"
            }

            RowLayout {
                spacing: 6

                Text {
                    text: "Your Location:"
                    color: "#2a3140"
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 16
                    font.bold: true
                }

                Text {
                    text: infoLocationText()
                    color: "#8e98aa"
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 16
                }
            }

            Item { Layout.fillWidth: true }
        }

        Row {
            id: quickActionsRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 86
            spacing: 20

            Controls.CircleIconButton {
                diameter: 64
                iconText: root.iconSetting
                iconFontFamily: root.faSolid
                iconPixelSize: 20
                iconColor: "#97a0b0"
                onClicked: settingsPopup.open()
            }

            Controls.CircleIconButton {
                diameter: 64
                iconText: root.iconSpeed
                iconFontFamily: root.faSolid
                iconPixelSize: 20
                iconColor: "#97a0b0"
                onClicked: speedTestPopup.open()
            }

            Controls.CircleIconButton {
                diameter: 64
                iconText: root.iconImport
                iconFontFamily: root.faSolid
                iconPixelSize: 20
                iconColor: "#97a0b0"
                onClicked: importPopup.open()
            }
        }

        Item { Layout.fillHeight: true; }

    }

    footer: Rectangle {
        id: footer
        width: parent.width
        height: 48
        color: Colors.pageground
        border.width: 1
        border.color: Colors.borderActivated

        RowLayout {
            anchors.fill: parent

            Item { Layout.preferredWidth: 10; }

            Text {
                text: "Build: v" + updater.appVersion
                color: Colors.textSecondary
                font.family: FontSystem.getContentFont.name
                font.pixelSize: Typography.t2
                Behavior on color { ColorAnimation { duration: 220 } }
            }

            Item { Layout.fillWidth: true; }

            Text {
                text: stateText()
                color: root.statePrimaryColor()
                font.family: FontSystem.getContentFont.name
                font.pixelSize: Typography.t2
                Behavior on color { ColorAnimation { duration: 220 } }
            }

            Item { Layout.preferredWidth: 10; }
        }
    }
}
