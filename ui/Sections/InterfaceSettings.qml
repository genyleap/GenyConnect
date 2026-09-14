import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import GenyConnect 1.0
import "../Core"
import "../Controls" as Controls

ColumnLayout {
    id: section

    required property var root
    required property var dashboardStatsSettings
    required property var interfaceThemeSettings
    required property var interfacePrivacySettings
    required property var interfaceLanguageSettings

    Layout.fillWidth: true
    spacing: Metrics.gap16

    component PreferenceRow: ColumnLayout {
        id: preference
        required property string title
        property string description: ""
        required property var choices
        property int selectedIndex: 0
        signal selected(int index)

        Layout.fillWidth: true
        spacing: Metrics.gap8

        GridLayout {
            Layout.fillWidth: true
            columns: preference.width < 380 ? 1 : 2
            columnSpacing: Metrics.gap16
            rowSpacing: Metrics.gap8

            Text {
                Layout.fillWidth: true
                text: preference.title
                color: Colors.dsText
                font.family: FontSystem.contentFontFamily
                font.pixelSize: Typography.uiBodyLg
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
            }

            Controls.ComboBox {
                Layout.fillWidth: true
                Layout.preferredWidth: 180
                Layout.maximumWidth: preference.width < 380 ? Number.POSITIVE_INFINITY : 200
                implicitHeight: 44
                model: preference.choices
                currentIndex: preference.selectedIndex
                Accessible.name: preference.title
                onActivated: function(index) { preference.selected(index) }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: preference.description.length > 0
            text: preference.description
            color: Colors.dsTextMuted
            font.family: FontSystem.contentFontFamily
            font.pixelSize: Typography.uiBody
            wrapMode: Text.WordWrap
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: appearanceColumn.implicitHeight + 32
        radius: Metrics.radiusMd
        color: Colors.dsSurface
        border.color: Colors.dsBorderSoft

        ColumnLayout {
            id: appearanceColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Metrics.gap16
            spacing: Metrics.gap20

            Text {
                Layout.fillWidth: true
                text: I18n.t("Theme and language")
                color: Colors.dsText
                font.family: FontSystem.contentFontFamily
                font.pixelSize: Typography.uiTitle
                font.weight: Font.Bold
                wrapMode: Text.WordWrap
            }

            PreferenceRow {
                title: I18n.t("Language")
                description: I18n.t("Changes are applied immediately and saved for the next launch.")
                choices: I18n.languages
                selectedIndex: I18n.languageIndex(interfaceLanguageSettings.language)
                onSelected: function(index) { interfaceLanguageSettings.language = I18n.languages[index].code }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Colors.dsBorderSoft }

            PreferenceRow {
                title: I18n.t("Theme")
                description: I18n.t("System follows your device appearance.")
                choices: root.themeModeOptions
                selectedIndex: root.unitIndex(root.themeModeOptions, interfaceThemeSettings.mode)
                onSelected: function(index) { interfaceThemeSettings.mode = root.themeModeOptions[index] }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: displayColumn.implicitHeight + 32
        radius: Metrics.radiusMd
        color: Colors.dsSurface
        border.color: Colors.dsBorderSoft

        ColumnLayout {
            id: displayColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Metrics.gap16
            spacing: Metrics.gap20

            Text {
                Layout.fillWidth: true
                text: I18n.t("Dashboard Stats")
                color: Colors.dsText
                font.family: FontSystem.contentFontFamily
                font.pixelSize: Typography.uiTitle
                font.weight: Font.Bold
                wrapMode: Text.WordWrap
            }

            PreferenceRow {
                title: I18n.t("IP Privacy")
                description: I18n.t(interfacePrivacySettings.ipDisplayMode === "Hidden"
                    ? "Home and status panels show *.*.*.* or Endpoint hidden instead of visible IP details."
                    : (interfacePrivacySettings.ipDisplayMode === "Partial Mask"
                       ? "Home and status panels keep enough context for troubleshooting while masking the precise address."
                       : "Visible IP and endpoint details are shown normally."))
                choices: root.ipPrivacyOptions
                selectedIndex: root.unitIndex(root.ipPrivacyOptions, interfacePrivacySettings.ipDisplayMode)
                onSelected: function(index) { interfacePrivacySettings.ipDisplayMode = root.ipPrivacyOptions[index] }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Colors.dsBorderSoft }

            PreferenceRow {
                title: I18n.t("Speed Units")
                description: I18n.t("Use lowercase b for bits and uppercase B for bytes.")
                choices: root.speedUnitOptions
                selectedIndex: root.unitIndex(root.speedUnitOptions, dashboardStatsSettings.speedUnit)
                onSelected: function(index) { dashboardStatsSettings.speedUnit = root.speedUnitOptions[index] }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Colors.dsBorderSoft }

            PreferenceRow {
                title: I18n.t("Total Traffic Units")
                choices: root.trafficUnitOptions
                selectedIndex: root.unitIndex(root.trafficUnitOptions, dashboardStatsSettings.trafficUnit)
                onSelected: function(index) { dashboardStatsSettings.trafficUnit = root.trafficUnitOptions[index] }
            }
        }
    }
}
