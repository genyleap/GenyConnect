import QtQuick

Item {
    id: root

    width: 640
    height: 320

    // ── Public API ─────────────────────────────────────────────────────────────
    property real value: 150.0
    property real minimumValue: 0.0
    property real maximumValue: 240.0
    property string unit: ""
    property bool darkMode: true
    property bool useOwnBackground: false
    property color darkBackgroundColor: "#000000"
    property color lightBackgroundColor: "transparent"

    // Particle controls
    property bool particlesEnabled: true
    property int particleCount: 64
    property int sparkCount: 12
    property real particleIntensity: 1.0
    property color valueTextColor: darkMode ? "#ffffff" : "#1f3f66"
    property color unitTextColor: darkMode ? "#c8c8e0" : "#5f7fa6"
    property color scaleTextColor: darkMode ? "#ffffff" : "#27548a"

    // Particles become faster as speed increases.
    readonly property real particleSpeedFactor: 1.0 + progress * 3.8

    // ── Geometry ───────────────────────────────────────────────────────────────
    readonly property real _cx: width * 0.50
    readonly property real _cy: height * 0.68

    readonly property real _R: Math.min(width, height) * 0.400

    readonly property real _bandThick: _R * 0.220
    readonly property real _rOuter: _R
    readonly property real _rInner: _R - _bandThick

    readonly property real startAngle: 150.0
    readonly property real sweepAngle: 240.0

    readonly property real progress: {
        const range = maximumValue - minimumValue
        if (range <= 0)
            return 0

        return Math.max(0, Math.min(1, (value - minimumValue) / range))
    }

    readonly property real currentAngle: startAngle + progress * sweepAngle

    // ── Color helpers ──────────────────────────────────────────────────────────
    function _mixChannel(a, b, t) {
        return Math.round(a + (b - a) * t)
    }

    function _mixHex(c1, c2, t) {
        t = Math.max(0, Math.min(1, t))

        const a = parseInt(c1.slice(1), 16)
        const b = parseInt(c2.slice(1), 16)

        const ar = (a >> 16) & 255
        const ag = (a >> 8) & 255
        const ab = a & 255

        const br = (b >> 16) & 255
        const bg = (b >> 8) & 255
        const bb = b & 255

        const r = _mixChannel(ar, br, t)
        const g = _mixChannel(ag, bg, t)
        const bl = _mixChannel(ab, bb, t)

        return "#" + ((1 << 24) + (r << 16) + (g << 8) + bl).toString(16).slice(1)
    }

    function colorForProgress(p) {
        p = Math.max(0, Math.min(1, p))

        if (p < 0.22)
            return _mixHex("#1688ff", "#22d6ff", p / 0.22)

        if (p < 0.46)
            return _mixHex("#22d6ff", "#6868ff", (p - 0.22) / 0.24)

        if (p < 0.64)
            return _mixHex("#6868ff", "#b83dff", (p - 0.46) / 0.18)

        if (p < 0.80)
            return _mixHex("#b83dff", "#ff3fa8", (p - 0.64) / 0.16)

        if (p < 0.92)
            return _mixHex("#ff3fa8", "#ff8a1f", (p - 0.80) / 0.12)

        return _mixHex("#ff8a1f", "#ff2d2d", (p - 0.92) / 0.08)
    }

    // ── Animation ──────────────────────────────────────────────────────────────
    Behavior on value {
        NumberAnimation {
            duration: 600
            easing.type: Easing.OutCubic
        }
    }

    onValueChanged: dynamicCanvas.requestPaint()

    onWidthChanged: {
        staticCanvas.requestPaint()
        dynamicCanvas.requestPaint()
    }

    onHeightChanged: {
        staticCanvas.requestPaint()
        dynamicCanvas.requestPaint()
    }
    onDarkModeChanged: {
        staticCanvas.requestPaint()
        dynamicCanvas.requestPaint()
    }

    // ══════════════════════════════════════════════════════════════════════════
    // Background
    // ══════════════════════════════════════════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        visible: root.useOwnBackground
        color: root.darkMode ? root.darkBackgroundColor : root.lightBackgroundColor
    }

    // ══════════════════════════════════════════════════════════════════════════
    // LAYER 1 — STATIC
    // ══════════════════════════════════════════════════════════════════════════
    Canvas {
        id: staticCanvas

        anchors.fill: parent
        antialiasing: true

        Component.onCompleted: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()

            const cx = root._cx
            const cy = root._cy
            const rO = root._rOuter
            const rI = root._rInner
            const bt = root._bandThick
            const sA = root.startAngle
            const sw = root.sweepAngle

            function rad(d) {
                return d * Math.PI / 180
            }

            function pt(r, d) {
                return {
                    x: cx + Math.cos(rad(d)) * r,
                    y: cy + Math.sin(rad(d)) * r
                }
            }

            function band(ro, ri, a0, a1, color) {
                ctx.beginPath()
                ctx.arc(cx, cy, ro, rad(a0), rad(a1), false)
                ctx.arc(cx, cy, ri, rad(a1), rad(a0), true)
                ctx.closePath()
                ctx.fillStyle = color
                ctx.fill()
            }

            // Inactive base band
            band(rO, rI, sA, sA + sw, root.darkMode ? "#12072d" : "#e7eef8")

            // Dark violet radial depth for inactive area
            const dg = ctx.createRadialGradient(
                cx, cy, rI * 0.85,
                cx, cy, rO * 1.01
            )

            if (root.darkMode) {
                dg.addColorStop(0.00, "rgba(8, 2, 40, 0.00)")
                dg.addColorStop(0.38, "rgba(28, 8, 88, 0.24)")
                dg.addColorStop(0.75, "rgba(48, 18, 140, 0.30)")
                dg.addColorStop(1.00, "rgba(70, 35, 190, 0.46)")
            } else {
                dg.addColorStop(0.00, "rgba(255,255,255,0.00)")
                dg.addColorStop(0.40, "rgba(120,163,220,0.18)")
                dg.addColorStop(0.75, "rgba(98,145,205,0.28)")
                dg.addColorStop(1.00, "rgba(84,131,193,0.38)")
            }

            band(rO, rI, sA, sA + sw, dg)

            // Outer rim stroke
            ctx.beginPath()
            ctx.arc(cx, cy, rO, rad(sA), rad(sA + sw), false)
            ctx.lineWidth = 3
            ctx.lineCap = "butt"
            ctx.strokeStyle = root.darkMode ? "rgba(80, 42, 210, 0.72)" : "rgba(112, 149, 193, 0.58)"
            ctx.stroke()

            // Inner dark border
            ctx.beginPath()
            ctx.arc(cx, cy, rI, rad(sA), rad(sA + sw), false)
            ctx.lineWidth = 2
            ctx.strokeStyle = root.darkMode ? "rgba(0, 0, 0, 0.82)" : "rgba(77, 110, 150, 0.26)"
            ctx.stroke()

            // Ticks
            const N = 24

            for (let i = 0; i <= N; ++i) {
                const isMajor = i % 2 === 0
                const ang = sA + (i / N) * sw

                const p1 = pt(rO + 1, ang)
                const p2 = pt(isMajor ? rI - 1 : rO - bt * 0.42, ang)

                ctx.beginPath()
                ctx.moveTo(p1.x, p1.y)
                ctx.lineTo(p2.x, p2.y)
                ctx.lineWidth = isMajor ? 2.0 : 1.2
                ctx.lineCap = "butt"
                ctx.strokeStyle = root.darkMode ? "rgba(0, 0, 0, 0.72)" : "rgba(73, 104, 146, 0.45)"
                ctx.stroke()
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // LAYER 2 — DYNAMIC
    // ══════════════════════════════════════════════════════════════════════════
    Canvas {
        id: dynamicCanvas

        anchors.fill: parent
        antialiasing: true

        Component.onCompleted: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()

            const prg = root.progress

            if (prg < 0.002)
                return

            const cx = root._cx
            const cy = root._cy
            const rO = root._rOuter
            const rI = root._rInner
            const sA = root.startAngle
            const sw = root.sweepAngle
            const cur = root.currentAngle

            function rad(d) {
                return d * Math.PI / 180
            }

            function pt(r, d) {
                return {
                    x: cx + Math.cos(rad(d)) * r,
                    y: cy + Math.sin(rad(d)) * r
                }
            }

            function band(ro, ri, a0, a1, color) {
                ctx.beginPath()
                ctx.arc(cx, cy, ro, rad(a0), rad(a1), false)
                ctx.arc(cx, cy, ri, rad(a1), rad(a0), true)
                ctx.closePath()
                ctx.fillStyle = color
                ctx.fill()
            }

            // Full-scale fixed gradient.
            // It covers the complete 0..maximumValue arc.
            // Only the visible painted segment is clipped by currentAngle.
            const gradientStart = pt(rO * 0.90, sA + 4)
            const gradientEnd = pt(rO * 0.90, sA + sw - 4)

            const angularGradient = ctx.createLinearGradient(
                gradientStart.x,
                gradientStart.y,
                gradientEnd.x,
                gradientEnd.y
            )

            if (root.darkMode) {
                angularGradient.addColorStop(0.00, "#1688ff")
                angularGradient.addColorStop(0.22, "#22d6ff")
                angularGradient.addColorStop(0.46, "#6868ff")
                angularGradient.addColorStop(0.64, "#b83dff")
                angularGradient.addColorStop(0.80, "#ff3fa8")
                angularGradient.addColorStop(0.92, "#ff8a1f")
                angularGradient.addColorStop(1.00, "#ff2d2d")
            } else {
                angularGradient.addColorStop(0.00, "#3b8dff")
                angularGradient.addColorStop(0.28, "#45b2ff")
                angularGradient.addColorStop(0.56, "#5f97ff")
                angularGradient.addColorStop(0.78, "#7987ff")
                angularGradient.addColorStop(1.00, "#9b86ff")
            }

            // Neutral radial sheen.
            const depthGradient = ctx.createRadialGradient(
                cx, cy, rI * 0.88,
                cx, cy, rO * 1.02
            )

            depthGradient.addColorStop(0.00, "rgba(255, 255, 255, 0.00)")
            depthGradient.addColorStop(0.52, root.darkMode ? "rgba(255, 255, 255, 0.10)" : "rgba(255, 255, 255, 0.07)")
            depthGradient.addColorStop(1.00, root.darkMode ? "rgba(255, 255, 255, 0.28)" : "rgba(255, 255, 255, 0.18)")

            // Neutral inner bloom.
            const bloomGradient = ctx.createRadialGradient(
                cx, cy, rI * 0.72,
                cx, cy, rI * 1.01
            )

            bloomGradient.addColorStop(0.00, "rgba(255, 255, 255, 0.00)")
            bloomGradient.addColorStop(0.72, root.darkMode ? "rgba(255, 255, 255, 0.06)" : "rgba(255, 255, 255, 0.04)")
            bloomGradient.addColorStop(1.00, root.darkMode ? "rgba(255, 255, 255, 0.14)" : "rgba(255, 255, 255, 0.10)")

            // Active band
            band(rO, rI, sA, cur, angularGradient)
            band(rO, rI, sA, cur, depthGradient)

            // Contained inner bloom
            band(rI, rI * 0.72, sA, cur, bloomGradient)

            // Active outer rim — soft neutral glow
            ctx.beginPath()
            ctx.arc(cx, cy, rO, rad(sA), rad(cur), false)
            ctx.lineWidth = 10
            ctx.lineCap = "butt"
            ctx.strokeStyle = root.darkMode ? "rgba(255, 255, 255, 0.10)" : "rgba(65, 103, 151, 0.12)"
            ctx.stroke()

            // Active outer rim — gradient highlight
            ctx.beginPath()
            ctx.arc(cx, cy, rO, rad(sA), rad(cur), false)
            ctx.lineWidth = 3.5
            ctx.lineCap = "butt"
            ctx.strokeStyle = angularGradient
            ctx.stroke()

            // Needle
            const pAng = cur
            const tipR = rO + 6
            const baseR = rI - 8
            const hb = root._R * 0.018

            const tip = pt(tipR, pAng)
            const baseC = pt(baseR, pAng)

            const nA = rad(pAng + 90)
            const nB = rad(pAng - 90)

            const bA = {
                x: baseC.x + Math.cos(nA) * hb,
                y: baseC.y + Math.sin(nA) * hb
            }

            const bB = {
                x: baseC.x + Math.cos(nB) * hb,
                y: baseC.y + Math.sin(nB) * hb
            }

            // Needle halo
            ctx.beginPath()
            ctx.moveTo(tip.x, tip.y)
            ctx.lineTo(baseC.x, baseC.y)
            ctx.lineWidth = 14
            ctx.lineCap = "round"
            ctx.strokeStyle = root.darkMode ? "rgba(255, 255, 255, 0.07)" : "rgba(42, 78, 120, 0.18)"
            ctx.stroke()

            // Needle body
            ctx.beginPath()
            ctx.moveTo(tip.x, tip.y)
            ctx.lineTo(bA.x, bA.y)
            ctx.lineTo(bB.x, bB.y)
            ctx.closePath()
            ctx.fillStyle = root.darkMode ? "#ffffff" : "#2c5b8f"
            ctx.fill()
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // LAYER 3 — WHITE GAUGE PARTICLES
    // ══════════════════════════════════════════════════════════════════════════
    Item {
        id: particleLayer

        anchors.fill: parent
        visible: root.particlesEnabled && root.progress > 0.025
        opacity: Math.min(1.0, (0.18 + root.progress * 0.82) * root.particleIntensity)

        // Moving white energy particles inside the active gauge band.
        Repeater {
            model: root.particleCount

            delegate: Item {
                id: particle

                readonly property real seedA: ((index * 37) % 100) / 100
                readonly property real seedB: ((index * 61) % 100) / 100
                readonly property real seedC: ((index * 83) % 100) / 100
                readonly property real seedD: ((index * 19) % 100) / 100

                property real phase: seedA

                readonly property real normalizedTravel: (phase + seedA * 0.53) % 1.0
                readonly property real activeProgress: normalizedTravel * root.progress

                readonly property real angleDeg: root.startAngle + activeProgress * root.sweepAngle
                readonly property real angleRad: angleDeg * Math.PI / 180

                readonly property real radialJitter: Math.sin((phase + seedB) * Math.PI * 2.0) * root._bandThick * 0.10
                readonly property real radiusOnArc: root._rInner
                                                    + root._bandThick * (0.22 + seedB * 0.56)
                                                    + radialJitter

                readonly property real px: root._cx + Math.cos(angleRad) * radiusOnArc
                readonly property real py: root._cy + Math.sin(angleRad) * radiusOnArc

                readonly property real dotSize: Math.max(1.7, root._R * (0.008 + seedC * 0.012))
                readonly property real tailLength: Math.max(8.0, root._R * (0.040 + seedD * 0.040))

                readonly property real headDistance: root.progress - activeProgress
                readonly property real headBoost: headDistance >= 0 && headDistance < 0.18 ? 1.0 : 0.45
                readonly property real speedBoost: 0.22 + root.progress * 0.78

                x: px - width / 2
                y: py - height / 2
                width: tailLength + dotSize * 4
                height: dotSize * 5
                opacity: Math.min(0.92, headBoost * speedBoost)

                rotation: angleDeg + 90
                scale: 0.88 + Math.sin(phase * Math.PI * 2.0) * 0.10

                NumberAnimation on phase {
                    from: 0
                    to: 1
                    duration: Math.max(260, (1450 + index * 41) / root.particleSpeedFactor)
                    loops: Animation.Infinite
                    easing.type: Easing.Linear
                }

                // Tail
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: glowDot.left
                    anchors.rightMargin: -particle.dotSize * 0.20

                    width: particle.tailLength
                    height: Math.max(1.0, particle.dotSize * 0.55)
                    radius: height / 2

                    opacity: 0.16
                    gradient: Gradient {
                        orientation: Gradient.Horizontal

                        GradientStop {
                            position: 0.00
                            color: "transparent"
                        }

                        GradientStop {
                            position: 0.72
                            color: root.darkMode ? "#88ffffff" : "#886ca4ff"
                        }

                        GradientStop {
                            position: 1.00
                            color: root.darkMode ? "#ffffffff" : "#ff4f88d8"
                        }
                    }
                }

                // Glow
                Rectangle {
                    id: glowDot

                    anchors.centerIn: parent

                    width: particle.dotSize * 4.2
                    height: width
                    radius: width / 2

                    color: root.darkMode ? "#ffffff" : "#5f96d9"
                    opacity: root.darkMode ? 0.11 : 0.16
                }

                // Core dot
                Rectangle {
                    anchors.centerIn: glowDot

                    width: particle.dotSize
                    height: width
                    radius: width / 2

                    color: root.darkMode ? "#ffffff" : "#2f6db6"
                    opacity: root.darkMode ? 0.82 : 0.90
                }
            }
        }

        // Small white sparks around the needle/head.
        Repeater {
            model: root.sparkCount

            delegate: Item {
                id: spark

                readonly property real seedA: ((index * 29) % 100) / 100
                readonly property real seedB: ((index * 47) % 100) / 100
                readonly property real seedC: ((index * 71) % 100) / 100

                property real pulse: seedA

                readonly property real burstDistance: root._bandThick * (0.10 + seedB * 0.55)
                readonly property real burstAngleOffset: -3.0 - seedA * 13.0 + Math.sin(pulse * Math.PI * 2.0) * 3.0

                readonly property real angleDeg: root.currentAngle + burstAngleOffset
                readonly property real angleRad: angleDeg * Math.PI / 180

                readonly property real radiusOnArc: root._rOuter
                                                    - root._bandThick * (0.18 + seedC * 0.46)
                                                    + pulse * burstDistance

                readonly property real px: root._cx + Math.cos(angleRad) * radiusOnArc
                readonly property real py: root._cy + Math.sin(angleRad) * radiusOnArc

                readonly property real sparkSize: Math.max(2.0, root._R * (0.010 + seedB * 0.013))

                x: px - width / 2
                y: py - height / 2
                width: sparkSize * 5
                height: sparkSize * 5

                opacity: root.progress > 0.05
                         ? Math.min(0.88, (0.15 + root.progress * 0.52) * (1.0 - pulse))
                         : 0

                scale: 0.56 + pulse * 0.82

                NumberAnimation on pulse {
                    from: 0
                    to: 1
                    duration: Math.max(180, (560 + index * 36) / root.particleSpeedFactor)
                    loops: Animation.Infinite
                    easing.type: Easing.OutCubic
                }

                Rectangle {
                    anchors.centerIn: parent

                    width: spark.sparkSize * 4.2
                    height: width
                    radius: width / 2

                    color: root.darkMode ? "#ffffff" : "#6aa0df"
                    opacity: root.darkMode ? 0.10 : 0.16
                }

                Rectangle {
                    anchors.centerIn: parent

                    width: spark.sparkSize
                    height: width
                    radius: width / 2

                    color: root.darkMode ? "#ffffff" : "#3f75bf"
                    opacity: root.darkMode ? 0.84 : 0.90
                }
            }
        }

        // A tiny white shine exactly at the gauge head.
        Item {
            id: gaugeHeadShine

            readonly property real angleRad: root.currentAngle * Math.PI / 180
            readonly property real radiusOnArc: root._rOuter - root._bandThick * 0.24
            readonly property real shineSize: Math.max(12, root._R * 0.075)

            x: root._cx + Math.cos(angleRad) * radiusOnArc - width / 2
            y: root._cy + Math.sin(angleRad) * radiusOnArc - height / 2
            width: shineSize
            height: shineSize
            opacity: root.progress > 0.03 ? 0.28 + root.progress * 0.32 : 0

            SequentialAnimation on scale {
                loops: Animation.Infinite

                NumberAnimation {
                    from: 0.75
                    to: 1.12
                    duration: Math.max(180, 620 / root.particleSpeedFactor)
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    from: 1.12
                    to: 0.75
                    duration: Math.max(180, 620 / root.particleSpeedFactor)
                    easing.type: Easing.InCubic
                }
            }

            Rectangle {
                anchors.centerIn: parent

                width: parent.width
                height: width
                radius: width / 2

                color: root.darkMode ? "#ffffff" : "#6da6e3"
                opacity: root.darkMode ? 0.09 : 0.14
            }

            Rectangle {
                anchors.centerIn: parent

                width: parent.width * 0.30
                height: width
                radius: width / 2

                color: root.darkMode ? "#ffffff" : "#3d74be"
                opacity: root.darkMode ? 0.62 : 0.75
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // QML labels
    // ══════════════════════════════════════════════════════════════════════════

    Text {
        readonly property real ang: root.startAngle * Math.PI / 180
        readonly property real lr: root._rOuter * 1.14

        text: Math.round(root.minimumValue).toString()
        color: root.scaleTextColor

        font.pixelSize: Math.max(14, root._R * 0.095)
        font.weight: Font.Medium

        x: root._cx + Math.cos(ang) * lr - width / 2
        y: root._cy + Math.sin(ang) * lr - height / 2
    }

    Text {
        readonly property real ang: (root.startAngle + root.sweepAngle) * Math.PI / 180
        readonly property real lr: root._rOuter * 1.14

        text: Math.round(root.maximumValue).toString()
        color: root.scaleTextColor

        font.pixelSize: Math.max(14, root._R * 0.095)
        font.weight: Font.Medium

        x: root._cx + Math.cos(ang) * lr - width / 2
        y: root._cy + Math.sin(ang) * lr - height / 2
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter

        y: root._cy - root._rInner * 0.90

        text: root.unit
        color: root.unitTextColor
        opacity: 0.80

        font.pixelSize: Math.max(12, root._R * 0.080)
        font.weight: Font.Normal
        font.letterSpacing: 0.5
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter

        y: root._cy - root._rInner * 0.48

        text: Math.round(root.value)
        color: root.valueTextColor

        font.pixelSize: Math.max(60, root._rInner * 0.88)
        font.weight: Font.Bold
        font.letterSpacing: -1
    }
}
