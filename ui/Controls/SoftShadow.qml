// Copyright (C) 2026 Genyleap Labs.
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Effects

Item {
    id: control

    property Item source: null
    property color shadowColor: "#33000000"
    property real shadowBlur: 0.5
    property real shadowScale: 1.0
    property real shadowOpacity: 0.35
    property real horizontalOffset: 0
    property real verticalOffset: 0
    property bool autoPaddingEnabled: true

    x: source ? source.x : 0
    y: source ? source.y : 0
    width: source ? source.width : 0
    height: source ? source.height : 0
    visible: source !== null && shadowColor.a > 0 && shadowOpacity > 0 && opacity > 0

    MultiEffect {
        anchors.fill: parent
        source: control.source
        autoPaddingEnabled: control.autoPaddingEnabled
        shadowEnabled: true
        shadowColor: control.shadowColor
        shadowBlur: Math.max(0, Math.min(1, control.shadowBlur))
        shadowScale: Math.max(0, control.shadowScale)
        shadowOpacity: Math.max(0, Math.min(1, control.shadowOpacity))
        shadowHorizontalOffset: control.horizontalOffset
        shadowVerticalOffset: control.verticalOffset
    }
}
