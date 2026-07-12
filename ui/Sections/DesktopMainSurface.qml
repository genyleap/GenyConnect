// Copyright (C) 2026 Genyleap Labs.
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtCore

import GenyConnect 1.0

import "../Core"
import "../Controls" as Controls

Item {
    id: desktop

    required property var root
    required property var vpnController
    required property var updater
    required property var dashboardStatsSettings
    required property var profilePopup
    required property var settingsPopup
    required property var logsPopup
    required property var speedTestPopup
    required property var dataUsagePopup
    required property var importPopup

    readonly property color pageBg: root.themeColorToken("mainHex_f7f9fc", "mainHex_090b14")
    readonly property color cardBg: root.themeColorToken("mainHex_ffffff", "mainHex_151c32")
    readonly property color softBg: root.themeColorToken("mainHex_f3f6fb", "mainHex_20314b")
    readonly property color borderColor: root.themeColorToken("mainHex_e0e6f0", "mainHex_30435d")
    readonly property color textStrong: root.themeColorToken("mainHex_0f1622", "mainHex_d8e1f0")
    readonly property color textMuted: root.themeColorToken("mainHex_667487", "mainHex_9bb0cb")
    readonly property color accentBlue: root.themeColorToken("mainHex_2f6ff1", "mainHex_7fb0ff")
    readonly property color accentGreen: root.themeColorToken("mainHex_16a34a", "mainHex_34d18a")
    readonly property color accentYellow: root.themeColorToken("mainHex_d97706", "mainHex_f7b251")
    readonly property string logoSource: "qrc:/ui/Resources/image/GenyConnect-Circle.png"
    readonly property bool connected: vpnController.connectionState === ConnectionState.Connected
    readonly property bool connecting: vpnController.connectionState === ConnectionState.Connecting
    readonly property bool errorState: vpnController.connectionState === ConnectionState.Error

    function statusColor() {
        if (connecting)
            return accentYellow
        if (connected)
            return accentGreen
        if (errorState)
            return Colors.dsDanger
        return textMuted
    }

    function modeText() {
        if (vpnController.tunMode)
            return "TUN"
        if (vpnController.supportsSystemProxy)
            return "System Proxy"
        return "Proxy"
    }

    function protocolText() {
        const meta = (root.selectedServerMeta || "").trim()
        if (meta.length === 0 || meta === "Import and select a profile" || meta === "Profile is selected")
            return "--"
        const first = meta.split(/\s+/)[0]
        return first.length > 0 ? first.toUpperCase() : "--"
    }

    function totalUsageText() {
        const rx = Number(vpnController.rxBytes || 0)
        const tx = Number(vpnController.txBytes || 0)
        const formatted = root.formatTrafficValue(Math.max(0, rx + tx), dashboardStatsSettings.trafficUnit)
        return formatted.value + " " + formatted.unit
    }

    function formatDuration(totalSeconds) {
        const seconds = Math.max(0, Math.floor(Number(totalSeconds || 0)))
        const h = Math.floor(seconds / 3600)
        const m = Math.floor((seconds % 3600) / 60)
        const s = seconds % 60
        const pad = function(value) { return value < 10 ? "0" + value : "" + value }
        return pad(h) + ":" + pad(m) + ":" + pad(s)
    }

    function serverMetaPreview() {
        const meta = (root.selectedServerMeta || "").trim()
        if (meta.length === 0 || meta === "Import and select a profile" || meta === "Profile is selected")
            return meta
        return meta.split("|")[0].trim()
    }

    function routeText() {
        const count = (vpnController.routingRuleItems || []).length
        if (count > 0)
            return "Smart Route"
        return "Default"
    }

    function dnsText() {
        const dns = (vpnController.customDnsServers || "").trim()
        return dns.length > 0 ? "Custom DNS" : "Secure DNS"
    }

    function coreText() {
        const version = (vpnController.xrayVersion || "").trim()
        if (version.length === 0 || version === "Unknown" || version === "Unavailable" || version === "Not detected")
            return "Checking"
        return "Healthy"
    }

    function normalizeLogLine(line) {
        return String(line || "")
            .replace(/^\[[^\]]+\]\s*/, "")
            .replace(/\s+/g, " ")
            .trim()
    }

    function connectionHistory() {
        const logs = vpnController.connectionHistory || []
        const events = []
        for (let i = 0; i < logs.length && events.length < 5; ++i) {
            const line = normalizeLogLine(logs[i])
            if (line.length > 0)
                events.push(line)
        }
        return events
    }

    function connectionHistoryCount() {
        return connectionHistory().length
    }

    function connectionHistoryText(indexFromTop) {
        return connectionHistory()[indexFromTop] || ""
    }

    function connectionHistoryColor(indexFromTop) {
        const lower = connectionHistoryText(indexFromTop).toLowerCase()
        if (lower.indexOf("failed") >= 0
                || lower.indexOf("terminated") >= 0
                || lower.indexOf("disconnected") >= 0
                || lower.indexOf("disconnect") >= 0)
            return Colors.dsDanger
        if (lower.indexOf("waiting") >= 0 || lower.indexOf("retry") >= 0)
            return accentYellow
        if (lower.indexOf("connected") >= 0
                || lower.indexOf("established") >= 0
                || lower.indexOf("started") >= 0
                || lower.indexOf("active") >= 0)
            return accentGreen
        return textMuted
    }

    function securityLabel(propertyName) {
        const status = vpnController.securityStatus
        if (!status)
            return "Unknown"
        if (propertyName === "killSwitch")
            return status.killSwitchLabel || "Unknown"
        if (propertyName === "dnsLeak")
            return status.dnsLeakLabel || "Unknown"
        if (propertyName === "ipv6Leak")
            return status.ipv6LeakLabel || "Unknown"
        if (propertyName === "encryption")
            return status.encryptionLabel || "Unknown"
        return "Unknown"
    }

    function securityValueColor(label) {
        if (label === "Active" || label === "Protected" || label === "Blocked")
            return accentGreen
        if (label === "Leaking")
            return Colors.dsDanger
        if (label === "Inactive" && connected)
            return accentYellow
        if (label === "Unknown" || label === "Unsupported" || label === "Not Available")
            return textMuted
        return textStrong
    }

    function currentNavAction() {
        if (profilePopup.visible || importPopup.visible)
            return "profiles"
        if (logsPopup.visible)
            return "logs"
        if (dataUsagePopup.visible)
            return "traffic"
        if (settingsPopup.visible) {
            if (root.settingsSection === "routing" || root.settingsSection === "dns" || root.settingsSection === "connection")
                return "routing"
            if (root.settingsSection === "lan")
                return "lan"
            return "settings"
        }
        return "dashboard"
    }

    function navSelected(action) {
        return currentNavAction() === action
    }

    function closeDrawer(popup) {
        if (popup && popup.visible)
            popup.close()
    }

    function closeDesktopDrawersExcept(exceptName) {
        if (exceptName !== "profiles")
            closeDrawer(profilePopup)
        if (exceptName !== "settings")
            closeDrawer(settingsPopup)
        if (exceptName !== "logs")
            closeDrawer(logsPopup)
        if (exceptName !== "diagnostics")
            closeDrawer(speedTestPopup)
        if (exceptName !== "traffic")
            closeDrawer(dataUsagePopup)
        if (exceptName !== "import")
            closeDrawer(importPopup)
    }

    function openSettingsDrawer(section) {
        closeDesktopDrawersExcept("settings")
        root.openSettingsSection(section)
    }

    function openDiagnosticsDrawer() {
        closeDesktopDrawersExcept("diagnostics")
        speedTestPopup.open()
    }

    function openNav(action) {
        if (action === "dashboard") {
            closeDesktopDrawersExcept("")
        } else if (action === "profiles") {
            closeDesktopDrawersExcept("profiles")
            profilePopup.open()
        } else if (action === "routing") {
            openSettingsDrawer("routing")
        } else if (action === "traffic") {
            closeDesktopDrawersExcept("traffic")
            if (dataUsagePopup)
                dataUsagePopup.open()
            else
                openSettingsDrawer("logs")
        } else if (action === "lan") {
            openSettingsDrawer("lan")
        } else if (action === "logs") {
            closeDesktopDrawersExcept("logs")
            logsPopup.open()
        } else if (action === "settings") {
            openSettingsDrawer("main")
        }
    }

    component IconBubble: Rectangle {
        id: bubble
        property string glyph: ""
        property color accent: desktop.accentBlue
        property color fill: Qt.rgba(accent.r, accent.g, accent.b, Colors.lightMode ? 0.10 : 0.20)
        property real iconSize: 13
        property bool interactive: false
        signal clicked()

        width: 34
        height: 34
        radius: Math.min(width, height) / 2
        color: interactive && bubbleMouse.containsMouse
               ? Qt.rgba(accent.r, accent.g, accent.b, Colors.lightMode ? 0.16 : 0.30)
               : fill
        border.width: 1
        border.color: interactive && bubbleMouse.containsMouse
                      ? Qt.rgba(accent.r, accent.g, accent.b, 0.38)
                      : Qt.rgba(accent.r, accent.g, accent.b, Colors.lightMode ? 0.12 : 0.30)
        scale: interactive && bubbleMouse.pressed ? 0.96 : 1.0

        Behavior on scale { NumberAnimation { duration: 90 } }

        Text {
            anchors.centerIn: parent
            text: bubble.glyph
            color: bubble.accent
            font.family: root.faSolid
            font.pixelSize: bubble.iconSize
        }

        MouseArea {
            id: bubbleMouse
            anchors.fill: parent
            enabled: bubble.interactive
            hoverEnabled: bubble.interactive
            cursorShape: bubble.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: bubble.clicked()
        }
    }

    component TopActionButton: Rectangle {
        id: actionButton
        property string label: ""
        property string glyph: ""
        property color accent: desktop.accentBlue
        signal clicked()

        Layout.preferredWidth: Math.max(112, labelText.implicitWidth + 48)
        Layout.preferredHeight: 38
        radius: 12
        color: actionMouse.pressed
               ? root.themeColorToken("mainHex_eaf2ff", "mainHex_223753")
               : (actionMouse.containsMouse ? root.themeColorToken("mainHex_f3f6fb", "mainHex_20314b") : desktop.softBg)
        border.width: 1
        border.color: actionMouse.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.26) : "transparent"

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: actionButton.glyph
                color: actionButton.accent
                font.family: root.faSolid
                font.pixelSize: 15
            }

            Text {
                id: labelText
                text: actionButton.label
                color: desktop.textStrong
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 13
                font.bold: true
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: actionButton.clicked()
        }
    }

    component SidebarButton: Rectangle {
        id: navItem
        property string label: ""
        property string glyph: ""
        property string action: ""
        property bool selected: false

        Layout.fillWidth: true
        Layout.preferredHeight: 48
        radius: 10
        topLeftRadius: 0
        bottomLeftRadius: 0
        color: selected ? root.themeColorToken("mainHex_eaf2ff", "mainHex_223753")
                        : (navMouse.containsMouse ? root.themeColorToken("mainHex_f3f6fb", "mainHex_20314b") : "transparent")
        border.width: selected ? 0 : 1
        border.color: navMouse.containsMouse ? desktop.borderColor : "transparent"

        Rectangle {
            visible: selected
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 3
            radius: 2
            color: desktop.accentBlue
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 32
            anchors.rightMargin: 14
            spacing: 14

            Text {
                text: navItem.glyph
                color: navItem.selected ? desktop.accentBlue : desktop.textMuted
                font.family: root.faSolid
                font.pixelSize: 16
                Layout.preferredWidth: 20
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                Layout.fillWidth: true
                text: navItem.label
                color: navItem.selected ? desktop.accentBlue : desktop.textStrong
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 14
                font.bold: navItem.selected
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: desktop.openNav(navItem.action)
        }
    }

    component SessionRow: Item {
        id: sessionRow
        property string glyph: ""
        property string label: ""
        property string value: ""
        property color accent: desktop.accentBlue
        property color valueColor: desktop.textStrong
        property var series: []
        property bool emphasized: false

        Layout.fillWidth: true
        Layout.preferredHeight: 34

        RowLayout {
            anchors.fill: parent
            spacing: 9

            IconBubble {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                glyph: sessionRow.glyph
                accent: sessionRow.accent
                fill: Qt.rgba(sessionRow.accent.r, sessionRow.accent.g, sessionRow.accent.b, Colors.lightMode ? 0.08 : 0.16)
                iconSize: 10
            }

            Text {
                Layout.fillWidth: true
                text: sessionRow.label
                color: desktop.textMuted
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            Text {
                text: sessionRow.value
                color: sessionRow.valueColor
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 12
                font.bold: sessionRow.emphasized
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
                Layout.maximumWidth: 124
            }

            Sparkline {
                visible: sessionRow.series.length > 0
                values: sessionRow.series
                lineColor: sessionRow.accent
                Layout.preferredWidth: 66
                Layout.preferredHeight: 22
            }
        }
    }

    component SessionGroupLabel: Text {
        Layout.fillWidth: true
        Layout.topMargin: 6
        Layout.bottomMargin: 2
        color: desktop.textMuted
        font.family: FontSystem.getContentFontBold.name
        font.pixelSize: 11
        font.bold: true
        font.capitalization: Font.AllUppercase
    }

    component MetricSummaryCard: Rectangle {
        id: metricCard
        property string title: ""
        property string value: ""
        property string unit: ""
        property string glyph: ""
        property color accent: desktop.accentBlue
        property var values: []

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 12
        color: "transparent"
        border.width: 0

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: metricCard.glyph
                    color: metricCard.accent
                    font.family: root.faSolid
                    font.pixelSize: 15
                }

                Text {
                    Layout.fillWidth: true
                    text: metricCard.title
                    color: desktop.textStrong
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Controls.NumberFlowText {
                    text: metricCard.value
                    color: desktop.textStrong
                    fontSize: 24
                    bold: true
                    animated: root.powerVisualAnimationsEnabled
                }

                Text {
                    text: metricCard.unit
                    color: desktop.textMuted
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 13
                }
            }

            Sparkline {
                Layout.fillWidth: true
                Layout.fillHeight: true
                values: metricCard.values
                lineColor: metricCard.accent
            }
        }
    }

    component Sparkline: Canvas {
        id: spark
        property var values: []
        property color lineColor: desktop.accentBlue
        property color gridColor: root.themeColorToken("mainHex_e6ebf3", "mainHex_334b67")
        property bool fillArea: true
        property real strokeWidth: 1.45

        function rgbaString(colorValue, alpha) {
            return "rgba("
                    + Math.round(colorValue.r * 255) + ","
                    + Math.round(colorValue.g * 255) + ","
                    + Math.round(colorValue.b * 255) + ","
                    + alpha + ")"
        }

        antialiasing: root.powerEffectsEnabled
        onValuesChanged: requestPaint()
        onLineColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            const data = values || []
            if (data.length < 2) {
                return
            }

            let maxValue = 0
            for (let i = 0; i < data.length; ++i)
                maxValue = Math.max(maxValue, Number(data[i]) || 0)
            maxValue = Math.max(1.0, maxValue * 1.12)

            ctx.strokeStyle = lineColor
            ctx.lineWidth = strokeWidth
            ctx.lineJoin = "round"
            ctx.lineCap = "round"
            ctx.shadowColor = root.powerEffectsEnabled ? rgbaString(lineColor, 0.38) : "transparent"
            ctx.shadowBlur = root.powerEffectsEnabled ? 4 : 0
            ctx.beginPath()
            for (let j = 0; j < data.length; ++j) {
                const x = data.length === 1 ? width : (j / (data.length - 1)) * width
                const normalized = Math.max(0, Math.min(1, (Number(data[j]) || 0) / maxValue))
                const y = height - 4 - normalized * (height - 8)
                if (j === 0)
                    ctx.moveTo(x, y)
                else
                    ctx.lineTo(x, y)
            }
            ctx.stroke()

            if (fillArea) {
                ctx.shadowBlur = 0
                ctx.lineTo(width, height - 4)
                ctx.lineTo(0, height - 4)
                ctx.closePath()
                const fill = ctx.createLinearGradient(0, 0, 0, height)
                fill.addColorStop(0.0, rgbaString(lineColor, 0.20))
                fill.addColorStop(1.0, rgbaString(lineColor, 0.03))
                ctx.fillStyle = fill
                ctx.fill()
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: pageBg
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        z: 0
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        z: 1

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 74
            color: cardBg
            border.width: 0

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: borderColor
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 20
                spacing: 8

                RowLayout {
                    Layout.preferredWidth: 244
                    spacing: 10

                    Image {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        source: logoSource
                        sourceSize.width: 60
                        sourceSize.height: 60
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "<strong>GENY</strong>CONNECT"
                        textFormat: Text.RichText
                        color: root.themeColor(root.brandInk, Colors.mainHex_e5edf9)
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 20
                        elide: Text.ElideRight
                    }
                }

                Item { Layout.fillWidth: true }

                TopActionButton {
                    label: "Quick Connect"
                    glyph: "\uf0e7"
                    accent: accentBlue
                    onClicked: root.handleConnectAction()
                }

                TopActionButton {
                    label: "Diagnostics"
                    glyph: root.iconSpeed
                    accent: Colors.dsLinkIconPurple
                    onClicked: openDiagnosticsDrawer()
                }

                TopActionButton {
                    label: "Update"
                    glyph: "\uf019"
                    accent: accentBlue
                    onClicked: {
                        openSettingsDrawer("updates")
                        updater.checkForUpdates(true)
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 20
                    color: settingsMouse.containsMouse ? softBg : root.themeColorToken("mainHex_f3f6fb", "mainHex_20314b")

                    Text {
                        anchors.centerIn: parent
                        text: root.iconGear
                        color: textStrong
                        font.family: root.faSolid
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: settingsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: openSettingsDrawer("main")
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Rectangle {
                Layout.preferredWidth: 224
                Layout.fillHeight: true
                color: root.themeColorToken("mainHex_f7f9fc", "mainHex_111425")
                border.width: 0

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: borderColor
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: 14
                    anchors.leftMargin: 0
                    anchors.rightMargin: 14
                    anchors.bottomMargin: 22
                    spacing: 8

                    SidebarButton { label: "Dashboard"; glyph: "\uf015"; selected: desktop.navSelected("dashboard"); action: "dashboard" }
                    SidebarButton { label: "Profiles"; glyph: "\uf007"; selected: desktop.navSelected("profiles"); action: "profiles" }
                    SidebarButton { label: "Routing"; glyph: "\uf542"; selected: desktop.navSelected("routing"); action: "routing" }
                    SidebarButton { label: "Traffic"; glyph: root.iconUsage; selected: desktop.navSelected("traffic"); action: "traffic" }
                    SidebarButton { label: "LAN Sharing"; glyph: "\uf108"; selected: desktop.navSelected("lan"); action: "lan" }
                    SidebarButton { label: "Logs"; glyph: "\uf15c"; selected: desktop.navSelected("logs"); action: "logs" }
                    SidebarButton { label: "Settings"; glyph: root.iconGear; selected: desktop.navSelected("settings"); action: "settings" }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 88
                        Layout.leftMargin: 14
                        radius: 12
                        color: cardBg
                        border.width: 1
                        border.color: borderColor

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 12

                            IconBubble {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 34
                                glyph: root.iconShield
                                accent: accentGreen
                                fill: Qt.rgba(accentGreen.r, accentGreen.g, accentGreen.b, 0.14)
                                iconSize: 13
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: "Core Status"
                                    color: textStrong
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: coreText()
                                    color: coreText() === "Healthy" ? accentGreen : accentYellow
                                    font.family: FontSystem.getContentFontBold.name
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                Text {
                                    text: "Xray Core " + ((vpnController.xrayVersion || "").trim().length > 0 ? vpnController.xrayVersion : "--")
                                    color: textMuted
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 7
                                Layout.preferredHeight: 7
                                radius: 4
                                color: coreText() === "Healthy" ? accentGreen : accentYellow
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 12
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    Rectangle {
                        id: connectionCard
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 390
                        Layout.preferredHeight: 480
                        radius: 14
                        color: cardBg
                        border.width: 1
                        border.color: borderColor
                        clip: true

                        Text {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.leftMargin: 24
                            anchors.topMargin: 22
                            text: "Connection"
                            color: textStrong
                            font.family: FontSystem.getContentFontBold.name
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.leftMargin: 24
                            anchors.topMargin: 50
                            width: heroStateText.implicitWidth + 26
                            height: 28
                            radius: 14
                            color: Qt.rgba(statusColor().r, statusColor().g, statusColor().b, Colors.lightMode ? 0.10 : 0.18)
                            border.width: 1
                            border.color: Qt.rgba(statusColor().r, statusColor().g, statusColor().b, Colors.lightMode ? 0.16 : 0.28)

                            Row {
                                anchors.centerIn: parent
                                spacing: 8

                                Rectangle {
                                    width: 7
                                    height: 7
                                    radius: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: statusColor()
                                }

                                Text {
                                    id: heroStateText
                                    text: root.stateText()
                                    color: statusColor()
                                    font.family: FontSystem.getContentFontBold.name
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.rightMargin: 24
                            anchors.topMargin: 18
                            spacing: 8

                            IconBubble {
                                width: 30
                                height: 30
                                glyph: "\uf0e7"
                                accent: accentBlue
                                interactive: true
                                onClicked: openSettingsDrawer("power")
                            }
                            IconBubble {
                                width: 30
                                height: 30
                                glyph: root.iconSpeed
                                accent: Colors.dsLinkIconPurple
                                interactive: true
                                onClicked: openDiagnosticsDrawer()
                            }
                        }

                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 42
                            spacing: 4

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: formatDuration(root.sessionSeconds)
                                color: root.themeColorToken("mainHex_050505", "mainHex_d8e1f0")
                                font.family: FontSystem.getContentFontBold.name
                                font.pixelSize: Math.max(42, Math.min(58, connectionCard.width * 0.066))
                                font.bold: true
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Last Usage: " + root.latestUsageValuePart() + " " + root.latestUsageUnitPart()
                                color: root.themeColorToken("mainHex_4f5d70", "mainHex_9fb4cd")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 15

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 88
                                    text: ""
                                }
                            }
                        }

                        Image {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: 32
                            width: Math.min(parent.width * 0.90, 720)
                            height: Math.min(parent.height * 0.54, 310)
                            source: root.mapPrimarySource
                            fillMode: Image.PreserveAspectFit
                            opacity: Colors.lightMode ? 0.18 : 0.12
                            smooth: true
                        }

                        Item {
                            id: powerCluster
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: 22
                            width: 216
                            height: 216
                            property color ringColor: root.heroPowerRingColor()

                            Repeater {
                                model: 3
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 136 + index * 32
                                    height: width
                                    radius: width / 2
                                    color: Qt.rgba(powerCluster.ringColor.r, powerCluster.ringColor.g, powerCluster.ringColor.b, Colors.lightMode ? 0.12 - index * 0.025 : 0.16 - index * 0.030)
                                    border.width: 1
                                    border.color: Qt.rgba(powerCluster.ringColor.r, powerCluster.ringColor.g, powerCluster.ringColor.b, 0.08)
                                    visible: connected || connecting
                                }
                            }

                            Controls.PowerModeParticleEffect {
                                anchors.fill: parent
                                visible: active
                                active: vpnController.connectionState !== ConnectionState.Disconnected
                                        && (root.powerEffectsEnabled || vpnController.powerMode === "Save")
                                animationsEnabled: root.powerVisualAnimationsEnabled || vpnController.powerMode === "Save"
                                modeName: vpnController.powerMode
                                intensity: vpnController.powerMode === "High Performance" ? 1.52
                                           : (vpnController.powerMode === "Save" ? 0.86 : 1.0)
                                velocityScale: root.heroParticleSpeedFactor()
                                accentColor: powerCluster.ringColor
                            }

                            Rectangle {
                                id: powerButton
                                anchors.centerIn: parent
                                width: 138
                                height: 138
                                radius: 69
                                color: root.heroPowerCoreColor()
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.35)
                                scale: powerMouse.pressed ? 0.97 : 1.0

                                Behavior on color { ColorAnimation { duration: 180 } }
                                Behavior on scale { NumberAnimation { duration: 90 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf0e7"
                                    color: Colors.mainHex_ffffff
                                    font.family: root.faSolid
                                    font.pixelSize: 46
                                }

                                MouseArea {
                                    id: powerMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.handleConnectAction()
                                }
                            }
                        }

                        Rectangle {
                            id: serverPill
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottomMargin: 18
                            width: Math.min(parent.width - 40, 600)
                            height: 64
                            radius: 28
                            color: softBg
                            border.width: 1
                            border.color: root.themeColorToken("mainHex_e6ebf3", "mainHex_334b67")

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 12
                                spacing: 10

                                IconBubble {
                                    Layout.preferredWidth: 36
                                    Layout.preferredHeight: 36
                                    glyph: root.iconShield
                                    accent: accentGreen
                                    fill: Qt.rgba(accentGreen.r, accentGreen.g, accentGreen.b, 0.14)
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: root.selectedServerLabel
                                        color: textStrong
                                        font.family: FontSystem.getContentFontBold.name
                                        font.pixelSize: 16
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: serverMetaPreview()
                                        color: textMuted
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                }

                                Controls.SignalBars {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 26
                                    level: root.currentProfileSignalLevel()
                                    activeColor: root.currentProfileSignalColor()
                                }

                                Text {
                                    text: root.currentProfilePingText()
                                    color: accentBlue
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 12
                                }

                                Rectangle {
                                    Layout.preferredWidth: 1
                                    Layout.fillHeight: true
                                    Layout.topMargin: 12
                                    Layout.bottomMargin: 12
                                    color: borderColor
                                }

                                Text {
                                    text: root.iconChevronDown
                                    color: textMuted
                                    font.family: root.faSolid
                                    font.pixelSize: 12
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: desktop.openNav("profiles")
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 218
                        spacing: 12

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 14
                            color: cardBg
                            border.width: 1
                            border.color: borderColor

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 18
                                spacing: 14

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Traffic Overview"
                                        color: textStrong
                                        font.family: FontSystem.getContentFontBold.name
                                        font.pixelSize: 15
                                        font.bold: true
                                    }

                                    Text {
                                        text: totalUsageText()
                                        color: textMuted
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 12

                                    MetricSummaryCard {
                                        title: "Downlink"
                                        glyph: "\uf063"
                                        accent: accentGreen
                                        value: root.formatSpeedValue(Math.max(0, root.downRateBytesPerSec), dashboardStatsSettings.speedUnit).value
                                        unit: root.formatSpeedValue(Math.max(0, root.downRateBytesPerSec), dashboardStatsSettings.speedUnit).unit
                                        values: root.downRateHistoryMbps
                                    }

                                    MetricSummaryCard {
                                        title: "Uplink"
                                        glyph: "\uf062"
                                        accent: accentYellow
                                        value: root.formatSpeedValue(Math.max(0, root.upRateBytesPerSec), dashboardStatsSettings.speedUnit).value
                                        unit: root.formatSpeedValue(Math.max(0, root.upRateBytesPerSec), dashboardStatsSettings.speedUnit).unit
                                        values: root.upRateHistoryMbps
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 318
                            Layout.fillHeight: true
                            radius: 14
                            color: cardBg
                            border.width: 1
                            border.color: borderColor

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 18
                                spacing: 12

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Connection History"
                                        color: textStrong
                                        font.family: FontSystem.getContentFontBold.name
                                        font.pixelSize: 15
                                        font.bold: true
                                    }

                                    Text {
                                        text: "View All"
                                        color: accentBlue
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 12

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: logsPopup.open()
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: connectionHistoryCount() === 0
                                    text: "No connection history yet."
                                    color: textMuted
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 12
                                }

                                Repeater {
                                    model: connectionHistoryCount()

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 9

                                        Rectangle {
                                            Layout.preferredWidth: 6
                                            Layout.preferredHeight: 6
                                            radius: 3
                                            color: connectionHistoryColor(index)
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: connectionHistoryText(index)
                                            color: textStrong
                                            font.family: FontSystem.contentFontFamily
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                        }
                                    }
                                }

                                Item { Layout.fillHeight: true }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 318
                    Layout.fillHeight: true
                    radius: 14
                    color: cardBg
                    border.width: 1
                    border.color: borderColor

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 4

                        Text {
                            text: "Session Info"
                            color: textStrong
                            font.family: FontSystem.getContentFontBold.name
                            font.pixelSize: 16
                            font.bold: true
                            Layout.bottomMargin: 8
                        }

                        SessionGroupLabel { text: "Connection" }

                        SessionRow {
                            glyph: "\uf3ed"
                            label: "Status"
                            value: root.stateText()
                            valueColor: statusColor()
                            accent: accentBlue
                            emphasized: true
                        }
                        SessionRow { glyph: "\uf542"; label: "Protocol"; value: protocolText(); accent: accentBlue; emphasized: true }
                        SessionRow { glyph: "\uf108"; label: "Mode"; value: modeText(); accent: accentBlue; emphasized: true }
                        SessionRow { glyph: "\uf233"; label: "Server"; value: root.selectedServerLabel + " " + root.selectedServerFlag; accent: accentBlue; emphasized: true }
                        SessionRow { glyph: "\uf3c5"; label: "IP Address"; value: root.infoIpText(); accent: accentBlue; valueColor: accentBlue }
                        SessionRow { glyph: "\uf625"; label: "Latency"; value: root.currentProfilePingText(); accent: accentBlue; valueColor: accentBlue; emphasized: true }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: borderColor
                            Layout.topMargin: 6
                            Layout.bottomMargin: 2
                        }

                        SessionGroupLabel { text: "Security" }

                        SessionRow {
                            glyph: "\uf3ed"
                            label: "Kill Switch"
                            value: securityLabel("killSwitch")
                            valueColor: securityValueColor(securityLabel("killSwitch"))
                            accent: securityValueColor(securityLabel("killSwitch"))
                            emphasized: securityLabel("killSwitch") !== "Unknown"
                        }
                        SessionRow {
                            glyph: "\uf57d"
                            label: "DNS Leak"
                            value: securityLabel("dnsLeak")
                            valueColor: securityValueColor(securityLabel("dnsLeak"))
                            accent: securityValueColor(securityLabel("dnsLeak"))
                            emphasized: securityLabel("dnsLeak") !== "Unknown"
                        }
                        SessionRow {
                            glyph: "\uf0ac"
                            label: "IPv6 Leak"
                            value: securityLabel("ipv6Leak")
                            valueColor: securityValueColor(securityLabel("ipv6Leak"))
                            accent: securityValueColor(securityLabel("ipv6Leak"))
                            emphasized: securityLabel("ipv6Leak") !== "Unknown"
                        }
                        SessionRow {
                            glyph: "\uf023"
                            label: "Encryption"
                            value: securityLabel("encryption")
                            valueColor: securityValueColor(securityLabel("encryption"))
                            accent: securityValueColor(securityLabel("encryption"))
                            emphasized: securityLabel("encryption") !== "Unknown"
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: borderColor
                            Layout.topMargin: 6
                            Layout.bottomMargin: 2
                        }

                        SessionGroupLabel { text: "System" }

                        SessionRow { glyph: "\uf0e7"; label: "Power Mode"; value: (vpnController.powerMode || "Normal"); valueColor: accentGreen; accent: accentBlue; emphasized: true }
                        SessionRow { glyph: "\uf542"; label: "Routing"; value: routeText(); accent: accentBlue; emphasized: true }
                        SessionRow { glyph: "\uf57d"; label: "DNS"; value: dnsText(); accent: accentBlue; emphasized: true }
                        SessionRow { glyph: "\uf1b2"; label: "Core"; value: coreText(); valueColor: coreText() === "Healthy" ? accentGreen : accentYellow; accent: accentBlue; emphasized: true }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}
