pragma Singleton
import QtQuick

QtObject {
    // Legacy tokens
    property int spacing: 12
    property int padding: 16
    property int cornerRadius: 12
    property int shadowOffset: 6

    // Unified layout scale
    readonly property int gap4: 4
    readonly property int gap6: 6
    readonly property int gap8: 8
    readonly property int gap10: 10
    readonly property int gap12: 12
    readonly property int gap14: 14
    readonly property int gap16: 16
    readonly property int gap20: 20
    readonly property int gap24: 24
    readonly property int gap28: 28

    readonly property int pagePaddingMobile: 12
    readonly property int pagePaddingDesktop: 16
    readonly property int cardPadding: 14
    readonly property int cardPaddingCompact: 12

    readonly property int radiusXs: 8
    readonly property int radiusSm: 12
    readonly property int radiusMd: 16
    readonly property int radiusLg: 20
    readonly property int radiusXl: 24
    readonly property int radiusPill: 999

    readonly property int rowHeightCompact: 38
    readonly property int rowHeight: 44
    readonly property int rowHeightLarge: 52
}
