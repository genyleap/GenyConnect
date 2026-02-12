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
    width: 1366
    height: 900
    minimumWidth: 920
    minimumHeight: 680
    title: "GenyConnect"

    color: "#eceff5"
    font.family: FontSystem.getContentFont.name

    property bool compact: width < 1080
    readonly property string faSolid: FontSystem.getAwesomeSolid.name

    readonly property string iconGrid: "\uf00a"
    readonly property string iconShield: "\uf3ed"
    readonly property string iconGear: "\uf013"
    readonly property string iconHistory: "\uf1da"
    readonly property string iconClose: "\uf00d"
    readonly property string iconClock: "\uf017"
    readonly property string iconKeyboard: "\uf11c"
    readonly property string iconChevronDown: "\uf078"

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

    function updateProfileSelection(label, protocol, address, port, security) {
        const cleanLabel = (label || "").trim()
        selectedServerLabel = cleanLabel.length > 0 ? cleanLabel : "Selected Profile"
        selectedServerFlag = guessFlag(selectedServerLabel)
        selectedServerMeta = (protocol || "").toUpperCase() + "  " + (address || "") + ":" + port
        if ((security || "").length > 0)
            selectedServerMeta += "  |  " + security
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

    function speedGaugeMaxMbps() {
        return 200.0
    }

    function speedGaugeValue() {
        const maxMbps = speedGaugeMaxMbps()
        if (vpnController.speedTestRunning) {
            if (vpnController.speedTestPhase === "Ping") {
                if (vpnController.speedTestPingMs >= 0)
                    return Math.min(vpnController.speedTestPingMs, maxMbps)
                return Math.min(30.0, 5.0 + (speedPhaseProgress() * 25.0))
            }
            return Math.min(Math.max(vpnController.speedTestCurrentMbps, 0.0), maxMbps)
        }
        // Reset dial pointer to zero whenever test is not actively running.
        return 0.0
    }

    function speedGaugeProgress() {
        const stops = [0, 5, 10, 20, 50, 100, 200]
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
        if (!locationCard || !profilePopup || !profilePopup.contentItem)
            return

        const margin = 12
        const popupWidth = locationCard.width
        const popupHeight = Math.min(profilePopup.contentItem.implicitHeight, 300)

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

        profilePopup.width = popupWidth
        profilePopup.height = popupHeight
        profilePopup.x = px
        profilePopup.y = py
    }

    Component.onCompleted: {
        AppGlobals.appWindow = root
        AppGlobals.mainRect = root.contentItem
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
            rateSampleInitialized = false
        }
    }

    Popup {
        id: profilePopup

        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onAboutToShow: root.positionProfilePopup()
        onOpened: Qt.callLater(root.positionProfilePopup)

        width: 420
        height: 72
        padding: 0

        background: Rectangle {
            radius: 22
            color: "#ffffff"
            border.width: 1
            border.color: "#d8dde8"
        }

        contentItem: Item {
            implicitHeight: listView.contentHeight > 0 ? Math.min(listView.contentHeight, 300) : 72

            ListView {
                id: listView
                anchors.fill: parent
                clip: true
                model: vpnController.profileModel
                spacing: 0

                delegate: Rectangle {
                    required property int index
                    required property string displayLabel
                    required property string protocol
                    required property string address
                    required property int port
                    required property string security

                    width: listView.width
                    height: 66
                    color: hoverArea.containsMouse ? "#f2f5fb" : "transparent"

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            vpnController.currentProfileIndex = index
                            root.updateProfileSelection(displayLabel, protocol, address, port, security)
                            profilePopup.close()
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        Text {
                            text: root.guessFlag(displayLabel)
                            font.pixelSize: 22
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: displayLabel
                                font.family: FontSystem.getContentFont.name
                                font.pixelSize: 19
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
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        height: 1
                        color: "#edf1f7"
                        visible: index < listView.count - 1
                    }
                }

                footer: Item {
                    width: listView.width
                    height: listView.count === 0 ? 72 : 0

                    Text {
                        anchors.centerIn: parent
                        visible: listView.count === 0
                        text: "No profiles. Import one first."
                        color: "#98a0ad"
                        font.family: FontSystem.getContentFont.name
                        font.pixelSize: 15
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
        width: Math.min(root.width - 40, 560)
        height: Math.min(root.height - 60, 720)
        x: (root.width - width) * 0.5
        y: (root.height - height) * 0.5
        padding: 0

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
                        text: "Settings"
                        font.family: FontSystem.getContentFont.name
                        font.pixelSize: 24
                        font.bold: true
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
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ColumnLayout {
                        width: settingsPopup.width - 54
                        spacing: 12

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
                            radius: 16
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
                                        ? "Global mode: macOS routes compatible apps through GenyConnect automatically."
                                        : "Clean mode: macOS proxy stays untouched. Only apps set to 127.0.0.1:10808 use the tunnel."
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
                                        radius: 12
                                        color: vpnController.useSystemProxy ? "#2f6ff1" : "#ffffff"
                                        border.width: 1
                                        border.color: vpnController.useSystemProxy ? "#2f6ff1" : "#d9e0ec"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Global Mode"
                                            color: vpnController.useSystemProxy ? "#ffffff" : "#344053"
                                            font.family: FontSystem.getContentFont.name
                                            font.pixelSize: 14
                                            font.bold: vpnController.useSystemProxy
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: !vpnController.useSystemProxy
                                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: {
                                                vpnController.useSystemProxy = true
                                                vpnController.autoDisableSystemProxyOnDisconnect = true
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 50
                                        radius: 12
                                        color: !vpnController.useSystemProxy ? "#2f6ff1" : "#ffffff"
                                        border.width: 1
                                        border.color: !vpnController.useSystemProxy ? "#2f6ff1" : "#d9e0ec"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Clean Mode"
                                            color: !vpnController.useSystemProxy ? "#ffffff" : "#344053"
                                            font.family: FontSystem.getContentFont.name
                                            font.pixelSize: 14
                                            font.bold: !vpnController.useSystemProxy
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: vpnController.useSystemProxy
                                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: {
                                                vpnController.useSystemProxy = false
                                                vpnController.autoDisableSystemProxyOnDisconnect = true
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
                                enabled: vpnController.useSystemProxy
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

                        Text {
                            Layout.fillWidth: true
                            text: vpnController.useSystemProxy
                                ? "Recommended: keep this enabled to restore system proxy cleanly after tunnel disconnect."
                                : "In Clean mode this option is ignored because system proxy remains disabled."
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

                        Controls.TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 74
                            placeholderText: "Tunnel Domains"
                            text: vpnController.proxyDomainRules
                            onTextChanged: vpnController.proxyDomainRules = text
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 74
                            placeholderText: "Direct Domains"
                            text: vpnController.directDomainRules
                            onTextChanged: vpnController.directDomainRules = text
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 74
                            placeholderText: "Block Domains"
                            text: vpnController.blockDomainRules
                            onTextChanged: vpnController.blockDomainRules = text
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 66
                            placeholderText: "Tunnel Apps"
                            text: vpnController.proxyAppRules
                            onTextChanged: vpnController.proxyAppRules = text
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 66
                            placeholderText: "Direct Apps"
                            text: vpnController.directAppRules
                            onTextChanged: vpnController.directAppRules = text
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 66
                            placeholderText: "Block Apps"
                            text: vpnController.blockAppRules
                            onTextChanged: vpnController.blockAppRules = text
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
                    text: "xray-core Logs"
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 24
                    font.bold: true
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

        background: Rectangle {
            color: root.color
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            RowLayout {
                Layout.fillWidth: true

                Controls.CircleIconButton {
                    diameter: 62
                    iconText: ""
                    iconPixelSize: 0

                    Rectangle {
                        anchors.fill: parent
                        radius: width * 0.5
                        color: "transparent"
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: 6
                            source: "qrc:/ui/Resources/image/avatar.svg"
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Speed Test"
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 46
                    color: "#1f2530"
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    spacing: 10

                    Controls.CircleIconButton {
                        diameter: 46
                        iconText: root.iconGear
                        iconFontFamily: root.faSolid
                        iconColor: "#a0a8b5"
                        iconPixelSize: 18
                        onClicked: settingsPopup.open()
                    }

                    Controls.CircleIconButton {
                        diameter: 46
                        iconText: root.iconHistory
                        iconFontFamily: root.faSolid
                        iconColor: speedTestPopup.showHistory ? "#4f5f79" : "#a0a8b5"
                        iconPixelSize: 18
                        onClicked: speedTestPopup.showHistory = !speedTestPopup.showHistory
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
                        readonly property var scaleLabels: [0, 5, 10, 20, 50, 100, 200]

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
                        anchors.leftMargin: -128
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
                width: 260
                height: 68
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
                Layout.preferredHeight: speedTestPopup.showHistory ? 136 : 42
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
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: Math.min(root.width - 40, 640)
        height: 280
        x: (root.width - width) * 0.5
        y: (root.height - height) * 0.5
        padding: 0

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

            Text {
                text: "Import Profile"
                font.family: FontSystem.getContentFont.name
                font.pixelSize: 24
                font.bold: true
                color: "#1f2530"
            }

            Controls.TextArea {
                id: importTextArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                placeholderText: "Paste vless:// or vmess:// link"
                text: root.importDraft
                onTextChanged: root.importDraft = text
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Controls.Button {
                    text: "Import"
                    Layout.fillWidth: false
                    onClicked: {
                        if (vpnController.importProfileLink(importTextArea.text.trim())) {
                            root.importDraft = ""
                            importTextArea.text = ""
                            importPopup.close()
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

            Controls.CircleIconButton {
                diameter: 62
                iconText: ""
                iconPixelSize: 0

                Rectangle {
                    anchors.fill: parent
                    radius: width * 0.5
                    color: "transparent"
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 6
                        source: "qrc:/ui/Resources/image/avatar.svg"
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "GenyConnect"
                color: "#1f2430"
                font.family: FontSystem.getContentFont.name
                font.pixelSize: 34
                font.bold: false
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 10

                Controls.CircleIconButton {
                    diameter: 46
                    iconText: root.iconGear
                    iconFontFamily: root.faSolid
                    iconColor: "#a0a8b5"
                    iconPixelSize: 18
                    onClicked: settingsPopup.open()
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
            anchors.topMargin: 30
            width: Math.min(parent.width - 90, 1060)
            height: width * 0.46

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
                x: mapContainer.width * 0.53 - width * 0.5
                y: mapContainer.height * 0.48 - height * 0.5
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
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    radius: 11
                    color: root.statePrimaryColor()
                    border.width: 3
                    border.color: "#f7f7fa"
                    Behavior on color { ColorAnimation { duration: 240 } }

                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        running: vpnController.connectionState === ConnectionState.Connecting
                        NumberAnimation { from: 1.0; to: 1.24; duration: 460; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.24; to: 1.0; duration: 460; easing.type: Easing.InOutQuad }
                    }
                }
            }

            Rectangle {
                x: mapContainer.width * 0.18 - width * 0.5
                y: mapContainer.height * 0.58 - height * 0.5
                width: 58
                height: 58
                radius: 29
                color: "#f5f7fa"
                border.width: 1
                border.color: "#d8dde7"

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    anchors.centerIn: parent
                    color: vpnController.connected ? "#1f9f53" : "#252a34"
                    Behavior on color { ColorAnimation { duration: 240 } }
                }
            }
        }

        RowLayout {
            id: actionRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: mapContainer.bottom
            anchors.topMargin: 18
            width: compact ? parent.width - 40 : 820
            spacing: 14

            Rectangle {
                id: locationCard
                Layout.fillWidth: true
                height: 84
                radius: 26
                color: "#ffffff"
                border.width: 1
                border.color: vpnController.connected ? "#c8ead8" : (vpnController.busy ? "#f7ddaa" : "#e0e4ec")
                Behavior on border.color { ColorAnimation { duration: 220 } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: profilePopup.open()
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 10

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 22
                        color: "#f3f5f9"
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
                        color: "#202634"
                        font.family: FontSystem.getContentFont.name
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

            Controls.PrimaryActionButton {
                Layout.preferredWidth: compact ? 240 : 260
                Layout.fillWidth: false
                height: 84
                text: connectButtonText()
                enabled: vpnController.currentProfileIndex >= 0 || vpnController.connected || vpnController.busy
                busy: vpnController.busy
                onClicked: vpnController.toggleConnection()
            }
        }

        RowLayout {
            id: trafficRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: statusRow.bottom
            anchors.topMargin: 10
            width: compact ? parent.width - 40 : 820
            spacing: 14

            Rectangle {
                Layout.fillWidth: true
                height: 72
                radius: 24
                color: "#ffffff"
                border.width: 1
                border.color: "#e0e4ec"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 8

                    Text {
                        text: "Download"
                        color: "#8f97a6"
                        font.family: FontSystem.getContentFont.name
                        font.pixelSize: 15
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        spacing: 0
                        Text {
                            text: downloadUsageText()
                            color: "#202634"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 18
                            font.bold: true
                        }
                        Text {
                            text: root.downloadRateText()
                            color: "#738096"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 12
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 72
                radius: 24
                color: "#ffffff"
                border.width: 1
                border.color: "#e0e4ec"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 8

                    Text {
                        text: "Upload"
                        color: "#8f97a6"
                        font.family: FontSystem.getContentFont.name
                        font.pixelSize: 15
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        spacing: 0
                        Text {
                            text: uploadUsageText()
                            color: "#202634"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 18
                            font.bold: true
                        }
                        Text {
                            text: root.uploadRateText()
                            color: "#738096"
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }

        RowLayout {
            id: statusRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: actionRow.bottom
            anchors.topMargin: 12
            width: compact ? parent.width - 40 : 820
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                radius: 16
                color: root.stateSoftColor()
                border.width: 1
                border.color: root.statePrimaryColor()
                implicitHeight: 46
                Behavior on color { ColorAnimation { duration: 220 } }
                Behavior on border.color { ColorAnimation { duration: 220 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

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

                    Text {
                        text: "Status: " + root.stateText()
                        color: "#1f2a37"
                        font.family: FontSystem.getContentFont.name
                        font.pixelSize: 15
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "DL " + root.downloadRateText() + "  •  UL " + root.uploadRateText()
                        color: "#5b6678"
                        font.family: FontSystem.getContentFont.name
                        font.pixelSize: 14
                    }
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: trafficRow.bottom
            anchors.topMargin: 18
            spacing: 22

            Row {
                spacing: 6
                Text {
                    text: "Your IP:"
                    color: "#1f2430"
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 18
                    font.bold: true
                }
                Text {
                    text: infoIpText()
                    color: "#9aa2b0"
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 18
                }
            }

            Rectangle {
                width: 1
                height: 32
                color: "#d4d9e3"
            }

            Row {
                spacing: 6
                Text {
                    text: "Your Location:"
                    color: "#1f2430"
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 18
                    font.bold: true
                }
                Text {
                    text: infoLocationText()
                    color: "#9aa2b0"
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: 18
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 28
            spacing: 20

            Controls.CircleIconButton {
                diameter: 64
                iconText: root.iconGrid
                iconFontFamily: root.faSolid
                iconPixelSize: 20
                iconColor: "#97a0b0"
                onClicked: profilePopup.open()
            }

            Controls.CircleIconButton {
                diameter: 64
                iconText: root.iconShield
                iconFontFamily: root.faSolid
                iconPixelSize: 20
                iconColor: "#97a0b0"
                onClicked: vpnController.toggleConnection()
            }

            Controls.CircleIconButton {
                diameter: 64
                iconText: root.iconGear
                iconFontFamily: root.faSolid
                iconPixelSize: 20
                iconColor: "#97a0b0"
                onClicked: settingsPopup.open()
            }

            Controls.CircleIconButton {
                diameter: 64
                iconText: root.iconClock
                iconFontFamily: root.faSolid
                iconPixelSize: 20
                iconColor: "#97a0b0"
                onClicked: speedTestPopup.open()
            }

            Controls.CircleIconButton {
                diameter: 64
                iconText: root.iconKeyboard
                iconFontFamily: root.faSolid
                iconPixelSize: 20
                iconColor: "#97a0b0"
                onClicked: importPopup.open()
            }
        }

        Text {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 14
            anchors.bottomMargin: 10
            text: stateText()
            color: root.statePrimaryColor()
            font.family: FontSystem.getContentFont.name
            font.pixelSize: 15
            Behavior on color { ColorAnimation { duration: 220 } }
        }
    }
}
