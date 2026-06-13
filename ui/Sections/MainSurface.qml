/*!
 * @file        MainSurface.qml
 *
 * @author      Kambiz Asadzadeh
 * @since       09 Feb 2026
 * @copyright   Copyright (c) 2026 Genyleap.
 * @license     See LICENSE in repository root.
 */

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
    property alias securityWarningPopup: securityWarningPopup
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

    component PowerHomeBadge: Rectangle {
        id: homeBadge
    
        property string modeName: "Normal"
        property bool compact: true
        readonly property color accentColor: root.powerModeAccent(modeName)
        readonly property string glyph: root.powerModeGlyph(modeName)
    
        signal clicked()
    
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
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
    }

    component ProfileActionChip: Rectangle {
        id: chip
    
        property string label: ""
        property string glyph: ""
        property bool compactStyle: root.compact
        property color accentColor: Colors.dsPrimarySolid
        property color fillColor: compactStyle ? Colors.dsSurfaceSoft : Colors.dsSurface
        property color hoverFillColor: compactStyle ? Colors.dsSurface : Colors.dsSurfaceSoft
        property color strokeColor: Colors.dsBorder
        property color labelColor: Colors.dsText
        property color iconBubbleColor: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, Colors.lightMode ? 0.14 : 0.22)
        readonly property color disabledFillColor: Colors.dsSurfaceSoft
        readonly property color disabledStrokeColor: Colors.dsBorderSoft
        readonly property color disabledLabelColor: Colors.dsTextSubtle
        readonly property color disabledAccentColor: Colors.dsTextSubtle
        readonly property color disabledIconBubbleColor: Qt.rgba(Colors.dsTextSubtle.r, Colors.dsTextSubtle.g, Colors.dsTextSubtle.b, Colors.lightMode ? 0.10 : 0.18)
    
        signal clicked()
    
        Layout.fillWidth: true
        Layout.preferredHeight: compactStyle ? 70 : 46
        radius: compactStyle ? 18 : 14
        color: !enabled
               ? disabledFillColor
               : chipMouse.pressed
                 ? (Colors.lightMode ? Qt.darker(hoverFillColor, 1.03) : Qt.lighter(hoverFillColor, 1.08))
                 : (chipMouse.containsMouse ? hoverFillColor : fillColor)
        border.width: 1
        border.color: enabled ? strokeColor : disabledStrokeColor
        opacity: 1.0
        scale: enabled && chipMouse.pressed ? 0.985 : 1.0
        antialiasing: true
    
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
        Behavior on scale { NumberAnimation { duration: 90 } }
    
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: compactStyle ? 8 : 0
            spacing: compactStyle ? 6 : 0
            visible: compactStyle
    
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                radius: 15
                color: chip.enabled ? chip.iconBubbleColor : chip.disabledIconBubbleColor
                border.width: 0
    
                Text {
                    anchors.centerIn: parent
                    text: chip.glyph
                    color: chip.enabled ? chip.accentColor : chip.disabledAccentColor
                    font.family: root.faSolid
                    font.pixelSize: 13
                }
            }
    
            Text {
                Layout.fillWidth: true
                text: chip.label
                color: chip.enabled ? chip.labelColor : chip.disabledLabelColor
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: 11
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }
    
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10
            visible: !compactStyle
    
            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: 14
                color: chip.enabled ? chip.iconBubbleColor : chip.disabledIconBubbleColor
                border.width: 0
    
                Text {
                    anchors.centerIn: parent
                    text: chip.glyph
                    color: chip.enabled ? chip.accentColor : chip.disabledAccentColor
                    font.family: root.faSolid
                    font.pixelSize: 12
                }
            }
    
            Text {
                Layout.fillWidth: true
                text: chip.label
                color: chip.enabled ? chip.labelColor : chip.disabledLabelColor
                font.family: FontSystem.getContentFontBold.name
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }
    
        MouseArea {
            id: chipMouse
            anchors.fill: parent
            enabled: chip.enabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: chip.clicked()
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
                text: root.tunConflictPopupTitle.length > 0
                      ? root.tunConflictPopupTitle
                      : "Connection Issue"
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
        id: securityWarningPopup
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: root.sheetWidth(430)
        height: root.sheetHeight(330)
        x: (root.width - width) * 0.5
        y: root.drawerY(height)
        padding: 0

        enter: Transition {
            NumberAnimation {
                property: "y"
                from: root.height
                to: root.drawerY(securityWarningPopup.height)
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
            color: root.themeColorToken("mainHex_ffffff", "mainHex_090b14")
            border.width: 0
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
                text: "Security Warning"
                color: root.themeColorToken("mainHex_1f2a3a", "mainHex_d8e1f0")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 22
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: "This profile uses legacy or insecure TLS settings. Newer Xray-core versions no longer support allowInsecure. GenyConnect will try to handle it safely, but you should review the profile before connecting."
                color: root.themeColorToken("mainHex_5f6f86", "mainHex_9bb0cb")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            CheckBox {
                id: securityWarningDontShowAgainBox
                Layout.fillWidth: true
                checked: root.securityWarningDontShowAgain
                text: "Don't show this warning again for this profile"
                onToggled: root.securityWarningDontShowAgain = checked
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Controls.Button {
                    Layout.fillWidth: true
                    text: "Review Profile"
                    onClicked: {
                        const row = root.securityWarningProfileRow
                        securityWarningPopup.close()
                        if (row >= 0) {
                            root.openEditProfile(row, vpnController.currentProfileLabel(), vpnController.currentProfileGroupLabel(), vpnController.exportProfileLink(row))
                        }
                    }
                }

                Controls.Button {
                    Layout.fillWidth: true
                    text: "Connect Anyway"
                    onClicked: {
                        const row = root.securityWarningProfileRow
                        if (row >= 0 && root.securityWarningDontShowAgain) {
                            vpnController.setSecurityWarningDismissedForProfile(row, true)
                        }
                        securityWarningPopup.close()
                        if (row >= 0) {
                            vpnController.connectToProfile(row)
                        }
                    }
                }
            }

            Controls.Button {
                Layout.fillWidth: true
                text: "Cancel"
                onClicked: securityWarningPopup.close()
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
                            + (root.compact ? compactActionGrid.implicitHeight : actionsRow.implicitHeight)
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

                GridLayout {
                    id: compactActionGrid
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: 8
                    rowSpacing: 8
                    visible: root.compact

                    ProfileActionChip {
                        compactStyle: true
                        enabled: listView.count > 0
                        label: (vpnController.currentProfileGroup || "All").toLowerCase() === "all" ? "Ping" : "Ping Group"
                        glyph: root.iconPing
                        accentColor: Colors.dsPrimarySolid
                        onClicked: vpnController.pingAllProfiles()
                    }

                    ProfileActionChip {
                        compactStyle: true
                        enabled: listView.count > 0 && !vpnController.busy
                        label: "Best"
                        glyph: "\uf521"
                        accentColor: Colors.dsSuccess
                        onClicked: vpnController.connectBestProfileInCurrentGroup()
                    }

                    ProfileActionChip {
                        compactStyle: true
                        enabled: listView.count > 1
                        label: "Sort Ping"
                        glyph: "\uf160"
                        accentColor: Colors.dsPrimarySolid
                        onClicked: vpnController.sortProfilesByPing(vpnController.currentProfileGroup || "All")
                    }

                    ProfileActionChip {
                        compactStyle: true
                        enabled: vpnController.subscriptions.length > 0 && !vpnController.subscriptionBusy
                        label: (vpnController.currentProfileGroup || "All") === "All" ? "Refresh" : "Refresh Group"
                        glyph: "\uf021"
                        accentColor: Colors.dsPrimarySolid
                        onClicked: {
                            const current = (vpnController.currentProfileGroup || "All")
                            if (current === "All")
                                vpnController.refreshSubscriptions()
                            else
                                vpnController.refreshSubscriptionsByGroup(current)
                        }
                    }

                    ProfileActionChip {
                        compactStyle: true
                        enabled: listView.count > 0 && !vpnController.busy
                        label: "Cleanup"
                        glyph: root.iconShield
                        accentColor: Colors.dsWarning
                        onClicked: {
                            const removed = vpnController.removeDeadProfiles()
                            if (removed > 0) {
                                root.syncSelectedProfileFromController()
                                root.showSettingsFeedback("Removed " + removed + " dead profile(s).")
                                Qt.callLater(root.positionProfilePopup)
                            } else if ((vpnController.lastError || "").trim().length > 0) {
                                root.showSettingsFeedback(vpnController.lastError)
                            } else {
                                root.showSettingsFeedback("No dead profiles to remove.")
                            }
                        }
                    }

                    ProfileActionChip {
                        compactStyle: true
                        enabled: listView.count > 0
                        label: "Export"
                        glyph: root.iconFileLines
                        accentColor: Colors.dsTextMuted
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

                    ProfileActionChip {
                        compactStyle: true
                        enabled: listView.count > 1
                        label: "Delete Rest"
                        glyph: root.iconTrash
                        accentColor: Colors.dsDanger
                        onClicked: clearProfilesPopup.open()
                    }

                    ProfileActionChip {
                        compactStyle: true
                        enabled: vpnController.subscriptions.length > 0 && !vpnController.subscriptionBusy && !vpnController.busy
                        label: "Remove Subs"
                        glyph: root.iconMinus
                        accentColor: Colors.dsDanger
                        onClicked: {
                            const current = (vpnController.currentProfileGroup || "All")
                            const removed = vpnController.removeSubscriptionsByGroup(current)
                            if (removed > 0) {
                                root.syncSelectedProfileFromController()
                                root.showSettingsFeedback(current === "All"
                                                              ? "Removed " + removed + " subscription(s)."
                                                              : "Removed " + removed + " subscription(s) from " + current + ".")
                                Qt.callLater(root.positionProfilePopup)
                            } else if ((vpnController.lastError || "").trim().length > 0) {
                                root.showSettingsFeedback(vpnController.lastError)
                            } else {
                                root.showSettingsFeedback("No subscriptions removed.")
                            }
                        }
                    }
                }

                GridLayout {
                    id: actionsRow
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: 10
                    rowSpacing: 10
                    visible: !root.compact

                    ProfileActionChip {
                        enabled: true
                        label: "Add Profile"
                        glyph: root.iconPlus
                        accentColor: Colors.dsPrimarySolid
                        onClicked: {
                            profilePopup.close()
                            importPopup.open()
                        }
                    }

                    ProfileActionChip {
                        enabled: listView.count > 0
                        label: (vpnController.currentProfileGroup || "All").toLowerCase() === "all"
                               ? "Ping Profiles"
                               : "Ping Group"
                        glyph: root.iconPing
                        accentColor: Colors.dsPrimarySolid
                        onClicked: vpnController.pingAllProfiles()
                    }

                    ProfileActionChip {
                        enabled: listView.count > 0 && !vpnController.busy
                        label: "Best in Group"
                        glyph: "\uf521"
                        accentColor: Colors.dsSuccess
                        onClicked: vpnController.connectBestProfileInCurrentGroup()
                    }

                    ProfileActionChip {
                        enabled: listView.count > 1
                        label: "Sort by Ping"
                        glyph: "\uf160"
                        accentColor: Colors.dsPrimarySolid
                        onClicked: vpnController.sortProfilesByPing(vpnController.currentProfileGroup || "All")
                    }

                    ProfileActionChip {
                        enabled: listView.count > 1
                        label: "Sort by Name"
                        glyph: "\uf15d"
                        accentColor: Colors.dsTextMuted
                        onClicked: vpnController.sortProfilesByName(vpnController.currentProfileGroup || "All")
                    }

                    ProfileActionChip {
                        enabled: listView.count > 1
                        label: "Sort Stable"
                        glyph: "\uf0ae"
                        accentColor: Colors.dsTextMuted
                        onClicked: vpnController.sortProfilesByLastSuccess(vpnController.currentProfileGroup || "All")
                    }

                    ProfileActionChip {
                        enabled: vpnController.subscriptions.length > 0 && !vpnController.subscriptionBusy
                        label: (vpnController.currentProfileGroup || "All") === "All"
                               ? "Refresh Subs"
                               : "Refresh Group"
                        glyph: "\uf021"
                        accentColor: Colors.dsPrimarySolid
                        onClicked: {
                            const current = (vpnController.currentProfileGroup || "All")
                            if (current === "All")
                                vpnController.refreshSubscriptions()
                            else
                                vpnController.refreshSubscriptionsByGroup(current)
                        }
                    }

                    ProfileActionChip {
                        enabled: listView.count > 0 && !vpnController.busy
                        label: "Remove Dead"
                        glyph: root.iconShield
                        accentColor: Colors.dsWarning
                        onClicked: {
                            const removed = vpnController.removeDeadProfiles()
                            if (removed > 0) {
                                root.syncSelectedProfileFromController()
                                root.showSettingsFeedback("Removed " + removed + " dead profile(s).")
                                Qt.callLater(root.positionProfilePopup)
                            } else if ((vpnController.lastError || "").trim().length > 0) {
                                root.showSettingsFeedback(vpnController.lastError)
                            } else {
                                root.showSettingsFeedback("No dead profiles to remove.")
                            }
                        }
                    }

                    ProfileActionChip {
                        enabled: listView.count > 0
                        label: "Export All"
                        glyph: root.iconFileLines
                        accentColor: Colors.dsTextMuted
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

                    ProfileActionChip {
                        enabled: listView.count > 1
                        label: "Delete Others"
                        glyph: root.iconTrash
                        accentColor: Colors.dsDanger
                        onClicked: clearProfilesPopup.open()
                    }

                    ProfileActionChip {
                        enabled: vpnController.subscriptions.length > 0 && !vpnController.subscriptionBusy && !vpnController.busy
                        label: "Remove Subs"
                        glyph: root.iconMinus
                        accentColor: Colors.dsDanger
                        onClicked: {
                            const current = (vpnController.currentProfileGroup || "All")
                            const removed = vpnController.removeSubscriptionsByGroup(current)
                            if (removed > 0) {
                                root.syncSelectedProfileFromController()
                                root.showSettingsFeedback(current === "All"
                                                              ? "Removed " + removed + " subscription(s)."
                                                              : "Removed " + removed + " subscription(s) from " + current + ".")
                                Qt.callLater(root.positionProfilePopup)
                            } else if ((vpnController.lastError || "").trim().length > 0) {
                                root.showSettingsFeedback(vpnController.lastError)
                            } else {
                                root.showSettingsFeedback("No subscriptions removed.")
                            }
                        }
                    }
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

                            Text {
                                text: "Mode"
                                color: root.themeColorToken("mainHex_5f6f86", "mainHex_9bb0cb")
                                font.family: FontSystem.contentFontFamily
                                font.pixelSize: 12
                            }

                            Controls.ComboBox {
                                id: groupModeCombo
                                Layout.preferredWidth: 134
                                Layout.preferredHeight: 30
                                model: ["Manual", "Best Latency", "Fallback"]
                                font.pixelSize: 11
                                leftPadding: 8
                                rightPadding: 24

                                function syncMode() {
                                    const mode = vpnController.profileGroupMode(groupFilterCombo.groupNameAt(groupFilterCombo.currentIndex)) || "Manual"
                                    for (let i = 0; i < model.length; ++i) {
                                        if (String(model[i]).toLowerCase() === String(mode).toLowerCase()) {
                                            if (currentIndex !== i)
                                                currentIndex = i
                                            return
                                        }
                                    }
                                    currentIndex = 0
                                }

                                onActivated: function(activatedIndex) {
                                    vpnController.setProfileGroupMode(groupFilterCombo.groupNameAt(groupFilterCombo.currentIndex), model[activatedIndex])
                                }
                                Component.onCompleted: syncMode()

                                Connections {
                                    target: vpnController
                                    function onProfileGroupOptionsChanged() { groupModeCombo.syncMode() }
                                    function onCurrentProfileGroupChanged() { groupModeCombo.syncMode() }
                                }
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
                            required property real packetLossPct
                            required property string packetLossText

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
                                            text: pinging ? "..." : (pingMs >= 0 ? (pingMs + " ms" + (packetLossPct > 0 ? (" / " + packetLossText) : "")) : "--")
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
                                    Layout.preferredWidth: root.compact ? 122 : 172
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: root.compact ? 2 : 10

                                    Text {
                                        Layout.preferredWidth: root.compact ? 17 : 20
                                        text: "\uf062"
                                        color: index > 0
                                               ? root.themeColorToken("mainHex_5b6f8e", "mainHex_a5bbd8")
                                               : root.themeColorToken("mainHex_c9d1dc", "mainHex_4a5b72")
                                        opacity: index > 0 ? 1.0 : 0.45
                                        font.family: root.faSolid
                                        font.pixelSize: root.compact ? 12 : 14
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: index > 0
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: vpnController.moveProfile(index, index - 1)
                                        }
                                    }

                                    Text {
                                        Layout.preferredWidth: root.compact ? 17 : 20
                                        text: "\uf063"
                                        color: index < listView.count - 1
                                               ? root.themeColorToken("mainHex_5b6f8e", "mainHex_a5bbd8")
                                               : root.themeColorToken("mainHex_c9d1dc", "mainHex_4a5b72")
                                        opacity: index < listView.count - 1 ? 1.0 : 0.45
                                        font.family: root.faSolid
                                        font.pixelSize: root.compact ? 12 : 14
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: index < listView.count - 1
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: vpnController.moveProfile(index, index + 1)
                                        }
                                    }

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
                                                const payload = vpnController.exportProfileLink(index)
                                                if ((payload || "").trim().length === 0) {
                                                    root.showSettingsFeedback("Profile link unavailable.")
                                                    return
                                                }
                                                vpnController.copyTextToClipboard(payload)
                                                root.showSettingsFeedback("Profile link copied to clipboard.")
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
                text: "Delete other profiles?"
                color: root.themeColorToken("mainHex_1f2530", "mainHex_d8e1f0")
                font.family: FontSystem.contentFontFamily
                font.pixelSize: 24
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: "This keeps the selected profile and any active connection, then removes the rest."
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
                                    text: (root.editProfileVlessForm.protocol || "vless")
                                    selectByMouse: true
                                }
                                Controls.TextField {
                                    id: editProfileUuidFieldDesktop
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38
                                    readOnly: false
                                    text: root.editProfileVlessForm.uuid || ""
                                    placeholderText: (root.editProfileVlessForm.protocol || "vless") === "wireguard"
                                                     ? "Private key"
                                                     : ((root.editProfileVlessForm.protocol || "vless") === "trojan"
                                                        || (root.editProfileVlessForm.protocol || "vless") === "shadowsocks"
                                                        ? "Password"
                                                        : "UUID")
                                    selectByMouse: true
                                    onTextChanged: {
                                        root.editProfileVlessForm.uuid = text
                                        root.editProfileError = ""
                                    }
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
                                    text: (root.editProfileVlessForm.protocol || "vless")
                                    selectByMouse: true
                                }
                                Controls.TextField {
                                    id: editProfileUuidFieldCompact
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38
                                    readOnly: false
                                    text: root.editProfileVlessForm.uuid || ""
                                    placeholderText: (root.editProfileVlessForm.protocol || "vless") === "wireguard"
                                                     ? "Private key"
                                                     : ((root.editProfileVlessForm.protocol || "vless") === "trojan"
                                                        || (root.editProfileVlessForm.protocol || "vless") === "shadowsocks"
                                                        ? "Password"
                                                        : "UUID")
                                    selectByMouse: true
                                    onTextChanged: {
                                        root.editProfileVlessForm.uuid = text
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
                                    model: (root.editProfileVlessForm.protocol || "vless") === "wireguard"
                                           ? ["wireguard"]
                                           : ["tcp", "ws", "xhttp", "grpc"]
                                    currentIndex: Math.max(0, model.indexOf(root.editProfileVlessForm.network || "tcp"))
                                    onActivated: function(activatedIndex) {
                                        root.editProfileVlessForm.network = model[activatedIndex]
                                        root.editProfileError = ""
                                    }
                                }
                                Controls.ComboBox {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38
                                    model: (root.editProfileVlessForm.protocol || "vless") === "wireguard"
                                           ? ["none"]
                                           : ["none", "tls", "reality"]
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
                                    placeholderText: (root.editProfileVlessForm.protocol || "vless") === "wireguard"
                                                     ? "Encryption"
                                                     : "Encryption (none/auto/...)"
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
                                    placeholderText: (root.editProfileVlessForm.protocol || "vless") === "wireguard"
                                                     ? "MTU"
                                                     : "Flow (optional)"
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
                                    placeholderText: (root.editProfileVlessForm.protocol || "vless") === "wireguard"
                                                     ? "DNS"
                                                     : "SNI"
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
                                    placeholderText: (root.editProfileVlessForm.protocol || "vless") === "wireguard"
                                                     ? "Public key"
                                                     : "Host header"
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
                                placeholderText: (root.editProfileVlessForm.protocol || "vless") === "wireguard"
                                                 ? "Client address"
                                                 : "Path (for ws/xhttp)"
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
                        wrapMode: TextEdit.WrapAnywhere
                        selectByMouse: true
                        onTextChanged: {
                            root.editProfileConfigLink = text
                            root.editProfileError = ""
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.editProfileVlessSupported
                              ? "You can edit common profile fields above or directly edit the full config text below."
                              : "This profile can be edited using the full config text field."
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
                            const built = root.buildEditableProfileLinkFromForm(root.editProfileVlessForm, editProfileNameField.text)
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

                        SettingsMainList {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "main"
                            root: surface.root
                        }

                        InterfaceSettings {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "interface"
                            root: surface.root
                            dashboardStatsSettings: surface.dashboardStatsSettings
                            interfaceThemeSettings: surface.interfaceThemeSettings
                            interfacePrivacySettings: surface.interfacePrivacySettings
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
                                    implicitHeight: aboutSoftwareColumn.implicitHeight + 14

                                    ColumnLayout {
                                        id: aboutSoftwareColumn
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 7

                                        Text {
                                            text: "Software Information"
                                            color: root.themeColorToken("mainHex_1f2530", "mainHex_d8e1f0")
                                            font.family: FontSystem.getContentFontBold.name
                                            font.pixelSize: 14
                                            font.bold: true
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: "App, runtime, and operating system details."
                                            color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                                            font.family: FontSystem.contentFontFamily
                                            font.pixelSize: 11
                                            wrapMode: Text.WordWrap
                                        }

                                        GridLayout {
                                            Layout.fillWidth: true
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
                                                text: aboutPopup.aboutSoftwareValue("appVersion")
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
                                                text: aboutPopup.aboutSoftwareValue("xrayVersion")
                                                color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                                font.family: FontSystem.getContentFontBold.name
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                            }

                                            Text {
                                                text: "Qt Runtime"
                                                color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 12
                                            }
                                            Text {
                                                text: aboutPopup.aboutSoftwareValue("qtVersion")
                                                color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                                font.family: FontSystem.getContentFontBold.name
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                            }

                                            Text {
                                                text: "Runtime"
                                                color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 12
                                            }
                                            Text {
                                                text: aboutPopup.aboutSoftwareValue("platformMode")
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
                                                text: aboutPopup.aboutSoftwareValue("platform")
                                                color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                                font.family: FontSystem.getContentFontBold.name
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                            }

                                            Text {
                                                text: "OS Name"
                                                color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 12
                                            }
                                            Text {
                                                text: aboutPopup.aboutSoftwareValue("osName")
                                                color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                                font.family: FontSystem.getContentFontBold.name
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                            }

                                            Text {
                                                text: "OS Kernel / API"
                                                color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 12
                                            }
                                            Text {
                                                text: aboutPopup.aboutSoftwareValue("apiText")
                                                color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                                font.family: FontSystem.getContentFontBold.name
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                            }

                                            Text {
                                                text: "SDK / Runtime"
                                                color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 12
                                            }
                                            Text {
                                                text: aboutPopup.aboutSoftwareValue("sdkText")
                                                color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                                font.family: FontSystem.getContentFontBold.name
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                            }

                                            Text {
                                                text: "Language Standard"
                                                color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 12
                                            }
                                            Text {
                                                text: aboutPopup.aboutSoftwareValue("languageStandard")
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
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    radius: 10
                                    color: root.themeColorToken("mainHex_ffffff", "mainHex_1a2b42")
                                    border.width: 1
                                    border.color: root.themeColorToken("mainHex_dce4f1", "mainHex_355173")
                                    implicitHeight: aboutSystemColumn.implicitHeight + 14

                                    ColumnLayout {
                                        id: aboutSystemColumn
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 7

                                        Text {
                                            text: "System Information"
                                            color: root.themeColorToken("mainHex_1f2530", "mainHex_d8e1f0")
                                            font.family: FontSystem.getContentFontBold.name
                                            font.pixelSize: 14
                                            font.bold: true
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: "Hardware, memory, and display details for troubleshooting."
                                            color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                                            font.family: FontSystem.contentFontFamily
                                            font.pixelSize: 11
                                            wrapMode: Text.WordWrap
                                        }

                                        GridLayout {
                                            Layout.fillWidth: true
                                            columns: 2
                                            columnSpacing: 8
                                            rowSpacing: 5

                                            Text {
                                                text: "CPU"
                                                color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 12
                                            }
                                            Text {
                                                text: aboutPopup.aboutHardwareValue("cpuName")
                                                color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                                font.family: FontSystem.getContentFontBold.name
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                            }

                                            Text {
                                                text: "Architecture"
                                                color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 12
                                            }
                                            Text {
                                                text: aboutPopup.aboutHardwareValue("cpuArchitecture")
                                                color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                                font.family: FontSystem.getContentFontBold.name
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                            }

                                            Text {
                                                text: "Memory"
                                                color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 12
                                            }
                                            Text {
                                                text: aboutPopup.aboutMemoryValue()
                                                color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                                font.family: FontSystem.getContentFontBold.name
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                            }

                                            Text {
                                                text: "Process Memory"
                                                color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 12
                                            }
                                            Text {
                                                text: aboutPopup.aboutHardwareValue("processMemoryText")
                                                color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                                font.family: FontSystem.getContentFontBold.name
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                            }

                                            Text {
                                                text: "Device / Host"
                                                color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 12
                                            }
                                            Text {
                                                text: aboutPopup.aboutHardwareValue("deviceName")
                                                color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                                font.family: FontSystem.getContentFontBold.name
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                            }

                                            Text {
                                                text: "Display"
                                                color: root.themeColorToken("mainHex_7c8697", "mainHex_9bb0cb")
                                                font.family: FontSystem.contentFontFamily
                                                font.pixelSize: 12
                                            }
                                            Text {
                                                text: aboutPopup.aboutHardwareValue("displayText")
                                                color: root.themeColorToken("mainHex_2a3240", "mainHex_d7e4f6")
                                                font.family: FontSystem.getContentFontBold.name
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignRight
                                            }
                                        }
                                    }
                                }

                                Controls.OutlineButton {
                                    Layout.fillWidth: true
                                    text: "Copy System Info"
                                    onClicked: vpnController.copyTextToClipboard(vpnController.systemInfoText())
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

                        UpdatesSettings {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "updates"
                            root: surface.root
                            vpnController: surface.vpnController
                            updater: surface.updater
                        }


                        ConnectionModeSettings {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "connection"
                            root: surface.root
                            vpnController: surface.vpnController
                        }

                        LogsSettings {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "logs"
                            root: surface.root
                            vpnController: surface.vpnController
                            logsPopup: surface.logsPopup
                        }

                        CacheSettings {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "cache"
                            root: surface.root
                            vpnController: surface.vpnController
                        }

                        PowerModeSettings {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "power"
                            root: surface.root
                            vpnController: surface.vpnController
                        }

                        LanSharingSettings {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "lan"
                            root: surface.root
                            vpnController: surface.vpnController
                            settingsFlick: settingsFlick
                        }

                        RoutingRulesSettings {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "routing"
                            root: surface.root
                            vpnController: surface.vpnController
                        }

                        CustomDnsSettings {
                            Layout.fillWidth: true
                            visible: root.settingsSection === "dns"
                            root: surface.root
                            vpnController: surface.vpnController
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
        property var aboutSoftwareInfo: ({})
        property var aboutHardwareInfo: ({})
        width: root.sheetWidth(430)
        height: root.compact ? root.height : root.sheetHeight(700)
        x: (root.width - width) * 0.5
        y: root.drawerY(height)
        padding: 0

        function aboutValue(map, key) {
            if (!map)
                return "Unavailable"
            const value = map[key]
            if (value === undefined || value === null)
                return "Unavailable"
            const text = String(value)
            return text.length > 0 ? text : "Unavailable"
        }

        function normalizeAboutValue(value) {
            if (value === undefined || value === null)
                return "Unavailable"
            const text = String(value).trim()
            return text.length > 0 ? text : "Unavailable"
        }

        function aboutSoftwareValue(key) {
            try {
                return normalizeAboutValue(vpnController.systemSoftwareInfoValue(key))
            } catch (error) {
            }
            return aboutValue(aboutSoftwareInfo, key)
        }

        function aboutHardwareValue(key) {
            try {
                return normalizeAboutValue(vpnController.systemHardwareInfoValue(key))
            } catch (error) {
            }
            return aboutValue(aboutHardwareInfo, key)
        }

        function aboutMemoryValue() {
            const value = aboutHardwareValue("memoryText")
            return value === "Unavailable" ? value : (value + " total")
        }

        function refreshAboutSystemInfoFromReport() {
            const software = ({})
            const hardware = ({})
            const softwareLabels = ({
                "App Version": "appVersion",
                "xray-core": "xrayVersion",
                "Qt Runtime": "qtVersion",
                "Language Standard": "languageStandard",
                "Runtime": "platformMode",
                "Platform": "platform",
                "OS": "osName",
                "Kernel / API": "apiText",
                "SDK": "sdkText"
            })
            const hardwareLabels = ({
                "CPU": "cpuName",
                "Architecture": "cpuArchitecture",
                "Memory": "memoryText",
                "Process Memory": "processMemoryText",
                "Device": "deviceName",
                "Display": "displayText"
            })
            const lines = String(vpnController.systemInfoText() || "").split(/\r?\n/)
            let section = ""

            for (let index = 0; index < lines.length; ++index) {
                const line = String(lines[index] || "").trim()
                if (line.length === 0)
                    continue
                if (line === "Software") {
                    section = "software"
                    continue
                }
                if (line === "Hardware") {
                    section = "hardware"
                    continue
                }
                const separator = line.indexOf(":")
                if (separator <= 0)
                    continue

                const label = line.slice(0, separator).trim()
                const value = line.slice(separator + 1).trim()
                if (section === "software" && softwareLabels[label])
                    software[softwareLabels[label]] = value
                else if (section === "hardware" && hardwareLabels[label])
                    hardware[hardwareLabels[label]] = value
            }

            aboutSoftwareInfo = ({
                "appVersion": software.appVersion,
                "xrayVersion": software.xrayVersion,
                "qtVersion": software.qtVersion,
                "platformMode": software.platformMode,
                "platform": software.platform,
                "osName": software.osName,
                "osKernel": software.osKernel,
                "apiText": software.apiText,
                "sdkText": software.sdkText,
                "languageStandard": software.languageStandard
            })

            aboutHardwareInfo = ({
                "cpuName": hardware.cpuName,
                "cpuArchitecture": hardware.cpuArchitecture,
                "memoryText": hardware.memoryText,
                "processMemoryText": hardware.processMemoryText,
                "deviceName": hardware.deviceName,
                "displayText": hardware.displayText
            })
        }

        function refreshAboutSystemInfo() {
            if (vpnController.systemSoftwareInfo && vpnController.systemHardwareInfo) {
                aboutSoftwareInfo = vpnController.systemSoftwareInfo() || ({})
                aboutHardwareInfo = vpnController.systemHardwareInfo() || ({})
                if (aboutValue(aboutSoftwareInfo, "appVersion") !== "Unavailable"
                        || aboutValue(aboutHardwareInfo, "cpuName") !== "Unavailable")
                    return
            }

            refreshAboutSystemInfoFromReport()
        }

        onVisibleChanged: if (visible) refreshAboutSystemInfo()
        onAboutToShow: refreshAboutSystemInfo()
        onOpened: refreshAboutSystemInfo()

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
                font.pixelSize: 20
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
                    onClicked: {
                        aboutPopup.refreshAboutSystemInfo()
                        aboutPopup.open()
                    }
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
                        font.pixelSize: 18
                        elide: Text.ElideRight
                    }

                    Item { Layout.fillWidth: true }

                    PowerHomeBadge {
                        modeName: vpnController.powerMode
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        onClicked: root.openSettingsSection("power")
                    }

                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
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
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32

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
                            color: root.heroPowerRingColor()
                            opacity: index === 0 ? 1.0 : (vpnController.connectionState === ConnectionState.Disconnected ? 0.12 : 0.16)
                            border.width: index === 3 ? 1 : 0
                            border.color: root.heroPowerRingColor()
                            scale: root.powerDecorativeAnimationsEnabled && vpnController.connectionState === ConnectionState.Connecting && index > 0 ? 1.04 : 1.0
                            Behavior on color { ColorAnimation { duration: 280 } }
                            Behavior on border.color { ColorAnimation { duration: 280 } }
                            Behavior on scale {
                                enabled: root.powerVisualAnimationsEnabled
                                NumberAnimation { duration: 520; easing.type: Easing.InOutQuad }
                            }
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
                        accentColor: root.heroPowerRingColor()
                    }

                    Rectangle {
                        id: heroConnectButton
                        anchors.centerIn: parent
                        property real idlePulseScale: 1.0
                        property real networkPulseTrafficFactor: root.clamp01((Math.max(0, root.downRateBytesPerSec, root.upRateBytesPerSec) * 8.0 / 1000000.0) / 120.0)
                        property bool networkPulseActive: root.powerDecorativeAnimationsEnabled
                                                          && vpnController.connectionState !== ConnectionState.Disconnected
                                                          && !heroConnectMouse.pressed
                        property int networkPulseDuration: vpnController.connectionState === ConnectionState.Connecting
                                                          ? 920
                                                          : (vpnController.connectionState === ConnectionState.Error
                                                             ? 1180
                                                             : Math.round(1540 - (networkPulseTrafficFactor * 420)))
                        property int networkPulseStagger: Math.max(150, Math.round(networkPulseDuration / 3.2))
                        property int networkPulseCycle: networkPulseDuration + (networkPulseStagger * 2)
                        width: Math.max(82, Math.round(104 * root.mobileHomeScale))
                        height: width
                        radius: width * 0.5
                        color: root.heroPowerCoreColor()
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

                        Repeater {
                            model: 3

                            Rectangle {
                                id: pulseRing
                                required property int index
                                anchors.centerIn: parent
                                width: parent.width * 1.02
                                height: width
                                radius: width * 0.5
                                color: "transparent"
                                border.width: 2
                                border.color: Qt.rgba(root.heroPowerRingColor().r, root.heroPowerRingColor().g, root.heroPowerRingColor().b, 0.28)
                                property real pulseProgress: 0.0
                                scale: 0.68 + (pulseProgress * 0.94)
                                opacity: heroConnectButton.networkPulseActive
                                         ? ((0.30 + (heroConnectButton.networkPulseTrafficFactor * 0.08)) * (1.0 - pulseProgress))
                                         : 0.0

                                SequentialAnimation on pulseProgress {
                                    running: heroConnectButton.networkPulseActive
                                    loops: Animation.Infinite
                                    PauseAnimation {
                                        duration: index * heroConnectButton.networkPulseStagger
                                    }
                                    NumberAnimation {
                                        from: 0.0
                                        to: 1.0
                                        duration: heroConnectButton.networkPulseDuration
                                        easing.type: Easing.OutCubic
                                    }
                                    PauseAnimation {
                                        duration: Math.max(1, heroConnectButton.networkPulseCycle - (index * heroConnectButton.networkPulseStagger) - heroConnectButton.networkPulseDuration)
                                    }
                                    onRunningChanged: {
                                        if (!running)
                                            pulseRing.pulseProgress = 0.0
                                    }
                                }

                                Behavior on border.color {
                                    enabled: root.powerVisualAnimationsEnabled
                                    ColorAnimation { duration: 240 }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: root.homeConnectGlyph()
                            color: Colors.mainHex_ffffff
                            font.family: root.faSolid
                            font.pixelSize: 50
                            scale: vpnController.connectionState === ConnectionState.Connecting
                                   ? 1.04
                                   : (heroConnectButton.networkPulseActive ? 1.01 + (heroConnectButton.networkPulseTrafficFactor * 0.03) : 1.0)
                            opacity: vpnController.connectionState === ConnectionState.Connecting ? 0.96 : 1.0
                            Behavior on scale {
                                enabled: root.powerVisualAnimationsEnabled
                                NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
                            }
                            Behavior on opacity {
                                enabled: root.powerVisualAnimationsEnabled
                                NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
                            }
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
                    color: root.heroPowerStatusColor()
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
                        color: root.heroPowerStatusTextColor()
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
