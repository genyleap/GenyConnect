/*!
 * @file        LanSharingSettingsSection.qml
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
    required property var settingsFlick

    Layout.fillWidth: true
    spacing: root.compact ? 14 : 10

    component LanStatTile: Rectangle {
        id: statTile


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
            anchors.margins: 8
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: 14
                color: Qt.rgba(statTile.accentColor.r, statTile.accentColor.g, statTile.accentColor.b, Colors.lightMode ? 0.12 : 0.20)

                Text {
                    anchors.centerIn: parent
                    text: statTile.glyph
                    color: statTile.accentColor
                    font.family: root.faSolid
                    font.pixelSize: 11
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: I18n.t(statTile.label)
                    color: Colors.dsTextSubtle
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: Typography.uiCaption
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: statTile.value
                    color: Colors.dsText
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: Typography.uiBody
                    font.bold: true
                    elide: Text.ElideMiddle
                }
            }
        }
    }

    component LanBadge: Rectangle {
        id: lanBadge


        property string text: ""
        property string glyph: ""
        property color badgeColor: Colors.dsSurfaceSoft
        property color borderColor: Colors.dsBorderSoft
        property color textColor: Colors.dsTextMuted
        property bool bold: true
        property int textPixelSize: Typography.t4
        property int horizontalPadding: 14

        radius: Metrics.radiusPill
        color: badgeColor
        border.width: 1
        border.color: borderColor
        implicitHeight: textPixelSize <= 11 ? 24 : 28
        implicitWidth: badgeRow.implicitWidth + horizontalPadding

        RowLayout {
            id: badgeRow
            anchors.centerIn: parent
            spacing: 5

            Text {
                visible: lanBadge.glyph.length > 0
                text: lanBadge.glyph
                color: lanBadge.textColor
                font.family: root.faSolid
                font.pixelSize: 8
            }

            Text {
                text: I18n.t(lanBadge.text)
                color: lanBadge.textColor
                font.family: lanBadge.bold ? FontSystem.getContentFontBold.name : FontSystem.contentFontFamily
                font.pixelSize: lanBadge.textPixelSize
                font.bold: lanBadge.bold
            }
        }
    }

    component LanActionButton: Rectangle {
        id: lanAction


        property string text: ""
        property string glyph: ""
        property color accentColor: Colors.dsPrimarySolid

        signal clicked()

        Layout.fillWidth: true
        implicitHeight: 46
        radius: Metrics.radiusSm
        color: actionMouse.pressed
               ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, Colors.lightMode ? 0.12 : 0.24)
               : (actionMouse.containsMouse
                  ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, Colors.lightMode ? 0.06 : 0.16)
                  : Colors.dsSurface)
        border.width: 1
        border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, Colors.lightMode ? 0.34 : 0.48)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 7

            Item { Layout.fillWidth: true }

            Text {
                text: lanAction.glyph
                color: lanAction.accentColor
                font.family: root.faSolid
                font.pixelSize: root.compact ? 12 : 14
            }

            Text {
                Layout.maximumWidth: Math.max(42, lanAction.width - 58)
                text: I18n.t(lanAction.text)
                color: lanAction.accentColor
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: root.compact ? Typography.uiBody : Typography.uiBodyLg
                font.bold: true
                elide: Text.ElideRight
            }

            Item { Layout.fillWidth: true }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: lanAction.clicked()
        }
    }

    component LanInfoCell: Item {
        id: lanInfoCell


        property string label: ""
        property string value: ""
        property string glyph: ""
        property bool copyable: false
        property bool chip: false
        property color accentColor: Colors.dsPrimarySolid
        property bool tight: width < 156
        property bool ultraTight: width < 124

        signal copyClicked()

        Layout.fillWidth: true
        implicitHeight: 66

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: lanInfoCell.tight ? 9 : 14
            anchors.rightMargin: lanInfoCell.tight ? 7 : 12
            spacing: lanInfoCell.tight ? 4 : 8

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                Text {
                    Layout.fillWidth: true
                    text: I18n.t(lanInfoCell.label)
                    color: Colors.dsTextMuted
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: Typography.uiCaption
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: !lanInfoCell.chip
                    text: lanInfoCell.value
                    color: Colors.dsText
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: lanInfoCell.ultraTight ? Typography.uiBodySm : (lanInfoCell.tight ? Typography.uiBody : Typography.uiTitleSm)
                    font.bold: true
                    elide: lanInfoCell.label === "Port" ? Text.ElideNone : Text.ElideMiddle
                }

                Rectangle {
                    id: protocolChip
                    visible: lanInfoCell.chip
                    Layout.alignment: Qt.AlignLeft
                    readonly property real maxChipWidth: Math.max(82, lanInfoCell.width - (lanInfoCell.copyable ? 20 : 12))
                    readonly property real desiredChipWidth: protocolText.implicitWidth
                                                          + (protocolGlyph.visible ? protocolGlyph.implicitWidth : 0)
                                                          + protocolChipRow.spacing
                                                          + (lanInfoCell.ultraTight ? 20 : 24)
                    implicitWidth: Math.max(82, Math.min(maxChipWidth, desiredChipWidth))
                    implicitHeight: lanInfoCell.ultraTight ? 26 : 29
                    radius: Metrics.radiusPill
                    color: Qt.rgba(lanInfoCell.accentColor.r, lanInfoCell.accentColor.g, lanInfoCell.accentColor.b, Colors.lightMode ? 0.10 : 0.18)
                    border.width: 1
                    border.color: Qt.rgba(lanInfoCell.accentColor.r, lanInfoCell.accentColor.g, lanInfoCell.accentColor.b, Colors.lightMode ? 0.26 : 0.42)

                    RowLayout {
                        id: protocolChipRow
                        anchors.fill: parent
                        anchors.leftMargin: lanInfoCell.ultraTight ? 8 : 10
                        anchors.rightMargin: lanInfoCell.ultraTight ? 8 : 10
                        spacing: lanInfoCell.ultraTight ? 5 : 6

                        Text {
                            id: protocolGlyph
                            text: lanInfoCell.glyph
                            color: lanInfoCell.accentColor
                            font.family: root.faSolid
                            font.pixelSize: lanInfoCell.ultraTight ? 11 : 12
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            id: protocolText
                            text: lanInfoCell.value
                            color: lanInfoCell.accentColor
                            font.family: FontSystem.getContentFontBold.name
                            font.pixelSize: lanInfoCell.ultraTight ? 10 : Typography.uiBodySm
                            font.bold: true
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            Rectangle {
                visible: lanInfoCell.copyable
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: 14
                color: copyMouse.containsMouse
                       ? Qt.rgba(lanInfoCell.accentColor.r, lanInfoCell.accentColor.g, lanInfoCell.accentColor.b, Colors.lightMode ? 0.12 : 0.20)
                       : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\uf0c5"
                    color: lanInfoCell.accentColor
                    font.family: root.faSolid
                    font.pixelSize: 13
                }

                MouseArea {
                    id: copyMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: lanInfoCell.copyClicked()
                }
            }
        }
    }

    component LanPresetTile: Rectangle {
        id: presetTile


        property string title: ""
        property string glyph: ""
        property color accentColor: Colors.dsPrimarySolid
        property bool selected: false

        signal clicked()

        Layout.fillWidth: true
        implicitHeight: root.compact ? 94 : 110
        radius: Metrics.radiusMd
        color: presetMouse.pressed
               ? Colors.dsSurfaceElevated
               : (selected
                  ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, Colors.lightMode ? 0.09 : 0.18)
                  : (presetMouse.containsMouse ? Colors.dsSurfaceSoft : Colors.dsSurface))
        border.width: selected ? 2 : 1
        border.color: selected ? accentColor : Colors.dsBorderSoft

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - 18
            spacing: root.compact ? 6 : 8

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: root.compact ? 44 : 48
                Layout.preferredHeight: root.compact ? 44 : 48
                radius: 24
                color: Qt.rgba(presetTile.accentColor.r, presetTile.accentColor.g, presetTile.accentColor.b, Colors.lightMode ? 0.10 : 0.18)

                Text {
                    anchors.centerIn: parent
                    text: presetTile.glyph
                    color: presetTile.accentColor
                    font.family: root.faSolid
                    font.pixelSize: root.compact ? 21 : 24
                }
            }

            Text {
                Layout.fillWidth: true
                text: I18n.t(presetTile.title)
                color: presetTile.selected ? presetTile.accentColor : Colors.dsText
                font.family: presetTile.selected ? FontSystem.getContentFontBold.name : FontSystem.contentFontFamily
                font.pixelSize: presetTile.width < 124 ? Typography.uiCaption : Typography.uiBody
                font.bold: presetTile.selected
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }

        Rectangle {
            visible: presetTile.selected
            width: 24
            height: 24
            radius: 12
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: -6
            anchors.rightMargin: -6
            color: presetTile.accentColor

            Text {
                anchors.centerIn: parent
                text: "\uf00c"
                color: Colors.dsPrimaryText
                font.family: root.faSolid
                font.pixelSize: 11
            }
        }

        MouseArea {
            id: presetMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: presetTile.clicked()
        }
    }

    component LanGuideStep: Rectangle {
        id: guideStep


        property string stepNumber: ""
        property string text: ""
        property string value: ""
        property string glyph: ""
        property bool copyable: false
        property color accentColor: Colors.dsPrimarySolid

        signal copyClicked()

        Layout.fillWidth: true
        implicitHeight: 46
        radius: Metrics.radiusSm
        color: Colors.dsSurface
        border.width: 1
        border.color: Colors.dsBorderSoft

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 14

            Rectangle {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 13
                color: guideStep.accentColor

                Text {
                    anchors.centerIn: parent
                    text: guideStep.stepNumber
                    color: Colors.dsPrimaryText
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: Typography.uiCaption
                    font.bold: true
                }
            }

            Text {
                Layout.fillWidth: true
                text: I18n.t(guideStep.text)
                color: Colors.dsText
                font.family: FontSystem.contentFontFamily
                font.pixelSize: Typography.uiBody
                elide: Text.ElideRight
            }

            LanBadge {

                visible: guideStep.value.length > 0
                Layout.leftMargin: 4
                text: guideStep.value
                glyph: guideStep.copyable ? "\uf0c5" : ""
                badgeColor: Qt.rgba(guideStep.accentColor.r, guideStep.accentColor.g, guideStep.accentColor.b, Colors.lightMode ? 0.10 : 0.18)
                borderColor: "transparent"
                textColor: guideStep.accentColor
                bold: true

                MouseArea {
                    anchors.fill: parent
                    enabled: guideStep.copyable
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: guideStep.copyClicked()
                }
            }

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: 14
                color: Qt.rgba(guideStep.accentColor.r, guideStep.accentColor.g, guideStep.accentColor.b, Colors.lightMode ? 0.08 : 0.16)

                Text {
                    anchors.centerIn: parent
                    text: guideStep.glyph
                    color: guideStep.accentColor
                    font.family: root.faSolid
                    font.pixelSize: 12
                }
            }
        }
    }

    component LanModeCard: Rectangle {
        id: lanModeCard


        property string modeName: ""
        property string summary: ""
        property string badgeText: ""
        property string glyph: ""
        property color accentColor: Colors.dsPrimarySolid
        property bool selected: false
        property bool animated: true

        signal clicked()

        Layout.fillWidth: true
        implicitHeight: 84
        radius: Metrics.radiusMd
        color: lanModeMouse.pressed
               ? Colors.dsSurfaceElevated
               : (selected
                  ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, Colors.lightMode ? 0.10 : 0.17)
                  : (lanModeMouse.containsMouse ? Colors.dsSurfaceSoft : Colors.dsSurface))
        border.width: selected ? 2 : 1
        border.color: selected ? accentColor : (lanModeMouse.containsMouse ? Colors.dsBorder : Colors.dsBorderSoft)
        activeFocusOnTab: true
        focus: false
        Accessible.role: Accessible.Button
        Accessible.name: lanModeCard.modeName + (lanModeCard.selected ? " selected" : "")
        Accessible.description: lanModeCard.summary

        Behavior on color {
            enabled: lanModeCard.animated
            ColorAnimation { duration: 120 }
        }

        Behavior on border.color {
            enabled: lanModeCard.animated
            ColorAnimation { duration: 120 }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 9

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: width / 2
                color: lanModeCard.selected
                       ? lanModeCard.accentColor
                       : Qt.rgba(lanModeCard.accentColor.r, lanModeCard.accentColor.g, lanModeCard.accentColor.b, Colors.lightMode ? 0.12 : 0.20)

                Text {
                    anchors.centerIn: parent
                    text: lanModeCard.glyph
                    color: lanModeCard.selected ? Colors.dsPrimaryText : lanModeCard.accentColor
                    font.family: root.faSolid
                    font.pixelSize: 12
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: I18n.t(lanModeCard.modeName)
                    color: Colors.dsText
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: Typography.uiBodyLg
                    font.bold: true
                    elide: Text.ElideRight
                }

                LanBadge {

                    visible: lanModeCard.badgeText.length > 0
                    text: I18n.t(lanModeCard.badgeText)
                    glyph: "\uf0a3"
                    badgeColor: Qt.rgba(lanModeCard.accentColor.r, lanModeCard.accentColor.g, lanModeCard.accentColor.b, Colors.lightMode ? 0.10 : 0.16)
                    borderColor: Qt.rgba(lanModeCard.accentColor.r, lanModeCard.accentColor.g, lanModeCard.accentColor.b, Colors.lightMode ? 0.30 : 0.44)
                    textColor: lanModeCard.accentColor
                }

                Text {
                    Layout.fillWidth: true
                    text: I18n.t(lanModeCard.summary)
                    color: Colors.dsTextMuted
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: Typography.uiCaption
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            Text {
                text: lanModeCard.selected ? "\uf00c" : "\uf054"
                color: lanModeCard.selected ? lanModeCard.accentColor : Colors.dsTextSubtle
                font.family: root.faSolid
                font.pixelSize: 12
            }
        }

        MouseArea {
            id: lanModeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                lanModeCard.forceActiveFocus()
                lanModeCard.clicked()
            }
        }

        Keys.onReturnPressed: lanModeCard.clicked()
        Keys.onEnterPressed: lanModeCard.clicked()
        Keys.onSpacePressed: lanModeCard.clicked()
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
                    text: I18n.t(metricChip.label)
                    color: Colors.dsTextMuted
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: Typography.uiCaption
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: I18n.localizeDigits(I18n.t(metricChip.value))
                    color: Colors.dsText
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: Typography.uiBodyLg
                    font.bold: true
                    elide: Text.ElideRight
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.settingsSection === "lan"
        spacing: root.compact ? 12 : 14

        Rectangle {
            id: lanStatusCard
            Layout.fillWidth: true
            radius: Metrics.radiusLg
            color: vpnController.lanSharingEnabled
                   ? Qt.rgba(Colors.dsSuccess.r, Colors.dsSuccess.g, Colors.dsSuccess.b, Colors.lightMode ? 0.08 : 0.15)
                   : Colors.dsSurface
            border.width: 1
            border.color: vpnController.lanSharingEnabled
                          ? Qt.rgba(Colors.dsSuccess.r, Colors.dsSuccess.g, Colors.dsSuccess.b, Colors.lightMode ? 0.26 : 0.38)
                          : Colors.dsBorderSoft
            implicitHeight: lanStatusCardLayout.implicitHeight + 28

            ColumnLayout {
                id: lanStatusCardLayout
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Rectangle {
                        Layout.preferredWidth: 58
                        Layout.preferredHeight: 58
                        radius: 29
                        color: vpnController.lanSharingEnabled
                               ? Colors.dsSuccess
                               : Qt.rgba(root.lanUiAccent.r, root.lanUiAccent.g, root.lanUiAccent.b, Colors.lightMode ? 0.14 : 0.22)

                        Text {
                            anchors.centerIn: parent
                            text: "\uf1eb"
                            color: vpnController.lanSharingEnabled ? Colors.dsPrimaryText : root.lanUiAccent
                            font.family: root.faSolid
                            font.pixelSize: 26
                        }

                        Rectangle {
                            visible: vpnController.lanSharingEnabled
                            width: 20
                            height: 20
                            radius: 10
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.rightMargin: -2
                            anchors.bottomMargin: -2
                            color: Colors.dsSuccess
                            border.width: 2
                            border.color: Colors.dsSurface

                            Text {
                                anchors.centerIn: parent
                                text: "\uf00c"
                                color: Colors.dsPrimaryText
                                font.family: root.faSolid
                                font.pixelSize: 9
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            Layout.fillWidth: true
                            text: I18n.t(vpnController.lanSharingEnabled ? "Sharing On" : "Sharing Off")
                            color: vpnController.lanSharingEnabled ? Colors.dsSuccess : Colors.dsText
                            font.family: FontSystem.getContentFontBold.name
                            font.pixelSize: Typography.uiTitle
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: I18n.t(vpnController.lanSharingEnabled
                                         ? (root.compact ? "Proxy is available on your LAN." : "Your proxy is available on the LAN.")
                                         : (root.compact ? "Share your proxy on local Wi-Fi." : "Enable to share your proxy on local Wi-Fi."))
                            color: Colors.dsTextMuted
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: root.compact ? Typography.uiBodySm : Typography.uiBody
                            elide: Text.ElideRight
                        }
                    }

                    Controls.Switch {
                        checked: vpnController.lanSharingEnabled
                        enabled: vpnController.lanSharingSupported
                        onToggled: vpnController.lanSharingEnabled = checked
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 80
                    radius: Metrics.radiusMd
                    color: Colors.dsSurface
                    border.width: 1
                    border.color: Colors.dsBorderSoft

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: root.compact ? 2 : 4
                        anchors.rightMargin: root.compact ? 2 : 4
                        spacing: 0

                        LanInfoCell {
                            Layout.minimumWidth: root.compact ? 96 : 166
                            Layout.preferredWidth: root.compact ? 148 : 260
                            Layout.maximumWidth: root.compact ? 208 : 360
                            label: I18n.t(settingsFlick.width < 560 ? "Host" : "LAN Address (Host)")
                            value: root.lanProxyHost()
                            copyable: true
                            accentColor: Colors.dsPrimarySolid
                            onCopyClicked: {
                                vpnController.copyTextToClipboard(root.lanProxyHost())
                                root.showSettingsFeedback(I18n.t("Host copied."))
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 52
                            color: Colors.dsBorderSoft
                        }

                        LanInfoCell {
                            Layout.minimumWidth: root.compact ? 74 : 116
                            Layout.preferredWidth: root.compact ? 94 : 162
                            Layout.maximumWidth: root.compact ? 132 : 208
                            label: I18n.t("Port")
                            value: String(vpnController.httpPort)
                            copyable: true
                            accentColor: Colors.dsPrimarySolid
                            onCopyClicked: {
                                vpnController.copyTextToClipboard(String(vpnController.httpPort))
                                root.showSettingsFeedback(I18n.t("Port copied."))
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 52
                            color: Colors.dsBorderSoft
                        }

                        LanInfoCell {
                            Layout.minimumWidth: root.compact ? 104 : 188
                            Layout.preferredWidth: root.compact ? 140 : 274
                            Layout.maximumWidth: root.compact ? 210 : 380
                            label: I18n.t("Protocol")
                            value: root.lanProtocolDisplay(root.lanUiMode)
                            glyph: "\uf0ac"
                            chip: true
                            accentColor: root.lanUiAccent
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    LanActionButton {
                        text: I18n.t(settingsFlick.width < 560 ? "Copy" : "Copy Address")
                        glyph: "\uf0c5"
                        accentColor: Colors.dsPrimarySolid
                        onClicked: {
                            vpnController.copyTextToClipboard(root.lanProxyHost())
                            root.showSettingsFeedback(I18n.t("Address copied."))
                        }
                    }

                    LanActionButton {
                        text: I18n.t(settingsFlick.width < 560 ? "Test" : "Test Connection")
                        glyph: "\uf2f1"
                        accentColor: Colors.dsPrimarySolid
                        onClicked: root.showLanStatusFeedback(I18n.t("Test with Host %1 and Port %2.", [
                                                                        I18n.ltr(root.lanProxyHost()),
                                                                        I18n.ltr(String(vpnController.httpPort))
                                                                    ]))
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.settingsFeedbackText.length > 0 || root.lanStatusFeedbackText.length > 0
                    text: I18n.t(root.lanStatusFeedbackText.length > 0 ? root.lanStatusFeedbackText : root.settingsFeedbackText)
                    color: Colors.dsTextSubtle
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: Typography.uiCaption
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    visible: !vpnController.lanSharingSupported
                    text: I18n.t("LAN proxy unavailable on this runtime.")
                    color: Colors.dsDanger
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: Typography.uiBody
                    wrapMode: Text.WordWrap
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            radius: Metrics.radiusLg
            color: Colors.dsSurface
            border.width: 1
            border.color: Colors.dsBorderSoft
            implicitHeight: lanSecurityRow.implicitHeight + 20

            RowLayout {
                id: lanSecurityRow
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: 17
                    color: Qt.rgba(Colors.dsSuccess.r, Colors.dsSuccess.g, Colors.dsSuccess.b, Colors.lightMode ? 0.12 : 0.20)

                    Text {
                        anchors.centerIn: parent
                        text: "\uf132"
                        color: Colors.dsSuccess
                        font.family: root.faSolid
                        font.pixelSize: 15
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: I18n.t(vpnController.lanSharingAllowAnyBind
                                         ? (root.compact ? "Security: LAN Access Allowed" : "Security: LAN Connections Allowed")
                                         : (root.compact ? "Security: Private LAN" : "Security: Private LAN Only"))
                            color: Colors.dsText
                            font.family: FontSystem.getContentFontBold.name
                            font.pixelSize: root.compact ? Typography.uiBodySm : Typography.uiBody
                            font.bold: true
                            wrapMode: Text.NoWrap
                            elide: Text.ElideRight
                        }

                        LanBadge {
                            Layout.alignment: Qt.AlignVCenter
                            text: I18n.t(vpnController.lanSharingAllowAnyBind ? "Review" : (root.compact ? "Safe" : "Recommended"))
                            badgeColor: vpnController.lanSharingAllowAnyBind
                                       ? Qt.rgba(Colors.dsWarning.r, Colors.dsWarning.g, Colors.dsWarning.b, Colors.lightMode ? 0.12 : 0.20)
                                       : Qt.rgba(Colors.dsSuccess.r, Colors.dsSuccess.g, Colors.dsSuccess.b, Colors.lightMode ? 0.12 : 0.20)
                            borderColor: "transparent"
                            textColor: vpnController.lanSharingAllowAnyBind ? Colors.dsWarning : Colors.dsSuccess
                            textPixelSize: root.compact ? 11 : Typography.t4
                            horizontalPadding: root.compact ? 12 : 14
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: I18n.t(vpnController.lanSharingAllowAnyBind
                                     ? "Devices on your LAN can connect."
                                     : "Only devices on your local network can connect.")
                        color: Colors.dsTextMuted
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: root.compact ? Typography.t4 : Typography.uiCaption
                        elide: Text.ElideRight
                    }
                }

                Controls.Switch {
                    Layout.alignment: Qt.AlignVCenter
                    checked: !vpnController.lanSharingAllowAnyBind
                    onToggled: vpnController.lanSharingAllowAnyBind = !checked
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            radius: Metrics.radiusLg
            color: Colors.dsSurface
            border.width: 1
            border.color: Colors.dsBorderSoft
            implicitHeight: lanDeviceCardLayout.implicitHeight + 28

            ColumnLayout {
                id: lanDeviceCardLayout
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: I18n.t("Choose Your Device")
                        color: Colors.dsText
                        font.family: FontSystem.getContentFontBold.name
                        font.pixelSize: Typography.uiTitleSm
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    LanBadge {
                        text: I18n.t(root.lanUiModeLabelCompact)
                        badgeColor: Qt.rgba(root.lanUiAccent.r, root.lanUiAccent.g, root.lanUiAccent.b, Colors.lightMode ? 0.10 : 0.18)
                        borderColor: "transparent"
                        textColor: root.lanUiAccent
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: settingsFlick.width < 360 ? 2 : 3
                    columnSpacing: root.compact ? 8 : 10
                    rowSpacing: root.compact ? 8 : 10

                    Repeater {
                        model: [
                            { "key": "mobile", "title": "Phone", "glyph": "\uf3cd", "accent": Colors.dsWarning },
                            { "key": "console", "title": "Game Console", "shortTitle": "Console", "glyph": "\uf11b", "accent": Colors.dsPrimarySolid },
                            { "key": "tv", "title": "Smart TV", "glyph": "\uf26c", "accent": Colors.dsSuccess },
                            { "key": "laptop", "title": "Laptop", "glyph": "\uf109", "accent": Colors.dsPrimarySolid },
                            { "key": "advanced", "title": "Advanced", "glyph": "\uf085", "accent": Colors.dsDanger }
                        ]

                        delegate: LanPresetTile {
                            required property var modelData
                            title: settingsFlick.width < 560 && (modelData.shortTitle || "").length > 0 ? modelData.shortTitle : (modelData.title || "")
                            glyph: modelData.glyph || ""
                            accentColor: modelData.accent || Colors.dsPrimarySolid
                            selected: root.lanModeKey() === (modelData.key || "")
                            onClicked: root.lanSetMode(modelData.key || "console")
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            radius: Metrics.radiusLg
            color: Colors.dsSurface
            border.width: 1
            border.color: Colors.dsBorderSoft
            implicitHeight: lanGuideCardLayout.implicitHeight + 28

            ColumnLayout {
                id: lanGuideCardLayout
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: 17
                        color: Qt.rgba(root.lanUiAccent.r, root.lanUiAccent.g, root.lanUiAccent.b, Colors.lightMode ? 0.10 : 0.18)

                        Text {
                            anchors.centerIn: parent
                            text: root.lanModeGlyph(root.lanUiMode)
                            color: root.lanUiAccent
                            font.family: root.faSolid
                            font.pixelSize: 16
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: I18n.t("Setup Guide: %1", [I18n.t(root.lanUiModeLabelCompact)])
                        color: Colors.dsText
                        font.family: FontSystem.getContentFontBold.name
                        font.pixelSize: Typography.uiTitleSm
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    LanBadge {
                        text: I18n.t("6 Steps")
                        badgeColor: Qt.rgba(Colors.dsPrimarySolid.r, Colors.dsPrimarySolid.g, Colors.dsPrimarySolid.b, Colors.lightMode ? 0.10 : 0.18)
                        borderColor: "transparent"
                        textColor: Colors.dsPrimarySolid
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            { "num": "1", "icon": "\uf1eb", "text": "Connect both devices to same Wi-Fi.", "value": "", "copy": "" },
                            { "num": "2", "icon": "\uf013", "text": "Open proxy/manual network settings.", "value": "", "copy": "" },
                            { "num": "3", "icon": "\uf1de", "text": "Set proxy to Manual.", "value": "", "copy": "" },
                            { "num": "4", "icon": "\uf0c5", "text": "Enter Host:", "value": root.lanProxyHost(), "copy": "host" },
                            { "num": "5", "icon": "\uf0c5", "text": "Enter Port:", "value": String(vpnController.httpPort), "copy": "port" },
                            { "num": "6", "icon": "\uf058", "text": "Test connection.", "value": "", "copy": "" }
                        ]

                        delegate: LanGuideStep {
                            required property var modelData
                            stepNumber: modelData.num || ""
                            text: modelData.text || ""
                            value: modelData.value || ""
                            glyph: modelData.icon || ""
                            copyable: (modelData.copy || "").length > 0
                            accentColor: root.lanUiAccent
                            onCopyClicked: {
                                const target = modelData.copy || ""
                                if (target === "host") {
                                    vpnController.copyTextToClipboard(root.lanProxyHost())
                                    root.showLanSetupFeedback(I18n.t("Host copied."))
                                } else if (target === "port") {
                                    vpnController.copyTextToClipboard(String(vpnController.httpPort))
                                    root.showLanSetupFeedback(I18n.t("Port copied."))
                                }
                            }
                        }
                    }
                }

                LanActionButton {
                    text: I18n.t("Test Connection")
                    glyph: "\uf2f1"
                    accentColor: Colors.dsPrimarySolid
                    onClicked: root.showLanSetupFeedback(I18n.t("Use Host %1 and Port %2.", [
                                                                   I18n.ltr(root.lanProxyHost()),
                                                                   I18n.ltr(String(vpnController.httpPort))
                                                               ]))
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.lanSetupFeedbackText.length > 0
                    text: I18n.t(root.lanSetupFeedbackText)
                    color: Colors.dsTextSubtle
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: Typography.uiCaption
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }
        }

        PowerSectionCard {
            root: surface.root
            title: I18n.t("Advanced Options")
            subtitle: I18n.t("Collapsed by default.")
            glyph: "\uf085"
            accentColor: Colors.dsPrimarySolid
            animated: root.powerVisualAnimationsEnabled

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: I18n.t(root.lanAdvancedControlsExpanded
                                 ? "Advanced controls visible."
                                 : "Advanced controls hidden.")
                    color: Colors.dsTextMuted
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: Typography.uiBody
                    elide: Text.ElideRight
                }

                LanBadge {
                    text: I18n.t(root.lanAdvancedControlsExpanded ? "Expanded" : "Collapsed")
                    glyph: root.lanAdvancedControlsExpanded ? "\uf06e" : "\uf070"
                    badgeColor: Qt.rgba(root.lanUiAccent.r, root.lanUiAccent.g, root.lanUiAccent.b, Colors.lightMode ? 0.11 : 0.18)
                    borderColor: Qt.rgba(root.lanUiAccent.r, root.lanUiAccent.g, root.lanUiAccent.b, Colors.lightMode ? 0.30 : 0.44)
                    textColor: root.lanUiAccent
                }

                Controls.OutlineButton {
                    compact: true
                    text: I18n.t(root.lanAdvancedControlsExpanded ? "Hide" : "Show")
                    onClicked: root.lanAdvancedControlsExpanded = !root.lanAdvancedControlsExpanded
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: root.lanAdvancedControlsExpanded

                GridLayout {
                    Layout.fillWidth: true
                    columns: settingsFlick.width < 700 ? 1 : 3
                    columnSpacing: 8
                    rowSpacing: 8

                    PowerMetricChip {
                        label: I18n.t("Sharing")
                        value: vpnController.lanSharingEnabled ? "Enabled" : "Disabled"
                        glyph: vpnController.lanSharingEnabled ? "\uf00c" : "\uf00d"
                        accentColor: vpnController.lanSharingEnabled ? Colors.dsSuccess : Colors.dsTextSubtle
                    }

                    PowerMetricChip {
                        label: I18n.t("Bind Mode")
                        value: vpnController.lanSharingAllowAnyBind ? "LAN Wide" : "Private LAN"
                        glyph: vpnController.lanSharingAllowAnyBind ? "\uf3ed" : "\uf132"
                        accentColor: vpnController.lanSharingAllowAnyBind ? Colors.dsWarning : Colors.dsSuccess
                    }

                    PowerMetricChip {
                        label: I18n.t("Gateway")
                        value: vpnController.lanGatewayExperimentalEnabled ? "Enabled" : "Off"
                        glyph: "\uf0e7"
                        accentColor: vpnController.lanGatewayExperimentalEnabled ? Colors.dsDanger : Colors.dsTextSubtle
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Controls.Switch {
                        checked: vpnController.lanSharingEnabled
                        enabled: vpnController.lanSharingSupported
                        onToggled: vpnController.lanSharingEnabled = checked
                    }

                    Text {
                        Layout.fillWidth: true
                        text: I18n.t(vpnController.lanSharingEnabled ? "Sharing enabled." : "Sharing disabled.")
                        color: Colors.dsTextMuted
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: Typography.uiBody
                        wrapMode: Text.WordWrap
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Controls.ComboBox {
                        id: lanBindAddressCombo
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        enabled: !vpnController.lanSharingAllowAnyBind
                                 && (root.lanHostCandidates || []).length > 0
                        model: (root.lanHostCandidates || []).length > 0
                               ? root.lanHostCandidates
                               : [{ "name": "No private LAN IP found", "address": "", "interface": "" }]
                        currentIndex: {
                            const wanted = (vpnController.lanSharingBindAddress || "").trim()
                            const list = model || []
                            for (let i = 0; i < list.length; ++i) {
                                if ((((list[i] || {}).address || "").trim()) === wanted)
                                    return i
                            }
                            return list.length > 0 ? 0 : -1
                        }
                        onActivated: function(activatedIndex) {
                            const item = model[activatedIndex] || {}
                            if ((item.address || "").length > 0) {
                                vpnController.lanSharingBindAddress = item.address
                                vpnController.lanSharingInterface = item.interface || ""
                            }
                        }
                    }

                    Controls.OutlineButton {
                        compact: true
                        text: I18n.t("Refresh")
                        onClicked: root.refreshLanHostCandidates()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Controls.Switch {
                        checked: vpnController.lanSharingAllowAnyBind
                        onToggled: vpnController.lanSharingAllowAnyBind = checked
                    }

                    LanBadge {
                        text: I18n.t(vpnController.lanSharingAllowAnyBind ? "LAN Wide (0.0.0.0)" : "Private LAN Only")
                        glyph: vpnController.lanSharingAllowAnyBind ? "\uf3ed" : "\uf132"
                        badgeColor: vpnController.lanSharingAllowAnyBind
                                   ? Qt.rgba(Colors.dsWarning.r, Colors.dsWarning.g, Colors.dsWarning.b, Colors.lightMode ? 0.14 : 0.22)
                                   : Qt.rgba(Colors.dsSuccess.r, Colors.dsSuccess.g, Colors.dsSuccess.b, Colors.lightMode ? 0.14 : 0.22)
                        borderColor: vpnController.lanSharingAllowAnyBind ? Colors.dsWarning : Colors.dsSuccess
                        textColor: vpnController.lanSharingAllowAnyBind ? Colors.dsWarning : Colors.dsSuccess
                    }

                    Item { Layout.fillWidth: true }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: Metrics.radiusMd
                    color: Colors.dsSurfaceSoft
                    border.width: 1
                    border.color: Colors.dsBorderSoft
                    implicitHeight: gatewayRow.implicitHeight + gatewayHintText.implicitHeight + 18

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 5

                        RowLayout {
                            id: gatewayRow
                            Layout.fillWidth: true
                            spacing: 8

                            Controls.Switch {
                                checked: vpnController.lanGatewayExperimentalEnabled
                                enabled: root.lanGatewayPlatformSupported()
                                onToggled: vpnController.lanGatewayExperimentalEnabled = checked
                            }

                            Text {
                                Layout.fillWidth: false
                                text: I18n.t("Full VPN Gateway / Hotspot")
                                color: Colors.dsText
                                font.family: FontSystem.getContentFontBold.name
                                font.pixelSize: Typography.uiBody
                                elide: Text.ElideRight
                            }

                            Item { Layout.fillWidth: true; }

                        }

                        Text {
                            id: gatewayHintText
                            Layout.fillWidth: true
                            text: I18n.t(root.lanGatewayPlatformSupported()
                                         ? "Experimental: Use only when you need full-device routing. Proxy mode is recommended first."
                                         : "Not available on this platform runtime (Experimental).")
                            color: Colors.dsTextSubtle
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: Typography.uiCaption
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }

}
