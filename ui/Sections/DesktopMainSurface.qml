// Copyright (C) 2026 Genyleap Labs.
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
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

    readonly property color pageBg: Colors.dsWindow
    readonly property color cardBg: Colors.dsSurface
    readonly property color softBg: Colors.dsSurfaceSoft
    readonly property color borderColor: Colors.dsBorder
    readonly property color textStrong: Colors.dsText
    readonly property color textMuted: Colors.dsTextMuted
    readonly property color accentBlue: Colors.dsLinkIconBlue
    readonly property color accentGreen: Colors.dsSuccess
    readonly property color accentYellow: Colors.dsWarning
    readonly property string logoSource: "qrc:/ui/Resources/image/GenyConnect-Circle.png"
    readonly property bool connected: vpnController.connectionState === ConnectionState.Connected
    readonly property bool connecting: vpnController.connectionState === ConnectionState.Connecting
    readonly property bool errorState: vpnController.connectionState === ConnectionState.Error
    // The full dashboard needs enough room for the sidebar, the hero and the
    // session inspector.  Collapse secondary panels before layouts can overlap.
    readonly property bool narrowLayout: width < 1160
    readonly property bool shortLayout: height < 720

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
        return root.privacyMaskedEndpointText(meta.split("|")[0].trim())
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

    function localizedConnectionHistoryText(indexFromTop) {
        const original = connectionHistoryText(indexFromTop)
        const match = original.match(/^(\d{1,2}:\d{2}:\d{2})\s+(Connected|Disconnected|Connecting|Waiting|Failed|Active)(?:\s+(.*))?$/i)
        if (!match)
            return original
        const statusKey = match[2].charAt(0).toUpperCase() + match[2].slice(1).toLowerCase()
        const detail = (match[3] || "").trim()
        return I18n.ltr(match[1]) + "  " + I18n.t(statusKey)
                + (detail.length > 0 ? ("  " + I18n.ltr(detail)) : "")
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

    function revealSidebarItem(item) {
        const itemTop = item.mapToItem(sidebarNavColumn, 0, 0).y
        const itemBottom = itemTop + item.height
        let nextY = sidebarNavFlick.contentY
        if (itemTop < nextY)
            nextY = itemTop
        else if (itemBottom > nextY + sidebarNavFlick.height)
            nextY = itemBottom - sidebarNavFlick.height
        sidebarNavFlick.contentY = Math.max(0, Math.min(nextY, Math.max(0, sidebarNavFlick.contentHeight - sidebarNavFlick.height)))
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

    component TopActionButton: Basic.Button {
        id: actionButton
        property string label: ""
        property string glyph: ""
        property color accent: desktop.accentBlue
        Layout.preferredWidth: Math.max(112, labelText.implicitWidth + 52)
        Layout.preferredHeight: 40
        padding: 12
        hoverEnabled: true
        focusPolicy: Qt.StrongFocus
        Accessible.name: I18n.t(label)

        background: Rectangle {
            radius: 12
            color: actionButton.down ? Colors.dsPrimaryTint
                                    : (actionButton.hovered ? Colors.dsSurfaceElevated : desktop.softBg)
            border.width: actionButton.activeFocus ? 2 : 1
            border.color: actionButton.activeFocus ? Colors.dsPrimarySolid
                                                  : (actionButton.hovered ? desktop.borderColor : "transparent")
        }

        contentItem: RowLayout {
            spacing: 8

            Text {
                text: actionButton.glyph
                color: actionButton.accent
                font.family: root.faSolid
                font.pixelSize: 15
                font.weight: Font.Black
            }

            Text {
                id: labelText
                text: I18n.t(actionButton.label)
                color: desktop.textStrong
                font.family: FontSystem.getContentFontMedium.name
                font.pixelSize: 13
                font.weight: Font.Medium
            }
        }
    }

    component SidebarButton: Basic.ItemDelegate {
        id: navItem
        property string label: ""
        property string glyph: ""
        property string navAction: ""
        property bool selected: false

        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(52, navLabel.implicitHeight + 24)
        leftPadding: 12
        rightPadding: 12
        topPadding: 10
        bottomPadding: 10
        hoverEnabled: true
        focusPolicy: Qt.StrongFocus
        text: I18n.t(label)
        Accessible.name: text
        onClicked: desktop.openNav(navAction)
        onActiveFocusChanged: {
            if (activeFocus)
                desktop.revealSidebarItem(navItem)
        }

        background: Rectangle {
            radius: 12
            color: navItem.selected || navItem.down ? Colors.dsPrimaryTint
                                                   : (navItem.hovered ? Colors.dsSurfaceSoft : "transparent")
            border.width: navItem.activeFocus ? 2 : 1
            border.color: navItem.activeFocus ? Colors.dsPrimarySolid
                                             : (navItem.selected ? Qt.rgba(desktop.accentBlue.r, desktop.accentBlue.g, desktop.accentBlue.b, 0.20)
                                                                 : (navItem.hovered ? Colors.dsBorderSoft : "transparent"))
        }

        contentItem: RowLayout {
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                radius: 9
                color: navItem.selected ? Qt.rgba(desktop.accentBlue.r, desktop.accentBlue.g, desktop.accentBlue.b, Colors.lightMode ? 0.09 : 0.13) : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: navItem.glyph
                    color: navItem.selected ? desktop.accentBlue : desktop.textMuted
                    font.family: root.faSolid
                    font.pixelSize: 16
                    font.weight: Font.Black
                }
            }

            Text {
                id: navLabel
                Layout.fillWidth: true
                text: navItem.text
                color: navItem.selected ? desktop.accentBlue : desktop.textStrong
                font.family: navItem.selected ? FontSystem.getContentFontBold.name : FontSystem.getContentFontMedium.name
                font.pixelSize: 14
                font.weight: navItem.selected ? Font.Bold : Font.Medium
                wrapMode: Text.WordWrap
                // The row inherits mirroring; text alignment is set once here.
                LayoutMirroring.enabled: false
                horizontalAlignment: I18n.isRtl ? Text.AlignRight : Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }
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
        property bool technicalValue: false

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
                text: I18n.t(sessionRow.label)
                color: desktop.textMuted
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 12
                elide: Text.ElideRight
                LayoutMirroring.enabled: false
                horizontalAlignment: I18n.isRtl ? Text.AlignRight : Text.AlignLeft
            }

            Text {
                text: sessionRow.technicalValue ? I18n.ltr(sessionRow.value) : I18n.t(sessionRow.value)
                color: sessionRow.valueColor
                font.family: sessionRow.technicalValue && !FontSystem.usePersianArabicFont
                             ? FontSystem.technicalFontFamily : FontSystem.contentFontFamily
                font.pixelSize: 12
                font.bold: sessionRow.emphasized
                horizontalAlignment: I18n.isRtl ? Text.AlignLeft : Text.AlignRight
                LayoutMirroring.enabled: false
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
        LayoutMirroring.enabled: false
        horizontalAlignment: I18n.isRtl ? Text.AlignRight : Text.AlignLeft
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
                    text: I18n.t(metricCard.title)
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
                    text: I18n.localizeDisplay(metricCard.value)
                    color: desktop.textStrong
                    fontSize: 24
                    bold: true
                    animated: root.powerVisualAnimationsEnabled
                }

                Text {
                    text: I18n.t(metricCard.unit)
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
                        text: I18n.language === "fa" ? I18n.t("GenyConnect") : "<strong>GENY</strong>CONNECT"
                        textFormat: I18n.language === "fa" ? Text.PlainText : Text.RichText
                        LayoutMirroring.enabled: false
                        color: root.themeColor(root.brandInk, Colors.mainHex_e5edf9)
                        font.family: I18n.language === "fa" ? FontSystem.getContentFontBold.name : FontSystem.technicalFontFamily
                        font.weight: I18n.language === "fa" ? Font.Bold : Font.Normal
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

                Controls.CircleIconButton {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    diameter: 40
                    backgroundColor: desktop.softBg
                    borderColor: "transparent"
                    iconText: root.iconGear
                    iconColor: desktop.textStrong
                    iconFontFamily: root.faSolid
                    iconPixelSize: 16
                    elevated: false
                    accessibleName: I18n.t("Settings")
                    onClicked: openSettingsDrawer("main")
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Rectangle {
                Layout.preferredWidth: desktop.narrowLayout
                                       ? (I18n.isRtl ? 224 : 190)
                                       : (I18n.isRtl ? 282 : 238)
                Layout.fillHeight: true
                color: Colors.dsWindow
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
                    anchors.margins: desktop.narrowLayout ? 12 : 14
                    spacing: 16

                    Flickable {
                        id: sidebarNavFlick
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: sidebarNavColumn.implicitHeight
                        flickableDirection: Flickable.VerticalFlick
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true
                        onHeightChanged: contentY = Math.max(0, Math.min(contentY, Math.max(0, contentHeight - height)))
                        Basic.ScrollIndicator.vertical: Basic.ScrollIndicator { }

                        ColumnLayout {
                            id: sidebarNavColumn
                            width: sidebarNavFlick.width
                            spacing: 6

                            SidebarButton { label: "Dashboard"; glyph: "\uf015"; selected: desktop.navSelected("dashboard"); navAction: "dashboard" }
                            SidebarButton { label: "Profiles"; glyph: "\uf007"; selected: desktop.navSelected("profiles"); navAction: "profiles" }
                            SidebarButton { label: "Routing"; glyph: "\uf542"; selected: desktop.navSelected("routing"); navAction: "routing" }
                            SidebarButton { label: "Traffic"; glyph: root.iconUsage; selected: desktop.navSelected("traffic"); navAction: "traffic" }
                            SidebarButton { label: "LAN Sharing"; glyph: "\uf108"; selected: desktop.navSelected("lan"); navAction: "lan" }
                            SidebarButton { label: "Logs"; glyph: "\uf15c"; selected: desktop.navSelected("logs"); navAction: "logs" }
                            SidebarButton { label: "Settings"; glyph: root.iconGear; selected: desktop.navSelected("settings"); navAction: "settings" }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 88
                        radius: 12
                        color: cardBg
                        border.width: 1
                        border.color: borderColor

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: desktop.narrowLayout ? 10 : 16
                            spacing: desktop.narrowLayout ? 8 : 12

                            IconBubble {
                                Layout.preferredWidth: desktop.narrowLayout ? 30 : 34
                                Layout.preferredHeight: desktop.narrowLayout ? 30 : 34
                                glyph: root.iconShield
                                accent: accentGreen
                                fill: Qt.rgba(accentGreen.r, accentGreen.g, accentGreen.b, 0.14)
                                iconSize: 13
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    Layout.fillWidth: true
                                    text: I18n.t("Core Status")
                                    color: textStrong
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    LayoutMirroring.enabled: false
                                    horizontalAlignment: I18n.isRtl ? Text.AlignRight : Text.AlignLeft
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: I18n.t(coreText())
                                    color: coreText() === "Healthy" ? accentGreen : accentYellow
                                    font.family: FontSystem.getContentFontBold.name
                                    font.pixelSize: 12
                                    font.bold: true
                                    LayoutMirroring.enabled: false
                                    horizontalAlignment: I18n.isRtl ? Text.AlignRight : Text.AlignLeft
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: I18n.ltr("Xray Core " + ((vpnController.xrayVersion || "").trim().length > 0 ? vpnController.xrayVersion : "--"))
                                    LayoutMirroring.enabled: false
                                    horizontalAlignment: I18n.isRtl ? Text.AlignRight : Text.AlignLeft
                                    color: textMuted
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                visible: !desktop.narrowLayout
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
                            text: I18n.t("Connection")
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
                                    text: I18n.t(root.stateText())
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
                                text: I18n.localizeDigits(formatDuration(root.sessionSeconds))
                                color: root.themeColorToken("mainHex_050505", "mainHex_d8e1f0")
                                font.family: FontSystem.getContentFontBold.name
                                font.pixelSize: Math.max(42, Math.min(58, connectionCard.width * 0.066))
                                font.bold: true
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: I18n.t("Last Usage: %1", [I18n.ltr(root.latestUsageValuePart() + " " + root.latestUsageUnitPart())])
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
                                        Layout.fillWidth: true
                                        text: I18n.ltr(root.selectedServerLabel)
                                        LayoutMirroring.enabled: false
                                        horizontalAlignment: I18n.isRtl ? Text.AlignRight : Text.AlignLeft
                                        color: textStrong
                                        font.family: FontSystem.usePersianArabicFont
                                                     ? FontSystem.getContentFontBold.name
                                                     : FontSystem.technicalFontFamily
                                        font.pixelSize: 16
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: I18n.ltr(serverMetaPreview())
                                        LayoutMirroring.enabled: false
                                        horizontalAlignment: I18n.isRtl ? Text.AlignRight : Text.AlignLeft
                                        color: textMuted
                                        font.family: FontSystem.usePersianArabicFont
                                                     ? FontSystem.contentFontFamily
                                                     : FontSystem.technicalFontFamily
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
                                    text: I18n.ltr(root.currentProfilePingText())
                                    LayoutMirroring.enabled: false
                                    color: accentBlue
                                    font.family: FontSystem.usePersianArabicFont
                                                 ? FontSystem.contentFontFamily
                                                 : FontSystem.technicalFontFamily
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
                        visible: !desktop.shortLayout
                        Layout.fillWidth: true
                        Layout.preferredHeight: visible ? 218 : 0
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
                                        text: I18n.t("Traffic Overview")
                                        color: textStrong
                                        font.family: FontSystem.getContentFontBold.name
                                        font.pixelSize: 15
                                        font.bold: true
                                    }

                                    Text {
                                        text: I18n.localizeDisplay(totalUsageText())
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
                                        title: I18n.t("Downlink")
                                        glyph: "\uf063"
                                        accent: accentGreen
                                        value: root.formatSpeedValue(Math.max(0, root.downRateBytesPerSec), dashboardStatsSettings.speedUnit).value
                                        unit: root.formatSpeedValue(Math.max(0, root.downRateBytesPerSec), dashboardStatsSettings.speedUnit).unit
                                        values: root.downRateHistoryMbps
                                    }

                                    MetricSummaryCard {
                                        title: I18n.t("Uplink")
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
                                        text: I18n.t("Connection History")
                                        color: textStrong
                                        font.family: FontSystem.getContentFontBold.name
                                        font.pixelSize: 15
                                        font.bold: true
                                    }

                                    Text {
                                        text: I18n.t("View All")
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
                                    text: I18n.t("No connection history yet.")
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
                                            text: localizedConnectionHistoryText(index)
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
                    visible: !desktop.narrowLayout && !desktop.shortLayout
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
                            Layout.fillWidth: true
                            text: I18n.t("Session Info")
                            color: textStrong
                            font.family: FontSystem.getContentFontBold.name
                            font.pixelSize: 16
                            font.bold: true
                            Layout.bottomMargin: 8
                            LayoutMirroring.enabled: false
                            horizontalAlignment: I18n.isRtl ? Text.AlignRight : Text.AlignLeft
                        }

                        SessionGroupLabel { text: I18n.t("Connection") }

                        SessionRow {
                            glyph: "\uf3ed"
                            label: I18n.t("Status")
                            value: root.stateText()
                            valueColor: statusColor()
                            accent: accentBlue
                            emphasized: true
                        }
                        SessionRow { glyph: "\uf542"; label: I18n.t("Protocol"); value: protocolText(); accent: accentBlue; emphasized: true; technicalValue: true }
                        SessionRow { glyph: "\uf108"; label: I18n.t("Mode"); value: modeText(); accent: accentBlue; emphasized: true; technicalValue: true }
                        SessionRow { glyph: "\uf233"; label: I18n.t("Server"); value: root.selectedServerLabel + " " + root.selectedServerFlag; accent: accentBlue; emphasized: true; technicalValue: true }
                        SessionRow { glyph: "\uf3c5"; label: I18n.t("IP Address"); value: root.infoIpText(); accent: accentBlue; valueColor: accentBlue; technicalValue: true }
                        SessionRow { glyph: "\uf625"; label: I18n.t("Latency"); value: root.currentProfilePingText(); accent: accentBlue; valueColor: accentBlue; emphasized: true; technicalValue: true }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: borderColor
                            Layout.topMargin: 6
                            Layout.bottomMargin: 2
                        }

                        SessionGroupLabel { text: I18n.t("Security") }

                        SessionRow {
                            glyph: "\uf3ed"
                            label: I18n.t("Kill Switch")
                            value: securityLabel("killSwitch")
                            valueColor: securityValueColor(securityLabel("killSwitch"))
                            accent: securityValueColor(securityLabel("killSwitch"))
                            emphasized: securityLabel("killSwitch") !== "Unknown"
                        }
                        SessionRow {
                            glyph: "\uf57d"
                            label: I18n.t("DNS Leak")
                            value: securityLabel("dnsLeak")
                            valueColor: securityValueColor(securityLabel("dnsLeak"))
                            accent: securityValueColor(securityLabel("dnsLeak"))
                            emphasized: securityLabel("dnsLeak") !== "Unknown"
                        }
                        SessionRow {
                            glyph: "\uf0ac"
                            label: I18n.t("IPv6 Leak")
                            value: securityLabel("ipv6Leak")
                            valueColor: securityValueColor(securityLabel("ipv6Leak"))
                            accent: securityValueColor(securityLabel("ipv6Leak"))
                            emphasized: securityLabel("ipv6Leak") !== "Unknown"
                        }
                        SessionRow {
                            glyph: "\uf023"
                            label: I18n.t("Encryption")
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

                        SessionGroupLabel { text: I18n.t("System") }

                        SessionRow { glyph: "\uf0e7"; label: I18n.t("Power Mode"); value: I18n.t(vpnController.powerMode || "Normal"); valueColor: accentGreen; accent: accentBlue; emphasized: true }
                        SessionRow { glyph: "\uf542"; label: I18n.t("Routing"); value: I18n.t(routeText()); accent: accentBlue; emphasized: true }
                        SessionRow { glyph: "\uf57d"; label: I18n.t("DNS"); value: I18n.t(dnsText()); accent: accentBlue; emphasized: true }
                        SessionRow { glyph: "\uf1b2"; label: I18n.t("Core"); value: I18n.t(coreText()); valueColor: coreText() === "Healthy" ? accentGreen : accentYellow; accent: accentBlue; emphasized: true }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}
