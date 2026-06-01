import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtCore

import GenyConnect 1.0

import "../Core"
import "../Controls" as Controls

Item {
    id: surface

    required property var root
    required property var vpnController
    required property var updater
    required property var dashboardStatsSettings
    required property var interfaceThemeSettings
    required property var interfacePrivacySettings

    property alias updateNoticePopup: updateNoticePopup
    property alias donationSuggestPopup: donationSuggestPopup
    property alias tunConflictPopup: tunConflictPopup
    property alias profilePopup: profilePopup
    property alias clearProfilesPopup: clearProfilesPopup
    property alias editProfilePopup: editProfilePopup
    property alias settingsPopup: settingsPopup
    property alias profileQrPopup: profileQrPopup
    property alias walletPickerPopup: walletPickerPopup
    property alias aboutPopup: aboutPopup
    property alias dataUsagePopup: dataUsagePopup
    property alias logsPopup: logsPopup
    property alias speedTestPopup: speedTestPopup
    property alias importPopup: importPopup
    property alias settingsFlickRef: settingsFlick

    component PowerSectionCard: Rectangle {
        id: sectionCard

        property string title: ""
        property string subtitle: ""
        property string glyph: ""
        property color accentColor: Colors.dsPrimarySolid
        property bool animated: true

        default property alias content: sectionBody.data

        Layout.fillWidth: true
        radius: Metrics.radiusLg
        color: Colors.dsSurface
        border.width: 1
        border.color: Colors.dsBorderSoft
        implicitHeight: sectionLayout.implicitHeight + 28

        Behavior on border.color {
            enabled: sectionCard.animated
            ColorAnimation { duration: 120 }
        }

        ColumnLayout {
            id: sectionLayout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    visible: sectionCard.glyph.length > 0
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: 17
                    color: Qt.rgba(sectionCard.accentColor.r, sectionCard.accentColor.g, sectionCard.accentColor.b, Colors.lightMode ? 0.12 : 0.20)

                    Text {
                        anchors.centerIn: parent
                        text: sectionCard.glyph
                        color: sectionCard.accentColor
                        font.family: root.faSolid
                        font.pixelSize: 14
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: sectionCard.title
                        color: Colors.dsText
                        font.family: FontSystem.getContentFontBold.name
                        font.pixelSize: Typography.uiTitleSm
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: sectionCard.subtitle.length > 0
                        text: sectionCard.subtitle
                        color: Colors.dsTextMuted
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: Typography.uiBody
                        wrapMode: Text.WordWrap
                    }
                }
            }

            ColumnLayout {
                id: sectionBody
                Layout.fillWidth: true
                spacing: 10
            }
        }
    }

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
                    text: statTile.label
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
                text: lanBadge.text
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
                text: lanAction.text
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
                    text: lanInfoCell.label
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
                text: presetTile.title
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
                text: guideStep.text
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
                    text: lanModeCard.modeName
                    color: Colors.dsText
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: Typography.uiBodyLg
                    font.bold: true
                    elide: Text.ElideRight
                }

                LanBadge {
                    visible: lanModeCard.badgeText.length > 0
                    text: lanModeCard.badgeText
                    glyph: "\uf0a3"
                    badgeColor: Qt.rgba(lanModeCard.accentColor.r, lanModeCard.accentColor.g, lanModeCard.accentColor.b, Colors.lightMode ? 0.10 : 0.16)
                    borderColor: Qt.rgba(lanModeCard.accentColor.r, lanModeCard.accentColor.g, lanModeCard.accentColor.b, Colors.lightMode ? 0.30 : 0.44)
                    textColor: lanModeCard.accentColor
                }

                Text {
                    Layout.fillWidth: true
                    text: lanModeCard.summary
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

    component PowerHomeBadge: Rectangle {
        id: homeBadge

        property string modeName: "Normal"
        property bool compact: true
        readonly property color accentColor: root.powerModeAccent(modeName)
        readonly property string glyph: root.powerModeGlyph(modeName)

        signal clicked()

        Layout.preferredWidth: compact ? 34 : Math.max(82, badgeRow.implicitWidth + 18)
        Layout.preferredHeight: compact ? 34 : 36
        Layout.alignment: Qt.AlignVCenter
        radius: height / 2
        color: homeBadgeMouse.pressed
               ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, Colors.lightMode ? 0.22 : 0.32)
               : Qt.rgba(accentColor.r, accentColor.g, accentColor.b, Colors.lightMode ? 0.12 : 0.20)
        border.width: 1
        border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, Colors.lightMode ? 0.28 : 0.46)
        scale: homeBadgeMouse.pressed ? 0.96 : 1.0

        Behavior on color {
            enabled: root.powerVisualAnimationsEnabled
            ColorAnimation { duration: 140 }
        }

        Behavior on border.color {
            enabled: root.powerVisualAnimationsEnabled
            ColorAnimation { duration: 140 }
        }

        Behavior on scale {
            enabled: root.powerVisualAnimationsEnabled
            NumberAnimation { duration: 90 }
        }

        RowLayout {
            id: badgeRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: homeBadge.glyph
                color: homeBadge.accentColor
                font.family: root.faSolid
                font.pixelSize: homeBadge.compact ? 13 : 12
            }

            Text {
                visible: !homeBadge.compact
                text: homeBadge.modeName === "High Performance" ? "Performance" : homeBadge.modeName
                color: homeBadge.accentColor
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: 11
                font.bold: true
            }
        }

        MouseArea {
            id: homeBadgeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: homeBadge.clicked()
        }

        ToolTip.visible: homeBadgeMouse.containsMouse
        ToolTip.text: homeBadge.modeName + " Power Mode"
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
            topLeftRadius: 16
            topRightRadius: 16
            bottomLeftRadius: 0
            bottomRightRadius: 0
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
                visible: !root.compact
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
        id: donationSuggestPopup
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 0
        width: root.sheetWidth(400)
        height: donationSuggestContent.implicitHeight + 28 + (root.mobilePlatform ? Math.max(20, root.safeBottomInset + 20) : 0)
        x: (root.width - width) * 0.5
        y: root.compact
           ? root.height - height
           : root.drawerY(height)
        z: 210

        enter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "y"
                    from: donationSuggestPopup.y + 26
                    to: donationSuggestPopup.y
                    duration: Animations.fast
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Animations.fast
                }
            }
        }

        exit: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "y"
                    to: donationSuggestPopup.y + 18
                    duration: Animations.fast * 0.75
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    property: "opacity"
                    to: 0
                    duration: Animations.fast * 0.7
                }
            }
        }

        background: Rectangle {
            topLeftRadius: 16
            topRightRadius: 16
            bottomLeftRadius: 0
            bottomRightRadius: 0
            color: root.themeColorToken("mainHex_ffffff", "mainHex_090b14")
            border.width: 0
            border.color: root.themeColorToken("mainHex_d6dfec", "mainHex_30435d")
        }

        contentItem: ColumnLayout {
            id: donationSuggestContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.topMargin: 14
            anchors.bottomMargin: 14 + (root.mobilePlatform ? Math.max(12, root.safeBottomInset) : 0)
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    radius: 13
                    color: Qt.rgba(Colors.dsDanger.r, Colors.dsDanger.g, Colors.dsDanger.b, root.darkThemeEnabled ? 0.30 : 0.14)

                    Text {
                        anchors.centerIn: parent
                        text: root.iconHeart
                        font.family: root.faSolid
                        font.pixelSize: 12
                        color: Colors.dsDanger
                    }

                    SequentialAnimation on scale {
                        running: donationSuggestPopup.visible
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.04; duration: 760; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 760; easing.type: Easing.InOutSine }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Enjoying GenyConnect?"
                    color: root.themeColorToken("mainHex_1f2a3a", "mainHex_d8e1f0")
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: 17
                    font.bold: true
                    wrapMode: Text.WordWrap
                }
            }

            Text {
                Layout.fillWidth: true
                text: "If it helps, you can support development with a small donation."
                color: root.themeColorToken("mainHex_667385", "mainHex_9bb0cb")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Controls.Button {
                    text: "Not now"
                    Layout.fillWidth: true
                    isDefault: false
                    onClicked: donationSuggestPopup.close()
                }

                Controls.Button {
                    text: "Support"
                    Layout.fillWidth: true
                    onClicked: {
                        donationSuggestPopup.close()
                        root.openSettingsSection("donate")
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
            topLeftRadius: 24
            topRightRadius: 24
            bottomLeftRadius: 0
            bottomRightRadius: 0
            color: root.themeColorToken("mainHex_ffffff", "mainHex_090b14")
            border.width: 0
            border.color: root.themeColorToken("mainHex_d7deea", "mainHex_30435d")
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: root.compact ? 12 : 16
            anchors.rightMargin: root.compact ? 12 : 16
            anchors.topMargin: root.compact ? 12 : 16
            anchors.bottomMargin: root.compact ? (12 + root.safeBottomInset) : 16
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
            if (vpnController.currentProfileIndex >= 0)
                vpnController.pingProfile(vpnController.currentProfileIndex)
            if (vpnController.autoPingProfiles)
                vpnController.pingAllProfiles()
        }
        onOpened: {
            if (!root.compact)
                profileSearchField.forceActiveFocus()
            else if (Qt.inputMethod && Qt.inputMethod.visible)
                Qt.inputMethod.hide()
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
            topLeftRadius: root.compact ? 0 : 22
            topRightRadius: root.compact ? 0 : 22
            bottomLeftRadius: 0
            bottomRightRadius: 0
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
                            + (root.compact ? compactActionIconRow.implicitHeight : actionsRow.implicitHeight)
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
                anchors.leftMargin: root.compact ? 16 : 10
                anchors.rightMargin: root.compact ? 16 : 10
                anchors.topMargin: root.compact ? (12 + root.safeTopInset) : 10
                anchors.bottomMargin: root.compact ? 24 : 10
                spacing: root.compact ? 12 : 8

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
                    implicitHeight: root.compact ? 48 : 58
                    radius: 14
                    color: Colors.dsSurface
                    border.width: 0
                    border.color: profileSearchField.activeFocus
                                  ? Colors.dsPrimarySolid
                                  : Colors.dsBorder
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
                        selectByMouse: true
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
                                if (!root.compact)
                                    profileSearchField.forceActiveFocus()
                            }
                        }
                    }
                }

                RowLayout {
                    id: compactActionIconRow
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    spacing: 8
                    visible: root.compact

                    Item { Layout.fillWidth: true }

                    Controls.CircleIconButton {
                        diameter: 32
                        elevated: false
                        enabled: listView.count > 0
                        iconText: root.iconTrash
                        iconFontFamily: root.faSolid
                        iconPixelSize: 13
                        backgroundColor: Qt.rgba(Colors.dsDanger.r, Colors.dsDanger.g, Colors.dsDanger.b, root.darkThemeEnabled ? 0.24 : 0.12)
                        iconColor: Colors.dsDanger
                        onClicked: clearProfilesPopup.open()
                    }

                    Controls.CircleIconButton {
                        diameter: 32
                        elevated: false
                        enabled: listView.count > 0
                        iconText: root.iconPing
                        iconFontFamily: root.faSolid
                        iconPixelSize: 12
                        backgroundColor: Colors.dsSurface
                        borderColor: Colors.dsBorder
                        iconColor: root.themeColorToken("mainHex_4b5d78", "mainHex_b0c3db")
                        onClicked: vpnController.pingAllProfiles()
                    }

                    Item {
                        width: 32
                        height: 32

                        Controls.CircleIconButton {
                            anchors.fill: parent
                            diameter: 32
                            elevated: false
                            enabled: vpnController.subscriptions.length > 0 && !vpnController.subscriptionBusy
                            iconText: "\uf2f1"
                            iconFontFamily: root.faSolid
                            iconPixelSize: 12
                            backgroundColor: Colors.dsSurface
                            borderColor: Colors.dsBorder
                            iconColor: root.themeColorToken("mainHex_4b5d78", "mainHex_b0c3db")
                            onClicked: {
                                const current = (vpnController.currentProfileGroup || "All")
                                if (current === "All")
                                    vpnController.refreshSubscriptions()
                                else
                                    vpnController.refreshSubscriptionsByGroup(current)
                            }
                        }

                        BusyIndicator {
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            running: vpnController.subscriptionBusy
                            visible: vpnController.subscriptionBusy
                        }
                    }

                    Controls.CircleIconButton {
                        diameter: 32
                        elevated: false
                        enabled: listView.count > 0
                        iconText: root.iconFileLines
                        iconFontFamily: root.faSolid
                        iconPixelSize: 12
                        backgroundColor: Colors.dsSurface
                        borderColor: Colors.dsBorder
                        iconColor: root.themeColorToken("mainHex_4b5d78", "mainHex_b0c3db")
                        onClicked: {
                            const payload = vpnController.exportProfiles([])
                            if ((payload || "").trim().length === 0) {
                                root.showSettingsFeedback("No profiles available to export.")
                                return
                            }
                            const shared = vpnController.shareText("GenyConnect Profiles Export", payload)
                            if (!shared)
                                vpnController.copyTextToClipboard(payload)
                            root.showSettingsFeedback(shared
                                                      ? "Export opened in share sheet."
                                                      : "Export copied to clipboard.")
                        }
                    }

                }

                GridLayout {
                    id: actionsRow
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 8
                    visible: !root.compact

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: root.compact ? 34 : 36
                        radius: root.compact ? 11 : 12
                        color: addProfileMouse.containsMouse ? Colors.dsPrimaryPressed : Colors.dsPrimarySolid
                        border.width: 0
                        border.color: Colors.dsPrimarySolid
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: root.compact ? "Add" : "Add Profile"
                            color: Colors.mainHex_ffffff
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: root.compact ? 12 : 13
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
                        Layout.preferredHeight: root.compact ? 34 : 36
                        radius: root.compact ? 11 : 12
                        color: clearAllMouse.containsMouse
                               ? Qt.rgba(Colors.dsDanger.r, Colors.dsDanger.g, Colors.dsDanger.b, root.darkThemeEnabled ? 0.34 : 0.18)
                               : Qt.rgba(Colors.dsDanger.r, Colors.dsDanger.g, Colors.dsDanger.b, root.darkThemeEnabled ? 0.26 : 0.12)
                        border.width: 0
                        border.color: Qt.rgba(Colors.dsDanger.r, Colors.dsDanger.g, Colors.dsDanger.b, root.darkThemeEnabled ? 0.45 : 0.24)
                        opacity: listView.count > 0 ? 1.0 : 0.55
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: root.compact ? "Delete" : "Delete Others"
                            color: Colors.dsDanger
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: root.compact ? 11 : 12
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
                        Layout.preferredHeight: root.compact ? 34 : 36
                        radius: root.compact ? 11 : 12
                        color: pingAllMouse.containsMouse
                               ? Colors.dsSurfaceSoft
                               : Colors.dsSurface
                        border.width: 0
                        border.color: Colors.dsBorder
                        opacity: listView.count > 0 ? 1.0 : 0.55
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: root.compact
                                  ? "Ping"
                                  : ((vpnController.currentProfileGroup || "All").toLowerCase() === "all"
                                     ? "Ping All"
                                     : "Ping Group")
                            color: root.themeColorToken("mainHex_4b5d78", "mainHex_b0c3db")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: root.compact ? 12 : 13
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
                        Layout.preferredHeight: root.compact ? 34 : 36
                        radius: root.compact ? 11 : 12
                        color: refreshSubsMouse.containsMouse
                               ? Colors.dsSurfaceSoft
                               : Colors.dsSurface
                        border.width: 0
                        border.color: Colors.dsBorder
                        opacity: vpnController.subscriptions.length > 0 ? 1.0 : 0.55
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: root.compact
                                  ? "Refresh"
                                  : ((vpnController.currentProfileGroup || "All") === "All"
                                     ? "Refresh Subs"
                                     : "Refresh Group")
                            color: root.themeColorToken("mainHex_4b5d78", "mainHex_b0c3db")
                            opacity: vpnController.subscriptionBusy ? 0.5 : 1.0
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: root.compact ? 12 : 13
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

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: root.compact ? 34 : 36
                        radius: root.compact ? 11 : 12
                        color: exportAllMouse.containsMouse
                               ? Colors.dsSurfaceSoft
                               : Colors.dsSurface
                        border.width: 0
                        border.color: Colors.dsBorder
                        opacity: listView.count > 0 ? 1.0 : 0.55
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: root.compact ? "Export" : "Export All"
                            color: root.themeColorToken("mainHex_4b5d78", "mainHex_b0c3db")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: root.compact ? 12 : 13
                            font.bold: false
                        }

                        MouseArea {
                            id: exportAllMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: listView.count > 0
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                const payload = vpnController.exportProfiles([])
                                if ((payload || "").trim().length === 0) {
                                    root.showSettingsFeedback("No profiles available to export.")
                                    return
                                }
                                const shared = vpnController.shareText("GenyConnect Profiles Export", payload)
                                if (!shared)
                                    vpnController.copyTextToClipboard(payload)
                                root.showSettingsFeedback(shared
                                                          ? "Export opened in share sheet."
                                                          : "Export copied to clipboard.")
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
                    Layout.preferredHeight: 38
                    spacing: 10
                    visible: root.compact

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 16
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
                            font.pixelSize: 12
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
                        Layout.preferredHeight: 36
                        radius: 16
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
                            font.pixelSize: 12
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
                        Layout.preferredHeight: 36
                        radius: 16
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
                            font.pixelSize: 12
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

                        onActivated: function(activatedIndex) {
                            const name = groupNameAt(activatedIndex)
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
                        spacing: root.compact ? 4 : 0
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
                            required property string originalLink
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
                            height: matched ? (root.compact ? 62 : 80) : 0
                            visible: matched

                            Rectangle {
                                id: rowBg
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.topMargin: root.compact ? 0 : 2
                                anchors.bottomMargin: root.compact ? 0 : 2
                                radius: root.compact ? 12 : 14
                                color: selected
                                       ? root.themeColorToken("mainHex_eef3ff", "mainHex_8a35527a")
                                       : (hoverArea.containsMouse
                                          ? root.themeColorToken("mainHex_f8fbff", "mainHex_7a2b4461")
                                          : root.themeColorToken("mainHex_ffffff", "mainHex_66263c56"))
                                border.width: selected ? 1.35 : 1
                                border.color: selected ? Colors.dsPrimarySolid : Colors.dsBorder
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
                                    anchors.leftMargin: root.compact ? 8 : 12
                                    anchors.rightMargin: root.compact ? 8 : 12
                                    spacing: root.compact ? 6 : 10

                                    Rectangle {
                                        Layout.preferredWidth: root.compact ? 30 : 38
                                        Layout.preferredHeight: root.compact ? 30 : 38
                                        radius: width / 2
                                        color: root.themeColorToken("mainHex_f3f6fb", "mainHex_20314b")
                                        border.width: 0
                                        border.color: root.themeColorToken("mainHex_dde4ef", "mainHex_151c32")

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.guessFlag(displayLabel)
                                            font.pixelSize: root.compact ? 17 : 21
                                        }
                                    }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    spacing: root.compact ? 3 : 4

                                    Text {
                                        Layout.fillWidth: true
                                        text: displayLabel
                                        font.family: FontSystem.getContentFontBold.name
                                        font.weight: Font.Bold
                                        font.pixelSize: root.compact ? 12 : 14
                                        color: root.themeColorToken("mainHex_202634", "mainHex_d7e4f6")
                                        elide: Text.ElideRight
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 1
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: root.compact ? 4 : 8

                                        Item {
                                            Layout.preferredWidth: root.compact ? 24 : 34
                                            Layout.preferredHeight: root.compact ? 20 : 22

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
                                            text: pinging ? "..." : (pingMs >= 0 ? (pingMs + " ms") : "--")
                                            color: pingMs >= 0 ? (pingMs < 250 ? Colors.mainHex_36d984 : (pingMs < 500 ? Colors.mainHex_d0ad19 : Colors.mainHex_ef4444)) : Colors.mainHex_9aa4b6
                                            font.family: FontSystem.getContentFontBold.name
                                            font.pixelSize: root.compact ? 11 : 12
                                            font.bold: true

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: vpnController.pingProfile(index)
                                            }
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: Math.min(compactBadgeText.implicitWidth + (root.compact ? 12 : 16), root.compact ? 72 : 92)
                                            Layout.preferredHeight: root.compact ? 17 : 21
                                            radius: root.compact ? 8 : 10
                                            color: root.themeColorToken("mainHex_edf2ff", "mainHex_223654")
                                            opacity: 0.92

                                            Text {
                                                id: compactBadgeText
                                                anchors.centerIn: parent
                                                text: groupBadge.length > 0
                                                      ? groupBadge
                                                      : (((vpnController.connected ? vpnController.runtimeTunActive : vpnController.tunMode)
                                                          ? "TUN" : "PROXY"))
                                                color: root.brandBlue
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: root.compact ? 9 : 11
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 1
                                            Layout.preferredHeight: root.compact ? 12 : 18
                                            color: root.themeColorToken("mainHex_c8d1e0", "mainHex_4e6686")
                                            opacity: 0.9
                                        }

                                        Text {
                                            text: root.iconPing
                                            color: pinging
                                                   ? root.brandBlue
                                                   : root.themeColorToken("mainHex_7e8ea8", "mainHex_9eb4ce")
                                            font.family: root.faSolid
                                            font.pixelSize: root.compact ? 12 : 14
                                            verticalAlignment: Text.AlignVCenter

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: vpnController.pingProfile(index)
                                            }
                                        }

                                        Item { Layout.fillWidth: true }
                                    }

                                    Text {
                                        visible: false
                                        text: protocol.toUpperCase() + " " + address + ":" + port + ((security || "").length ? " | " + security : "")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 12
                                        color: root.themeColorToken("mainHex_8c95a4", "mainHex_9fb4cd")
                                        elide: Text.ElideRight
                                        wrapMode: Text.NoWrap
                                        maximumLineCount: 1
                                    }

                                    Text {
                                        visible: false
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
                                    Layout.preferredWidth: root.compact ? 88 : 132
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: root.compact ? 2 : 10

                                    Text {
                                        Layout.preferredWidth: root.compact ? 17 : 20
                                        text: "\uf044"
                                        color: root.brandViolet
                                        font.family: root.faSolid
                                        font.pixelSize: root.compact ? 12 : 15
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.openEditProfile(index, displayLabel, groupName, originalLink)
                                        }
                                    }

                                    Text {
                                        Layout.preferredWidth: root.compact ? 17 : 20
                                        text: root.iconFileLines
                                        color: root.themeColorToken("mainHex_5b6f8e", "mainHex_a5bbd8")
                                        font.family: root.faSolid
                                        font.pixelSize: root.compact ? 12 : 15
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                const payload = vpnController.exportProfile(index)
                                                if ((payload || "").trim().length === 0) {
                                                    root.showSettingsFeedback("Profile export failed.")
                                                    return
                                                }
                                                const shared = vpnController.shareText("GenyConnect Profile Export", payload)
                                                if (!shared)
                                                    vpnController.copyTextToClipboard(payload)
                                                root.showSettingsFeedback(shared
                                                                          ? "Profile export opened."
                                                                          : "Profile export copied to clipboard.")
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.preferredWidth: root.compact ? 17 : 20
                                        text: "\uf029"
                                        color: root.themeColorToken("mainHex_5b6f8e", "mainHex_a5bbd8")
                                        font.family: root.faSolid
                                        font.pixelSize: root.compact ? 12 : 15
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.openProfileQrPopup(displayLabel, vpnController.exportProfile(index))
                                        }
                                    }

                                    Text {
                                        Layout.preferredWidth: root.compact ? 17 : 20
                                        visible: !selected
                                        text: root.iconTrash
                                        color: root.themeColorToken("mainHex_cb4f4f", "mainHex_ff8e8e")
                                        font.family: root.faSolid
                                        font.pixelSize: root.compact ? 12 : 15
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
                                        Layout.preferredWidth: selected ? (root.compact ? 17 : 20) : 0
                                        text: "\uf00c"
                                        color: root.themeColorToken("mainHex_1f6fe0", "mainHex_9fc4ff")
                                        font.family: root.faSolid
                                        font.pixelSize: root.compact ? 12 : 15
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        visible: selected
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
            topLeftRadius: 20
            topRightRadius: 20
            bottomLeftRadius: 0
            bottomRightRadius: 0
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
                text: "This removes inactive profiles only. Active/connected profile(s) will be kept."
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
                    text: "Delete Others"
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
        height: {
            if (root.compact) {
                const topGap = root.safeTopInset + 14
                return Math.max(420, root.height - topGap)
            }
            const target = editProfileContent.implicitHeight + 22
            return Math.min(root.height - 58, target)
        }
        x: (root.width - width) * 0.5
        y: root.compact ? (root.safeTopInset + 6) : root.drawerY(height)
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
            id: editProfileContent
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 16
            anchors.bottomMargin: root.compact ? 10 : 20
            spacing: 10

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
                font.pixelSize: root.compact ? 20 : 22
                font.bold: true
            }

            Flickable {
                id: editProfileBodyFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: editProfileBodyColumn.implicitHeight
                boundsBehavior: Flickable.DragAndOvershootBounds
                flickableDirection: Flickable.VerticalFlick
                interactive: true
                pressDelay: 80
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                ColumnLayout {
                    id: editProfileBodyColumn
                    width: editProfileBodyFlick.width
                    spacing: 12

                    Controls.TextField {
                        id: editProfileNameField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        text: root.editProfileName
                        placeholderText: "Profile name"
                        selectByMouse: true
                        onTextEdited: {
                            root.editProfileName = text
                            root.editProfileError = ""
                        }
                    }

                    Controls.TextField {
                        id: editProfileGroupField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        text: root.editProfileGroup
                        placeholderText: "Group"
                        selectByMouse: true
                        onTextEdited: {
                            root.editProfileGroup = text
                            root.editProfileError = ""
                        }
                    }

                    Rectangle {
                        id: editProfileVlessFormCard
                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        implicitHeight: editProfileVlessFormLayout.implicitHeight + 24
                        visible: root.editProfileVlessSupported
                        radius: 14
                        color: root.themeColor(Colors.dsSurfaceSoft, Colors.dsSurface)
                        border.width: 1
                        border.color: root.themeColor(Colors.dsBorderSoft, Colors.dsBorder)
                        clip: true

                        ColumnLayout {
                            id: editProfileVlessFormLayout
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            RowLayout {
                                visible: !root.compact
                                Layout.fillWidth: true
                                spacing: 8

                                Controls.TextField {
                                    Layout.preferredWidth: 100
                                    Layout.preferredHeight: 38
                                    readOnly: true
                                    text: "vless"
                                    selectByMouse: true
                                }
                                Controls.TextField {
                                    id: editProfileUuidFieldDesktop
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38
                                    readOnly: true
                                    text: root.editProfileVlessForm.uuid || ""
                                    placeholderText: "UUID (read only)"
                                    selectByMouse: true
                                    onTextChanged: cursorPosition = 0
                                }
                            }

                            ColumnLayout {
                                visible: root.compact
                                Layout.fillWidth: true
                                spacing: 8

                                Controls.TextField {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38
                                    readOnly: true
                                    text: "vless"
                                    selectByMouse: true
                                }
                                Controls.TextField {
                                    id: editProfileUuidFieldCompact
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38
                                    readOnly: true
                                    text: root.editProfileVlessForm.uuid || ""
                                    placeholderText: "UUID (read only)"
                                    selectByMouse: true
                                    onTextChanged: cursorPosition = 0
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Controls.TextField {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38
                                    text: root.editProfileVlessForm.address || ""
                                    placeholderText: "Address"
                                    selectByMouse: true
                                    onTextChanged: {
                                        root.editProfileVlessForm.address = text
                                        root.editProfileError = ""
                                    }
                                }
                                Controls.TextField {
                                    Layout.preferredWidth: 108
                                    Layout.preferredHeight: 38
                                    text: root.editProfileVlessForm.port || "443"
                                    placeholderText: "Port"
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    validator: IntValidator { bottom: 1; top: 65535 }
                                    selectByMouse: true
                                    onTextChanged: {
                                        root.editProfileVlessForm.port = text
                                        root.editProfileError = ""
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Controls.ComboBox {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38
                                    model: ["tcp", "ws", "xhttp", "grpc"]
                                    currentIndex: Math.max(0, model.indexOf(root.editProfileVlessForm.network || "tcp"))
                                    onActivated: function(activatedIndex) {
                                        root.editProfileVlessForm.network = model[activatedIndex]
                                        root.editProfileError = ""
                                    }
                                }
                                Controls.ComboBox {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38
                                    model: ["none", "tls", "reality"]
                                    currentIndex: Math.max(0, model.indexOf(root.editProfileVlessForm.security || "none"))
                                    onActivated: function(activatedIndex) {
                                        root.editProfileVlessForm.security = model[activatedIndex]
                                        root.editProfileError = ""
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Controls.TextField {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38
                                    text: root.editProfileVlessForm.encryption || "none"
                                    placeholderText: "Encryption (none/zero/...)"
                                    selectByMouse: true
                                    onTextChanged: {
                                        root.editProfileVlessForm.encryption = text
                                        root.editProfileError = ""
                                    }
                                }

                                Controls.TextField {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38
                                    text: root.editProfileVlessForm.flow || ""
                                    placeholderText: "Flow (optional)"
                                    selectByMouse: true
                                    onTextChanged: {
                                        root.editProfileVlessForm.flow = text
                                        root.editProfileError = ""
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Controls.TextField {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38
                                    text: root.editProfileVlessForm.sni || ""
                                    placeholderText: "SNI"
                                    selectByMouse: true
                                    onTextChanged: {
                                        root.editProfileVlessForm.sni = text
                                        root.editProfileError = ""
                                    }
                                }
                                Controls.TextField {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38
                                    text: root.editProfileVlessForm.host || ""
                                    placeholderText: "Host header"
                                    selectByMouse: true
                                    onTextChanged: {
                                        root.editProfileVlessForm.host = text
                                        root.editProfileError = ""
                                    }
                                }
                            }

                            Controls.TextField {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 38
                                text: root.editProfileVlessForm.path || ""
                                placeholderText: "Path (for ws/xhttp)"
                                selectByMouse: true
                                onTextChanged: {
                                    root.editProfileVlessForm.path = text
                                    root.editProfileError = ""
                                }
                            }
                        }
                    }

                    Controls.TextArea {
                        id: editProfileConfigArea
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.editProfileVlessSupported ? 120 : 140
                        placeholderText: "Paste or edit full profile link/config"
                        text: root.editProfileConfigLink
                        onTextChanged: {
                            root.editProfileConfigLink = text
                            root.editProfileError = ""
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.editProfileVlessSupported
                              ? "You can edit VLESS fields above or directly edit the full config text below."
                              : "Non-VLESS profiles can be edited using the full config text field."
                        color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: root.editProfileError.length > 0
                        text: root.editProfileError
                        color: root.themeColorToken("mainHex_c65050", "mainHex_ff8e8e")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Layout.topMargin: 2
                Layout.bottomMargin: root.safeBottomInset + 12

                Controls.Button {
                    Layout.fillWidth: true
                    text: "Cancel"
                    onClicked: editProfilePopup.close()
                }

                Controls.Button {
                    Layout.fillWidth: true
                    text: "Save"
                    onClicked: {
                        let saved = false
                        const rawConfigText = (editProfileConfigArea.text || "").trim()
                        const originalConfigText = (root.editProfileOriginalConfigLink || "").trim()
                        if (root.editProfileVlessSupported) {
                            const built = root.buildVlessLinkFromForm(root.editProfileVlessForm, editProfileNameField.text)
                            if (!built.ok) {
                                root.editProfileError = built.error || "Invalid config fields."
                                return
                            }
                            let configToSave = built.link
                            if (rawConfigText.length > 0
                                    && rawConfigText !== originalConfigText
                                    && rawConfigText !== (built.link || "").trim()) {
                                configToSave = rawConfigText
                            }
                            root.editProfileConfigLink = configToSave
                            saved = vpnController.updateProfile(
                                        root.editProfileRow,
                                        editProfileNameField.text,
                                        editProfileGroupField.text,
                                        root.editProfileConfigLink)
                        } else {
                            if (rawConfigText.length > 0) {
                                saved = vpnController.updateProfile(
                                            root.editProfileRow,
                                            editProfileNameField.text,
                                            editProfileGroupField.text,
                                            rawConfigText)
                            } else {
                                saved = vpnController.updateProfileBasics(
                                            root.editProfileRow,
                                            editProfileNameField.text,
                                            editProfileGroupField.text)
                            }
                        }

                        if (saved) {
                            root.editProfileError = ""
                            editProfilePopup.close()
                            root.syncSelectedProfileFromController()
                            Qt.callLater(root.positionProfilePopup)
                        } else {
                            root.editProfileError = vpnController.lastError || "Failed to update profile."
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.compact ? 6 : 2
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
            root.settingsSectionStack = ["main"]
            if (root.pendingSettingsSection.length > 0) {
                const targetSection = root.pendingSettingsSection
                root.pendingSettingsSection = ""
                if (targetSection !== "main")
                    root.openSettingsSection(targetSection)
            }
            if (root.settingsSection === "routing") {
                root.refreshAppRuleSuggestions()
                root.resetRoutingRuleDraft()
            } else if (root.settingsSection === "lan") {
                root.refreshLanHostCandidates()
            }
            root.syncCustomDnsDraftFromController()
        }
        onClosed: {
            root.settingsSection = "main"
            root.settingsSectionStack = ["main"]
            root.pendingSettingsSection = ""
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
            topLeftRadius: root.compact ? 0 : 24
            topRightRadius: root.compact ? 0 : 24
            bottomLeftRadius: 0
            bottomRightRadius: 0
            color: Colors.dsWindow
            border.width: 0
            border.color: Colors.dsBorderSoft
            clip: true
        }

        contentItem: Item {
            anchors.fill: parent
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: root.compact ? 12 : 16
                anchors.rightMargin: root.compact ? 12 : 16
                anchors.topMargin: root.compact ? (12 + root.safeTopInset) : 16
                anchors.bottomMargin: root.compact ? 12 : 16
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
                        onClicked: root.stepBackSettingsSection()
                    }

                    Text {
                        text: root.settingsTitle()
                        font.family: FontSystem.getContentFontBold.name
                        font.weight: Font.Bold
                        font.pixelSize: root.compact ? 18 : 24
                        color: Colors.dsText
                    }
                    Item { Layout.fillWidth: true }

                    Controls.CircleIconButton {
                        visible: root.compact && root.settingsSection === "donate"
                        diameter: 38
                        elevated: false
                        backgroundColor: root.themeColorToken("mainHex_faf9ff", "mainHex_151c32")
                        borderColor: root.themeColorToken("mainHex_f0eef8", "mainHex_151c32")
                        iconText: "\uf3ed"
                        iconFontFamily: root.faSolid
                        iconColor: root.themeColorToken("mainHex_2f6ff1", "mainHex_7faeff")
                        iconPixelSize: 15
                        enabled: false
                    }

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
                    contentHeight: settingsContent.implicitHeight + (root.compact ? (root.safeBottomInset + 12) : 0)
                    boundsBehavior: Flickable.DragAndOvershootBounds
                    flickableDirection: Flickable.VerticalFlick

                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: function(event) {
                            root.scrollFlickByWheel(settingsFlick, event)
                        }
                    }

                    ColumnLayout {
                        id: settingsContent
                        width: settingsFlick.width
                        x: 0
                        opacity: root.settingsPageOpacity
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
                                        { "title": "Power Mode", "icon": "\uf0e7", "action": "power" },
                                        { "title": "Routing Rules", "icon": "\uf542", "action": "routing" },
                                        { "title": "LAN Sharing", "icon": "\uf1eb", "action": "lan" },
                                        { "title": "Custom DNS", "icon": "\uf1eb", "action": "dns" },
                                        { "title": "Logs", "icon": "\uf1da", "action": "logs" },
                                        { "title": "Terms & License", "icon": "\uf15c", "action": "terms" },
                                        { "title": "Share App", "icon": "\uf1e0", "action": "share" },
                                        { "title": "Donate $GENY", "icon": "\uf4b9", "action": "donate" },
                                        { "title": "About App", "icon": "\uf05a", "action": "about" }
                                    ]

                                    delegate: Rectangle {
                                        required property var modelData
                                        color: "transparent"
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: rowControl.implicitHeight

                                        Controls.SettingRow {
                                            id: rowControl
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            compact: root.compact
                                            title: modelData.title
                                            glyph: modelData.icon
                                            glyphFontFamily: root.faSolid
                                            onClicked: root.openSettingsSection(modelData.action)
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
                                    text: "Choose visual behavior, privacy display, and the unit used by live transfer-rate indicators."
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
                                        onActivated: function(activatedIndex) {
                                            interfaceThemeSettings.mode = root.themeModeOptions[activatedIndex]
                                        }
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
                                        text: "IP Privacy"
                                        color: root.themeColorToken("mainHex_334155", "mainHex_c8d3e2")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 14
                                    }

                                    Controls.ComboBox {
                                        Layout.preferredWidth: 140
                                        Layout.preferredHeight: 40
                                        model: root.ipPrivacyOptions
                                        currentIndex: root.unitIndex(root.ipPrivacyOptions, interfacePrivacySettings.ipDisplayMode)
                                        onActivated: function(activatedIndex) {
                                            interfacePrivacySettings.ipDisplayMode = root.ipPrivacyOptions[activatedIndex]
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: interfacePrivacySettings.ipDisplayMode === "Hidden"
                                          ? "Home and status panels show *.*.*.* or Endpoint hidden instead of visible IP details."
                                          : (interfacePrivacySettings.ipDisplayMode === "Partial Mask"
                                             ? "Home and status panels keep enough context for troubleshooting while masking the precise address."
                                             : "Visible IP and endpoint details are shown normally.")
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
                                        onActivated: function(activatedIndex) {
                                            dashboardStatsSettings.speedUnit = root.speedUnitOptions[activatedIndex]
                                        }
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
                                        onActivated: function(activatedIndex) {
                                            dashboardStatsSettings.trafficUnit = root.trafficUnitOptions[activatedIndex]
                                        }
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
                                anchors.margins: root.compact ? 12 : 14
                                spacing: 8

                                Text {
                                    text: "Terms, Conditions & License"
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

                                Text {
                                    Layout.fillWidth: true
                                    text: "This app is provided without warranty. Review the full license text below before production deployment."
                                    color: root.themeColorToken("mainHex_7c8697", "mainHex_99abc4")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                }

                                Controls.Button {
                                    text: "Copy License Text"
                                    Layout.fillWidth: true
                                    isDefault: false
                                    onClicked: {
                                        vpnController.copyTextToClipboard(vpnController.licenseText())
                                        root.showSettingsFeedback("License copied to clipboard.")
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: root.compact ? 240 : 300
                                    radius: 12
                                    color: root.themeColorToken("mainHex_ffffff", "mainHex_1a2b42")
                                    border.width: 1
                                    border.color: root.themeColorToken("mainHex_dce4f1", "mainHex_355173")
                                    clip: true

                                    Flickable {
                                        id: termsLicenseFlick
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        contentWidth: width
                                        contentHeight: licenseBody.implicitHeight
                                        clip: true

                                        WheelHandler {
                                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                            onWheel: function(event) {
                                                root.scrollFlickByWheel(termsLicenseFlick, event)
                                            }
                                        }

                                        Text {
                                            id: licenseBody
                                            width: parent.width
                                            text: vpnController.licenseText()
                                            color: root.themeColorToken("mainHex_4d607a", "mainHex_b5c7de")
                                            font.family: FontSystem.contentFontFamily
                                            font.pixelSize: 11
                                            wrapMode: Text.Wrap
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "share"
                            implicitHeight: shareColumn.implicitHeight + 28
                            radius: Metrics.radiusXl
                            color: Colors.dsSurfaceSoft
                            border.width: 1
                            border.color: Colors.dsBorderSoft

                            ColumnLayout {
                                id: shareColumn
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                Text {
                                    text: "Share App"
                                    color: Colors.dsText
                                    font.family: FontSystem.getContentFontBold.name
                                    font.pixelSize: Typography.uiTitleLg
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Share GenyConnect using the native share sheet on mobile or desktop integrations where available."
                                    color: Colors.dsTextMuted
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: Typography.uiBodyLg
                                    wrapMode: Text.WordWrap
                                }

                                Controls.PrimaryButton {
                                    text: "Share Now"
                                    glyph: "\uf1e0"
                                    glyphFontFamily: root.faSolid
                                    Layout.fillWidth: true
                                    onClicked: root.shareAppNow()
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: root.compact ? 1 : 2
                                    columnSpacing: 8
                                    rowSpacing: 8

                                    Controls.LinkRow {
                                        title: "Copy App Link"
                                        glyph: "\uf0c5"
                                        iconBackground: Colors.dsLinkIconBgPurple
                                        iconColor: Colors.dsLinkIconPurple
                                        Layout.fillWidth: true
                                        onClicked: {
                                            vpnController.copyTextToClipboard(root.appSiteUrl)
                                            root.showSettingsFeedback("App link copied.")
                                        }
                                    }

                                    Controls.LinkRow {
                                        title: "Copy Repo Link"
                                        glyph: "\uf0c5"
                                        iconBackground: Colors.dsLinkIconBgPurple
                                        iconColor: Colors.dsLinkIconPurple
                                        Layout.fillWidth: true
                                        onClicked: {
                                            vpnController.copyTextToClipboard(root.appRepoUrl)
                                            root.showSettingsFeedback("Repository link copied.")
                                        }
                                    }

                                    Controls.LinkRow {
                                        title: "Open Website"
                                        glyph: "\uf35d"
                                        iconBackground: Colors.dsLinkIconBgBlue
                                        iconColor: Colors.dsLinkIconBlue
                                        Layout.fillWidth: true
                                        onClicked: Qt.openUrlExternally(root.appSiteUrl)
                                    }

                                    Controls.LinkRow {
                                        title: "Open Repository"
                                        glyph: "\uf09b"
                                        glyphFontFamily: FontSystem.getAwesomeBrand.name
                                        iconBackground: Colors.dsSurface
                                        iconColor: Colors.dsText
                                        Layout.fillWidth: true
                                        onClicked: Qt.openUrlExternally(root.appRepoUrl)
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: root.settingsFeedbackText.length > 0
                                    text: root.settingsFeedbackText
                                    color: root.themeColorToken("mainHex_2c8b57", "mainHex_5adf97")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "about"
                            implicitHeight: aboutSettingsColumn.implicitHeight + 28
                            radius: Metrics.radiusXl
                            color: Colors.dsSurfaceSoft
                            border.width: 1
                            border.color: Colors.dsBorderSoft

                            ColumnLayout {
                                id: aboutSettingsColumn
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Rectangle {
                                        Layout.preferredWidth: 42
                                        Layout.preferredHeight: 42
                                        radius: 21
                                        color: Colors.dsPrimaryTint
                                        border.width: 1
                                        border.color: Colors.dsBorder

                                        Text {
                                            anchors.centerIn: parent
                                            text: "\uf05a"
                                            font.family: root.faSolid
                                            font.pixelSize: 16
                                            color: Colors.dsPrimarySolid
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            text: "About GenyConnect"
                                            color: Colors.dsText
                                            font.family: FontSystem.getContentFontBold.name
                                            font.pixelSize: Typography.uiTitleLg
                                            font.bold: true
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: "Secure, profile-based connectivity for desktop and mobile runtimes."
                                            color: Colors.dsTextMuted
                                            font.family: FontSystem.contentFontFamily
                                            font.pixelSize: Typography.uiBody
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    radius: Metrics.radiusMd
                                    color: Colors.dsPrimaryTint
                                    border.width: 1
                                    border.color: Colors.dsBorderSoft
                                    implicitHeight: visionText.implicitHeight + 16

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8

                                        Text {
                                            text: "\uf004"
                                            font.family: root.faSolid
                                            font.pixelSize: 13
                                            color: Colors.dsDanger
                                        }

                                        Text {
                                            id: visionText
                                            Layout.fillWidth: true
                                            text: "We stand with IRAN, with love."
                                            color: Colors.dsText
                                            font.family: FontSystem.getContentFontBold.name
                                            font.pixelSize: Typography.uiBody
                                            font.bold: true
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    radius: 10
                                    color: root.themeColorToken("mainHex_ffffff", "mainHex_1a2b42")
                                    border.width: 1
                                    border.color: root.themeColorToken("mainHex_dce4f1", "mainHex_355173")
                                    implicitHeight: aboutDetailsGrid.implicitHeight + 14

                                    GridLayout {
                                        id: aboutDetailsGrid
                                        anchors.fill: parent
                                        anchors.margins: 7
                                        columns: 2
                                        columnSpacing: 8
                                        rowSpacing: 5

                                        Text {
                                            text: "App Version"
                                            color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                                            font.family: FontSystem.contentFontFamily
                                            font.pixelSize: 12
                                        }
                                        Text {
                                            text: updater.appVersion
                                            color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                            font.family: FontSystem.getContentFontBold.name
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignRight
                                        }

                                        Text {
                                            text: "xray-core"
                                            color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                                            font.family: FontSystem.contentFontFamily
                                            font.pixelSize: 12
                                        }
                                        Text {
                                            text: vpnController.xrayVersion
                                            color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                            font.family: FontSystem.getContentFontBold.name
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignRight
                                        }

                                        Text {
                                            text: "Platform"
                                            color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                                            font.family: FontSystem.contentFontFamily
                                            font.pixelSize: 12
                                        }
                                        Text {
                                            text: osNameText() + (vpnController.isMobile ? " (Mobile)" : " (Desktop)")
                                            color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                            font.family: FontSystem.getContentFontBold.name
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignRight
                                        }

                                        Text {
                                            text: "Developer"
                                            color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                                            font.family: FontSystem.contentFontFamily
                                            font.pixelSize: 12
                                        }
                                        Text {
                                            text: "Genyleap LLC"
                                            color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                            font.family: FontSystem.getContentFontBold.name
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Controls.PrimaryButton {
                                        Layout.fillWidth: true
                                        text: "Open Project"
                                        onClicked: Qt.openUrlExternally(root.appRepoUrl)
                                    }

                                    Controls.OutlineButton {
                                        Layout.fillWidth: true
                                        text: "Share App"
                                        onClicked: root.openSettingsSection("share")
                                    }
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: root.compact ? 1 : 2
                                    columnSpacing: 8
                                    rowSpacing: 8

                                    Controls.OutlineButton {
                                        Layout.fillWidth: true
                                        text: "Website"
                                        onClicked: Qt.openUrlExternally(root.appSiteUrl)
                                    }

                                    Controls.OutlineButton {
                                        Layout.fillWidth: true
                                        text: "Support"
                                        onClicked: Qt.openUrlExternally("https://genyleap.com/support")
                                    }

                                    Controls.PrimaryButton {
                                        Layout.fillWidth: true
                                        Layout.columnSpan: root.compact ? 1 : 2
                                        text: "Support Development"
                                        onClicked: root.openSettingsSection("donate")
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "donate"
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: root.mobilePlatform ? Math.min(settingsFlick.width, 390) : settingsFlick.width
                            Layout.maximumWidth: root.mobilePlatform ? Math.min(settingsFlick.width, 390) : settingsFlick.width
                            implicitHeight: donateColumn.implicitHeight + 24 + (root.compact ? root.safeBottomInset : 0)
                            radius: 0
                            color: "transparent"
                            border.width: 0
                            border.color: "transparent"

                            ColumnLayout {
                                id: donateColumn
                                anchors.fill: parent
                                anchors.margins: root.compact ? 12 : 16
                                spacing: root.compact ? 14 : 16
                                readonly property var activeToken: root.donationTokenBySymbol(root.donationSelectedToken)
                                readonly property int amountColumns: width < 320 ? 2 : 4
                                readonly property int usefulLinkColumns: width < 430 ? 1 : 2

                                Controls.SupportHeroCard {
                                    Layout.fillWidth: true
                                    compact: root.compact
                                    title: "Support GenyConnect"
                                    description: "Your donation helps us improve GenyConnect, maintain infrastructure, and grow the Geny ecosystem."
                                    networkName: root.donationConfig.networkName || "Base Mainnet"
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    color: Colors.dsSurface
                                    border.width: 1
                                    border.color: Colors.dsBorder
                                    radius: 24
                                    implicitHeight: donationCardColumn.implicitHeight + 26

                                    ColumnLayout {
                                        id: donationCardColumn
                                        anchors.fill: parent
                                        anchors.margins: root.compact ? 16 : 20
                                        spacing: 14

                                        Text {
                                            Layout.fillWidth: true
                                            text: "1. Choose Token"
                                            color: Colors.dsText
                                            font.family: FontSystem.getContentFontBold.name
                                            font.pixelSize: root.compact ? 16 : 18
                                            font.bold: true
                                        }

                                        Item {
                                            id: donationTokenArea
                                            Layout.fillWidth: true
                                            implicitHeight: donationTokenFlow.implicitHeight
                                            readonly property real gap: root.mobilePlatform ? 8 : 10
                                            readonly property int tokenColumns: root.compact ? 1 : 2
                                            readonly property real tokenCellWidth: tokenColumns > 1
                                                                                   ? Math.floor((width - gap) / 2)
                                                                                   : width

                                            Flow {
                                                id: donationTokenFlow
                                                width: parent.width
                                                spacing: donationTokenArea.gap

                                                Repeater {
                                                    model: root.donationTokens
                                                    delegate: Controls.TokenOptionCard {
                                                        required property var modelData
                                                        width: donationTokenArea.tokenCellWidth
                                                        selected: (modelData.symbol || "") === root.donationSelectedToken
                                                        title: modelData.symbol || ""
                                                        subtitle: modelData.displayName || ""
                                                        badgeText: modelData.recommended === true ? "Recommended" : ""
                                                        iconImageSource: ""
                                                        iconGlyph: (modelData.symbol || "").toUpperCase() === "GENY"
                                                                   ? root.iconDna
                                                                   : ((modelData.symbol || "").toUpperCase() === "USDC" ? "\uf51e" : "")
                                                        iconBackground: (modelData.symbol || "").toUpperCase() === "GENY"
                                                                        ? Colors.dsLinkIconBgGreen
                                                                        : Colors.dsLinkIconBgBlue
                                                        iconColor: (modelData.symbol || "").toUpperCase() === "GENY"
                                                                   ? Colors.dsLinkIconGreen
                                                                   : Colors.dsLinkIconBlue
                                                        imageFallbackText: "G"
                                                        onClicked: root.selectDonationToken(modelData.symbol || "")
                                                    }
                                                }
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            visible: donateColumn.activeToken !== null
                                            text: donateColumn.activeToken ? donateColumn.activeToken.message || "" : ""
                                            color: Colors.dsTextMuted
                                            font.family: FontSystem.contentFontFamily
                                            font.pixelSize: Typography.uiBodySm
                                            wrapMode: Text.WordWrap
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: "2. Choose Amount"
                                            color: Colors.dsText
                                            font.family: FontSystem.getContentFontBold.name
                                            font.pixelSize: root.compact ? 16 : 18
                                            font.bold: true
                                        }

                                        GridLayout {
                                            Layout.fillWidth: true
                                            columns: donateColumn.amountColumns
                                            columnSpacing: 8
                                            rowSpacing: 8

                                            Repeater {
                                                model: donateColumn.activeToken && donateColumn.activeToken.presetAmounts
                                                       ? donateColumn.activeToken.presetAmounts : []
                                                delegate: Controls.AmountButton {
                                                    required property var modelData
                                                    Layout.fillWidth: true
                                                    label: modelData
                                                    selected: root.donationSelectedAmountPreset === modelData
                                                    onClicked: {
                                                        root.donationSelectedAmountPreset = modelData
                                                        root.donationValidationError = ""
                                                        if (modelData !== "Custom")
                                                            root.donationCustomAmount = ""
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            visible: root.donationSelectedAmountPreset === "Custom"
                                            radius: Metrics.radiusSm
                                            color: Colors.dsSurfaceSoft
                                            border.width: 1
                                            border.color: Colors.dsBorder
                                            implicitHeight: Metrics.rowHeight

                                            TextField {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                text: root.donationCustomAmount
                                                placeholderText: "Enter custom amount"
                                                color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 13
                                                background: null
                                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                                                onTextChanged: {
                                                    root.donationCustomAmount = text
                                                    root.donationValidationError = ""
                                                }
                                            }
                                        }

                                        Controls.DonationSummaryCard {
                                            Layout.fillWidth: true
                                            amountText: root.donationEffectiveAmountText()
                                            tokenSymbol: root.donationSelectedToken
                                            estimatedValueText: root.donationEstimatedUsdText()
                                        }

                                        Controls.PrimaryButton {
                                            text: "Connect Wallet & Donate"
                                            glyph: "\uf555"
                                            glyphFontFamily: root.faSolid
                                            Layout.fillWidth: true
                                            onClicked: root.triggerDonation(Qt.platform.os === "android")
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: "\uf023"
                                                color: Colors.dsTextSubtle
                                                font.family: root.faSolid
                                                font.pixelSize: Typography.uiBodySm
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: "Secure • Non-custodial • You stay in control"
                                                color: Colors.dsTextSubtle
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: Typography.uiBodySm
                                                horizontalAlignment: Text.AlignHCenter
                                                wrapMode: Text.WordWrap
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            visible: root.donationValidationError.length > 0
                                            text: root.donationValidationError
                                            color: Colors.dsDanger
                                            font.family: FontSystem.contentFontFamily
                                            font.pixelSize: Typography.uiBody
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Useful Links"
                                    color: Colors.dsText
                                    font.family: FontSystem.getContentFontBold.name
                                    font.pixelSize: root.compact ? 16 : 18
                                    font.bold: true
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: donateColumn.usefulLinkColumns
                                    columnSpacing: 10
                                    rowSpacing: 10

                                    Controls.UsefulLinkCard {
                                        title: "Copy Creator Address"
                                        glyph: "\uf0c5"
                                        iconBackground: Colors.dsLinkIconBgPurple
                                        iconColor: Colors.dsLinkIconPurple
                                        Layout.fillWidth: true
                                        onClicked: {
                                            vpnController.copyTextToClipboard(root.donationConfig.receiverWallet || "")
                                            root.donationFeedbackText = "Receiver wallet copied."
                                            donationFeedbackTimer.restart()
                                        }
                                    }

                                    Controls.UsefulLinkCard {
                                        title: "Copy GENY Token CA"
                                        glyph: "\uf0c5"
                                        iconBackground: Colors.dsLinkIconBgPurple
                                        iconColor: Colors.dsLinkIconPurple
                                        Layout.fillWidth: true
                                        onClicked: {
                                            const token = root.donationTokenBySymbol("GENY")
                                            vpnController.copyTextToClipboard(token ? token.contract || "" : "")
                                            root.donationFeedbackText = "Token contract copied."
                                            donationFeedbackTimer.restart()
                                        }
                                    }

                                    Controls.UsefulLinkCard {
                                        title: "Creator BaseScan"
                                        glyph: "\uf029"
                                        iconBackground: Colors.dsLinkIconBgBlue
                                        iconColor: Colors.dsLinkIconBlue
                                        Layout.fillWidth: true
                                        onClicked: Qt.openUrlExternally(root.donationConfig.receiverBaseScanUrl || "")
                                    }

                                    Controls.UsefulLinkCard {
                                        title: "Token BaseScan"
                                        glyph: "\uf029"
                                        iconBackground: Colors.dsLinkIconBgBlue
                                        iconColor: Colors.dsLinkIconBlue
                                        Layout.fillWidth: true
                                        onClicked: {
                                            const token = donateColumn.activeToken
                                            Qt.openUrlExternally(token ? token.baseScanUrl || "" : "")
                                        }
                                    }

                                    Controls.UsefulLinkCard {
                                        title: "Swap on Uniswap"
                                        glyph: "\uf0ec"
                                        glyphFontFamily: FontSystem.getAwesomeBrand.name
                                        iconBackground: Colors.dsLinkIconBgPurple
                                        iconColor: Colors.dsLinkIconPurple
                                        Layout.fillWidth: true
                                        onClicked: {
                                            const token = donateColumn.activeToken
                                            Qt.openUrlExternally(token ? token.uniswapUrl || "" : "")
                                        }
                                    }

                                    Controls.UsefulLinkCard {
                                        title: "White Paper"
                                        glyph: "\uf15c"
                                        iconBackground: Colors.dsLinkIconBgGreen
                                        iconColor: Colors.dsLinkIconGreen
                                        Layout.fillWidth: true
                                        onClicked: Qt.openUrlExternally(root.donationConfig.whitePaperUrl || "")
                                    }

                                    Controls.UsefulLinkCard {
                                        title: "GENY Repository"
                                        glyph: "\uf09b"
                                        glyphFontFamily: FontSystem.getAwesomeBrand.name
                                        iconBackground: Colors.dsSurface
                                        iconColor: Colors.dsText
                                        Layout.fillWidth: true
                                        onClicked: Qt.openUrlExternally(root.donationConfig.tokenRepoUrl || "")
                                    }
                                }

                                // ColumnLayout {
                                //     Layout.fillWidth: true
                                //     spacing: 4

                                //     Row {
                                //         Layout.alignment: Qt.AlignHCenter
                                //         spacing: 6

                                //         Text {
                                //             text: "\uf3ed"
                                //             color: Colors.dsTextSubtle
                                //             font.family: root.faSolid
                                //             font.pixelSize: Typography.uiBody
                                //         }

                                //         Text {
                                //             text: "Donations are voluntary and non-refundable."
                                //             color: Colors.dsTextSubtle
                                //             font.family: FontSystem.contentFontFamily
                                //             font.pixelSize: Typography.uiBodySm
                                //         }
                                //     }

                                //     Row {
                                //         Layout.alignment: Qt.AlignHCenter
                                //         spacing: 6

                                //         Text {
                                //             text: "\uf3ed"
                                //             color: Colors.dsTextSubtle
                                //             font.family: root.faSolid
                                //             font.pixelSize: Typography.uiBody
                                //         }

                                //         Text {
                                //             text: "Always verify the network and receiver address before sending."
                                //             color: Colors.dsTextSubtle
                                //             font.family: FontSystem.contentFontFamily
                                //             font.pixelSize: Typography.uiBodySm
                                //         }
                                //     }

                                // }

                                Text {
                                    Layout.fillWidth: true
                                    visible: root.donationFeedbackText.length > 0
                                    text: root.donationFeedbackText
                                    color: Colors.dsSuccess
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: Typography.uiBody
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "updates" && vpnController.supportsAutoUpdate
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

                                Rectangle {
                                    id: updateProgressTrack
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 8
                                    visible: updater.checking
                                    radius: 4
                                    color: root.themeColorToken("mainHex_dfe7f2", "mainHex_223147")
                                    border.width: 0
                                    clip: true

                                    readonly property real normalizedProgress: Math.max(0, Math.min(1, updater.downloadProgress))
                                    readonly property bool indeterminateMode: normalizedProgress <= 0.001 || normalizedProgress >= 0.999

                                    Rectangle {
                                        id: updateProgressDeterminate
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: parent.height
                                        radius: parent.radius
                                        visible: !parent.indeterminateMode
                                        width: parent.width * parent.normalizedProgress
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: root.themeColorToken("mainHex_2f74ff", "mainHex_3f7cf3") }
                                            GradientStop { position: 1.0; color: root.themeColorToken("mainHex_7b53ff", "mainHex_7f72ff") }
                                        }
                                    }

                                    Rectangle {
                                        id: updateProgressIndeterminate
                                        width: Math.max(36, parent.width * 0.26)
                                        height: parent.height
                                        y: 0
                                        x: -width
                                        radius: parent.radius
                                        visible: parent.indeterminateMode
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: "transparent" }
                                            GradientStop { position: 0.2; color: root.themeColorToken("mainHex_2f74ff", "mainHex_3f7cf3") }
                                            GradientStop { position: 0.8; color: root.themeColorToken("mainHex_7b53ff", "mainHex_7f72ff") }
                                            GradientStop { position: 1.0; color: "transparent" }
                                        }

                                        NumberAnimation on x {
                                            running: updater.checking && updateProgressIndeterminate.visible
                                            from: -updateProgressIndeterminate.width
                                            to: updateProgressTrack.width
                                            duration: 1100
                                            loops: Animation.Infinite
                                            easing.type: Easing.InOutQuad
                                        }
                                    }
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
                                        visible: !root.mobilePlatform
                                        enabled: !root.mobilePlatform && updater.releaseUrl.length > 0
                                        Layout.fillWidth: true
                                        onClicked: updater.openReleasePage()
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "updates" && !vpnController.supportsAutoUpdate && !root.mobilePlatform
                            Layout.maximumWidth: settingsFlick.width
                            implicitHeight: manualUpdateColumn.implicitHeight + 24
                            radius: Colors.innerRadius
                            color: root.themeColorToken("mainHex_eff4fb", "mainHex_151c32")
                            border.width: 1
                            border.color: root.themeColorToken("mainHex_d7e4f6", "mainHex_30435d")

                            ColumnLayout {
                                id: manualUpdateColumn
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 8

                                Text {
                                    Layout.fillWidth: true
                                    text: "App Updates"
                                    color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 15
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Current " + updater.appVersion
                                    color: root.themeColorToken("mainHex_677385", "mainHex_9bb0cb")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 13
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Auto-update is not available on this runtime build. Use the release page to get the latest APK or desktop package."
                                    color: root.themeColorToken("mainHex_5f6f88", "mainHex_9bb0cb")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                }

                                Controls.Button {
                                    text: "Release Page"
                                    Layout.fillWidth: true
                                    onClicked: updater.openReleasePage()
                                }

                                Controls.Button {
                                    text: "Open Project"
                                    Layout.fillWidth: true
                                    isDefault: false
                                    onClicked: Qt.openUrlExternally("https://github.com/genyleap/genyconnect")
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
                                             : (vpnController.isMobile
                                                ? "Mobile mode: runtime uses platform VPN APIs and ignores desktop proxy helpers."
                                                : "Clean mode: " + osNameText() + " proxy stays untouched. Only apps set to 127.0.0.1:10808 use the tunnel."))
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
                                                "subtitle": vpnController.supportsSystemProxy
                                                            ? "Apply system proxy for compatible apps."
                                                            : "Unavailable on this runtime (system proxy control is not supported).",
                                                "checked": vpnController.supportsSystemProxy && vpnController.useSystemProxy && !vpnController.tunMode,
                                                "enabled": vpnController.supportsSystemProxy,
                                                "apply": function() {
                                                    vpnController.tunMode = false
                                                    vpnController.useSystemProxy = true
                                                    vpnController.autoDisableSystemProxyOnDisconnect = true
                                                }
                                            },
                                            {
                                                "title": "Clean Mode",
                                                "subtitle": "Keep OS proxy unchanged and route manual proxy apps only.",
                                                "checked": !vpnController.tunMode && (!vpnController.supportsSystemProxy || !vpnController.useSystemProxy),
                                                "enabled": true,
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
                                                "enabled": vpnController.supportsTun,
                                                "apply": function() {
                                                    vpnController.useSystemProxy = false
                                                    vpnController.tunMode = true
                                                }
                                            }
                                        ]

                                        delegate: Rectangle {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: root.compact ? 66 : 56
                                            radius: 8
                                            opacity: modelData.enabled ? 1.0 : 0.58
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
                                                        wrapMode: root.compact ? Text.WordWrap : Text.NoWrap
                                                        elide: root.compact ? Text.ElideNone : Text.ElideRight
                                                        maximumLineCount: root.compact ? 2 : 1
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                enabled: modelData.enabled
                                                cursorShape: modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
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
                                enabled: vpnController.supportsSystemProxy && vpnController.useSystemProxy && !vpnController.tunMode
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
                                enabled: vpnController.supportsSystemProxy
                                onToggled: vpnController.killSwitchEnabled = checked
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: vpnController.supportsSystemProxy ? "Kill Switch" : "Kill Switch (Unavailable)"
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

                        Text {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "connection" && !vpnController.supportsSystemProxy
                            text: "Global mode and Kill Switch require system proxy control, which is not available on this runtime. Use TUN Mode for full-device routing."
                            color: root.themeColorToken("mainHex_a0682a", "mainHex_f4c56a")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "logs"
                            radius: Metrics.radiusLg
                            color: Colors.dsSurfaceSoft
                            border.width: 1
                            border.color: Colors.dsBorder
                            implicitHeight: logsSettingsColumn.implicitHeight + 22

                            ColumnLayout {
                                id: logsSettingsColumn
                                anchors.fill: parent
                                anchors.margins: 11
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            Layout.fillWidth: true
                                            text: "Logs & Diagnostics"
                                            color: Colors.dsText
                                            font.family: FontSystem.getContentFontBold.name
                                            font.pixelSize: Typography.uiTitle
                                            font.bold: true
                                            wrapMode: Text.WordWrap
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: vpnController.loggingEnabled
                                                  ? "Captured lines: " + vpnController.recentLogs.length
                                                  : "Enable logging to capture connection diagnostics."
                                            color: Colors.dsTextMuted
                                            font.family: FontSystem.contentFontFamily
                                            font.pixelSize: Typography.uiBody
                                            wrapMode: Text.WordWrap
                                        }
                                    }

                                    Controls.StatusPill {
                                        text: vpnController.loggingEnabled ? "Enabled" : "Disabled"
                                        pillColor: vpnController.loggingEnabled ? Colors.dsPrimarySolid : Colors.dsSurface
                                        borderColor: vpnController.loggingEnabled ? Colors.dsPrimarySolid : Colors.dsBorder
                                        textColor: vpnController.loggingEnabled ? Colors.dsPrimaryText : Colors.dsTextMuted

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: vpnController.loggingEnabled = !vpnController.loggingEnabled
                                        }
                                    }
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: root.compact ? 2 : 3
                                    columnSpacing: 8
                                    rowSpacing: 8

                                    Controls.PrimaryButton {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        Layout.columnSpan: root.compact ? 2 : 1
                                        compact: true
                                        text: "Open Viewer"
                                        onClicked: logsPopup.open()
                                    }

                                    Controls.OutlineButton {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        compact: true
                                        text: "Copy"
                                        enabled: vpnController.loggingEnabled && vpnController.recentLogs.length > 0
                                        onClicked: vpnController.copyLogsToClipboard()
                                    }

                                    Controls.OutlineButton {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        compact: true
                                        text: "Clear"
                                        enabled: vpnController.recentLogs.length > 0
                                        onClicked: vpnController.clearLogs()
                                    }
                                }
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
                                  ? (vpnController.isMobile
                                     ? "Mobile TUN uses VPN service permissions and native runtime bridge setup."
                                     : "TUN mode does not change OS proxy settings. If connect fails, run app with elevated privileges.")
                                  : (vpnController.useSystemProxy
                                     ? "Recommended: keep this enabled to restore system proxy cleanly after tunnel disconnect."
                                     : "In Clean mode this option is ignored because system proxy remains disabled.")
                            color: root.themeColorToken("mainHex_7f8897", "mainHex_99abc4")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "power"
                            spacing: root.compact ? 12 : 14

                            PowerSectionCard {
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
                                                text: vpnController.lanSharingEnabled ? "Sharing On" : "Sharing Off"
                                                color: vpnController.lanSharingEnabled ? Colors.dsSuccess : Colors.dsText
                                                font.family: FontSystem.getContentFontBold.name
                                                font.pixelSize: Typography.uiTitle
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: vpnController.lanSharingEnabled
                                                      ? (root.compact ? "Proxy is available on your LAN." : "Your proxy is available on the LAN.")
                                                      : (root.compact ? "Share your proxy on local Wi-Fi." : "Enable to share your proxy on local Wi-Fi.")
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
                                                label: settingsFlick.width < 560 ? "Host" : "LAN Address (Host)"
                                                value: root.lanProxyHost()
                                                copyable: true
                                                accentColor: Colors.dsPrimarySolid
                                                onCopyClicked: {
                                                    vpnController.copyTextToClipboard(root.lanProxyHost())
                                                    root.showSettingsFeedback("Host copied.")
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
                                                label: "Port"
                                                value: String(vpnController.httpPort)
                                                copyable: true
                                                accentColor: Colors.dsPrimarySolid
                                                onCopyClicked: {
                                                    vpnController.copyTextToClipboard(String(vpnController.httpPort))
                                                    root.showSettingsFeedback("Port copied.")
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
                                                label: "Protocol"
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
                                            text: settingsFlick.width < 560 ? "Copy" : "Copy Address"
                                            glyph: "\uf0c5"
                                            accentColor: Colors.dsPrimarySolid
                                            onClicked: {
                                                vpnController.copyTextToClipboard(root.lanProxyHost())
                                                root.showSettingsFeedback("Address copied.")
                                            }
                                        }

                                        LanActionButton {
                                            text: settingsFlick.width < 560 ? "Test" : "Test Connection"
                                            glyph: "\uf2f1"
                                            accentColor: Colors.dsPrimarySolid
                                            onClicked: root.showLanStatusFeedback("Test with Host " + root.lanProxyHost() + " and Port " + String(vpnController.httpPort) + ".")
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: root.settingsFeedbackText.length > 0 || root.lanStatusFeedbackText.length > 0
                                        text: root.lanStatusFeedbackText.length > 0 ? root.lanStatusFeedbackText : root.settingsFeedbackText
                                        color: Colors.dsTextSubtle
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: Typography.uiCaption
                                        wrapMode: Text.WordWrap
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: !vpnController.lanSharingSupported
                                        text: "LAN proxy unavailable on this runtime."
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
                                                text: vpnController.lanSharingAllowAnyBind
                                                      ? (root.compact ? "Security: LAN Access Allowed" : "Security: LAN Connections Allowed")
                                                      : (root.compact ? "Security: Private LAN" : "Security: Private LAN Only")
                                                color: Colors.dsText
                                                font.family: FontSystem.getContentFontBold.name
                                                font.pixelSize: root.compact ? Typography.uiBodySm : Typography.uiBody
                                                font.bold: true
                                                wrapMode: Text.NoWrap
                                                elide: Text.ElideRight
                                            }

                                            LanBadge {
                                                Layout.alignment: Qt.AlignVCenter
                                                text: vpnController.lanSharingAllowAnyBind ? "Review" : (root.compact ? "Safe" : "Recommended")
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
                                            text: vpnController.lanSharingAllowAnyBind
                                                  ? "Devices on your LAN can connect."
                                                  : "Only devices on your local network can connect."
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
                                            text: "Choose Your Device"
                                            color: Colors.dsText
                                            font.family: FontSystem.getContentFontBold.name
                                            font.pixelSize: Typography.uiTitleSm
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }

                                        LanBadge {
                                            text: root.lanUiModeLabelCompact
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
                                            text: "Setup Guide: " + root.lanUiModeLabelCompact
                                            color: Colors.dsText
                                            font.family: FontSystem.getContentFontBold.name
                                            font.pixelSize: Typography.uiTitleSm
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }

                                        LanBadge {
                                            text: "6 Steps"
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
                                                        root.showLanSetupFeedback("Host copied.")
                                                    } else if (target === "port") {
                                                        vpnController.copyTextToClipboard(String(vpnController.httpPort))
                                                        root.showLanSetupFeedback("Port copied.")
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    LanActionButton {
                                        text: "Test Connection"
                                        glyph: "\uf2f1"
                                        accentColor: Colors.dsPrimarySolid
                                        onClicked: root.showLanSetupFeedback("Use Host " + root.lanProxyHost() + " and Port " + String(vpnController.httpPort) + ".")
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: root.lanSetupFeedbackText.length > 0
                                        text: root.lanSetupFeedbackText
                                        color: Colors.dsTextSubtle
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: Typography.uiCaption
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }

                            PowerSectionCard {
                                title: "Advanced Options"
                                subtitle: "Collapsed by default."
                                glyph: "\uf085"
                                accentColor: Colors.dsPrimarySolid
                                animated: root.powerVisualAnimationsEnabled

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.lanAdvancedControlsExpanded
                                              ? "Advanced controls visible."
                                              : "Advanced controls hidden."
                                        color: Colors.dsTextMuted
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: Typography.uiBody
                                        elide: Text.ElideRight
                                    }

                                    LanBadge {
                                        text: root.lanAdvancedControlsExpanded ? "Expanded" : "Collapsed"
                                        glyph: root.lanAdvancedControlsExpanded ? "\uf06e" : "\uf070"
                                        badgeColor: Qt.rgba(root.lanUiAccent.r, root.lanUiAccent.g, root.lanUiAccent.b, Colors.lightMode ? 0.11 : 0.18)
                                        borderColor: Qt.rgba(root.lanUiAccent.r, root.lanUiAccent.g, root.lanUiAccent.b, Colors.lightMode ? 0.30 : 0.44)
                                        textColor: root.lanUiAccent
                                    }

                                    Controls.OutlineButton {
                                        compact: true
                                        text: root.lanAdvancedControlsExpanded ? "Hide" : "Show"
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
                                            label: "Sharing"
                                            value: vpnController.lanSharingEnabled ? "Enabled" : "Disabled"
                                            glyph: vpnController.lanSharingEnabled ? "\uf00c" : "\uf00d"
                                            accentColor: vpnController.lanSharingEnabled ? Colors.dsSuccess : Colors.dsTextSubtle
                                        }

                                        PowerMetricChip {
                                            label: "Bind Mode"
                                            value: vpnController.lanSharingAllowAnyBind ? "LAN Wide" : "Private LAN"
                                            glyph: vpnController.lanSharingAllowAnyBind ? "\uf3ed" : "\uf132"
                                            accentColor: vpnController.lanSharingAllowAnyBind ? Colors.dsWarning : Colors.dsSuccess
                                        }

                                        PowerMetricChip {
                                            label: "Gateway"
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
                                            text: vpnController.lanSharingEnabled ? "Sharing enabled." : "Sharing disabled."
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
                                            text: "Refresh"
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
                                            text: vpnController.lanSharingAllowAnyBind ? "LAN Wide (0.0.0.0)" : "Private LAN Only"
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
                                                    text: "Full VPN Gateway / Hotspot"
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
                                                text: root.lanGatewayPlatformSupported()
                                                      ? "Experimental: Use only when you need full-device routing. Proxy mode is recommended first."
                                                      : "Not available on this platform runtime (Experimental)."
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

                        Text {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "routing"
                            text: {
                                if (vpnController.tunMode)
                                    return "TUN mode keeps unmatched traffic on VPN by default. Use Direct rules for explicit bypass targets."
                                return vpnController.whitelistMode
                                       ? "Whitelist mode is ON: unmatched traffic goes Direct, and only rules set to VPN/Tunnel use the VPN."
                                       : "Whitelist mode is OFF: unmatched traffic goes through VPN, unless a rule sends it Direct or Block."
                            }
                            wrapMode: Text.Wrap
                            color: root.themeColorToken("mainHex_8a95a8", "mainHex_9eb2cb")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 12
                        }

                        Button {
                            visible: root.settingsSection === "connection" && vpnController.supportsSystemProxy
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
                            text: "Create rules with Target Type + Target Value + Action. Rules are evaluated from top to bottom."
                            wrapMode: Text.Wrap
                            color: root.themeColorToken("mainHex_8a95a8", "mainHex_9eb2cb")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 12
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "routing"
                            text: "Tip: choose Action = Direct to bypass VPN for that target."
                            wrapMode: Text.Wrap
                            color: root.themeColorToken("mainHex_8a95a8", "mainHex_9eb2cb")
                            font.family: FontSystem.contentFontFamily
                            font.pixelSize: 12
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            visible: false
                            Layout.preferredHeight: 74
                            placeholderText: "Tunnel Domains\nexample.com\ndomain:youtube.com\nregexp:.*\\\\.openai\\\\.com$"
                            text: vpnController.proxyDomainRules
                            onTextChanged: vpnController.proxyDomainRules = text
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            visible: false
                            Layout.preferredHeight: 74
                            placeholderText: "Direct Domains\nfull:localhost\ngeosite:private\nexample.org"
                            text: vpnController.directDomainRules
                            onTextChanged: vpnController.directDomainRules = text
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            visible: false
                            Layout.preferredHeight: 74
                            placeholderText: "Block Domains\ngeosite:category-ads-all\nregexp:.*ads.*"
                            text: vpnController.blockDomainRules
                            onTextChanged: vpnController.blockDomainRules = text
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
                                    text: root.routingRuleEditingId.length > 0 ? "Edit Rule" : "Create Rule"
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
                                        text: root.routingRuleDraftEnabled ? "Enabled" : "Disabled"
                                        color: root.themeColorToken("mainHex_5f7088", "mainHex_9eb2cb")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: 12
                                    }
                                }

                                Controls.TextField {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    text: root.routingRuleDraftValue
                                    placeholderText: {
                                        const type = (root.routingRuleDraftType || "domain").toLowerCase()
                                        if (type === "ip")
                                            return "Example: 185.143.233.0/24 or geoip:ir"
                                        if (type === "app")
                                            return "Example: C:/Games/game.exe or /Applications/Telegram.app/Contents/MacOS/Telegram"
                                        if (type === "process")
                                            return "Example: telegram.exe or com.apple.Safari"
                                        if (type === "protocol")
                                            return "Example: tcp,udp"
                                        return "Example: bankmellat.ir or domain:bankmellat.ir"
                                    }
                                    onTextEdited: {
                                        root.routingRuleDraftValue = text
                                        root.routingRuleValidationText = ""
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: root.routingRuleValidationText.length > 0
                                    text: root.routingRuleValidationText
                                    color: root.themeColorToken("mainHex_c65050", "mainHex_ff8e8e")
                                    font.family: FontSystem.contentFontFamily
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Controls.Button {
                                        Layout.fillWidth: true
                                        text: root.routingRuleEditingId.length > 0 ? "Save Rule" : "Add Rule"
                                        onClicked: root.saveRoutingRuleDraft()
                                    }

                                    Controls.Button {
                                        text: root.routingRuleEditingId.length > 0 ? "Cancel" : "Validate"
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
                                        text: "Clear All"
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
                                    text: "Active Rules"
                                    color: root.themeColorToken("mainHex_334155", "mainHex_d7e4f6")
                                    font.family: FontSystem.getContentFontBold.name
                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                ListView {
                                    id: routingRuleListView
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: count > 0 ? Math.min(320, Math.max(140, count * 72)) : 90
                                    clip: true
                                    spacing: 6
                                    model: root.currentRoutingRules()

                                    delegate: Rectangle {
                                        required property int index
                                        required property var modelData
                                        width: ListView.view.width
                                        height: 66
                                        radius: 10
                                        color: root.themeColorToken("mainHex_ffffff", "mainHex_22324a")
                                        border.width: 1
                                        border.color: root.themeColorToken("mainHex_dbe3ef", "mainHex_3a5470")

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 6

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: (index + 1) + ". " + root.routingRuleTypeLabel(modelData.targetType)
                                                          + " → " + root.routingRuleActionLabel(modelData.action)
                                                    color: root.themeColorToken("mainHex_334155", "mainHex_d2def0")
                                                    font.family: FontSystem.getContentFontBold.name
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.targetValue || ""
                                                    color: root.themeColorToken("mainHex_4f6078", "mainHex_9eb2cb")
                                                    font.family: FontSystem.contentFontFamily
                                                    font.pixelSize: 11
                                                    elide: Text.ElideMiddle
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: "Scope: " + (modelData.profileName || "All Profiles")
                                                          + " • " + (modelData.enabled === false ? "Disabled" : "Enabled")
                                                    color: root.themeColorToken("mainHex_7f8da2", "mainHex_a8bdd7")
                                                    font.family: FontSystem.contentFontFamily
                                                    font.pixelSize: 10
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Controls.Button {
                                                Layout.fillWidth: false
                                                sizeType: "compact"
                                                text: "↑"
                                                implicitWidth: 32
                                                implicitHeight: 28
                                                enabled: index > 0
                                                onClicked: vpnController.moveRoutingRule(modelData.id || "", index - 1)
                                            }

                                            Controls.Button {
                                                Layout.fillWidth: false
                                                sizeType: "compact"
                                                text: "↓"
                                                implicitWidth: 32
                                                implicitHeight: 28
                                                enabled: index < routingRuleListView.count - 1
                                                onClicked: vpnController.moveRoutingRule(modelData.id || "", index + 1)
                                            }

                                            Controls.Button {
                                                Layout.fillWidth: false
                                                sizeType: "compact"
                                                text: modelData.enabled === false ? "Off" : "On"
                                                implicitWidth: 44
                                                implicitHeight: 28
                                                onClicked: vpnController.setRoutingRuleEnabled(modelData.id || "", modelData.enabled === false)
                                            }

                                            Controls.Button {
                                                Layout.fillWidth: false
                                                sizeType: "compact"
                                                text: "Edit"
                                                implicitWidth: 46
                                                implicitHeight: 28
                                                onClicked: root.editRoutingRule(modelData)
                                            }

                                            Controls.Button {
                                                Layout.fillWidth: false
                                                sizeType: "compact"
                                                text: "Dup"
                                                implicitWidth: 42
                                                implicitHeight: 28
                                                onClicked: vpnController.duplicateRoutingRule(modelData.id || "")
                                            }

                                            Controls.Button {
                                                Layout.fillWidth: false
                                                sizeType: "compact"
                                                text: "Del"
                                                implicitWidth: 42
                                                implicitHeight: 28
                                                onClicked: vpnController.removeRoutingRule(modelData.id || "")
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.fill: parent
                                        visible: routingRuleListView.count === 0
                                        text: "No rules yet. Add your first rule above.\nExample: Domain bankmellat.ir → Direct."
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
                            text: {
                                if (!vpnController.supportsPerAppRouting) {
                                    return "App/process routing is not supported on this platform runtime."
                                }
                                if (Qt.platform.os === "android" || Qt.platform.os === "ios")
                                    return "Mobile platforms currently support domain/IP/protocol rules. App-level routing visibility may be limited by OS/runtime constraints."
                                if (!vpnController.processRoutingSupported) {
                                    const detected = (vpnController.xrayVersion || "").trim()
                                    if (detected.length > 0)
                                        return detected
                                    return "Desktop app/process routing requires xray-core 26.1.23+ with process matching enabled."
                                }
                                return "App rules are supported on this runtime. Use absolute executable paths for the most reliable matching."
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
                                text: "Running apps"
                                color: root.themeColorToken("mainHex_334155", "mainHex_d7e4f6")
                                font.family: FontSystem.getContentFontBold.name
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Controls.Button {
                                text: root.appRuleSuggestionsLoading ? "Loading..." : "Refresh"
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
                                    text: "Clear"
                                    implicitWidth: 62
                                    implicitHeight: 30
                                    enabled: (root.selectedAppRuleTargets || []).length > 0
                                    onClicked: root.clearAppSuggestionSelection()
                                }

                                Controls.Button {
                                    text: "Direct"
                                    implicitWidth: 72
                                    implicitHeight: 30
                                    enabled: vpnController.processRoutingSupported
                                             && (root.selectedAppRuleTargets || []).length > 0
                                    onClicked: root.appendSelectedAppRules("direct")
                                }

                                Controls.Button {
                                    text: "Tunnel"
                                    implicitWidth: 72
                                    implicitHeight: 30
                                    enabled: vpnController.processRoutingSupported
                                             && (root.selectedAppRuleTargets || []).length > 0
                                    onClicked: root.appendSelectedAppRules("proxy")
                                }

                                Controls.Button {
                                    text: "Block"
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
                                    text: "Clear"
                                    enabled: (root.selectedAppRuleTargets || []).length > 0
                                    onClicked: root.clearAppSuggestionSelection()
                                }

                                Controls.Button {
                                    width: Math.max(66, Math.floor((routingRuleActionFlow.width - (routingRuleActionFlow.spacing * 3)) / 4))
                                    implicitHeight: 30
                                    text: "Direct"
                                    enabled: vpnController.processRoutingSupported
                                             && (root.selectedAppRuleTargets || []).length > 0
                                    onClicked: root.appendSelectedAppRules("direct")
                                }

                                Controls.Button {
                                    width: Math.max(66, Math.floor((routingRuleActionFlow.width - (routingRuleActionFlow.spacing * 3)) / 4))
                                    implicitHeight: 30
                                    text: "Tunnel"
                                    enabled: vpnController.processRoutingSupported
                                             && (root.selectedAppRuleTargets || []).length > 0
                                    onClicked: root.appendSelectedAppRules("proxy")
                                }

                                Controls.Button {
                                    width: Math.max(66, Math.floor((routingRuleActionFlow.width - (routingRuleActionFlow.spacing * 3)) / 4))
                                    implicitHeight: 30
                                    text: "Block"
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
                                    required property var modelData
                                    width: ListView.view.width
                                    height: 56
                                    radius: 8
                                    color: root.isAppSuggestionSelected(modelData)
                                           ? root.themeColorToken("mainHex_edf4ff", "mainHex_274062")
                                           : root.themeColorToken("mainHex_ffffff", "mainHex_22324a")
                                    border.width: 0
                                    border.color: root.isAppSuggestionSelected(modelData)
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
                                            color: root.isAppSuggestionSelected(modelData)
                                                   ? root.themeColorToken("mainHex_dbe8ff", "mainHex_335178")
                                                   : root.themeColorToken("mainHex_eff4fb", "mainHex_2a3f5b")
                                            border.width: 0
                                            border.color: root.isAppSuggestionSelected(modelData)
                                                         ? root.themeColorToken("mainHex_9db9f9", "mainHex_659bdf")
                                                         : root.themeColorToken("mainHex_d4dfef", "mainHex_496384")

                                            Text {
                                                anchors.centerIn: parent
                                                text: root.appSuggestionInitial(modelData)
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

                                            Text {
                                                width: parent.width
                                                text: (modelData.ruleTarget || "").length > 0
                                                      ? ("Match: " + modelData.ruleTarget)
                                                      : ""
                                                visible: text.length > 0
                                                         && (modelData.ruleTarget || "") !== (modelData.process || "")
                                                color: root.themeColorToken("mainHex_95a3b8", "mainHex_a4b6cd")
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 10
                                                elide: Text.ElideMiddle
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
                                                onClicked: vpnController.appendAppRule("direct", root.appSuggestionRuleKey(modelData))
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
                                                onClicked: vpnController.appendAppRule("proxy", root.appSuggestionRuleKey(modelData))
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
                                                onClicked: vpnController.appendAppRule("block", root.appSuggestionRuleKey(modelData))
                                            }
                                        }
                                    }

                                    MouseArea {
                                        z: 0
                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton
                                        onClicked: root.toggleAppSuggestionSelection(modelData)
                                    }
                                }
                            }
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            visible: false
                            Layout.preferredHeight: 66
                            enabled: vpnController.processRoutingSupported
                            opacity: enabled ? 1.0 : 0.6
                            placeholderText: "Tunnel Apps\nTelegram\nchrome.exe\ncom.apple.Safari"
                            text: vpnController.proxyAppRules
                            onTextChanged: vpnController.proxyAppRules = text
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            visible: false
                            Layout.preferredHeight: 66
                            enabled: vpnController.processRoutingSupported
                            opacity: enabled ? 1.0 : 0.6
                            placeholderText: "Direct Apps\nFinder\nexplorer.exe\nfirefox"
                            text: vpnController.directAppRules
                            onTextChanged: vpnController.directAppRules = text
                        }

                        Controls.TextArea {
                            Layout.fillWidth: true
                            visible: false
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
        id: profileQrPopup
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: profileQrCanvas.requestPaint()
        width: root.sheetWidth(400)
        height: {
            const targetHeight = profileQrPopupContent.implicitHeight + (root.compact ? (12 + Math.max(4, root.safeBottomInset)) : 16)
            const maxHeight = root.compact
                    ? Math.max(300, root.height - Math.max(4, root.safeBottomInset))
                    : root.sheetHeight(620)
            return Math.min(maxHeight, targetHeight)
        }
        x: (root.width - width) * 0.5
        y: root.compact ? Math.max(0, root.height - height) : root.drawerY(height)
        padding: 0

        background: Rectangle {
            topLeftRadius: root.compact ? 20 : 24
            topRightRadius: root.compact ? 20 : 24
            bottomLeftRadius: 0
            bottomRightRadius: 0
            color: root.themeColorToken("mainHex_f8fbff", "mainHex_090b14")
            border.width: 1
            border.color: root.themeColorToken("mainHex_d8dde8", "mainHex_30435d")
        }

        contentItem: Flickable {
            id: profileQrPopupFlick
            anchors.fill: parent
            clip: true
            contentWidth: width
            readonly property int panelPadding: root.compact ? 10 : 12
            readonly property int topInsetPadding: root.compact ? (Math.max(0, root.safeTopInset - 2) + panelPadding) : panelPadding
            readonly property int bottomInsetPadding: root.compact ? Math.max(4, root.safeBottomInset + 4) : 4
            contentHeight: profileQrPopupContent.implicitHeight + topInsetPadding + bottomInsetPadding
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            interactive: contentHeight > height + 2

            ColumnLayout {
                id: profileQrPopupContent
                x: profileQrPopupFlick.panelPadding
                y: profileQrPopupFlick.topInsetPadding
                width: profileQrPopupFlick.width - (profileQrPopupFlick.panelPadding * 2)
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "Profile QR Code"
                        color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                        font.family: FontSystem.getContentFontBold.name
                        font.pixelSize: 19
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Controls.CircleIconButton {
                        diameter: 34
                        iconText: root.iconClose
                        iconFontFamily: root.faSolid
                        iconColor: root.themeColorToken("mainHex_8d96a5", "mainHex_9db0ca")
                        backgroundColor: root.themeColorToken("mainHex_f7f8fb", "mainHex_151c32")
                        borderColor: root.themeColorToken("mainHex_e1e5ed", "mainHex_151c32")
                        onClicked: profileQrPopup.close()
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Scan on another device to import this profile config."
                    color: root.themeColorToken("mainHex_667385", "mainHex_9bb0cb")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: Typography.uiBody
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    text: "Profile: " + root.profileQrProfileName
                    color: root.themeColorToken("mainHex_556378", "mainHex_9db6d6")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: Typography.uiCaption
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    id: profileQrCaptureCard
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Math.min(profileQrPopupContent.width, root.compact ? 330 : 344)
                    Layout.preferredHeight: Math.min(profileQrPopupContent.width, root.compact ? 330 : 344)
                    radius: Metrics.radiusMd
                    color: "#ffffff"
                    border.width: 1
                    border.color: root.themeColorToken("mainHex_d7dfea", "mainHex_2a3e5a")

                    Canvas {
                        id: profileQrCanvas
                        anchors.fill: parent
                        anchors.margins: 0
                        antialiasing: false
                        renderTarget: Canvas.Image
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()

                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.fillStyle = "#ffffff"
                            ctx.fillRect(0, 0, width, height)

                            const matrix = root.profileQrMatrixData || {}
                            const size = Math.max(0, Number(matrix.size) || 0)
                            const rows = matrix.rows || []
                            if (matrix.ok !== true || size <= 0 || rows.length < size)
                                return

                            const borderModules = size >= 85 ? 2 : 3
                            const totalModules = size + (borderModules * 2)
                            const drawSide = Math.max(1, Math.floor(Math.min(width, height)))
                            const offsetX = Math.floor((width - drawSide) * 0.5)
                            const offsetY = Math.floor((height - drawSide) * 0.5)
                            const step = drawSide / totalModules
                            ctx.fillStyle = "#0b1424"
                            for (let y = 0; y < size; ++y) {
                                const row = String(rows[y] || "")
                                const y0 = Math.round(offsetY + ((y + borderModules) * step))
                                const y1 = Math.round(offsetY + ((y + borderModules + 1) * step))
                                if (y1 <= y0)
                                    continue
                                for (let x = 0; x < size; ++x) {
                                    if (row.length > x && row.charAt(x) === "1") {
                                        const x0 = Math.round(offsetX + ((x + borderModules) * step))
                                        const x1 = Math.round(offsetX + ((x + borderModules + 1) * step))
                                        if (x1 > x0)
                                            ctx.fillRect(x0,
                                                         y0,
                                                         x1 - x0,
                                                         y1 - y0)
                                    }
                                }
                            }
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 8

                    Controls.OutlineButton {
                        Layout.fillWidth: true
                        compact: true
                        text: "Copy as JSON"
                        onClicked: {
                            vpnController.copyTextToClipboard(root.profileQrCopyJsonText.length > 0
                                                              ? root.profileQrCopyJsonText
                                                              : root.profileQrPayloadText)
                            root.showSettingsFeedback("Profile config copied.")
                        }
                    }

                    Controls.OutlineButton {
                        Layout.fillWidth: true
                        compact: true
                        text: "Save PNG"
                        onClicked: root.saveProfileQrImage()
                    }

                    Controls.Button {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        text: "Close"
                        onClicked: profileQrPopup.close()
                    }
                }
            }
        }
    }

    Popup {
        id: walletPickerPopup
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: root.sheetWidth(420)
        height: root.compact
                ? Math.min(root.height, walletPickerColumn.implicitHeight + 52 + Math.max(10, root.safeBottomInset))
                : walletPickerColumn.implicitHeight + 52
        x: (root.width - width) * 0.5
        y: root.compact ? Math.max(0, root.height - height - Math.max(6, root.safeBottomInset * 0.4)) : root.drawerY(height)
        padding: 0

        background: Rectangle {
            topLeftRadius: root.compact ? 20 : 24
            topRightRadius: root.compact ? 20 : 24
            bottomLeftRadius: 0
            bottomRightRadius: 0
            color: root.themeColorToken("mainHex_f8fbff", "mainHex_090b14")
            border.width: 1
            border.color: root.themeColorToken("mainHex_d8dde8", "mainHex_30435d")
        }

        contentItem: Item {
            anchors.fill: parent

            ColumnLayout {
                id: walletPickerColumn
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                anchors.topMargin: 14
                anchors.bottomMargin: 14 + (root.compact ? Math.max(8, root.safeBottomInset) : 0)
                spacing: 10

                Text {
                    text: "Choose Wallet"
                    color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                    font.family: FontSystem.getContentFontBold.name
                    font.pixelSize: 18
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    text: "Some apps support direct transfer links, while others (like Uniswap) open swap/buy flow."
                    color: root.themeColorToken("mainHex_667385", "mainHex_9bb0cb")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }

                Repeater {
                    model: root.donationWalletTargets
                    delegate: Controls.Button {
                        required property var modelData
                        visible: root.donationTargetVisible(modelData)
                        Layout.fillWidth: true
                        enabled: true
                        text: modelData.label || "Wallet"
                        isDefault: modelData.id === "system"
                        onClicked: root.openDonationViaTarget(modelData)
                    }
                }

                Controls.Button {
                    Layout.fillWidth: true
                    isDefault: false
                    text: "Cancel"
                    onClicked: walletPickerPopup.close()
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
            topLeftRadius: 24
            topRightRadius: 24
            bottomLeftRadius: 0
            bottomRightRadius: 0
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
            topLeftRadius: root.compact ? 0 : 24
            topRightRadius: root.compact ? 0 : 24
            bottomLeftRadius: 0
            bottomRightRadius: 0
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
            readonly property int panelPadding: root.compact ? 12 : 14
            readonly property int topInsetPadding: root.compact ? (root.safeTopInset + panelPadding) : panelPadding
            readonly property int bottomPadding: root.compact ? (root.safeBottomInset + 26) : panelPadding
            contentHeight: usagePopupContent.implicitHeight + topInsetPadding + bottomPadding
            boundsBehavior: Flickable.StopAtBounds

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: function(event) {
                    root.scrollFlickByWheel(usagePopupFlick, event)
                }
            }

            ColumnLayout {
                id: usagePopupContent
                x: usagePopupFlick.panelPadding
                y: usagePopupFlick.topInsetPadding
                width: usagePopupFlick.width - (usagePopupFlick.panelPadding * 2)
                spacing: 10

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
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: "Data Usage — " + root.selectedUsageProfileLabel()
                        color: root.themeColorToken("mainHex_1f2530", "mainHex_d8e1f0")
                        font.family: FontSystem.getContentFontBold.name
                        font.weight: Font.Bold
                        font.pixelSize: 21
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

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

                Text {
                    Layout.fillWidth: true
                    text: "Track upload/download totals per profile or across all profiles."
                    color: root.themeColorToken("mainHex_6f7f95", "mainHex_9eb2cb")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Profile"
                        color: root.themeColorToken("mainHex_5f7088", "mainHex_b5c8df")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 12
                    }

                    Controls.ComboBox {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        model: vpnController.usageProfileOptions
                        currentIndex: {
                            const wanted = (vpnController.selectedUsageProfileId || "").trim()
                            const list = model || []
                            for (let i = 0; i < list.length; ++i) {
                                if ((((list[i] || {}).id || "").trim()) === wanted)
                                    return i
                            }
                            return 0
                        }
                        onActivated: function(activatedIndex) {
                            const item = model[activatedIndex] || {}
                            vpnController.selectedUsageProfileId = item.id || ""
                            root.usageRefreshNonce += 1
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: Metrics.radiusLg
                    color: Colors.dsSurfaceSoft
                    border.width: 1
                    border.color: Colors.dsBorderSoft
                    implicitHeight: summaryGrid.implicitHeight + 14

                    GridLayout {
                        id: summaryGrid
                        anchors.fill: parent
                        anchors.margins: 7
                        columns: root.compact ? 2 : 3
                        columnSpacing: root.compact ? 6 : 8
                        rowSpacing: root.compact ? 6 : 8

                        Repeater {
                            model: root.usageSummaryModel()

                            delegate: Controls.StatCard {
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                Layout.columnSpan: root.compact && index === 2 ? 2 : 1
                                compact: true
                                label: modelData.label
                                value: modelData.value
                            }
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: root.compact ? 2 : 3
                    rowSpacing: root.compact ? 4 : 0
                    columnSpacing: 8

                    Text {
                        Layout.fillWidth: true
                        Layout.columnSpan: 1
                        text: "Download: " + ((vpnController.usageSummaryForProfile(vpnController.selectedUsageProfileId || "").totalRxText) || "0 B")
                        color: root.themeColorToken("mainHex_64748b", "mainHex_a4b6cd")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.columnSpan: 1
                        text: "Upload: " + ((vpnController.usageSummaryForProfile(vpnController.selectedUsageProfileId || "").totalTxText) || "0 B")
                        color: root.themeColorToken("mainHex_64748b", "mainHex_a4b6cd")
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.columnSpan: root.compact ? 2 : 1
                        text: "Total: " + ((vpnController.usageSummaryForProfile(vpnController.selectedUsageProfileId || "").totalText) || "0 B")
                        color: root.themeColorToken("mainHex_334155", "mainHex_d2def0")
                        font.family: FontSystem.getContentFontBold.name
                        font.pixelSize: 11
                        horizontalAlignment: root.compact ? Text.AlignLeft : Text.AlignRight
                        elide: Text.ElideRight
                    }
                }

                Controls.SegmentedSelector {
                    Layout.fillWidth: true
                    compact: true
                    model: [
                        { "key": "current", "label": "Current Profile" },
                        { "key": "recent", "label": "Recent Sessions" }
                    ]
                    currentKey: root.usagePanelTab
                    onActivated: function(key) {
                        root.usagePanelTab = key
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
                            columnSpacing: root.compact ? 6 : 8
                            rowSpacing: root.compact ? 6 : 8

                            Repeater {
                                model: root.usageCurrentStatsModel()

                                delegate: Controls.StatCard {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    Layout.columnSpan: root.compact && index === 2 ? 2 : 1
                                    compact: true
                                    label: modelData.label
                                    value: modelData.value
                                }
                            }
                        }

                        Controls.SegmentedSelector {
                            Layout.fillWidth: true
                            compact: true
                            model: ["hour", "day", "week", "month"]
                            currentKey: root.usageHistoryPeriod
                            onActivated: function(key) {
                                root.usageHistoryPeriod = key
                                root.usageRefreshNonce += 1
                            }
                        }

                        ListView {
                            id: usageHistoryListPopup
                            Layout.fillWidth: true
                            Layout.preferredHeight: count > 0 ? Math.min(260, Math.max(104, count * 48)) : 72
                            clip: true
                            spacing: 6
                            model: root.currentUsageHistoryModel()

                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                width: ListView.view.width
                                height: root.compact ? 62 : 48
                                radius: 8
                                color: root.themeColorToken("mainHex_f7f9fd", "mainHex_22324a")
                                border.width: 1
                                border.color: root.themeColorToken("mainHex_dbe3ef", "mainHex_3a5470")

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: root.compact ? 8 : 10
                                    anchors.rightMargin: root.compact ? 8 : 10
                                    anchors.topMargin: root.compact ? 5 : 0
                                    anchors.bottomMargin: root.compact ? 5 : 0
                                    spacing: root.compact ? 2 : 0

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.key || ""
                                            color: root.themeColorToken("mainHex_334155", "mainHex_d2def0")
                                            font.family: FontSystem.contentFontFamily
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.totalText || "0 B"
                                            color: root.themeColor(root.brandBlue, Colors.mainHex_7fb0ff)
                                            font.family: FontSystem.getContentFontBold.name
                                            font.pixelSize: 12
                                            font.bold: true
                                            elide: Text.ElideRight
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            Layout.fillWidth: true
                                            text: "Down " + (modelData.rxText || "0 B")
                                            color: root.themeColorToken("mainHex_64748b", "mainHex_a4b6cd")
                                            font.family: FontSystem.contentFontFamily
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: "Up " + (modelData.txText || "0 B")
                                            color: root.themeColorToken("mainHex_64748b", "mainHex_a4b6cd")
                                            font.family: FontSystem.contentFontFamily
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                            horizontalAlignment: Text.AlignRight
                                        }
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
                            Layout.preferredHeight: usageSessionsListPopup.count > 0 ? Math.min(300, Math.max(110, usageSessionsListPopup.count * 46)) : 90
                            clip: true
                            spacing: 6
                            model: root.currentUsageSessionsModel()

                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                width: ListView.view.width
                                height: 44
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
                                        Layout.fillWidth: true
                                        text: modelData.totalText || "0 B"
                                        color: root.themeColor(root.brandBlue, Colors.mainHex_7fb0ff)
                                        font.family: FontSystem.getContentFontBold.name
                                        font.pixelSize: 12
                                        font.bold: true
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignRight
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

                GridLayout {
                    Layout.fillWidth: true
                    columns: root.compact ? 2 : 3
                    rowSpacing: 8
                    columnSpacing: 8

                    Controls.PrimaryButton {
                        text: "Refresh"
                        compact: true
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.columnSpan: root.compact ? 2 : 1
                        onClicked: root.usageRefreshNonce += 1
                    }

                    Controls.OutlineButton {
                        text: "Clear Selected"
                        compact: true
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        enabled: (vpnController.selectedUsageProfileId || "").trim().length > 0
                        onClicked: {
                            vpnController.clearCurrentProfileUsage()
                            root.usageRefreshNonce += 1
                        }
                    }

                    Controls.OutlineButton {
                        text: "Clear All"
                        compact: true
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
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
                    text: "Runtime Logs"
                    font.family: FontSystem.getContentFontBold.name
                    font.weight: Font.Bold
                    font.pixelSize: 20
                    color: root.themeColorToken("mainHex_1f2530", "mainHex_d8e1f0")
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: logModeLabel.implicitWidth + 16
                    radius: 12
                    color: vpnController.loggingEnabled ? Colors.dsPrimaryTint : Colors.dsSurface
                    border.width: 1
                    border.color: vpnController.loggingEnabled ? Colors.dsPrimarySolid : Colors.dsBorder

                    Text {
                        id: logModeLabel
                        anchors.centerIn: parent
                        text: vpnController.loggingEnabled ? "Live" : "Disabled"
                        color: vpnController.loggingEnabled ? Colors.dsPrimarySolid : Colors.dsTextMuted
                        font.family: FontSystem.getContentFontBold.name
                        font.pixelSize: Typography.uiBodySm
                        font.bold: true
                    }
                }

                Item { Layout.fillWidth: true }

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
                    wrapMode: TextEdit.WrapAnywhere
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
            topLeftRadius: root.compact ? 0 : 24
            topRightRadius: root.compact ? 0 : 24
            bottomLeftRadius: 0
            bottomRightRadius: 0
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
            readonly property int topInsetPadding: root.compact ? (root.safeTopInset + panelPadding) : panelPadding
            readonly property int bottomInsetPadding: root.compact ? (root.safeBottomInset + 12) : panelPadding
            contentHeight: speedTestPopupContent.implicitHeight + topInsetPadding + bottomInsetPadding
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: speedTestPopupContent
                x: speedTestPopupFlick.panelPadding
                y: speedTestPopupFlick.topInsetPadding
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
                    animationsEnabled: root.powerVisualAnimationsEnabled
                    effectsEnabled: root.powerEffectsEnabled
                    particlesEnabled: root.powerParticlesEnabled && vpnController.speedTestRunning
                    particleIntensity: (root.powerParticlesEnabled && vpnController.speedTestRunning) ? 1.0 : 0.0
                    particleCount: root.powerParticlesEnabled ? (root.compact ? 54 : 72) : 0
                    sparkCount: root.powerParticlesEnabled ? (root.compact ? 10 : 14) : 0
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

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Gauge Range"
                    color: root.themeColorToken("mainHex_64748b", "mainHex_9db2cc")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 12
                }

                Flow {
                    id: speedRangeFlow
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    Repeater {
                        model: ["Small", "Medium", "Large", "Auto"]

                        delegate: Rectangle {
                            required property string modelData
                            width: root.compact
                                   ? (modelData === "Medium" ? 66 : 58)
                                   : (modelData === "Medium" ? 72 : 62)
                            height: 26
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
                    Layout.fillWidth: true
                    text: "Route stability " + ((vpnController.speedTestRunning || vpnController.speedTestState === "Completed")
                                                ? (vpnController.speedTestRouteStabilityPct + "%")
                                                : "--")
                    color: root.themeColorToken("mainHex_5d6d84", "mainHex_9db2cc")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    Layout.preferredWidth: root.compact ? 102 : implicitWidth
                    horizontalAlignment: Text.AlignRight
                    text: "Overall " + root.speedOverallDisplayText()
                    color: root.themeColorToken("mainHex_5d6d84", "mainHex_9db2cc")
                    font.family: FontSystem.contentFontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    maximumLineCount: 1
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
        height: root.compact ? root.height : root.sheetHeight(660)
        x: (root.width - width) * 0.5
        y: root.compact ? 0 : root.drawerY(height)
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
                to: root.compact ? 0 : root.drawerY(importPopup.height)
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
                    importPopup.close()
                }
            }
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: root.compact ? 12 : 16
            anchors.rightMargin: root.compact ? 12 : 16
            anchors.topMargin: root.compact ? (12 + root.safeTopInset) : 16
            anchors.bottomMargin: root.compact ? (20 + root.safeBottomInset) : 16
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
                text: "Paste VMESS/VLESS/Trojan/Shadowsocks/WireGuard links, profile JSON, percent/base64 encoded JSON, WireGuard config text, base64 payload, or an https subscription URL. Multi-line import is supported."
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
                    iconText: "\uf044"
                    iconFontFamily: root.faSolid
                    iconPixelSize: 11
                    backgroundColor: root.themeColorToken("mainHex_f8f5ff", "mainHex_3c2b55")
                    borderColor: root.themeColorToken("mainHex_e3d7ff", "mainHex_7155a2")
                    iconColor: root.themeColorToken("mainHex_7050b8", "mainHex_b89cff")
                    enabled: !vpnController.subscriptionBusy
                             && ((importPopup.selectedManageGroup || "").trim().length > 0)
                             && !root.isProtectedGroup(importPopup.selectedManageGroup)
                    onClicked: {
                        const fromGroup = root.normalizeImportGroupName(importPopup.selectedManageGroup || "")
                        const toGroup = root.normalizeImportGroupName(subscriptionGroupField.text)
                        if (fromGroup.toLowerCase() === toGroup.toLowerCase()) {
                            root.importStatusKind = "error"
                            root.importStatusText = "Choose a different group name to rename."
                            return
                        }
                        if (vpnController.renameProfileGroup(fromGroup, toGroup)) {
                            subscriptionGroupField.text = toGroup
                            root.subscriptionGroupDraft = toGroup
                            importPopup.selectedManageGroup = toGroup
                            root.importStatusKind = "success"
                            root.importStatusText = "Group '" + fromGroup + "' renamed to '" + toGroup + "'."
                        } else {
                            root.importStatusKind = "error"
                            root.importStatusText = "Cannot rename this group."
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
                Layout.minimumHeight: root.compact ? 180 : 128
                fillColor: root.themeColorToken("mainHex_f8fbff", "mainHex_8a18283d")
                strokeColor: root.themeColorToken("mainHex_d8e2f0", "mainHex_3f587a")
                focusColor: root.themeColorToken("mainHex_8bb8ff", "mainHex_6ba0ff")
                placeholderText: "Paste links/configs here (multi-line supported)"
                wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
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
                    implicitWidth: root.compact ? 96 : 104
                    isDefault: false
                    text: vpnController.subscriptionBusy ? "Working..." : "Close"
                    Layout.fillWidth: root.compact
                    enabled: !vpnController.subscriptionBusy
                    onClicked: importPopup.close()
                }

                Item {
                    Layout.fillWidth: !root.compact
                    Layout.preferredWidth: root.compact ? 0 : 1
                }

                Controls.Button {
                    implicitWidth: root.compact ? 140 : 218
                    isDefault: true
                    text: vpnController.subscriptionBusy ? "Please wait..." : "Import"
                    Layout.fillWidth: true
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
                            importPopup.close()
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
                        opacity: (vpnController.currentProfileIndex >= 0 || vpnController.connected || vpnController.busy) ? 1.0 : 0.82
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
                            enabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.handleConnectAction()
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
                                    animated: root.powerVisualAnimationsEnabled
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Controls.NumberFlowText {
                                text: downloadUsageText()
                                color: root.themeColorToken("mainHex_1f2b3d", "mainHex_edf4ff")
                                fontSize: Typography.h3
                                animated: root.powerVisualAnimationsEnabled
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
                                    animated: root.powerVisualAnimationsEnabled
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Controls.NumberFlowText {
                                text: uploadUsageText()
                                color: root.themeColorToken("mainHex_1f2b3d", "mainHex_edf4ff")
                                fontSize: Typography.h3
                                animated: root.powerVisualAnimationsEnabled
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
        visible: root.compact
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
            anchors.verticalCenterOffset: root.mobileHomeMapVerticalOffset
            width: parent.width * root.mobileHomeMapWidthFactor
            height: parent.height * root.mobileHomeMapHeightFactor
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: root.mobileHomeMapOpacity
            source: root.mapPrimarySource
        }

        Flickable {
            id: compactHomeFlick
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: compactBottomNav.top
            clip: true
            contentWidth: width
            contentHeight: compactHomeContent.implicitHeight + root.mobileHomeTopMargin + root.mobileHomeBottomMargin
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            interactive: contentHeight > height

            ColumnLayout {
                id: compactHomeContent
                width: Math.max(0, compactHomeFlick.width - (root.mobileHomeHorizontalMargin * 2))
                height: Math.max(implicitHeight, compactHomeFlick.height - root.mobileHomeTopMargin - root.mobileHomeBottomMargin)
                x: root.mobileHomeHorizontalMargin
                y: root.mobileHomeTopMargin
                spacing: root.mobileHomeSectionGap

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.mobileHomeHeaderHeight
                    spacing: 10

                    Text {
                        text: "<strong>GENY</strong>CONNECT"
                        color: root.themeColor(root.brandInk, Colors.mainHex_e5edf9)
                        font.family: FontSystem.contentFontFamily
                        font.pixelSize: 15
                        elide: Text.ElideRight
                        Layout.maximumWidth: Math.max(112, compactHomeContent.width * 0.40)
                    }

                    Item { Layout.fillWidth: true }

                    PowerHomeBadge {
                        modeName: vpnController.powerMode
                        compact: compactHomeContent.width < 410
                        onClicked: root.openSettingsSection("power")
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
                }

                Text {
                id: dashboardTimerText
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: root.mobileHomeTimerHeight
                text: vpnController.connected ? root.sessionTimeText() : "00:00:00"
                color: root.themeColorToken("mainHex_050505", "mainHex_f1f5ff")
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: Math.max(32, Math.round(44 * root.mobileHomeScale))
                font.bold: true
            }

                Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(parent.width - 44, 276)
                Layout.preferredHeight: root.mobileHomeUsageHeight

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
                            animated: root.powerVisualAnimationsEnabled
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
                Layout.preferredHeight: root.mobileHomeHeroBlockHeight
                Layout.minimumHeight: root.mobileHomeHeroBlockHeight
                Layout.maximumHeight: root.mobileHomeHeroBlockHeight

                Item {
                    id: heroPowerCluster
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 0
                    width: Math.min(parent.width, root.mobileHomeHeroDiameter)
                    height: width

                    Repeater {
                        model: 4
                        delegate: Rectangle {
                            required property int index
                            anchors.centerIn: parent
                            width: heroPowerCluster.width * (0.58 + (index * 0.14))
                            height: width
                            radius: width / 2
                            color: root.connectRingColor()
                            opacity: index === 0 ? 1.0 : (vpnController.connectionState === ConnectionState.Disconnected ? 0.12 : 0.16)
                            border.width: index === 3 ? 1 : 0
                            border.color: root.connectRingColor()
                            scale: root.powerDecorativeAnimationsEnabled && vpnController.connectionState === ConnectionState.Connecting && index > 0 ? 1.04 : 1.0
                            Behavior on color { ColorAnimation { duration: 280 } }
                            Behavior on border.color { ColorAnimation { duration: 280 } }
                            Behavior on scale {
                                enabled: root.powerVisualAnimationsEnabled
                                NumberAnimation { duration: 520; easing.type: Easing.InOutQuad }
                            }
                        }
                    }

                    Rectangle {
                        id: heroConnectButton
                        anchors.centerIn: parent
                        property real idlePulseScale: 1.0
                        width: Math.max(82, Math.round(104 * root.mobileHomeScale))
                        height: width
                        radius: width * 0.5
                        color: root.connectCoreColor()
                        opacity: (vpnController.currentProfileIndex >= 0 || vpnController.connected || vpnController.busy) ? 1.0 : 0.82
                        scale: (heroConnectMouse.pressed ? 0.96 : 1.0) * heroConnectButton.idlePulseScale
                        Behavior on color {
                            enabled: root.powerVisualAnimationsEnabled
                            ColorAnimation { duration: 280 }
                        }
                        Behavior on scale {
                            enabled: root.powerVisualAnimationsEnabled
                            NumberAnimation { duration: 90 }
                        }

                        SequentialAnimation on idlePulseScale {
                            running: root.powerDecorativeAnimationsEnabled
                                     && vpnController.connectionState === ConnectionState.Disconnected
                                     && !vpnController.busy
                                     && !heroConnectMouse.pressed
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 1.045; duration: 860; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 1.045; to: 1.0; duration: 860; easing.type: Easing.InOutQuad }
                            PauseAnimation { duration: 220 }
                            onRunningChanged: {
                                if (!running)
                                    heroConnectButton.idlePulseScale = 1.0
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: root.homeConnectGlyph()
                            color: Colors.mainHex_ffffff
                            font.family: root.faSolid
                            font.pixelSize: 50
                        }

                        MouseArea {
                            id: heroConnectMouse
                            anchors.fill: parent
                            enabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.handleConnectAction()
                        }
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: heroPowerCluster.bottom
                    anchors.topMargin: root.mobileHomeStatusTopGap
                    width: Math.max(statusChipText.implicitWidth + 38, root.mobileHomeStatusMinWidth)
                    height: root.mobileHomeStatusChipHeight
                    radius: height * 0.5
                    color: vpnController.connected
                           ? root.themeColorToken("mainHex_e7faef", "mainHex_6646a77c")
                           : (vpnController.busy
                              ? root.themeColorToken("mainHex_fff5d8", "mainHex_666f5b2e")
                              : root.themeColorToken("mainHex_f1f3f7", "mainHex_66557a9f"))
                    scale: root.powerDecorativeAnimationsEnabled && vpnController.busy ? 1.04 : 1.0
                    Behavior on color {
                        enabled: root.powerVisualAnimationsEnabled
                        ColorAnimation { duration: 260 }
                    }
                    Behavior on border.color {
                        enabled: root.powerVisualAnimationsEnabled
                        ColorAnimation { duration: 260 }
                    }
                    Behavior on scale {
                        enabled: root.powerVisualAnimationsEnabled
                        NumberAnimation { duration: 260; easing.type: Easing.InOutQuad }
                    }

                    SequentialAnimation on opacity {
                        running: root.powerVisualAnimationsEnabled && vpnController.connectionState === ConnectionState.Connecting
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


                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0
                    Layout.maximumHeight: root.mobileLandscape ? 10 : (root.mobilePlatform ? 26 : 34)
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.mobileHomeInfoPillHeight
                    radius: 23
                    color: root.themeColorToken("mainHex_f5f7fb", "mainHex_182230")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            radius: 12
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

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: selectedServerLabel
                                color: root.themeColorToken("mainHex_263248", "mainHex_d4e2f5")
                                font.family: FontSystem.getContentFontBold.name
                                font.pixelSize: 13
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.infoIpText()
                                color: root.themeColorToken("mainHex_65758b", "mainHex_9eb4ce")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 11
                                elide: Text.ElideMiddle
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 5

                            Controls.SignalBars {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 18
                                level: root.currentProfileSignalLevel()
                                activeColor: root.currentProfileSignalColor()
                                inactiveColor: root.themeColorToken("mainHex_d5deeb", "mainHex_33465f")
                            }

                            Text {
                                text: root.currentProfilePingText()
                                color: root.currentProfileSignalColor()
                                font.family: FontSystem.getContentFontBold.name
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        Text {
                            text: root.iconChevronDown
                            color: root.themeColorToken("mainHex_a0afc4", "mainHex_90a5bf")
                            font.family: root.faSolid
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.profilePopupAnchor = null
                            profilePopup.open()
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
                Layout.preferredHeight: root.mobileHomeStatsHeight
                Layout.minimumHeight: root.mobileHomeStatsHeight
                Layout.maximumHeight: root.mobileHomeStatsHeight
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

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
                                        width: root.mobileLandscape ? 52 : 56
                                        text: root.formatSpeedValue(Math.max(0, downRateBytesPerSec), dashboardStatsSettings.speedUnit).value
                                        color: root.themeColorToken("mainHex_050505", "mainHex_eef4ff")
                                        fontSize: root.mobileLandscape ? 15 : 16
                                        bold: true
                                        animated: root.powerVisualAnimationsEnabled
                                    }
                                    Text {
                                        width: root.mobileLandscape ? 38 : 42
                                        text: root.formatSpeedValue(Math.max(0, downRateBytesPerSec), dashboardStatsSettings.speedUnit).unit
                                        color: root.themeColorToken("mainHex_5b5d66", "mainHex_9db0c9")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: root.mobileLandscape ? 11 : 12
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        Canvas {
                            id: downSparkline
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.mobileLandscape ? 16 : 18
                            Layout.minimumHeight: root.mobileLandscape ? 16 : 18
                            antialiasing: root.powerEffectsEnabled
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
                                ctx.shadowColor = root.powerEffectsEnabled ? "rgba(111,92,255,0.45)" : "transparent"
                                ctx.shadowBlur = root.powerEffectsEnabled ? 4 : 0
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
                    clip: true

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
                                        width: root.mobileLandscape ? 52 : 56
                                        text: root.formatSpeedValue(Math.max(0, upRateBytesPerSec), dashboardStatsSettings.speedUnit).value
                                        color: root.themeColorToken("mainHex_050505", "mainHex_eef4ff")
                                        fontSize: root.mobileLandscape ? 15 : 16
                                        bold: true
                                        animated: root.powerVisualAnimationsEnabled
                                    }
                                    Text {
                                        width: root.mobileLandscape ? 38 : 42
                                        text: root.formatSpeedValue(Math.max(0, upRateBytesPerSec), dashboardStatsSettings.speedUnit).unit
                                        color: root.themeColorToken("mainHex_5b5d66", "mainHex_9db0c9")
                                        font.family: FontSystem.contentFontFamily
                                        font.pixelSize: root.mobileLandscape ? 11 : 12
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        Canvas {
                            id: upSparkline
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.mobileLandscape ? 16 : 18
                            Layout.minimumHeight: root.mobileLandscape ? 16 : 18
                            antialiasing: root.powerEffectsEnabled
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
                                ctx.shadowColor = root.powerEffectsEnabled ? "rgba(61,180,255,0.45)" : "transparent"
                                ctx.shadowBlur = root.powerEffectsEnabled ? 4 : 0
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

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 0
                }
            }
        }

        Rectangle {
            id: compactBottomNav

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            height: root.compactBottomNavHeight

            topLeftRadius: 22
            topRightRadius: 22
            bottomLeftRadius: 0
            bottomRightRadius: 0

            color: root.themeColorToken("mainHex_ffffff", "mainHex_121d2e")

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: root.compactBottomNavSafeFillHeight
                color: root.themeColorToken("mainHex_ffffff", "mainHex_121d2e")
            }

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: root.compactBottomNavTopMargin
                height: root.compactBottomNavVisualHeight
                anchors.leftMargin: root.mobileLandscape ? 24 : 42
                anchors.rightMargin: root.mobileLandscape ? 24 : 42

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

}
