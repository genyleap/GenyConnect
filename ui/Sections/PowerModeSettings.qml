/*!
 * @file        PowerModeSettingsSection.qml
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

    component PowerModeCard: Rectangle {
        id: modeCard


        property string modeName: ""
        property string summary: ""
        property string badgeText: ""
        property string glyph: ""
        property color accentColor: Colors.dsPrimarySolid
        property bool selected: false
        property bool compact: false
        property bool animated: true

        signal clicked()

        Layout.fillWidth: true
        implicitHeight: Math.max(compact ? 92 : 104, modeTextColumn.implicitHeight + (compact ? 22 : 24))
        radius: Metrics.radiusMd
        color: modeMouse.pressed
               ? Colors.dsSurfaceElevated
               : (selected
                  ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, Colors.lightMode ? 0.12 : 0.20)
                  : (modeMouse.containsMouse ? Colors.dsSurfaceSoft : Colors.dsSurface))
        border.width: selected ? 2 : 1
        border.color: modeCard.activeFocus
                      ? modeCard.accentColor
                      : (selected
                      ? accentColor
                      : (modeMouse.containsMouse ? Colors.dsBorder : Colors.dsBorderSoft))
        activeFocusOnTab: true
        focus: false
        Accessible.role: Accessible.Button
        Accessible.name: modeCard.modeName + (modeCard.selected ? " selected" : "")
        Accessible.description: modeCard.summary

        Behavior on color {
            enabled: modeCard.animated
            ColorAnimation { duration: 120 }
        }

        Behavior on border.color {
            enabled: modeCard.animated
            ColorAnimation { duration: 120 }
        }

            RowLayout {
                anchors.fill: parent
                anchors.margins: compact ? 10 : 11
                spacing: 9

                Rectangle {
                Layout.preferredWidth: compact ? 36 : 40
                Layout.preferredHeight: compact ? 36 : 40
                radius: width / 2
                color: selected
                       ? modeCard.accentColor
                       : Qt.rgba(modeCard.accentColor.r, modeCard.accentColor.g, modeCard.accentColor.b, Colors.lightMode ? 0.10 : 0.18)

                Text {
                    anchors.centerIn: parent
                    text: modeCard.glyph
                    color: selected ? Colors.dsPrimaryText : modeCard.accentColor
                    font.family: root.faSolid
                    font.pixelSize: compact ? 13 : 15
                }
            }

                ColumnLayout {
                id: modeTextColumn
                Layout.fillWidth: true
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    text: modeCard.modeName
                    color: Colors.dsText
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: compact ? Typography.uiBodyLg : Typography.uiTitleSm
                    font.bold: true
                    elide: Text.ElideRight
                }

                Controls.StatusPill {
                    visible: modeCard.badgeText.length > 0
                    text: modeCard.badgeText
                    glyph: "\uf0a3"
                    bold: true
                    pillColor: Qt.rgba(modeCard.accentColor.r, modeCard.accentColor.g, modeCard.accentColor.b, Colors.lightMode ? 0.12 : 0.20)
                    borderColor: Qt.rgba(modeCard.accentColor.r, modeCard.accentColor.g, modeCard.accentColor.b, Colors.lightMode ? 0.34 : 0.52)
                    textColor: modeCard.accentColor
                }

                Text {
                    Layout.fillWidth: true
                    text: modeCard.summary
                    color: Colors.dsTextMuted
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: compact ? Typography.uiBody : Typography.uiBodyLg
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                    elide: Text.ElideRight
                }
            }

            Text {
                visible: modeCard.selected
                text: "\uf00c"
                color: modeCard.accentColor
                font.family: root.faSolid
                font.pixelSize: 14
            }
        }

        MouseArea {
            id: modeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                modeCard.forceActiveFocus()
                modeCard.clicked()
            }
        }

        Keys.onReturnPressed: modeCard.clicked()
        Keys.onEnterPressed: modeCard.clicked()
        Keys.onSpacePressed: modeCard.clicked()
    }

    component PowerMetricChip: Rectangle {
        id: metricChip


        property string label: ""
        property string value: ""
        property string glyph: ""
        property color accentColor: Colors.dsPrimarySolid

        Layout.fillWidth: true
        implicitHeight: 58
        radius: Metrics.radiusMd
        color: Colors.dsSurfaceSoft
        border.width: 1
        border.color: Colors.dsBorderSoft

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 9

            Rectangle {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                radius: 15
                color: Qt.rgba(metricChip.accentColor.r, metricChip.accentColor.g, metricChip.accentColor.b, Colors.lightMode ? 0.12 : 0.18)

                Text {
                    anchors.centerIn: parent
                    text: metricChip.glyph
                    color: metricChip.accentColor
                    font.family: root.faSolid
                    font.pixelSize: 12
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: metricChip.label
                    color: Colors.dsTextMuted
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: Typography.uiCaption
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: metricChip.value
                    color: Colors.dsText
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: Typography.uiBodyLg
                    font.bold: true
                    elide: Text.ElideRight
                }
            }
        }
    }

    component PowerStatusBadge: Rectangle {
        id: statusBadge


        property string status: "Balanced"
        readonly property bool friendly: status.indexOf("Battery") >= 0
        readonly property bool highPower: status.indexOf("High") >= 0
        readonly property color badgeColor: friendly ? Colors.dsSuccess : (highPower ? Colors.dsWarning : Colors.dsPrimarySolid)
        readonly property string badgeGlyph: friendly ? "\uf06c" : (highPower ? "\uf0e7" : "\uf3fd")

        radius: Metrics.radiusPill
        color: Qt.rgba(badgeColor.r, badgeColor.g, badgeColor.b, Colors.lightMode ? 0.13 : 0.20)
        border.width: 1
        border.color: Qt.rgba(badgeColor.r, badgeColor.g, badgeColor.b, Colors.lightMode ? 0.36 : 0.55)
        implicitHeight: 34
        implicitWidth: badgeRow.implicitWidth + 18

        RowLayout {
            id: badgeRow
            anchors.centerIn: parent
            spacing: 7

            Text {
                text: statusBadge.badgeGlyph
                color: statusBadge.badgeColor
                font.family: root.faSolid
                font.pixelSize: 12
            }

            Text {
                text: statusBadge.status
                color: statusBadge.badgeColor
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: Typography.uiBody
                font.bold: true
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.settingsSection === "power"
        spacing: root.compact ? 12 : 14

        PowerSectionCard {
            root: surface.root
            title: "Power Mode"
            subtitle: "Choose how GenyConnect balances battery use, stats refresh, reconnect pressure, and visual effects. The tunnel lifecycle stays owned by the existing VPN runtime."
            glyph: "\uf0e7"
            accentColor: root.powerModeAccent(vpnController.powerMode)
            animated: root.powerVisualAnimationsEnabled

            Rectangle {
                Layout.fillWidth: true
                radius: Metrics.radiusMd
                color: Qt.rgba(root.powerModeAccent(vpnController.powerMode).r,
                               root.powerModeAccent(vpnController.powerMode).g,
                               root.powerModeAccent(vpnController.powerMode).b,
                               Colors.lightMode ? 0.08 : 0.14)
                border.width: 1
                border.color: Qt.rgba(root.powerModeAccent(vpnController.powerMode).r,
                                      root.powerModeAccent(vpnController.powerMode).g,
                                      root.powerModeAccent(vpnController.powerMode).b,
                                      Colors.lightMode ? 0.18 : 0.30)
                implicitHeight: introRow.implicitHeight + 22

                RowLayout {
                    id: introRow
                    anchors.fill: parent
                    anchors.margins: 11
                    spacing: 10

                    Text {
                        Layout.preferredWidth: 22
                        text: root.powerModeGlyph(vpnController.powerMode)
                        color: root.powerModeAccent(vpnController.powerMode)
                        font.family: root.faSolid
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.powerModeSummary(vpnController.powerMode)
                        color: Colors.dsText
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: Typography.uiBodyLg
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: root.compact ? 1 : 3
            columnSpacing: 10
            rowSpacing: 10

            Repeater {
                model: ["Save", "Normal", "High Performance"]

                delegate: PowerModeCard {
                    required property string modelData
                    Layout.fillWidth: true
                    compact: root.compact
                    animated: root.powerVisualAnimationsEnabled
                    modeName: modelData
                    glyph: root.powerModeGlyph(modelData)
                    accentColor: root.powerModeAccent(modelData)
                    summary: root.powerModeSummary(modelData)
                    selected: vpnController.powerMode === modelData
                    onClicked: vpnController.powerMode = modelData
                }
            }
        }

        PowerSectionCard {
            root: surface.root
            title: "Active Policy"
            subtitle: "Effective runtime and UI intervals after mode and adaptive tuning."
            glyph: "\uf085"
            accentColor: Colors.dsPrimarySolid
            animated: root.powerVisualAnimationsEnabled

            GridLayout {
                Layout.fillWidth: true
                columns: root.compact ? 2 : 3
                columnSpacing: 8
                rowSpacing: 8

                PowerMetricChip {
                    label: "Stats Poll"
                    value: root.powerMsText((vpnController.powerPolicy || {}).statsPollIntervalMs || 1000)
                    glyph: "\uf201"
                    accentColor: Colors.dsPrimarySolid
                }

                PowerMetricChip {
                    label: "UI Refresh"
                    value: root.powerMsText(root.powerUiStatsIntervalMs)
                    glyph: "\uf2f1"
                    accentColor: Colors.dsSuccess
                }

                PowerMetricChip {
                    label: "Gauge"
                    value: root.powerMsText(root.powerGaugeRefreshIntervalMs)
                    glyph: "\uf3fd"
                    accentColor: Colors.dsWarning
                }

                PowerMetricChip {
                    label: "Reconnect"
                    value: ((vpnController.powerPolicy || {}).conservativeReconnect === true) ? "Backoff" : "Standard"
                    glyph: "\uf2f1"
                    accentColor: ((vpnController.powerPolicy || {}).conservativeReconnect === true) ? Colors.dsSuccess : Colors.dsPrimarySolid
                }

                PowerMetricChip {
                    label: "Visuals"
                    value: root.powerVisualAnimationsEnabled ? "Enabled" : "Reduced"
                    glyph: "\uf53f"
                    accentColor: root.powerVisualAnimationsEnabled ? Colors.dsPrimarySolid : Colors.dsSuccess
                }

                PowerMetricChip {
                    label: "FakeDNS Sniff"
                    value: ((vpnController.powerPolicy || {}).reduceFakeDnsSniffing === true) ? "Reduced" : "Standard"
                    glyph: "\uf1eb"
                    accentColor: ((vpnController.powerPolicy || {}).reduceFakeDnsSniffing === true) ? Colors.dsSuccess : Colors.dsPrimarySolid
                }
            }
        }

        PowerSectionCard {
            root: surface.root
            title: "Transport Power Profile"
            subtitle: vpnController.transportPowerDescription(vpnController.currentProfileTransportPowerClass())
            glyph: "\uf362"
            accentColor: root.powerModeAccent(vpnController.powerMode)
            animated: root.powerVisualAnimationsEnabled

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                PowerStatusBadge {
                    status: vpnController.currentProfileTransportPowerClass()
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Metadata only"
                    color: Colors.dsTextSubtle
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: Typography.uiCaption
                    elide: Text.ElideRight
                }
            }
        }

        PowerSectionCard {
            root: surface.root
            title: "Diagnostics"
            subtitle: "Clean counters for wakeups, reconnect pressure, and adaptive state."
            glyph: "\uf7d9"
            accentColor: Colors.dsPrimarySolid
            animated: root.powerVisualAnimationsEnabled

            GridLayout {
                Layout.fillWidth: true
                columns: root.compact ? 2 : 3
                columnSpacing: 8
                rowSpacing: 8

                PowerMetricChip {
                    label: "Wakeups"
                    value: String(root.powerDiagnosticValue("timerWakeups", 0))
                    glyph: "\uf017"
                    accentColor: Colors.dsPrimarySolid
                }

                PowerMetricChip {
                    label: "Reconnects"
                    value: String(root.powerDiagnosticValue("reconnectAttempts", 0))
                    glyph: "\uf2f1"
                    accentColor: Colors.dsWarning
                }

                PowerMetricChip {
                    label: "Instability"
                    value: String(root.powerDiagnosticValue("instabilityCount", 0))
                    glyph: "\uf071"
                    accentColor: Number(root.powerDiagnosticValue("instabilityCount", 0)) > 0 ? Colors.dsDanger : Colors.dsSuccess
                }

                PowerMetricChip {
                    label: "Battery"
                    value: root.powerBatteryText()
                    glyph: "\uf240"
                    accentColor: Colors.dsSuccess
                }

                PowerMetricChip {
                    label: "Network"
                    value: root.powerNetworkText()
                    glyph: "\uf1eb"
                    accentColor: Colors.dsPrimarySolid
                }
            }
        }

        PowerSectionCard {
            root: surface.root
            visible: vpnController.isMobile
            title: "Android Battery"
            subtitle: "Keep Android from suspending the VPN foreground service during long sessions."
            glyph: "\uf5df"
            accentColor: ((vpnController.powerDiagnostics || {}).batteryOptimizationIgnored !== false) ? Colors.dsSuccess : Colors.dsWarning
            animated: root.powerVisualAnimationsEnabled

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                PowerMetricChip {
                    Layout.fillWidth: true
                    label: "Optimization"
                    value: ((vpnController.powerDiagnostics || {}).batteryOptimizationIgnored !== false) ? "Exempt" : "Restricted"
                    glyph: "\uf3ed"
                    accentColor: ((vpnController.powerDiagnostics || {}).batteryOptimizationIgnored !== false) ? Colors.dsSuccess : Colors.dsWarning
                }

                Controls.OutlineButton {
                    Layout.preferredWidth: root.compact ? 96 : 128
                    compact: true
                    strokeColor: Colors.dsWarning
                    textColor: Colors.dsWarning
                    text: "Open"
                    onClicked: {
                        const opened = vpnController.openBatteryOptimizationSettings()
                        root.settingsFeedbackText = opened ? "Opened Android battery settings." : "Battery settings are unavailable."
                    }
                }
            }
        }

        PowerSectionCard {
            root: surface.root
            visible: root.powerAdaptiveInputsAvailable()
            title: "Adaptive Inputs"
            subtitle: "Signals that can tune intervals at runtime without reconnecting."
            glyph: "\uf1da"
            accentColor: Colors.dsSuccess
            animated: root.powerVisualAnimationsEnabled

            GridLayout {
                Layout.fillWidth: true
                columns: root.compact ? 2 : 3
                columnSpacing: 8
                rowSpacing: 8

                PowerMetricChip {
                    label: "Screen"
                    value: (vpnController.powerDiagnostics || {}).screenOn === false ? "Off" : "On"
                    glyph: "\uf108"
                    accentColor: (vpnController.powerDiagnostics || {}).screenOn === false ? Colors.dsSuccess : Colors.dsPrimarySolid
                }

                PowerMetricChip {
                    label: "Charging"
                    value: (vpnController.powerDiagnostics || {}).charging === true ? "Yes" : "No"
                    glyph: "\uf1e6"
                    accentColor: (vpnController.powerDiagnostics || {}).charging === true ? Colors.dsSuccess : Colors.dsTextSubtle
                }

                PowerMetricChip {
                    label: "Battery Saver"
                    value: (vpnController.powerDiagnostics || {}).batterySaver === true ? "On" : "Off"
                    glyph: "\uf06c"
                    accentColor: (vpnController.powerDiagnostics || {}).batterySaver === true ? Colors.dsSuccess : Colors.dsTextSubtle
                }

                PowerMetricChip {
                    label: "App State"
                    value: (vpnController.powerDiagnostics || {}).backgrounded === true ? "Background" : "Foreground"
                    glyph: "\uf2d0"
                    accentColor: (vpnController.powerDiagnostics || {}).backgrounded === true ? Colors.dsSuccess : Colors.dsPrimarySolid
                }
            }
        }
    }

}
