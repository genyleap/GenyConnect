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
    // Brand artwork stays stable; UI surfaces and states use the semantic roles below.
    // ══════════════════════════════════════════════════════════════════════════

    readonly property color brandGreen: "#2fe09c"
    readonly property color brandGreenSoft: "#72efbf"
    readonly property color brandGreenDeep: "#19b874"
    readonly property color brandGreenBack: "#1f2fe09c"

    readonly property color brandRed: "#ff3158"
    readonly property color brandYellow: "#ffb84d"
    readonly property color brandBlue: "#3f7cf3"
    readonly property color brandPurple: "#7f72ff"

    readonly property color cosmicBlack: "#0c0e12"
    readonly property color cosmicBg: dsWindow
    readonly property color cosmicBg2: dsSurface
    readonly property color cosmicPanel: dsSurface
    readonly property color cosmicPanel2: dsSurfaceSoft
    readonly property color cosmicPanel3: dsSurfaceElevated
    readonly property color cosmicStroke: dsBorder
    readonly property color cosmicStrokeSoft: dsBorderSoft

    // ══════════════════════════════════════════════════════════════════════════
    // Accent and page colors
    // ══════════════════════════════════════════════════════════════════════════

    readonly property color accent: lightMode ? "#2f74ff" : dsPrimarySolid
    readonly property color accentSoft: lightMode ? "#5f95f2" : dsLinkIconBlue
    readonly property color accentPressed: lightMode ? "#2b6dcf" : dsPrimaryPressed
    readonly property color accentBack: lightMode ? "#203f7cf3" : "#263775d8"

    readonly property color pageground: lightMode ? "#eef3f8" : dsWindow
    readonly property color pagespaceActivated: lightMode ? "#ffffff" : dsSurface
    readonly property color pagespacePressed: lightMode ? "#e9eef6" : dsSurfaceElevated
    readonly property color pagespaceHovered: lightMode ? "#f5f8fc" : dsSurfaceSoft

    // ══════════════════════════════════════════════════════════════════════════
    // Text colors
    // ══════════════════════════════════════════════════════════════════════════

    readonly property color textPrimary: lightMode ? "#151a24" : dsText
    readonly property color textSecondary: lightMode ? "#4f5d70" : dsTextMuted
    readonly property color textMuted: lightMode ? "#7c8798" : dsTextSubtle
    readonly property color textSubtle: lightMode ? "#9aa4b4" : dsTextSubtle

    readonly property color textAccent: lightMode ? "#2f6ff1" : dsLinkIconBlue
    readonly property color textSuccess: lightMode ? "#10b66f" : dsSuccess
    readonly property color textWarning: lightMode ? "#d98510" : dsWarning
    readonly property color textError: lightMode ? "#d6455d" : dsDanger

    // Static colors
    readonly property color staticPrimary: "#ffffff"
    readonly property color staticSecondry: "#000000"

    // ══════════════════════════════════════════════════════════════════════════
    // Backgrounds
    // ══════════════════════════════════════════════════════════════════════════

    readonly property color background: lightMode ? "#f2f5fa" : dsWindow
    readonly property color backgroundActivated: lightMode ? "#ffffff" : dsSurface
    readonly property color backgroundDeactivated: lightMode ? "#e4e9f1" : dsSurfaceSoft
    readonly property color backgroundHovered: lightMode ? "#f6f8fc" : dsSurfaceSoft
    readonly property color backgroundFocused: lightMode ? "#ffffff" : dsSurfaceElevated

    // Background items
    readonly property color backgroundItemActivated: lightMode ? "#ffffff" : dsSurface
    readonly property color backgroundItemDeactivated: lightMode ? "#edf1f7" : dsWindow
    readonly property color backgroundItemHovered: lightMode ? "#eaf3ff" : dsSurfaceSoft
    readonly property color backgroundItemFocused: lightMode ? "#e8f1ff" : dsPrimaryTint

    // Foregrounds
    readonly property color foregroundActivated: lightMode ? "#131722" : dsText
    readonly property color foregroundDeactivated: lightMode ? "#8d97a8" : dsTextSubtle
    readonly property color foregroundHovered: lightMode ? "#344054" : dsText
    readonly property color foregroundFocused: lightMode ? "#111827" : dsText

    // Borders
    readonly property color borderActivated: lightMode ? "#dce3ee" : dsBorder
    readonly property color borderDeactivated: lightMode ? "#e4e9f1" : dsBorderSoft
    readonly property color borderHovered: lightMode ? "#bfd1e8" : dsBorderStrong
    readonly property color borderFocused: lightMode ? "#5f95f2" : dsLinkIconBlue

    // Lines
    readonly property color lineBorderActivated: lightMode ? "#e4e9f1" : dsBorderSoft
    readonly property color lineBorderDeactivated: lightMode ? "#eef2f7" : dsBorderSoft
    readonly property color lineBorderHovered: lightMode ? "#d8e1ee" : dsBorder
    readonly property color lineBorderFocused: lightMode ? "#c7dbf8" : dsBorderStrong

    // Header and footer
    readonly property color header: lightMode ? "#ffffff" : dsSurface
    readonly property color footer: lightMode ? "#ffffff" : dsSurface

    // ══════════════════════════════════════════════════════════════════════════
    // Status colors
    // ══════════════════════════════════════════════════════════════════════════

    readonly property color primary: lightMode ? "#556170" : dsTextMuted
    readonly property color primaryBack: lightMode ? "#2f6ff1" : dsPrimarySolid

    readonly property color secondry: lightMode ? "#2f6ff1" : dsLinkIconBlue
    readonly property color secondryBack: lightMode ? "#e6efff" : dsPrimaryTint

    readonly property color success: lightMode ? "#10b66f" : dsSuccess
    readonly property color successBack: lightMode ? "#ddfff0" : "#223a32"

    readonly property color warning: lightMode ? "#e38a12" : dsWarning
    readonly property color warningBack: lightMode ? "#fff2d9" : "#3d3325"

    readonly property color error: lightMode ? "#d6455d" : dsDanger
    readonly property color errorBack: lightMode ? "#ffe5ea" : "#402b33"

    // Shadows
    readonly property color lightShadow: lightMode ? "#20000000" : "#20ffffff"
    readonly property color darkShadow: lightMode ? "#22334455" : "#cc000000"

    readonly property bool shadow: true

    // ══════════════════════════════════════════════════════════════════════════
    // VPN app semantic tokens
    // Compatibility names share the same dark surface and status roles as controls.
    // ══════════════════════════════════════════════════════════════════════════

    readonly property color vpnWindow: lightMode ? "#eef3f8" : dsWindow
    readonly property color vpnStarColor: lightMode ? "#b7c5d8" : dsTextSubtle

    readonly property color vpnPhoneFrame: lightMode ? "#dce5f0" : dsBorderStrong
    readonly property color vpnPhoneBezel: lightMode ? "#ffffff" : "#0c0e12"
    readonly property color vpnPhoneScreen: lightMode ? "#f8fbff" : dsWindow

    readonly property color vpnSurface0: lightMode ? "#ffffff" : dsWindow
    readonly property color vpnSurface1: lightMode ? "#f3f6fb" : dsSurface
    readonly property color vpnSurface2: lightMode ? "#eef3f9" : dsSurfaceSoft
    readonly property color vpnSurface3: lightMode ? "#e8eef7" : dsSurfaceElevated

    readonly property color vpnGlass0: lightMode ? "#ccffffff" : "#cc191e26"
    readonly property color vpnGlass1: lightMode ? "#eaffffff" : "#e6202731"
    readonly property color vpnGlass2: lightMode ? "#f4ffffff" : "#ed29323e"

    readonly property color vpnCard: lightMode ? "#ffffff" : dsSurface
    readonly property color vpnCardSoft: lightMode ? "#f4f8fc" : dsSurfaceSoft
    readonly property color vpnCardRaised: lightMode ? "#ffffff" : dsSurfaceElevated
    readonly property color vpnCardPressed: lightMode ? "#e9eff7" : dsSurfaceElevated

    readonly property color vpnBorder: lightMode ? "#d8e2ee" : dsBorder
    readonly property color vpnBorderSoft: lightMode ? "#e8eef6" : dsBorderSoft
    readonly property color vpnBorderStrong: lightMode ? "#b9cadf" : dsBorderStrong
    readonly property color vpnBorderAccent: lightMode ? "#7fb0ff" : dsLinkIconBlue

    readonly property color vpnTextPrimary: lightMode ? "#101621" : dsText
    readonly property color vpnTextSecondary: lightMode ? "#566276" : dsTextMuted
    readonly property color vpnTextMuted: lightMode ? "#8995a8" : dsTextSubtle
    readonly property color vpnTextSubtle: lightMode ? "#a4adbc" : dsTextSubtle

    readonly property color vpnGreen: lightMode ? brandGreen : dsSuccess
    readonly property color vpnGreenSoft: lightMode ? brandGreenSoft : dsLinkIconGreen
    readonly property color vpnGreenDark: lightMode ? brandGreenDeep : "#2b986d"
    readonly property color vpnGreenBack: lightMode ? "#e8faef" : "#2249c994"

    readonly property color vpnDanger: lightMode ? "#e23d58" : dsDanger
    readonly property color vpnDangerBack: lightMode ? "#ffe7ec" : "#402b33"

    readonly property color vpnSearchBg: lightMode ? "#f4f7fb" : dsSurface
    readonly property color vpnSearchBorder: lightMode ? "#d9e3f0" : dsBorder
    readonly property color vpnSearchText: lightMode ? "#263244" : dsText
    readonly property color vpnSearchPlaceholder: lightMode ? "#8b96a8" : dsTextSubtle

    readonly property color vpnCountryRow: lightMode ? "#ffffff" : dsSurface
    readonly property color vpnCountryRowHover: lightMode ? "#f1f6ff" : dsSurfaceSoft
    readonly property color vpnCountryRowSelected: lightMode ? "#ebf3ff" : dsPrimaryTint
    readonly property color vpnCountryRowBorder: lightMode ? "#e8edf4" : dsBorderSoft

    readonly property color vpnMapLine: lightMode ? "#7488a0" : dsTextMuted
    readonly property color vpnMapLineSoft: lightMode ? "#aab8c9" : dsTextSubtle
    readonly property color vpnMapDot: "#36d984"
    readonly property color vpnMapGlow: "#5536d984"

    readonly property color vpnGraphLine: "#3db4ff"
    readonly property color vpnGraphLineMuted: lightMode ? "#7c8798" : dsTextSubtle
    readonly property color vpnGraphFill: lightMode ? "#303f7cf3" : "#263775d8"

    readonly property color vpnPrimaryButtonBg: lightMode ? "#2f74ff" : dsPrimarySolid
    readonly property color vpnPrimaryButtonText: "#ffffff"
    readonly property color vpnPrimaryButtonPressed: lightMode ? "#2b6dcf" : dsPrimaryPressed

    readonly property color vpnSecondaryButtonBg: lightMode ? "#ffffff" : dsSurface
    readonly property color vpnSecondaryButtonText: lightMode ? "#1a2230" : dsText
    readonly property color vpnSecondaryButtonBorder: lightMode ? "#d8e2ee" : dsBorder

    readonly property color vpnPowerButtonBg: lightMode ? "#ffedf1" : "#bf405b"
    readonly property color vpnPowerButtonText: lightMode ? "#d92f49" : "#ffffff"

    readonly property color vpnIconButtonBg: lightMode ? "#ffffff" : dsSurfaceSoft
    readonly property color vpnIconButtonBorder: lightMode ? "#d8e2ee" : dsBorder
    readonly property color vpnIconButtonIcon: lightMode ? "#667487" : dsTextMuted

    readonly property color vpnPillBg: lightMode ? "#f4f7fb" : dsSurfaceSoft
    readonly property color vpnPillBorder: lightMode ? "#d9e3f0" : dsBorder
    readonly property color vpnPillText: lightMode ? "#425066" : dsTextMuted

    // ══════════════════════════════════════════════════════════════════════════
    // GenyConnect semantic tokens
    // Kept for compatibility with older pages and controls.
    // ══════════════════════════════════════════════════════════════════════════

    readonly property color gcWindow: vpnWindow
    readonly property color gcSurface0: vpnSurface0
    readonly property color gcSurface1: vpnSurface1
    readonly property color gcSurface2: vpnSurface2
    readonly property color gcSurfacePanel: vpnCardRaised
    readonly property color gcPanelSoft: vpnCardSoft
    readonly property color gcPanelTint: lightMode ? "#eaf6ff" : dsPrimaryTint

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
    readonly property color gcAccentText: lightMode ? "#ffffff" : dsLinkIconBlue
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

    // Shared UI palette: charcoal surfaces, blue interaction, distinct status colors.
    // Surface -> soft -> elevated provides depth without tinting every panel blue.
    readonly property color dsWindow: lightMode ? "#f5f7fc" : "#101318"
    readonly property color dsSurface: lightMode ? "#ffffff" : "#191e26"
    readonly property color dsSurfaceSoft: lightMode ? "#f2f5fb" : "#202731"
    readonly property color dsSurfaceElevated: lightMode ? "#ffffff" : "#29323e"
    readonly property color dsGlass: lightMode ? "#e6edf8ee" : "#e6191e26"
    readonly property color dsBorder: lightMode ? "#d7e2f0" : "#364150"
    readonly property color dsBorderSoft: lightMode ? "#e6edf6" : "#2b3440"
    readonly property color dsBorderStrong: lightMode ? "#bfd1e8" : "#526174"

    readonly property color dsText: lightMode ? "#0f172a" : "#edf1f7"
    readonly property color dsTextMuted: lightMode ? "#5f6f86" : "#b3bece"
    readonly property color dsTextSubtle: lightMode ? "#8392a6" : "#93a1b5"

    readonly property color dsPrimaryStart: lightMode ? "#2f74ff" : "#3775d8"
    readonly property color dsPrimaryEnd: lightMode ? "#7b53ff" : "#586fce"
    readonly property color dsPrimarySolid: lightMode ? "#2f74ff" : "#3775d8"
    readonly property color dsPrimaryPressed: lightMode ? "#2a66d1" : "#2f62bb"
    readonly property color dsPrimaryText: "#ffffff"
    readonly property color dsPrimaryTint: lightMode ? "#eaf2ff" : "#22344e"

    readonly property color dsDanger: lightMode ? "#d6455d" : "#ed8293"
    readonly property color dsSuccess: lightMode ? "#14b873" : "#49c994"
    readonly property color dsWarning: lightMode ? "#de8a1a" : "#e6b566"

    readonly property color dsShadowSoft: lightMode ? "#140f1b2a" : "#3a000000"
    readonly property color dsShadowStrong: lightMode ? "#1f1e2c47" : "#70000000"

    readonly property color dsLinkIconBgPurple: lightMode ? "#ede8ff" : "#302c43"
    readonly property color dsLinkIconPurple: lightMode ? "#7b53ff" : "#bdadf0"
    readonly property color dsLinkIconBgBlue: lightMode ? "#e8f2ff" : dsPrimaryTint
    readonly property color dsLinkIconBlue: lightMode ? "#2f74ff" : "#94baff"
    readonly property color dsLinkIconBgGreen: lightMode ? "#e7f7ed" : "#223a32"
    readonly property color dsLinkIconGreen: lightMode ? "#22a86d" : "#79d5ae"

    // Legacy tokens remain available to themeColorToken; dark UI colors resolve
    // to the shared roles above, while literal artwork colors stay unchanged.
    readonly property color mainHex_34d18a: lightMode ? "#34d18a" : dsSuccess
    readonly property color mainHex_f7b251: lightMode ? "#f7b251" : dsWarning
    readonly property color mainHex_8fa3be: lightMode ? "#8fa3be" : dsTextSubtle

    readonly property color mainHex_050505: "#050505"
    readonly property color mainHex_070707: "#070707"
    readonly property color mainHex_090909: "#090909"
    readonly property color mainHex_090b14: lightMode ? "#090b14" : dsWindow
    readonly property color mainHex_0b121d: lightMode ? "#0b121d" : dsWindow
    readonly property color mainHex_0f1622: lightMode ? "#0f1622" : dsSurface
    readonly property color mainHex_101927: lightMode ? "#101927" : dsSurface
    readonly property color mainHex_102b1f: "#102b1f"
    readonly property color mainHex_111111: "#111111"
    readonly property color mainHex_111425: lightMode ? "#111425" : dsWindow
    readonly property color mainHex_11c5ff: "#11c5ff"
    readonly property color mainHex_121d2e: lightMode ? "#121d2e" : dsSurface
    readonly property color mainHex_131f2d: lightMode ? "#131f2d" : dsSurface
    readonly property color mainHex_142032: lightMode ? "#142032" : dsSurface
    readonly property color mainHex_151c32: lightMode ? "#151c32" : dsSurface
    readonly property color mainHex_15803d: "#15803d"
    readonly property color mainHex_15803d26: "#15803d26"
    readonly property color mainHex_16365c: lightMode ? "#16365c" : dsPrimaryTint
    readonly property color mainHex_16a34a: "#16a34a"
    readonly property color mainHex_171a2b: lightMode ? "#171a2b" : dsSurface
    readonly property color mainHex_17284a: lightMode ? "#17284a" : dsPrimaryTint
    readonly property color mainHex_173126: "#173126"
    readonly property color mainHex_173323: "#173323"
    readonly property color mainHex_173c2f: "#173c2f"
    readonly property color mainHex_173f75: "#173f75"
    readonly property color mainHex_182230: lightMode ? "#182230" : dsSurface
    readonly property color mainHex_1a2b42: lightMode ? "#1a2b42" : dsSurfaceSoft
    readonly property color mainHex_1b1b1f: lightMode ? "#1b1b1f" : dsSurface
    readonly property color mainHex_1b2f4c: lightMode ? "#1b2f4c" : dsSurfaceSoft
    readonly property color mainHex_1ea768: "#1ea768"
    readonly property color mainHex_1f2430: lightMode ? "#1f2430" : dsSurface
    readonly property color mainHex_1f2530: lightMode ? "#1f2530" : dsSurfaceSoft
    readonly property color mainHex_1f2937: lightMode ? "#1f2937" : dsSurfaceSoft
    readonly property color mainHex_1f2a37: lightMode ? "#1f2a37" : dsSurfaceSoft
    readonly property color mainHex_1f2a3a: lightMode ? "#1f2a3a" : dsSurfaceSoft
    readonly property color mainHex_1f2b3d: lightMode ? "#1f2b3d" : dsSurfaceSoft
    readonly property color mainHex_1f5ed8: "#1f5ed8"
    readonly property color mainHex_1f7a51: "#1f7a51"
    readonly property color mainHex_202634: lightMode ? "#202634" : dsSurfaceSoft
    readonly property color mainHex_20314b: lightMode ? "#20314b" : dsSurfaceSoft
    readonly property color mainHex_213655: lightMode ? "#213655" : dsSurfaceSoft
    readonly property color mainHex_221c36: lightMode ? "#202634" : dsSurfaceSoft
    readonly property color mainHex_223147: lightMode ? "#223147" : dsSurfaceSoft
    readonly property color mainHex_223149: lightMode ? "#223149" : dsSurfaceSoft
    readonly property color mainHex_22324a: lightMode ? "#22324a" : dsSurfaceSoft
    readonly property color mainHex_223753: lightMode ? "#223753" : dsPrimaryTint
    readonly property color mainHex_22456f: lightMode ? "#22456f" : dsPrimaryTint
    readonly property color mainHex_22a557: "#278c59"
    readonly property color mainHex_22b26a: "#2ea768"
    readonly property color mainHex_22c55e: "#34c37b"
    readonly property color mainHex_241f3d: "#241f3d"
    readonly property color mainHex_244f86: "#244f86"
    readonly property color mainHex_263858: lightMode ? "#263858" : dsSurfaceElevated
    readonly property color mainHex_263a58: lightMode ? "#263a58" : dsSurfaceElevated
    readonly property color mainHex_273c58: lightMode ? "#273c58" : dsSurfaceElevated
    readonly property color mainHex_274062: lightMode ? "#274062" : dsBorder
    readonly property color mainHex_275641: "#275641"
    readonly property color mainHex_278c59: "#278c59"
    readonly property color mainHex_2874f0: "#2874f0"
    readonly property color mainHex_2a2450: "#2a2450"
    readonly property color mainHex_2a2834: lightMode ? "#2a2834" : dsSurfaceElevated
    readonly property color mainHex_2a3140: lightMode ? "#2a3140" : dsSurfaceElevated
    readonly property color mainHex_2a3240: lightMode ? "#2a3240" : dsSurfaceElevated
    readonly property color mainHex_2a3950: lightMode ? "#2a3950" : dsSurfaceElevated
    readonly property color mainHex_2a3f5b: lightMode ? "#2a3f5b" : dsSurfaceElevated
    readonly property color mainHex_2b3648: lightMode ? "#2b3648" : dsSurfaceElevated
    readonly property color mainHex_2b6dcf: "#2b6dcf"
    readonly property color mainHex_2c5eaf: "#2c5eaf"
    readonly property color mainHex_2c8b57: "#2c8b57"
    readonly property color mainHex_2d65d8: "#2d65d8"
    readonly property color mainHex_2e3d52: lightMode ? "#2e3d52" : dsBorder
    readonly property color mainHex_2e7b58: "#2e7b58"
    readonly property color mainHex_2f3d53: lightMode ? "#2f3d53" : dsBorder
    readonly property color mainHex_2f425d: lightMode ? "#2f425d" : dsBorder
    readonly property color mainHex_2f6de2: "#2f6de2"
    readonly property color mainHex_2f6ff1: "#2f6ff1"
    readonly property color mainHex_2f74ff: "#2f74ff"
    readonly property color mainHex_30435d: lightMode ? "#30435d" : dsBorder
    readonly property color mainHex_3147d0: "#3147d0"
    readonly property color mainHex_314f73: lightMode ? "#314f73" : dsBorder
    readonly property color mainHex_334155: lightMode ? "#334155" : dsBorderSoft
    readonly property color mainHex_334b67: lightMode ? "#334b67" : dsBorderSoft
    readonly property color mainHex_335178: lightMode ? "#335178" : dsBorder
    readonly property color mainHex_344053: lightMode ? "#344053" : dsBorder
    readonly property color mainHex_34c37b: lightMode ? "#34c37b" : dsSuccess
    readonly property color mainHex_355173: lightMode ? "#355173" : dsBorder
    readonly property color mainHex_364b66: lightMode ? "#364b66" : dsBorderSoft
    readonly property color mainHex_36d984: "#55d793"
    readonly property color mainHex_376de0: "#376de0"
    readonly property color mainHex_376e52: "#376e52"
    readonly property color mainHex_3862a9: "#3862a9"
    readonly property color mainHex_395170: lightMode ? "#395170" : dsBorder
    readonly property color mainHex_39526f: lightMode ? "#39526f" : dsBorder
    readonly property color mainHex_3a3215: "#3a3215"
    readonly property color mainHex_3a4f69: lightMode ? "#3a4f69" : dsBorder
    readonly property color mainHex_3a5470: lightMode ? "#3a5470" : dsBorder
    readonly property color mainHex_3a7bff: "#3a7bff"
    readonly property color mainHex_3b2631: "#3b2631"
    readonly property color mainHex_3b311d: "#3b311d"
    readonly property color mainHex_3b4a61: lightMode ? "#3b4a61" : dsBorder
    readonly property color mainHex_3b4e67: lightMode ? "#3b4e67" : dsBorder
    readonly property color mainHex_3d5876: lightMode ? "#3d5876" : dsBorderStrong
    readonly property color mainHex_3d7ae6: "#3d7ae6"
    readonly property color mainHex_3db4ff: "#3db4ff"
    readonly property color mainHex_3e6fff: "#3e6fff"
    readonly property color mainHex_3f4d63: lightMode ? "#3f4d63" : dsBorderStrong
    readonly property color mainHex_3f587a: lightMode ? "#3f587a" : dsBorderStrong
    readonly property color mainHex_3f5e93: "#3f5e93"
    readonly property color mainHex_3f7cf3: "#3f7cf3"
    readonly property color mainHex_3f8569: "#3f8569"
    readonly property color mainHex_40618f: lightMode ? "#40618f" : dsBorderStrong
    readonly property color mainHex_41536c: lightMode ? "#41536c" : dsBorderStrong
    readonly property color mainHex_425874: lightMode ? "#425874" : dsBorderStrong
    readonly property color mainHex_43556f: lightMode ? "#43556f" : dsBorderStrong
    readonly property color mainHex_463472: "#463472"
    readonly property color mainHex_47638c: lightMode ? "#47638c" : dsBorderStrong
    readonly property color mainHex_4770af: "#4770af"
    readonly property color mainHex_495971: lightMode ? "#495971" : dsBorderStrong
    readonly property color mainHex_496384: lightMode ? "#496384" : dsBorderStrong
    readonly property color mainHex_496688: lightMode ? "#496688" : dsBorderStrong
    readonly property color mainHex_4b3d73: "#4b3d73"
    readonly property color mainHex_4b5d75: lightMode ? "#4b5d75" : dsBorderStrong
    readonly property color mainHex_4b5d78: lightMode ? "#4b5d78" : dsBorderStrong
    readonly property color mainHex_4c6990: lightMode ? "#4c6990" : dsBorderStrong
    readonly property color mainHex_4d1f324a: lightMode ? "#4d1f324a" : Qt.rgba(dsSurfaceElevated.r, dsSurfaceElevated.g, dsSurfaceElevated.b, 0.302)
    readonly property color mainHex_4d20334d: lightMode ? "#4d20334d" : Qt.rgba(dsSurfaceElevated.r, dsSurfaceElevated.g, dsSurfaceElevated.b, 0.302)
    readonly property color mainHex_4d313b: "#4d313b"
    readonly property color mainHex_4d6691: lightMode ? "#4d6691" : dsBorderStrong
    readonly property color mainHex_4d6a8d: lightMode ? "#4d6a8d" : dsBorderStrong
    readonly property color mainHex_4e6a8b: lightMode ? "#4e6a8b" : dsBorderStrong
    readonly property color mainHex_4f627f: lightMode ? "#4f627f" : dsBorderStrong
    readonly property color mainHex_4f6b8b: lightMode ? "#4f6b8b" : dsBorderStrong
    readonly property color mainHex_4f6f95: lightMode ? "#4f6f95" : dsBorderStrong
    readonly property color mainHex_4f86e6: "#4f86e6"
    readonly property color mainHex_55182538: lightMode ? "#55182538" : Qt.rgba(dsSurfaceElevated.r, dsSurfaceElevated.g, dsSurfaceElevated.b, 0.3333)
    readonly property color mainHex_557299: "#557299"
    readonly property color mainHex_55c982: "#55c982"
    readonly property color mainHex_55d793: lightMode ? "#55d793" : dsSuccess
    readonly property color mainHex_55f2f2f2: "#55f2f2f2"
    readonly property color mainHex_578dcf: "#578dcf"
    readonly property color mainHex_586780: "#586780"
    readonly property color mainHex_5a2b4462: lightMode ? "#5a2b4462" : Qt.rgba(dsSurfaceElevated.r, dsSurfaceElevated.g, dsSurfaceElevated.b, 0.3529)
    readonly property color mainHex_5a2d4462: lightMode ? "#5a2d4462" : Qt.rgba(dsSurfaceElevated.r, dsSurfaceElevated.g, dsSurfaceElevated.b, 0.3529)
    readonly property color mainHex_5adf97: lightMode ? "#5adf97" : dsSuccess
    readonly property color mainHex_5b3f22: "#5b3f22"
    readonly property color mainHex_5b5d66: "#5b5d66"
    readonly property color mainHex_5d6d84: "#5d6d84"
    readonly property color mainHex_5d7ea3: "#5d7ea3"
    readonly property color mainHex_5e6f89: "#5e6f89"
    readonly property color mainHex_5edc86: "#72efbf"
    readonly property color mainHex_5f233851: lightMode ? "#5f233851" : Qt.rgba(dsSurfaceElevated.r, dsSurfaceElevated.g, dsSurfaceElevated.b, 0.3725)
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
    readonly property color mainHex_66263c56: lightMode ? "#66263c56" : Qt.rgba(dsSurfaceElevated.r, dsSurfaceElevated.g, dsSurfaceElevated.b, 0.4)
    readonly property color mainHex_6646a77c: "#6646a77c"
    readonly property color mainHex_66557a9f: lightMode ? "#66557a9f" : Qt.rgba(dsSurfaceElevated.r, dsSurfaceElevated.g, dsSurfaceElevated.b, 0.4)
    readonly property color mainHex_666f5b2e: "#666f5b2e"
    readonly property color mainHex_667081: "#667081"
    readonly property color mainHex_667385: "#667385"
    readonly property color mainHex_667487: "#667487"
    readonly property color mainHex_6682ad: "#6682ad"
    readonly property color mainHex_677385: "#677385"
    readonly property color mainHex_6a355172: lightMode ? "#6a355172" : Qt.rgba(dsSurfaceElevated.r, dsSurfaceElevated.g, dsSurfaceElevated.b, 0.4157)
    readonly property color mainHex_6a3f4f: "#6a3f4f"
    readonly property color mainHex_6a778b: "#6a778b"
    readonly property color mainHex_6a7890: "#6a7890"
    readonly property color mainHex_6b35ff: "#6b35ff"
    readonly property color mainHex_6b778a: "#6b778a"
    readonly property color mainHex_6b7b92: "#6b7b92"
    readonly property color mainHex_6b98d5: "#6b98d5"
    readonly property color mainHex_6ba0ff: lightMode ? "#5f95f2" : dsLinkIconBlue
    readonly property color mainHex_6da2ff: lightMode ? "#6da2ff" : dsLinkIconBlue
    readonly property color mainHex_6f5cff: "#6f5cff"
    readonly property color mainHex_6f7f95: lightMode ? "#6f7f95" : dsTextSubtle
    readonly property color mainHex_6f7f96: lightMode ? "#6f7f96" : dsTextSubtle
    readonly property color mainHex_7385a0: lightMode ? "#7385a0" : dsTextSubtle
    readonly property color mainHex_7568d5: "#7568d5"
    readonly property color mainHex_7a2b4461: lightMode ? "#7a2b4461" : Qt.rgba(dsSurfaceElevated.r, dsSurfaceElevated.g, dsSurfaceElevated.b, 0.4784)
    readonly property color mainHex_7b8798: lightMode ? "#7b8798" : dsTextSubtle
    readonly property color mainHex_7b8799: lightMode ? "#7b8799" : dsTextSubtle
    readonly property color mainHex_7b889d: lightMode ? "#7b889d" : dsTextSubtle
    readonly property color mainHex_7c8697: lightMode ? "#7c8697" : dsTextSubtle
    readonly property color mainHex_7c8ba1: lightMode ? "#7c8ba1" : dsTextSubtle
    readonly property color mainHex_7c8ca5: lightMode ? "#7c8ca5" : dsTextSubtle
    readonly property color mainHex_7d5062: "#7d5062"
    readonly property color mainHex_7d8ea7: lightMode ? "#7d8ea7" : dsTextSubtle
    readonly property color mainHex_7e6633: "#7e6633"
    readonly property color mainHex_7eb1ff: lightMode ? "#7eb1ff" : dsLinkIconBlue
    readonly property color mainHex_7f8897: lightMode ? "#7f8897" : dsTextSubtle
    readonly property color mainHex_7fb0ff: lightMode ? "#6da2ff" : dsLinkIconBlue
    readonly property color mainHex_82e3bb: "#82e3bb"
    readonly property color mainHex_84b2ff: lightMode ? "#7eb1ff" : dsLinkIconBlue
    readonly property color mainHex_866333: "#866333"
    readonly property color mainHex_86b6ff: lightMode ? "#86b6ff" : dsLinkIconBlue
    readonly property color mainHex_8993a4: lightMode ? "#8993a4" : dsTextSubtle
    readonly property color mainHex_89a8c8: lightMode ? "#89a8c8" : dsTextSubtle
    readonly property color mainHex_8a18283d: lightMode ? "#8a18283d" : Qt.rgba(dsSurfaceElevated.r, dsSurfaceElevated.g, dsSurfaceElevated.b, 0.5412)
    readonly property color mainHex_8a35527a: lightMode ? "#8a35527a" : Qt.rgba(dsSurfaceElevated.r, dsSurfaceElevated.g, dsSurfaceElevated.b, 0.5412)
    readonly property color mainHex_8a95a8: lightMode ? "#8a95a8" : dsTextSubtle
    readonly property color mainHex_8ab2ff: lightMode ? "#8ab2ff" : dsLinkIconBlue
    readonly property color mainHex_8ab6ff: lightMode ? "#8ab6ff" : dsLinkIconBlue
    readonly property color mainHex_8b95a5: lightMode ? "#8b95a5" : dsTextSubtle
    readonly property color mainHex_8bb7ff: lightMode ? "#8bb7ff" : dsLinkIconBlue
    readonly property color mainHex_8bb8ff: lightMode ? "#8bb8ff" : dsLinkIconBlue
    readonly property color mainHex_8c8f98: lightMode ? "#8c8f98" : dsTextSubtle
    readonly property color mainHex_8c95a4: lightMode ? "#8c95a4" : dsTextSubtle
    readonly property color mainHex_8d96a5: lightMode ? "#8d96a5" : dsTextSubtle
    readonly property color mainHex_8da0ba: lightMode ? "#8da0ba" : dsTextSubtle
    readonly property color mainHex_8e98aa: lightMode ? "#8e98aa" : dsTextSubtle
    readonly property color mainHex_8ea0b8: lightMode ? "#8ea0b8" : dsTextSubtle
    readonly property color mainHex_8ea1ba: lightMode ? "#8ea1ba" : dsTextSubtle
    readonly property color mainHex_8f97a6: lightMode ? "#8f97a6" : dsTextSubtle
    readonly property color mainHex_8f9bad: lightMode ? "#8f9bad" : dsTextSubtle
    readonly property color mainHex_90a0b5: lightMode ? "#90a0b5" : dsTextSubtle
    readonly property color mainHex_90a6c2: lightMode ? "#90a6c2" : dsTextSubtle
    readonly property color mainHex_93a2b8: lightMode ? "#93a2b8" : dsTextSubtle
    readonly property color mainHex_94a3b8: lightMode ? "#94a3b8" : dsTextSubtle
    readonly property color mainHex_95a0b3: lightMode ? "#95a0b3" : dsTextSubtle
    readonly property color mainHex_95a3b8: lightMode ? "#95a3b8" : dsTextSubtle
    readonly property color mainHex_97a0b0: lightMode ? "#97a0b0" : dsTextSubtle
    readonly property color mainHex_97acc8: lightMode ? "#97acc8" : dsTextSubtle
    readonly property color mainHex_99abc4: lightMode ? "#99abc4" : dsTextMuted
    readonly property color mainHex_9aa4b6: lightMode ? "#9aa4b6" : dsTextMuted
    readonly property color mainHex_9aa5b5: lightMode ? "#9aa5b5" : dsTextMuted
    readonly property color mainHex_9aa6ba: lightMode ? "#9aa6ba" : dsTextMuted
    readonly property color mainHex_9aa8bb: lightMode ? "#9aa8bb" : dsTextMuted
    readonly property color mainHex_9ab0ca: lightMode ? "#9ab0ca" : dsTextMuted
    readonly property color mainHex_9ab2ce: lightMode ? "#9ab2ce" : dsTextMuted
    readonly property color mainHex_9bb0cb: lightMode ? "#9bb0cb" : dsTextMuted
    readonly property color mainHex_9c6b1f: "#9c6b1f"
    readonly property color mainHex_9c7a44: "#9c7a44"
    readonly property color mainHex_9cb0c8: lightMode ? "#9cb0c8" : dsTextMuted
    readonly property color mainHex_9cb2cf: lightMode ? "#9cb2cf" : dsTextMuted
    readonly property color mainHex_9db0c9: lightMode ? "#9db0c9" : dsTextMuted
    readonly property color mainHex_9db0ca: lightMode ? "#9db0ca" : dsTextMuted
    readonly property color mainHex_9db1ca: lightMode ? "#9db1ca" : dsTextMuted
    readonly property color mainHex_9db2cc: lightMode ? "#9db2cc" : dsTextMuted
    readonly property color mainHex_9db9f9: "#9db9f9"
    readonly property color mainHex_9ea6b5: lightMode ? "#9ea6b5" : dsTextMuted
    readonly property color mainHex_9eb1c9: lightMode ? "#9eb1c9" : dsTextMuted
    readonly property color mainHex_9eb2cb: lightMode ? "#9eb2cb" : dsTextMuted
    readonly property color mainHex_9eb3cc: lightMode ? "#9eb3cc" : dsTextMuted
    readonly property color mainHex_9eb4d0: lightMode ? "#9eb4d0" : dsTextMuted
    readonly property color mainHex_9ec1ff: lightMode ? "#8bb8ff" : dsLinkIconBlue
    readonly property color mainHex_9fb4cd: lightMode ? "#9fb4cd" : dsTextMuted
    readonly property color mainHex_9fc3f2: "#9fc3f2"
    readonly property color mainHex_9fceb7: "#9fceb7"
    readonly property color mainHex_a0a8b5: lightMode ? "#a0a8b5" : dsTextMuted
    readonly property color mainHex_a0acbe: lightMode ? "#a0acbe" : dsTextMuted
    readonly property color mainHex_a2b5ce: lightMode ? "#a2b5ce" : dsTextMuted
    readonly property color mainHex_a4b6cd: lightMode ? "#a4b6cd" : dsTextMuted
    readonly property color mainHex_a88dff: "#a88dff"
    readonly property color mainHex_a8b2c0: lightMode ? "#a8b2c0" : dsTextMuted
    readonly property color mainHex_a9c1de: lightMode ? "#a9c1de" : dsTextMuted
    readonly property color mainHex_aeb6c7: lightMode ? "#aeb6c7" : dsTextMuted
    readonly property color mainHex_b0c3db: lightMode ? "#b0c3db" : dsTextMuted
    readonly property color mainHex_b6c8df: lightMode ? "#b6c8df" : dsTextMuted
    readonly property color mainHex_b7cae2: lightMode ? "#b7cae2" : dsTextMuted
    readonly property color mainHex_b7caee: "#b7caee"
    readonly property color mainHex_b7e4cb: "#b7e4cb"
    readonly property color mainHex_b8acff: "#b8acff"
    readonly property color mainHex_b8c9de: lightMode ? "#b8c9de" : dsTextMuted
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
    readonly property color mainHex_c7d4e6: lightMode ? "#c7d4e6" : dsText
    readonly property color mainHex_c7dbf8: "#c7dbf8"
    readonly property color mainHex_c8d3e2: lightMode ? "#c8d3e2" : dsText
    readonly property color mainHex_c8d9ed: lightMode ? "#c8d9ed" : dsText
    readonly property color mainHex_c8d9f7: "#c8d9f7"
    readonly property color mainHex_c8ead8: "#c8ead8"
    readonly property color mainHex_ca3b3b: "#ca3b3b"
    readonly property color mainHex_cadcf3: "#cadcf3"
    readonly property color mainHex_cb4f4f: "#cb4f4f"
    readonly property color mainHex_cbd9ec: lightMode ? "#cbd9ec" : dsText
    readonly property color mainHex_ccefdc: "#ccefdc"
    readonly property color mainHex_cfd5e3: lightMode ? "#cfd5e3" : dsText
    readonly property color mainHex_d0ad19: "#d0ad19"
    readonly property color mainHex_d0ddf0: lightMode ? "#d0ddf0" : dsText
    readonly property color mainHex_d14545: "#d14545"
    readonly property color mainHex_d18b22: "#d18b22"
    readonly property color mainHex_d1e0f2: lightMode ? "#d1e0f2" : dsText
    readonly property color mainHex_d2def0: lightMode ? "#d2def0" : dsText
    readonly property color mainHex_d2def4: lightMode ? "#d2def4" : dsText
    readonly property color mainHex_d2e1f6: lightMode ? "#d2e1f6" : dsText
    readonly property color mainHex_d35b5b: "#d35b5b"
    readonly property color mainHex_d3a722: "#d3a722"
    readonly property color mainHex_d4d9e3: lightMode ? "#d4d9e3" : dsText
    readonly property color mainHex_d4dfef: lightMode ? "#d4dfef" : dsText
    readonly property color mainHex_d4e1f8: "#d4e1f8"
    readonly property color mainHex_d5deeb: lightMode ? "#d5deeb" : dsText
    readonly property color mainHex_d5deec: lightMode ? "#d5deec" : dsText
    readonly property color mainHex_d5dfed: lightMode ? "#d5dfed" : dsText
    readonly property color mainHex_d5e3f8: "#d5e3f8"
    readonly property color mainHex_d6dde8: lightMode ? "#d6dde8" : dsText
    readonly property color mainHex_d6dfec: lightMode ? "#d6dfec" : dsText
    readonly property color mainHex_d7deea: lightMode ? "#d7deea" : dsText
    readonly property color mainHex_d7dfec: lightMode ? "#d7dfec" : dsText
    readonly property color mainHex_d7e2f0: "#d7e2f0"
    readonly property color mainHex_d7e4f5: "#d7e4f5"
    readonly property color mainHex_d7e4f6: lightMode ? "#d7e4f6" : dsText
    readonly property color mainHex_d7e4fb: "#d7e4fb"
    readonly property color mainHex_d7e9ff: "#d7e9ff"
    readonly property color mainHex_d8dde8: lightMode ? "#d8dde8" : dsText
    readonly property color mainHex_d8e1ef: lightMode ? "#d8e1ef" : dsText
    readonly property color mainHex_d8e1f0: lightMode ? "#d8e1f0" : dsText
    readonly property color mainHex_d8e2f0: lightMode ? "#d8e2f0" : dsText
    readonly property color mainHex_d8e4f8: "#d8e4f8"
    readonly property color mainHex_d8efdf: "#d8efdf"
    readonly property color mainHex_d97706: "#d97706"
    readonly property color mainHex_d9770626: "#d9770626"
    readonly property color mainHex_d9d0ff: "#d9d0ff"
    readonly property color mainHex_d9dee8: lightMode ? "#d9dee8" : dsText
    readonly property color mainHex_d9e0ec: lightMode ? "#d9e0ec" : dsText
    readonly property color mainHex_d9e0ed: lightMode ? "#d9e0ed" : dsText
    readonly property color mainHex_d9e1ef: lightMode ? "#d9e1ef" : dsText
    readonly property color mainHex_d9e6fb: "#d9e6fb"
    readonly property color mainHex_d9edff: "#d9edff"
    readonly property color mainHex_dbe2ee: lightMode ? "#dbe2ee" : dsText
    readonly property color mainHex_dbe3ef: lightMode ? "#dbe3ef" : dsText
    readonly property color mainHex_dbe8ff: "#dbe8ff"
    readonly property color mainHex_dce4f2: "#dce4f2"
    readonly property color mainHex_dce7f8: "#dce7f8"
    readonly property color mainHex_dde4ef: lightMode ? "#dde4ef" : dsText
    readonly property color mainHex_dde5ef: lightMode ? "#dde5ef" : dsText
    readonly property color mainHex_dee3ec: lightMode ? "#dee3ec" : dsText
    readonly property color mainHex_dee6f3: lightMode ? "#dee6f3" : dsText
    readonly property color mainHex_dfbf22: "#dfbf22"
    readonly property color mainHex_dfc33f: "#dfc33f"
    readonly property color mainHex_dfe6f1: "#dfe6f1"
    readonly property color mainHex_dfe7f2: "#dfe7f2"
    readonly property color mainHex_e0e6f0: "#e0e6f0"
    readonly property color mainHex_e1e5ed: "#e1e5ed"
    readonly property color mainHex_e1e6ee: "#e1e6ee"
    readonly property color mainHex_e1e8f2: "#e1e8f2"
    readonly property color mainHex_e1e9f4: "#e1e9f4"
    readonly property color mainHex_e2ecf9: lightMode ? "#e2ecf9" : dsText
    readonly property color mainHex_e3e8f1: "#e3e8f1"
    readonly property color mainHex_e4e8ef: "#e4e8ef"
    readonly property color mainHex_e4eaf4: "#e4eaf4"
    readonly property color mainHex_e5ebf4: "#e5ebf4"
    readonly property color mainHex_e5edf9: "#e5edf9"
    readonly property color mainHex_e6ebf3: "#e6ebf3"
    readonly property color mainHex_e7e9ee: "#e7e9ee"
    readonly property color mainHex_e7edf5: "#e7edf5"
    readonly property color mainHex_e7edf6: "#e7edf5"
    readonly property color mainHex_e7eefb: lightMode ? "#e7eefb" : dsText
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
    readonly property color mainHex_edf4ff: lightMode ? "#edf4ff" : dsText
    readonly property color mainHex_edf5ff: "#edf5ff"
    readonly property color mainHex_edf7ff: "#edf7ff"
    readonly property color mainHex_eef0f4: "#eef0f4"
    readonly property color mainHex_eef0ff: "#eef0ff"
    readonly property color mainHex_eef2f7: "#eef2f7"
    readonly property color mainHex_eef2f8: "#eef2f8"
    readonly property color mainHex_eef3ff: "#eef3ff"
    readonly property color mainHex_eef4ff: lightMode ? "#eef4ff" : dsText
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
    readonly property color mainHex_f1f5ff: lightMode ? "#f1f5ff" : dsText
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
    readonly property color mainHex_ff7d92: lightMode ? "#ff7d92" : dsDanger
    readonly property color mainHex_ff8da0: lightMode ? "#ff8da0" : dsDanger
    readonly property color mainHex_ff8e8e: lightMode ? "#ff8e8e" : dsDanger
    readonly property color mainHex_ffb454: lightMode ? "#ffb454" : dsWarning
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
    readonly property color mainHex_223654: lightMode ? "#223654" : dsSurfaceSoft
    readonly property color mainHex_263248: lightMode ? "#263248" : dsSurfaceSoft
    readonly property color mainHex_3c2b55: "#3c2b55"
    readonly property color mainHex_463260: "#463260"
    readonly property color mainHex_4d607a: lightMode ? "#4d607a" : dsBorderStrong
    readonly property color mainHex_65758b: "#65758b"
    readonly property color mainHex_7050b8: "#7050b8"
    readonly property color mainHex_7155a2: "#7155a2"
    readonly property color mainHex_7b53ff: "#7b53ff"
    readonly property color mainHex_7f72ff: "#7f72ff"
    readonly property color mainHex_7faeff: lightMode ? "#7faeff" : dsLinkIconBlue
    readonly property color mainHex_90a5bf: lightMode ? "#90a5bf" : dsTextSubtle
    readonly property color mainHex_9eb4ce: lightMode ? "#9eb4ce" : dsTextMuted
    readonly property color mainHex_a0682a: "#a0682a"
    readonly property color mainHex_a0afc4: lightMode ? "#a0afc4" : dsTextMuted
    readonly property color mainHex_b5c7de: lightMode ? "#b5c7de" : dsTextMuted
    readonly property color mainHex_b89cff: "#b89cff"
    readonly property color mainHex_d4e2f5: lightMode ? "#d4e2f5" : dsText
    readonly property color mainHex_dce4f1: lightMode ? "#dce4f1" : dsText
    readonly property color mainHex_e3d7ff: "#e3d7ff"
    readonly property color mainHex_f3efff: "#f3efff"
    readonly property color mainHex_f5f7fc: "#f5f7fc"
    readonly property color mainHex_f8f5ff: "#f8f5ff"

    // Complete legacy names used by profile metadata and Settings pages.
    readonly property color mainHex_1f6fe0: lightMode ? "#1f6fe0" : dsLinkIconBlue
    readonly property color mainHex_9fc4ff: lightMode ? "#9fc4ff" : dsLinkIconBlue
    readonly property color mainHex_233854: lightMode ? "#233854" : dsSurfaceSoft
    readonly property color mainHex_2a3e5a: lightMode ? "#2a3e5a" : dsBorder
    readonly property color mainHex_2e4260: lightMode ? "#2e4260" : dsBorder
    readonly property color mainHex_33465f: lightMode ? "#33465f" : dsBorderStrong
    readonly property color mainHex_4a5b72: lightMode ? "#4a5b72" : dsBorderStrong
    readonly property color mainHex_4e6686: lightMode ? "#4e6686" : dsBorderStrong
    readonly property color mainHex_4f5d70: lightMode ? "#4f5d70" : dsTextMuted
    readonly property color mainHex_52627a: lightMode ? "#52627a" : dsTextMuted
    readonly property color mainHex_556378: lightMode ? "#556378" : dsTextMuted
    readonly property color mainHex_5b6f8e: lightMode ? "#5b6f8e" : dsTextMuted
    readonly property color mainHex_5f7088: lightMode ? "#5f7088" : dsTextMuted
    readonly property color mainHex_9db6d6: lightMode ? "#9db6d6" : dsTextMuted
    readonly property color mainHex_a5bbd8: lightMode ? "#a5bbd8" : dsTextMuted
    readonly property color mainHex_aac0dc: lightMode ? "#aac0dc" : dsTextMuted
    readonly property color mainHex_b5c8df: lightMode ? "#b5c8df" : dsTextMuted
    readonly property color mainHex_7e8ea8: lightMode ? "#7e8ea8" : dsTextSubtle
    readonly property color mainHex_c8d1e0: lightMode ? "#c8d1e0" : dsText
    readonly property color mainHex_c9d1dc: lightMode ? "#c9d1dc" : dsText
    readonly property color mainHex_d6e2f4: lightMode ? "#d6e2f4" : dsText
    readonly property color mainHex_d7dfea: lightMode ? "#d7dfea" : dsText
    readonly property color mainHex_b42318: lightMode ? "#b42318" : dsDanger
    readonly property color mainHex_ff8a8a: lightMode ? "#ff8a8a" : dsDanger
}
