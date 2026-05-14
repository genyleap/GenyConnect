pragma Singleton

import QtQuick
import QtQuick.Controls

QtObject {
    id: styleObject

    // ══════════════════════════════════════════════════════════════════════════
    // Shape / spacing
    // ══════════════════════════════════════════════════════════════════════════

    readonly property int radius: 28
    readonly property int padding: 8
    readonly property int outerRadius: 28
    readonly property int innerRadius: 20

    readonly property int radiusXs: 10
    readonly property int radiusSm: 14
    readonly property int radiusMd: 18
    readonly property int radiusLg: 24
    readonly property int radiusXl: 30
    readonly property int radiusPill: 999

    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 12
    readonly property int spacingLg: 18
    readonly property int spacingXl: 24

    property bool lightMode: Theme.mode === Theme.Light

    // ══════════════════════════════════════════════════════════════════════════
    // Main brand palette
    // MVP style: deep cosmic navy + indigo/blue accents with restrained green.
    // ══════════════════════════════════════════════════════════════════════════

    readonly property color brandGreen: "#2fe09c"
    readonly property color brandGreenSoft: "#72efbf"
    readonly property color brandGreenDeep: "#19b874"
    readonly property color brandGreenBack: "#1f2fe09c"

    readonly property color brandRed: "#ff3158"
    readonly property color brandYellow: "#ffb84d"
    readonly property color brandBlue: "#3f7cf3"
    readonly property color brandPurple: "#7f72ff"

    readonly property color cosmicBlack: "#05070f"
    readonly property color cosmicBg: "#070b1a"
    readonly property color cosmicBg2: "#0d1327"
    readonly property color cosmicPanel: "#111a30"
    readonly property color cosmicPanel2: "#16213a"
    readonly property color cosmicPanel3: "#1d2d4a"
    readonly property color cosmicStroke: "#274062"
    readonly property color cosmicStrokeSoft: "#1a2f4c"

    // ══════════════════════════════════════════════════════════════════════════
    // Accent and page colors
    // ══════════════════════════════════════════════════════════════════════════

    readonly property color accent: lightMode ? "#2f74ff" : brandBlue
    readonly property color accentSoft: lightMode ? "#5f95f2" : "#6da2ff"
    readonly property color accentPressed: lightMode ? "#2b6dcf" : "#2f6de2"
    readonly property color accentBack: lightMode ? "#203f7cf3" : "#243f7cf3"

    readonly property color pageground: lightMode ? "#eef3f8" : cosmicBg
    readonly property color pagespaceActivated: lightMode ? "#ffffff" : cosmicPanel
    readonly property color pagespacePressed: lightMode ? "#e9eef6" : "#202034"
    readonly property color pagespaceHovered: lightMode ? "#f5f8fc" : "#24243a"

    // ══════════════════════════════════════════════════════════════════════════
    // Text colors
    // ══════════════════════════════════════════════════════════════════════════

    readonly property color textPrimary: lightMode ? "#151a24" : "#f4f6ff"
    readonly property color textSecondary: lightMode ? "#4f5d70" : "#c8ccdc"
    readonly property color textMuted: lightMode ? "#7c8798" : "#85899d"
    readonly property color textSubtle: lightMode ? "#9aa4b4" : "#6f7388"

    readonly property color textAccent: lightMode ? "#2f6ff1" : brandBlue
    readonly property color textSuccess: lightMode ? "#10b66f" : brandGreen
    readonly property color textWarning: lightMode ? "#d98510" : "#ffb84d"
    readonly property color textError: lightMode ? "#d6455d" : "#ff6b86"

    // Static colors
    readonly property color staticPrimary: "#ffffff"
    readonly property color staticSecondry: "#000000"

    // ══════════════════════════════════════════════════════════════════════════
    // Backgrounds
    // ══════════════════════════════════════════════════════════════════════════

    readonly property color background: lightMode ? "#f2f5fa" : cosmicBg
    readonly property color backgroundActivated: lightMode ? "#ffffff" : cosmicPanel
    readonly property color backgroundDeactivated: lightMode ? "#e4e9f1" : "#191a28"
    readonly property color backgroundHovered: lightMode ? "#f6f8fc" : "#202135"
    readonly property color backgroundFocused: lightMode ? "#ffffff" : "#24243a"

    // Background items
    readonly property color backgroundItemActivated: lightMode ? "#ffffff" : "#181824"
    readonly property color backgroundItemDeactivated: lightMode ? "#edf1f7" : "#151620"
    readonly property color backgroundItemHovered: lightMode ? "#eaf3ff" : "#222236"
    readonly property color backgroundItemFocused: lightMode ? "#e8f1ff" : "#243a5c"

    // Foregrounds
    readonly property color foregroundActivated: lightMode ? "#131722" : "#f3f6ff"
    readonly property color foregroundDeactivated: lightMode ? "#8d97a8" : "#7f8497"
    readonly property color foregroundHovered: lightMode ? "#344054" : "#d8dcee"
    readonly property color foregroundFocused: lightMode ? "#111827" : "#ffffff"

    // Borders
    readonly property color borderActivated: lightMode ? "#dce3ee" : cosmicStroke
    readonly property color borderDeactivated: lightMode ? "#e4e9f1" : cosmicStrokeSoft
    readonly property color borderHovered: lightMode ? "#bfd1e8" : "#4b496b"
    readonly property color borderFocused: lightMode ? "#5f95f2" : "#7fb0ff"

    // Lines
    readonly property color lineBorderActivated: lightMode ? "#e4e9f1" : "#262638"
    readonly property color lineBorderDeactivated: lightMode ? "#eef2f7" : "#202031"
    readonly property color lineBorderHovered: lightMode ? "#d8e1ee" : "#32324a"
    readonly property color lineBorderFocused: lightMode ? "#c7dbf8" : "#355173"

    // Header and footer
    readonly property color header: lightMode ? "#ffffff" : "#11121d"
    readonly property color footer: lightMode ? "#ffffff" : "#11121d"

    // ══════════════════════════════════════════════════════════════════════════
    // Status colors
    // ══════════════════════════════════════════════════════════════════════════

    readonly property color primary: lightMode ? "#556170" : "#cfd5e7"
    readonly property color primaryBack: lightMode ? "#2f6ff1" : "#2f6ff1"

    readonly property color secondry: lightMode ? "#2f6ff1" : "#6b98d5"
    readonly property color secondryBack: lightMode ? "#e6efff" : "#1a2b42"

    readonly property color success: lightMode ? "#10b66f" : brandGreen
    readonly property color successBack: lightMode ? "#ddfff0" : "#182e28"

    readonly property color warning: lightMode ? "#e38a12" : "#ffb84d"
    readonly property color warningBack: lightMode ? "#fff2d9" : "#342817"

    readonly property color error: lightMode ? "#d6455d" : "#ff3158"
    readonly property color errorBack: lightMode ? "#ffe5ea" : "#351923"

    // Shadows
    readonly property color lightShadow: lightMode ? "#20000000" : "#20ffffff"
    readonly property color darkShadow: lightMode ? "#22334455" : "#cc000000"

    readonly property bool shadow: true

    // ══════════════════════════════════════════════════════════════════════════
    // VPN app semantic tokens
    // Based on screenshot: black/navy device UI, glass cards, green action.
    // ══════════════════════════════════════════════════════════════════════════

    readonly property color vpnWindow: lightMode ? "#eef3f8" : cosmicBg
    readonly property color vpnStarColor: lightMode ? "#b7c5d8" : "#5d6074"

    readonly property color vpnPhoneFrame: lightMode ? "#dce5f0" : "#2c3042"
    readonly property color vpnPhoneBezel: lightMode ? "#ffffff" : "#07080d"
    readonly property color vpnPhoneScreen: lightMode ? "#f8fbff" : "#0d0e17"

    readonly property color vpnSurface0: lightMode ? "#ffffff" : "#070d1f"
    readonly property color vpnSurface1: lightMode ? "#f3f6fb" : "#0f1830"
    readonly property color vpnSurface2: lightMode ? "#eef3f9" : "#141f3a"
    readonly property color vpnSurface3: lightMode ? "#e8eef7" : "#1b2a46"

    readonly property color vpnGlass0: lightMode ? "#ccffffff" : "#99121830"
    readonly property color vpnGlass1: lightMode ? "#eaffffff" : "#b3162340"
    readonly property color vpnGlass2: lightMode ? "#f4ffffff" : "#cc1c2d50"

    readonly property color vpnCard: lightMode ? "#ffffff" : "#111c32"
    readonly property color vpnCardSoft: lightMode ? "#f4f8fc" : "#14213a"
    readonly property color vpnCardRaised: lightMode ? "#ffffff" : "#1a2a47"
    readonly property color vpnCardPressed: lightMode ? "#e9eff7" : "#223657"

    readonly property color vpnBorder: lightMode ? "#d8e2ee" : "#274062"
    readonly property color vpnBorderSoft: lightMode ? "#e8eef6" : "#1b3658"
    readonly property color vpnBorderStrong: lightMode ? "#b9cadf" : "#3d5f86"
    readonly property color vpnBorderAccent: lightMode ? "#7fb0ff" : "#6ba0ff"

    readonly property color vpnTextPrimary: lightMode ? "#101621" : "#f5f6ff"
    readonly property color vpnTextSecondary: lightMode ? "#566276" : "#c6cadb"
    readonly property color vpnTextMuted: lightMode ? "#8995a8" : "#90a6c2"
    readonly property color vpnTextSubtle: lightMode ? "#a4adbc" : "#6f7f95"

    readonly property color vpnGreen: brandGreen
    readonly property color vpnGreenSoft: brandGreenSoft
    readonly property color vpnGreenDark: brandGreenDeep
    readonly property color vpnGreenBack: lightMode ? "#e8faef" : "#2034c37b"

    readonly property color vpnDanger: lightMode ? "#e23d58" : "#ff3158"
    readonly property color vpnDangerBack: lightMode ? "#ffe7ec" : "#33ff3158"

    readonly property color vpnSearchBg: lightMode ? "#f4f7fb" : "#111a30"
    readonly property color vpnSearchBorder: lightMode ? "#d9e3f0" : "#2b4462"
    readonly property color vpnSearchText: lightMode ? "#263244" : "#e6e9f7"
    readonly property color vpnSearchPlaceholder: lightMode ? "#8b96a8" : "#9a9eb3"

    readonly property color vpnCountryRow: lightMode ? "#ffffff" : "#111a30"
    readonly property color vpnCountryRowHover: lightMode ? "#f1f6ff" : "#162544"
    readonly property color vpnCountryRowSelected: lightMode ? "#ebf3ff" : "#1a2a46"
    readonly property color vpnCountryRowBorder: lightMode ? "#e8edf4" : "#213655"

    readonly property color vpnMapLine: lightMode ? "#7488a0" : "#c2c5d1"
    readonly property color vpnMapLineSoft: lightMode ? "#aab8c9" : "#6d7083"
    readonly property color vpnMapDot: "#36d984"
    readonly property color vpnMapGlow: "#5536d984"

    readonly property color vpnGraphLine: "#3db4ff"
    readonly property color vpnGraphLineMuted: lightMode ? "#7c8798" : "#b9bdcc"
    readonly property color vpnGraphFill: lightMode ? "#303f7cf3" : "#203f7cf3"

    readonly property color vpnPrimaryButtonBg: lightMode ? "#2f74ff" : brandBlue
    readonly property color vpnPrimaryButtonText: "#ffffff"
    readonly property color vpnPrimaryButtonPressed: lightMode ? "#2b6dcf" : "#376de0"

    readonly property color vpnSecondaryButtonBg: lightMode ? "#ffffff" : "#111c32"
    readonly property color vpnSecondaryButtonText: lightMode ? "#1a2230" : "#f4f6ff"
    readonly property color vpnSecondaryButtonBorder: lightMode ? "#d8e2ee" : "#2b4462"

    readonly property color vpnPowerButtonBg: lightMode ? "#ffedf1" : "#ff3158"
    readonly property color vpnPowerButtonText: lightMode ? "#d92f49" : "#ffffff"

    readonly property color vpnIconButtonBg: lightMode ? "#ffffff" : "#121d36"
    readonly property color vpnIconButtonBorder: lightMode ? "#d8e2ee" : "#2b4462"
    readonly property color vpnIconButtonIcon: lightMode ? "#667487" : "#d9ddef"

    readonly property color vpnPillBg: lightMode ? "#f4f7fb" : "#121d36"
    readonly property color vpnPillBorder: lightMode ? "#d9e3f0" : "#2b4462"
    readonly property color vpnPillText: lightMode ? "#425066" : "#c8ccdc"

    // ══════════════════════════════════════════════════════════════════════════
    // GenyConnect semantic tokens
    // Kept for compatibility, remapped to screenshot-inspired palette.
    // ══════════════════════════════════════════════════════════════════════════

    readonly property color gcWindow: vpnWindow
    readonly property color gcSurface0: vpnSurface0
    readonly property color gcSurface1: vpnSurface1
    readonly property color gcSurface2: vpnSurface2
    readonly property color gcSurfacePanel: vpnCardRaised
    readonly property color gcPanelSoft: vpnCardSoft
    readonly property color gcPanelTint: lightMode ? "#eaf6ff" : "#1b2f4c"

    readonly property color gcBorder0: vpnBorder
    readonly property color gcBorder1: vpnBorderSoft
    readonly property color gcBorder2: vpnBorderSoft
    readonly property color gcBorder3: vpnBorderSoft
    readonly property color gcBorder4: vpnBorder
    readonly property color gcBorder5: vpnBorderStrong

    readonly property color gcTextStrong: vpnTextPrimary
    readonly property color gcTextPrimary: vpnTextPrimary
    readonly property color gcTextBody: vpnTextSecondary
    readonly property color gcTextMuted: vpnTextMuted
    readonly property color gcTextMutedAlt: vpnTextMuted
    readonly property color gcTextSubtle: vpnTextSubtle
    readonly property color gcTextSubtleAlt: vpnTextSubtle
    readonly property color gcTextMeta: vpnTextMuted

    readonly property color gcAccent: accent
    readonly property color gcAccentText: lightMode ? "#ffffff" : "#c3d8ff"
    readonly property color gcDanger: vpnDanger

    readonly property color gcControlBg: vpnPillBg
    readonly property color gcControlBorder: vpnPillBorder
    readonly property color gcControlText: vpnTextPrimary
    readonly property color gcControlMuted: vpnTextMuted

    readonly property color gcPopupBg: vpnCard
    readonly property color gcPopupBorder: vpnBorder
    readonly property color gcPopupHover: vpnCountryRowHover

    readonly property color gcIconButtonBg: vpnIconButtonBg
    readonly property color gcIconButtonBorder: vpnIconButtonBorder
    readonly property color gcIconButtonIcon: vpnIconButtonIcon
    readonly property color mainHex_050505: "#050505"
    readonly property color mainHex_070707: "#070707"
    readonly property color mainHex_090909: "#090909"
    readonly property color mainHex_090b14: "#090b14"
    readonly property color mainHex_0b121d: "#0b121d"
    readonly property color mainHex_0f1622: "#0f1622"
    readonly property color mainHex_101927: "#101927"
    readonly property color mainHex_102b1f: "#102b1f"
    readonly property color mainHex_111111: "#111111"
    readonly property color mainHex_111425: "#111425"
    readonly property color mainHex_11c5ff: "#11c5ff"
    readonly property color mainHex_121d2e: "#121d2e"
    readonly property color mainHex_131f2d: "#131f2d"
    readonly property color mainHex_142032: "#142032"
    readonly property color mainHex_151c32: "#151c32"
    readonly property color mainHex_15803d: "#15803d"
    readonly property color mainHex_15803d26: "#15803d26"
    readonly property color mainHex_16365c: "#16365c"
    readonly property color mainHex_16a34a: "#16a34a"
    readonly property color mainHex_171a2b: "#171a2b"
    readonly property color mainHex_17284a: "#17284a"
    readonly property color mainHex_173126: "#173126"
    readonly property color mainHex_173323: "#173323"
    readonly property color mainHex_173c2f: "#173c2f"
    readonly property color mainHex_173f75: "#173f75"
    readonly property color mainHex_182230: "#182230"
    readonly property color mainHex_1a2b42: "#1a2b42"
    readonly property color mainHex_1b1b1f: "#1b1b1f"
    readonly property color mainHex_1b2f4c: "#1b2f4c"
    readonly property color mainHex_1ea768: "#1ea768"
    readonly property color mainHex_1f2430: "#1f2430"
    readonly property color mainHex_1f2530: "#1f2530"
    readonly property color mainHex_1f2937: "#1f2937"
    readonly property color mainHex_1f2a37: "#1f2a37"
    readonly property color mainHex_1f2a3a: "#1f2a3a"
    readonly property color mainHex_1f2b3d: "#1f2b3d"
    readonly property color mainHex_1f5ed8: "#1f5ed8"
    readonly property color mainHex_1f7a51: "#1f7a51"
    readonly property color mainHex_202634: "#202634"
    readonly property color mainHex_20314b: "#20314b"
    readonly property color mainHex_213655: "#213655"
    readonly property color mainHex_221c36: "#202634"
    readonly property color mainHex_223147: "#223147"
    readonly property color mainHex_223149: "#223149"
    readonly property color mainHex_22324a: "#22324a"
    readonly property color mainHex_223753: "#223753"
    readonly property color mainHex_22456f: "#22456f"
    readonly property color mainHex_22a557: "#278c59"
    readonly property color mainHex_22b26a: "#2ea768"
    readonly property color mainHex_22c55e: "#34c37b"
    readonly property color mainHex_241f3d: "#241f3d"
    readonly property color mainHex_244f86: "#244f86"
    readonly property color mainHex_263858: "#263858"
    readonly property color mainHex_263a58: "#263a58"
    readonly property color mainHex_273c58: "#273c58"
    readonly property color mainHex_274062: "#274062"
    readonly property color mainHex_275641: "#275641"
    readonly property color mainHex_278c59: "#278c59"
    readonly property color mainHex_2874f0: "#2874f0"
    readonly property color mainHex_2a2450: "#2a2450"
    readonly property color mainHex_2a2834: "#2a2834"
    readonly property color mainHex_2a3140: "#2a3140"
    readonly property color mainHex_2a3240: "#2a3240"
    readonly property color mainHex_2a3950: "#2a3950"
    readonly property color mainHex_2a3f5b: "#2a3f5b"
    readonly property color mainHex_2b3648: "#2b3648"
    readonly property color mainHex_2b6dcf: "#2b6dcf"
    readonly property color mainHex_2c5eaf: "#2c5eaf"
    readonly property color mainHex_2c8b57: "#2c8b57"
    readonly property color mainHex_2d65d8: "#2d65d8"
    readonly property color mainHex_2e3d52: "#2e3d52"
    readonly property color mainHex_2e7b58: "#2e7b58"
    readonly property color mainHex_2f3d53: "#2f3d53"
    readonly property color mainHex_2f425d: "#2f425d"
    readonly property color mainHex_2f6de2: "#2f6de2"
    readonly property color mainHex_2f6ff1: "#2f6ff1"
    readonly property color mainHex_2f74ff: "#2f74ff"
    readonly property color mainHex_30435d: "#30435d"
    readonly property color mainHex_3147d0: "#3147d0"
    readonly property color mainHex_314f73: "#314f73"
    readonly property color mainHex_334155: "#334155"
    readonly property color mainHex_334b67: "#334b67"
    readonly property color mainHex_335178: "#335178"
    readonly property color mainHex_344053: "#344053"
    readonly property color mainHex_34c37b: "#34c37b"
    readonly property color mainHex_355173: "#355173"
    readonly property color mainHex_364b66: "#364b66"
    readonly property color mainHex_36d984: "#55d793"
    readonly property color mainHex_376de0: "#376de0"
    readonly property color mainHex_376e52: "#376e52"
    readonly property color mainHex_3862a9: "#3862a9"
    readonly property color mainHex_395170: "#395170"
    readonly property color mainHex_39526f: "#39526f"
    readonly property color mainHex_3a3215: "#3a3215"
    readonly property color mainHex_3a4f69: "#3a4f69"
    readonly property color mainHex_3a5470: "#3a5470"
    readonly property color mainHex_3a7bff: "#3a7bff"
    readonly property color mainHex_3b2631: "#3b2631"
    readonly property color mainHex_3b311d: "#3b311d"
    readonly property color mainHex_3b4a61: "#3b4a61"
    readonly property color mainHex_3b4e67: "#3b4e67"
    readonly property color mainHex_3d5876: "#3d5876"
    readonly property color mainHex_3d7ae6: "#3d7ae6"
    readonly property color mainHex_3db4ff: "#3db4ff"
    readonly property color mainHex_3e6fff: "#3e6fff"
    readonly property color mainHex_3f4d63: "#3f4d63"
    readonly property color mainHex_3f587a: "#3f587a"
    readonly property color mainHex_3f5e93: "#3f5e93"
    readonly property color mainHex_3f7cf3: "#3f7cf3"
    readonly property color mainHex_3f8569: "#3f8569"
    readonly property color mainHex_40618f: "#40618f"
    readonly property color mainHex_41536c: "#41536c"
    readonly property color mainHex_425874: "#425874"
    readonly property color mainHex_43556f: "#43556f"
    readonly property color mainHex_463472: "#463472"
    readonly property color mainHex_47638c: "#47638c"
    readonly property color mainHex_4770af: "#4770af"
    readonly property color mainHex_495971: "#495971"
    readonly property color mainHex_496384: "#496384"
    readonly property color mainHex_496688: "#496688"
    readonly property color mainHex_4b3d73: "#4b3d73"
    readonly property color mainHex_4b5d75: "#4b5d75"
    readonly property color mainHex_4b5d78: "#4b5d78"
    readonly property color mainHex_4c6990: "#4c6990"
    readonly property color mainHex_4d1f324a: "#4d1f324a"
    readonly property color mainHex_4d20334d: "#4d20334d"
    readonly property color mainHex_4d313b: "#4d313b"
    readonly property color mainHex_4d6691: "#4d6691"
    readonly property color mainHex_4d6a8d: "#4d6a8d"
    readonly property color mainHex_4e6a8b: "#4e6a8b"
    readonly property color mainHex_4f627f: "#4f627f"
    readonly property color mainHex_4f6b8b: "#4f6b8b"
    readonly property color mainHex_4f6f95: "#4f6f95"
    readonly property color mainHex_4f86e6: "#4f86e6"
    readonly property color mainHex_55182538: "#55182538"
    readonly property color mainHex_557299: "#557299"
    readonly property color mainHex_55c982: "#55c982"
    readonly property color mainHex_55d793: "#55d793"
    readonly property color mainHex_55f2f2f2: "#55f2f2f2"
    readonly property color mainHex_578dcf: "#578dcf"
    readonly property color mainHex_586780: "#586780"
    readonly property color mainHex_5a2b4462: "#5a2b4462"
    readonly property color mainHex_5a2d4462: "#5a2d4462"
    readonly property color mainHex_5adf97: "#5adf97"
    readonly property color mainHex_5b3f22: "#5b3f22"
    readonly property color mainHex_5b5d66: "#5b5d66"
    readonly property color mainHex_5d6d84: "#5d6d84"
    readonly property color mainHex_5d7ea3: "#5d7ea3"
    readonly property color mainHex_5e6f89: "#5e6f89"
    readonly property color mainHex_5edc86: "#72efbf"
    readonly property color mainHex_5f233851: "#5f233851"
    readonly property color mainHex_5f3b46: "#5f3b46"
    readonly property color mainHex_5f6f86: "#5f6f86"
    readonly property color mainHex_5f6f88: "#5f6f88"
    readonly property color mainHex_5f7290: "#5f7290"
    readonly property color mainHex_5f87c2: "#5f87c2"
    readonly property color mainHex_5f9478: "#5f9478"
    readonly property color mainHex_5f95f2: "#5f95f2"
    readonly property color mainHex_64748b: "#64748b"
    readonly property color mainHex_64748b20: "#64748b20"
    readonly property color mainHex_647891: "#647891"
    readonly property color mainHex_659bdf: "#659bdf"
    readonly property color mainHex_66263c56: "#66263c56"
    readonly property color mainHex_6646a77c: "#6646a77c"
    readonly property color mainHex_66557a9f: "#66557a9f"
    readonly property color mainHex_666f5b2e: "#666f5b2e"
    readonly property color mainHex_667081: "#667081"
    readonly property color mainHex_667385: "#667385"
    readonly property color mainHex_667487: "#667487"
    readonly property color mainHex_6682ad: "#6682ad"
    readonly property color mainHex_677385: "#677385"
    readonly property color mainHex_6a355172: "#6a355172"
    readonly property color mainHex_6a3f4f: "#6a3f4f"
    readonly property color mainHex_6a778b: "#6a778b"
    readonly property color mainHex_6a7890: "#6a7890"
    readonly property color mainHex_6b35ff: "#6b35ff"
    readonly property color mainHex_6b778a: "#6b778a"
    readonly property color mainHex_6b7b92: "#6b7b92"
    readonly property color mainHex_6b98d5: "#6b98d5"
    readonly property color mainHex_6ba0ff: "#5f95f2"
    readonly property color mainHex_6da2ff: "#6da2ff"
    readonly property color mainHex_6f5cff: "#6f5cff"
    readonly property color mainHex_6f7f95: "#6f7f95"
    readonly property color mainHex_6f7f96: "#6f7f96"
    readonly property color mainHex_7385a0: "#7385a0"
    readonly property color mainHex_7568d5: "#7568d5"
    readonly property color mainHex_7a2b4461: "#7a2b4461"
    readonly property color mainHex_7b8798: "#7b8798"
    readonly property color mainHex_7b8799: "#7b8799"
    readonly property color mainHex_7b889d: "#7b889d"
    readonly property color mainHex_7c8697: "#7c8697"
    readonly property color mainHex_7c8ba1: "#7c8ba1"
    readonly property color mainHex_7c8ca5: "#7c8ca5"
    readonly property color mainHex_7d5062: "#7d5062"
    readonly property color mainHex_7d8ea7: "#7d8ea7"
    readonly property color mainHex_7e6633: "#7e6633"
    readonly property color mainHex_7eb1ff: "#7eb1ff"
    readonly property color mainHex_7f8897: "#7f8897"
    readonly property color mainHex_7fb0ff: "#6da2ff"
    readonly property color mainHex_82e3bb: "#82e3bb"
    readonly property color mainHex_84b2ff: "#7eb1ff"
    readonly property color mainHex_866333: "#866333"
    readonly property color mainHex_86b6ff: "#86b6ff"
    readonly property color mainHex_8993a4: "#8993a4"
    readonly property color mainHex_89a8c8: "#89a8c8"
    readonly property color mainHex_8a18283d: "#8a18283d"
    readonly property color mainHex_8a35527a: "#8a35527a"
    readonly property color mainHex_8a95a8: "#8a95a8"
    readonly property color mainHex_8ab2ff: "#8ab2ff"
    readonly property color mainHex_8ab6ff: "#8ab6ff"
    readonly property color mainHex_8b95a5: "#8b95a5"
    readonly property color mainHex_8bb7ff: "#8bb7ff"
    readonly property color mainHex_8bb8ff: "#8bb8ff"
    readonly property color mainHex_8c8f98: "#8c8f98"
    readonly property color mainHex_8c95a4: "#8c95a4"
    readonly property color mainHex_8d96a5: "#8d96a5"
    readonly property color mainHex_8da0ba: "#8da0ba"
    readonly property color mainHex_8e98aa: "#8e98aa"
    readonly property color mainHex_8ea0b8: "#8ea0b8"
    readonly property color mainHex_8ea1ba: "#8ea1ba"
    readonly property color mainHex_8f97a6: "#8f97a6"
    readonly property color mainHex_8f9bad: "#8f9bad"
    readonly property color mainHex_90a0b5: "#90a0b5"
    readonly property color mainHex_90a6c2: "#90a6c2"
    readonly property color mainHex_93a2b8: "#93a2b8"
    readonly property color mainHex_94a3b8: "#94a3b8"
    readonly property color mainHex_95a0b3: "#95a0b3"
    readonly property color mainHex_95a3b8: "#95a3b8"
    readonly property color mainHex_97a0b0: "#97a0b0"
    readonly property color mainHex_97acc8: "#97acc8"
    readonly property color mainHex_99abc4: "#99abc4"
    readonly property color mainHex_9aa4b6: "#9aa4b6"
    readonly property color mainHex_9aa5b5: "#9aa5b5"
    readonly property color mainHex_9aa6ba: "#9aa6ba"
    readonly property color mainHex_9aa8bb: "#9aa8bb"
    readonly property color mainHex_9ab0ca: "#9ab0ca"
    readonly property color mainHex_9ab2ce: "#9ab2ce"
    readonly property color mainHex_9bb0cb: "#9bb0cb"
    readonly property color mainHex_9c6b1f: "#9c6b1f"
    readonly property color mainHex_9c7a44: "#9c7a44"
    readonly property color mainHex_9cb0c8: "#9cb0c8"
    readonly property color mainHex_9cb2cf: "#9cb2cf"
    readonly property color mainHex_9db0c9: "#9db0c9"
    readonly property color mainHex_9db0ca: "#9db0ca"
    readonly property color mainHex_9db1ca: "#9db1ca"
    readonly property color mainHex_9db2cc: "#9db2cc"
    readonly property color mainHex_9db9f9: "#9db9f9"
    readonly property color mainHex_9ea6b5: "#9ea6b5"
    readonly property color mainHex_9eb1c9: "#9eb1c9"
    readonly property color mainHex_9eb2cb: "#9eb2cb"
    readonly property color mainHex_9eb3cc: "#9eb3cc"
    readonly property color mainHex_9eb4d0: "#9eb4d0"
    readonly property color mainHex_9ec1ff: "#8bb8ff"
    readonly property color mainHex_9fb4cd: "#9fb4cd"
    readonly property color mainHex_9fc3f2: "#9fc3f2"
    readonly property color mainHex_9fceb7: "#9fceb7"
    readonly property color mainHex_a0a8b5: "#a0a8b5"
    readonly property color mainHex_a0acbe: "#a0acbe"
    readonly property color mainHex_a2b5ce: "#a2b5ce"
    readonly property color mainHex_a4b6cd: "#a4b6cd"
    readonly property color mainHex_a88dff: "#a88dff"
    readonly property color mainHex_a8b2c0: "#a8b2c0"
    readonly property color mainHex_a9c1de: "#a9c1de"
    readonly property color mainHex_aeb6c7: "#aeb6c7"
    readonly property color mainHex_b0c3db: "#b0c3db"
    readonly property color mainHex_b6c8df: "#b6c8df"
    readonly property color mainHex_b7cae2: "#b7cae2"
    readonly property color mainHex_b7caee: "#b7caee"
    readonly property color mainHex_b7e4cb: "#b7e4cb"
    readonly property color mainHex_b8acff: "#b8acff"
    readonly property color mainHex_b8c9de: "#b8c9de"
    readonly property color mainHex_b8d0ff: "#b8d0ff"
    readonly property color mainHex_b9ccee: "#b9ccee"
    readonly property color mainHex_b9e3c8: "#b9e3c8"
    readonly property color mainHex_bdeacb: "#bdeacb"
    readonly property color mainHex_be123c: "#be123c"
    readonly property color mainHex_be123c24: "#be123c24"
    readonly property color mainHex_bee9d3: "#bee9d3"
    readonly property color mainHex_bf3f50: "#bf3f50"
    readonly property color mainHex_bf4d4d: "#bf4d4d"
    readonly property color mainHex_bfe6cc: "#bfe6cc"
    readonly property color mainHex_c3d8ff: "#c3d8ff"
    readonly property color mainHex_c44a4a: "#c44a4a"
    readonly property color mainHex_c65050: "#c65050"
    readonly property color mainHex_c7d4e6: "#c7d4e6"
    readonly property color mainHex_c7dbf8: "#c7dbf8"
    readonly property color mainHex_c8d3e2: "#c8d3e2"
    readonly property color mainHex_c8d9ed: "#c8d9ed"
    readonly property color mainHex_c8d9f7: "#c8d9f7"
    readonly property color mainHex_c8ead8: "#c8ead8"
    readonly property color mainHex_ca3b3b: "#ca3b3b"
    readonly property color mainHex_cadcf3: "#cadcf3"
    readonly property color mainHex_cb4f4f: "#cb4f4f"
    readonly property color mainHex_cbd9ec: "#cbd9ec"
    readonly property color mainHex_ccefdc: "#ccefdc"
    readonly property color mainHex_cfd5e3: "#cfd5e3"
    readonly property color mainHex_d0ad19: "#d0ad19"
    readonly property color mainHex_d0ddf0: "#d0ddf0"
    readonly property color mainHex_d14545: "#d14545"
    readonly property color mainHex_d18b22: "#d18b22"
    readonly property color mainHex_d1e0f2: "#d1e0f2"
    readonly property color mainHex_d2def0: "#d2def0"
    readonly property color mainHex_d2def4: "#d2def4"
    readonly property color mainHex_d2e1f6: "#d2e1f6"
    readonly property color mainHex_d35b5b: "#d35b5b"
    readonly property color mainHex_d3a722: "#d3a722"
    readonly property color mainHex_d4d9e3: "#d4d9e3"
    readonly property color mainHex_d4dfef: "#d4dfef"
    readonly property color mainHex_d4e1f8: "#d4e1f8"
    readonly property color mainHex_d5deeb: "#d5deeb"
    readonly property color mainHex_d5deec: "#d5deec"
    readonly property color mainHex_d5dfed: "#d5dfed"
    readonly property color mainHex_d5e3f8: "#d5e3f8"
    readonly property color mainHex_d6dde8: "#d6dde8"
    readonly property color mainHex_d6dfec: "#d6dfec"
    readonly property color mainHex_d7deea: "#d7deea"
    readonly property color mainHex_d7dfec: "#d7dfec"
    readonly property color mainHex_d7e2f0: "#d7e2f0"
    readonly property color mainHex_d7e4f5: "#d7e4f5"
    readonly property color mainHex_d7e4f6: "#d7e4f6"
    readonly property color mainHex_d7e4fb: "#d7e4fb"
    readonly property color mainHex_d7e9ff: "#d7e9ff"
    readonly property color mainHex_d8dde8: "#d8dde8"
    readonly property color mainHex_d8e1ef: "#d8e1ef"
    readonly property color mainHex_d8e1f0: "#d8e1f0"
    readonly property color mainHex_d8e2f0: "#d8e2f0"
    readonly property color mainHex_d8e4f8: "#d8e4f8"
    readonly property color mainHex_d8efdf: "#d8efdf"
    readonly property color mainHex_d97706: "#d97706"
    readonly property color mainHex_d9770626: "#d9770626"
    readonly property color mainHex_d9d0ff: "#d9d0ff"
    readonly property color mainHex_d9dee8: "#d9dee8"
    readonly property color mainHex_d9e0ec: "#d9e0ec"
    readonly property color mainHex_d9e0ed: "#d9e0ed"
    readonly property color mainHex_d9e1ef: "#d9e1ef"
    readonly property color mainHex_d9e6fb: "#d9e6fb"
    readonly property color mainHex_d9edff: "#d9edff"
    readonly property color mainHex_dbe2ee: "#dbe2ee"
    readonly property color mainHex_dbe3ef: "#dbe3ef"
    readonly property color mainHex_dbe8ff: "#dbe8ff"
    readonly property color mainHex_dce4f2: "#dce4f2"
    readonly property color mainHex_dce7f8: "#dce7f8"
    readonly property color mainHex_dde4ef: "#dde4ef"
    readonly property color mainHex_dde5ef: "#dde5ef"
    readonly property color mainHex_dee3ec: "#dee3ec"
    readonly property color mainHex_dee6f3: "#dee6f3"
    readonly property color mainHex_dfbf22: "#dfbf22"
    readonly property color mainHex_dfc33f: "#dfc33f"
    readonly property color mainHex_dfe6f1: "#dfe6f1"
    readonly property color mainHex_dfe7f2: "#dfe7f2"
    readonly property color mainHex_e0e6f0: "#e0e6f0"
    readonly property color mainHex_e1e5ed: "#e1e5ed"
    readonly property color mainHex_e1e6ee: "#e1e6ee"
    readonly property color mainHex_e1e8f2: "#e1e8f2"
    readonly property color mainHex_e1e9f4: "#e1e9f4"
    readonly property color mainHex_e2ecf9: "#e2ecf9"
    readonly property color mainHex_e3e8f1: "#e3e8f1"
    readonly property color mainHex_e4e8ef: "#e4e8ef"
    readonly property color mainHex_e4eaf4: "#e4eaf4"
    readonly property color mainHex_e5ebf4: "#e5ebf4"
    readonly property color mainHex_e5edf9: "#e5edf9"
    readonly property color mainHex_e6ebf3: "#e6ebf3"
    readonly property color mainHex_e7e9ee: "#e7e9ee"
    readonly property color mainHex_e7edf5: "#e7edf5"
    readonly property color mainHex_e7edf6: "#e7edf5"
    readonly property color mainHex_e7eefb: "#e7eefb"
    readonly property color mainHex_e7faef: "#e7faef"
    readonly property color mainHex_e8edf5: "#e8edf5"
    readonly property color mainHex_e8f7ef: "#e8f7ef"
    readonly property color mainHex_e8f8ee: "#e8f8ee"
    readonly property color mainHex_e8faef: "#e8faef"
    readonly property color mainHex_e9f1ff: "#e9f1ff"
    readonly property color mainHex_e9fff2: "#e9fff2"
    readonly property color mainHex_eaf2ff: "#eaf2ff"
    readonly property color mainHex_ebedf3: "#ebedf3"
    readonly property color mainHex_ecfaf3: "#ecfaf3"
    readonly property color mainHex_ecfff3: "#ecfff3"
    readonly property color mainHex_edf2ff: "#edf2ff"
    readonly property color mainHex_edf3fe: "#edf3fe"
    readonly property color mainHex_edf4ff: "#edf4ff"
    readonly property color mainHex_edf5ff: "#edf5ff"
    readonly property color mainHex_edf7ff: "#edf7ff"
    readonly property color mainHex_eef0f4: "#eef0f4"
    readonly property color mainHex_eef0ff: "#eef0ff"
    readonly property color mainHex_eef2f7: "#eef2f7"
    readonly property color mainHex_eef2f8: "#eef2f8"
    readonly property color mainHex_eef3ff: "#eef3ff"
    readonly property color mainHex_eef4ff: "#eef4ff"
    readonly property color mainHex_eef7ff: "#eef7ff"
    readonly property color mainHex_ef4444: "#ef4444"
    readonly property color mainHex_efeaff: "#efeaff"
    readonly property color mainHex_eff1f6: "#eff1f6"
    readonly property color mainHex_eff4fb: "#eff4fb"
    readonly property color mainHex_eff5ff: "#eff5ff"
    readonly property color mainHex_f0bf6b: "#f0bf6b"
    readonly property color mainHex_f0c86e: "#f0c86e"
    readonly property color mainHex_f0ced1: "#f0ced1"
    readonly property color mainHex_f0d5d5: "#f0d5d5"
    readonly property color mainHex_f0edff: "#f0edff"
    readonly property color mainHex_f0eef8: "#f0eef8"
    readonly property color mainHex_f0f1f5: "#f0f1f5"
    readonly property color mainHex_f0f1ff: "#f0f1ff"
    readonly property color mainHex_f1edff: "#f1edff"
    readonly property color mainHex_f1f3f7: "#f1f3f7"
    readonly property color mainHex_f1f5ff: "#f1f5ff"
    readonly property color mainHex_f2c6c6: "#f2c6c6"
    readonly property color mainHex_f2cdcd: "#f2cdcd"
    readonly property color mainHex_f2f6fd: "#f2f6fd"
    readonly property color mainHex_f2f7ff: "#f2f7ff"
    readonly property color mainHex_f3f6fb: "#f3f6fb"
    readonly property color mainHex_f3f7ff: "#f3f7ff"
    readonly property color mainHex_f3f8ff: "#f3f8ff"
    readonly property color mainHex_f43f5e: "#f43f5e"
    readonly property color mainHex_f4b7bd: "#f4b7bd"
    readonly property color mainHex_f4c56a: "#f4c56a"
    readonly property color mainHex_f4d9b1: "#f4d9b1"
    readonly property color mainHex_f4f8ff: "#f4f8ff"
    readonly property color mainHex_f59e0b: "#f59e0b"
    readonly property color mainHex_f5d08a: "#f5d08a"
    readonly property color mainHex_f5f7fb: "#f5f7fb"
    readonly property color mainHex_f5f8fc: "#f5f8fc"
    readonly property color mainHex_f7ddaa: "#f7ddaa"
    readonly property color mainHex_f7f8fb: "#f7f8fb"
    readonly property color mainHex_f7f9fc: "#f7f9fc"
    readonly property color mainHex_f7f9fd: "#f7f9fd"
    readonly property color mainHex_f8fbff: "#f8fbff"
    readonly property color mainHex_f9d9a8: "#f9d9a8"
    readonly property color mainHex_f9fbff: "#f9fbff"
    readonly property color mainHex_faf9ff: "#faf9ff"
    readonly property color mainHex_fbbf24: "#fbbf24"
    readonly property color mainHex_fbfcff: "#fbfcff"
    readonly property color mainHex_fbfffc: "#fbfffc"
    readonly property color mainHex_feeceb: "#feeceb"
    readonly property color mainHex_ff7d92: "#ff7d92"
    readonly property color mainHex_ff8da0: "#ff8da0"
    readonly property color mainHex_ff8e8e: "#ff8e8e"
    readonly property color mainHex_ffb454: "#ffb454"
    readonly property color mainHex_ffd0d0: "#ffd0d0"
    readonly property color mainHex_fff0f0: "#fff0f0"
    readonly property color mainHex_fff4dc: "#fff4dc"
    readonly property color mainHex_fff5d8: "#fff5d8"
    readonly property color mainHex_fff5e8: "#fff5e8"
    readonly property color mainHex_fff5e9: "#fff5e9"
    readonly property color mainHex_fff6f6: "#fff6f6"
    readonly property color mainHex_fff7f8: "#fff7f8"
    readonly property color mainHex_fff9db: "#fff9db"
    readonly property color mainHex_fffcf4: "#fffcf4"
    readonly property color mainHex_ffffff: "#ffffff"
}
