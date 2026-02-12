pragma Singleton

import QtQuick
import QtQuick.Controls

QtObject {
    id: styleObject

    readonly property int radius : 15

    property bool lightMode: {
        if (!AppGlobals.appWindow)
        return true
        return Qt.darker(AppGlobals.appWindow.palette.window, 1.2)
        !== AppGlobals.appWindow.palette.window
    }

    // Accent and page colors
    readonly property color accent: lightMode ? "#ffffff" : "#1e1e1e"
    readonly property color pageground: lightMode ? "#ebecf1" : "#121212"
    readonly property color pagespaceActivated: lightMode ? "#fcfcfc" : "#1c1c1c"
    readonly property color pagespacePressed: lightMode ? "#ebecf1" : "#2a2a2a"
    readonly property color pagespaceHovered: lightMode ? "#ececec" : "#2e2e2e"

    // Text colors
    readonly property color textPrimary: lightMode ? "#1a1a1a" : "#ffffff"
    readonly property color textSecondary: lightMode ? "#555555" : "#cccccc"
    readonly property color textMuted: lightMode ? "#888888" : "#888888"
    readonly property color textAccent: lightMode ? "#3a86ff" : "#2a5dcc"
    readonly property color textSuccess: lightMode ? "#0cce6b" : "#0c9944"
    readonly property color textWarning: lightMode ? "#ee7e0a" : "#cc6600"
    readonly property color textError: lightMode ? "#cc3333" : "#ff6666"

    // Static colors
    readonly property color staticPrimary: "#ffffff"
    readonly property color staticSecondry: "#000000"


    // Backgrounds
    readonly property color background: lightMode ? "#ffffff" : "#1b1b1b"
    readonly property color backgroundActivated: lightMode ? "#ffffff" : "#2b2b2b"
    readonly property color backgroundDeactivated: lightMode ? "#E5E5E5" : "#3a3a3a"
    readonly property color backgroundHovered: lightMode ? "#dcdcdc" : "#444444"
    readonly property color backgroundFocused: lightMode ? "#fafafa" : "#333333"

    // Background items
    readonly property color backgroundItemActivated: lightMode ? "#f3f4f6" : "#2c2c2c"
    readonly property color backgroundItemDeactivated: lightMode ? "#F1F1F1" : "#3b3b3b"
    readonly property color backgroundItemHovered: lightMode ? "#E3C7B7" : "#555555"
    readonly property color backgroundItemFocused: lightMode ? "#D2A992" : "#666666"

    // Foregrounds
    readonly property color foregroundActivated: lightMode ? "#ffffff" : "#eeeeee"
    readonly property color foregroundDeactivated: lightMode ? "#9097a6" : "#888888"
    readonly property color foregroundHovered: lightMode ? "#767676" : "#bbbbbb"
    readonly property color foregroundFocused: lightMode ? "#ffffff" : "#ffffff"

    // Borders
    readonly property color borderActivated: lightMode ? "#E5E5E5" : "#444444"
    readonly property color borderDeactivated: lightMode ? "#D9D9DB" : "#555555"
    readonly property color borderHovered: lightMode ? "#2b303b" : "#bbbbbb"
    readonly property color borderFocused: lightMode ? "#50535a" : "#ffffff"

    // Lines
    readonly property color lineBorderActivated: lightMode ? "#E1E1E1" : "#333333"
    readonly property color lineBorderDeactivated: lightMode ? "#f1f1f1" : "#444444"
    readonly property color lineBorderHovered: lightMode ? "#f1f1f1" : "#555555"
    readonly property color lineBorderFocused: lightMode ? "#f1f1f1" : "#777777"

    // Header and footer
    readonly property color header: lightMode ? "#ddd9f1" : "#222222"
    readonly property color footer: lightMode ? "#0e121b" : "#111111"

    // Status colors
    readonly property color primary: lightMode ? "#6e707b" : "#a0a0a0"
    readonly property color primaryBack: lightMode ? "#4572e8" : "#3050a0"
    readonly property color secondry: lightMode ? "#3a86ff" : "#2a5dcc"
    readonly property color secondryBack: lightMode ? "#CCEEFF" : "#224466"
    readonly property color success: lightMode ? "#00a693" : "#00a693"
    readonly property color successBack: lightMode ? "#480cce6b" : "#00534a"
    readonly property color warning: lightMode ? "#ee7e0a" : "#cc6600"
    readonly property color warningBack: lightMode ? "#ffe8c2" : "#554422"
    readonly property color error: lightMode ? "#cc3333" : "#ff6666"
    readonly property color errorBack: lightMode ? "#ffcccc" : "#552222"

    // Shadows
    readonly property color lightShadow: lightMode ? "#28555555" : "#11111155"
    readonly property color darkShadow: lightMode ? "#1e2533" : "#000000"

    // Misc
    readonly property bool shadow: true
}
