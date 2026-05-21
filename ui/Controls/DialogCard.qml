import QtQuick
import GenyConnect 1.0

GlassCard {
    id: root

    property bool compact: false

    cardRadius: compact ? Metrics.radiusLg : Metrics.radiusXl
    cardPadding: compact ? Metrics.cardPaddingCompact : Metrics.cardPadding
    fillColor: Colors.dsSurface
    strokeColor: Colors.dsBorder
    elevated: true
}
