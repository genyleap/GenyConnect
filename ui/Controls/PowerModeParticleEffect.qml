import QtQuick
import QtQuick.Particles

Item {
    id: root

    property bool active: false
    property bool animationsEnabled: true
    property real intensity: 1.0
    property real velocityScale: 1.0
    property string modeName: "Normal"
    property color accentColor: "#25f29a"

    readonly property bool saveMode: modeName === "Save"
    readonly property bool highMode: modeName === "High Performance"
    readonly property bool effectActive: active && animationsEnabled
    readonly property real minDimension: Math.max(1, Math.min(width, height))
    readonly property real scaleFactor: Math.max(0.88, Math.min(1.35, minDimension / 96.0))
    readonly property real clampedVelocityScale: Math.max(0.38, Math.min(2.4, velocityScale))
    readonly property real modeDensity: saveMode ? 0.34 : (highMode ? 1.12 : 0.66)
    readonly property real modeSpeed: (saveMode ? 0.42 : (highMode ? 1.48 : 0.86)) * clampedVelocityScale
    readonly property real primaryRate: Math.max(saveMode ? 3 : 7, Math.round(17 * intensity * scaleFactor * modeDensity))
    readonly property real secondaryRate: Math.max(saveMode ? 1 : 4, Math.round(8 * intensity * scaleFactor * modeDensity))
    readonly property real sparkRate: Math.max(saveMode ? 1 : 3, Math.round(5 * intensity * scaleFactor * modeDensity))
    readonly property color primaryColor: accentColor
    readonly property color secondaryColor: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, highMode ? 0.76 : 0.58)
    readonly property color sparkColor: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, highMode ? 0.88 : 0.66)
    readonly property color glowColor: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, highMode ? 0.26 : 0.18)
    readonly property url particleSource: "qrc:/ui/Resources/image/power-orb-particle.svg"

    visible: active

    Rectangle {
        anchors.centerIn: parent
        width: Math.max(54, Math.round(root.minDimension * (root.highMode ? 0.92 : 0.96)))
        height: width
        radius: width / 2
        color: root.glowColor
        opacity: root.effectActive ? (root.highMode ? 0.15 : 0.11) : 0.0
        scale: root.effectActive ? 1.0 : 0.96

        SequentialAnimation on scale {
            running: root.effectActive
            loops: Animation.Infinite
            NumberAnimation {
                from: 1.0
                to: root.highMode ? 1.13 : (root.saveMode ? 1.035 : 1.075)
                duration: root.highMode ? 640 : (root.saveMode ? 2200 : 1280)
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                from: root.highMode ? 1.13 : (root.saveMode ? 1.035 : 1.075)
                to: 1.0
                duration: root.highMode ? 640 : (root.saveMode ? 2200 : 1280)
                easing.type: Easing.InOutQuad
            }
        }

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.max(76, Math.round(root.minDimension * 1.30))
        height: width
        radius: width / 2
        color: root.glowColor
        opacity: root.effectActive ? (root.highMode ? 0.065 : 0.052) : 0.0
        scale: root.effectActive ? 1.0 : 0.96

        SequentialAnimation on scale {
            running: root.effectActive
            loops: Animation.Infinite
            NumberAnimation {
                from: 1.0
                to: root.highMode ? 1.09 : (root.saveMode ? 1.025 : 1.055)
                duration: root.highMode ? 760 : (root.saveMode ? 2500 : 1520)
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                from: root.highMode ? 1.09 : (root.saveMode ? 1.025 : 1.055)
                to: 1.0
                duration: root.highMode ? 760 : (root.saveMode ? 2500 : 1520)
                easing.type: Easing.InOutQuad
            }
        }

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    ParticleSystem {
        id: powerModeSystem
        running: root.effectActive
    }

    ImageParticle {
        anchors.fill: parent
        system: powerModeSystem
        groups: ["primary"]
        source: root.particleSource
        color: root.primaryColor
        colorVariation: root.highMode ? 0.04 : 0.02
        alpha: root.highMode ? 0.70 : (root.saveMode ? 0.38 : 0.54)
        alphaVariation: root.highMode ? 0.22 : 0.26
        entryEffect: ImageParticle.Scale
        autoRotation: true
        rotationVariation: root.saveMode ? 70 : (root.highMode ? 220 : 150)
        rotationVelocityVariation: root.saveMode ? 28 : (root.highMode ? 180 : 70)
    }

    ImageParticle {
        anchors.fill: parent
        system: powerModeSystem
        groups: ["secondary"]
        source: root.particleSource
        color: root.secondaryColor
        colorVariation: root.highMode ? 0.04 : 0.02
        alpha: root.highMode ? 0.56 : (root.saveMode ? 0.28 : 0.38)
        alphaVariation: 0.24
        entryEffect: ImageParticle.Fade
        autoRotation: true
        rotationVariation: root.saveMode ? 90 : (root.highMode ? 260 : 170)
        rotationVelocityVariation: root.saveMode ? 32 : (root.highMode ? 220 : 90)
    }

    ImageParticle {
        anchors.fill: parent
        system: powerModeSystem
        groups: ["spark"]
        source: root.particleSource
        color: root.sparkColor
        colorVariation: 0.02
        alpha: root.highMode ? 0.46 : (root.saveMode ? 0.22 : 0.30)
        alphaVariation: 0.22
        entryEffect: ImageParticle.Fade
        autoRotation: true
        rotationVariation: root.highMode ? 220 : 120
        rotationVelocityVariation: root.highMode ? 180 : 60
    }

    Emitter {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: Math.round(root.minDimension * 0.01)
        width: Math.max(24, Math.round(root.minDimension * 1.14))
        height: width
        system: powerModeSystem
        group: "primary"
        enabled: root.effectActive
        emitRate: root.effectActive ? root.primaryRate : 0
        lifeSpan: root.saveMode ? 2100 : (root.highMode ? 760 : 1280)
        lifeSpanVariation: root.saveMode ? 420 : (root.highMode ? 190 : 300)
        size: Math.max(2, Math.round(root.minDimension * (root.saveMode ? 0.024 : (root.highMode ? 0.040 : 0.032))))
        sizeVariation: Math.max(1, Math.round(root.minDimension * (root.saveMode ? 0.012 : 0.020)))
        endSize: Math.max(1, Math.round(root.minDimension * 0.014))
        shape: EllipseShape { }
        velocity: AngleDirection {
            angle: root.highMode ? 265 : 250
            angleVariation: root.highMode ? 92 : 120
            magnitude: Math.max(8, Math.round(root.minDimension * (root.highMode ? 0.21 : 0.13) * root.modeSpeed))
            magnitudeVariation: Math.max(4, Math.round(root.minDimension * (root.highMode ? 0.11 : 0.08) * root.modeSpeed))
        }
        acceleration: AngleDirection {
            angle: root.highMode ? 270 : 250
            angleVariation: root.highMode ? 70 : 90
            magnitude: Math.max(1, Math.round(root.minDimension * (root.highMode ? 0.036 : 0.016) * root.modeSpeed))
            magnitudeVariation: Math.max(1, Math.round(root.minDimension * 0.012 * root.modeSpeed))
        }
    }

    Emitter {
        anchors.centerIn: parent
        width: Math.max(28, Math.round(root.minDimension * 1.30))
        height: width
        system: powerModeSystem
        group: "secondary"
        enabled: root.effectActive
        emitRate: root.effectActive ? root.secondaryRate : 0
        lifeSpan: root.saveMode ? 1800 : (root.highMode ? 620 : 1120)
        lifeSpanVariation: root.saveMode ? 360 : (root.highMode ? 160 : 280)
        size: Math.max(1, Math.round(root.minDimension * (root.saveMode ? 0.018 : (root.highMode ? 0.026 : 0.022))))
        sizeVariation: Math.max(1, Math.round(root.minDimension * 0.014))
        endSize: 1
        shape: EllipseShape { }
        velocity: AngleDirection {
            angle: root.highMode ? 285 : 292
            angleVariation: root.highMode ? 120 : 145
            magnitude: Math.max(10, Math.round(root.minDimension * (root.highMode ? 0.26 : 0.15) * root.modeSpeed))
            magnitudeVariation: Math.max(5, Math.round(root.minDimension * (root.highMode ? 0.12 : 0.09) * root.modeSpeed))
        }
        acceleration: AngleDirection {
            angle: root.highMode ? 270 : 290
            angleVariation: root.highMode ? 80 : 100
            magnitude: Math.max(1, Math.round(root.minDimension * (root.highMode ? 0.040 : 0.014) * root.modeSpeed))
            magnitudeVariation: Math.max(1, Math.round(root.minDimension * 0.010 * root.modeSpeed))
        }
    }

    Emitter {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: Math.round(root.minDimension * -0.02)
        width: Math.max(28, Math.round(root.minDimension * 1.38))
        height: width
        system: powerModeSystem
        group: "spark"
        enabled: root.effectActive
        emitRate: root.effectActive ? root.sparkRate : 0
        lifeSpan: root.saveMode ? 1400 : (root.highMode ? 420 : 960)
        lifeSpanVariation: root.saveMode ? 260 : (root.highMode ? 120 : 220)
        size: Math.max(1, Math.round(root.minDimension * (root.highMode ? 0.013 : 0.012)))
        sizeVariation: Math.max(1, Math.round(root.minDimension * 0.008))
        endSize: 1
        shape: EllipseShape { }
        velocity: AngleDirection {
            angle: root.highMode ? 270 : 270
            angleVariation: root.highMode ? 150 : 160
            magnitude: Math.max(12, Math.round(root.minDimension * (root.highMode ? 0.34 : 0.14) * root.modeSpeed))
            magnitudeVariation: Math.max(5, Math.round(root.minDimension * (root.highMode ? 0.15 : 0.09) * root.modeSpeed))
        }
        acceleration: AngleDirection {
            angle: 270
            angleVariation: root.highMode ? 90 : 80
            magnitude: Math.max(1, Math.round(root.minDimension * (root.highMode ? 0.050 : 0.012) * root.modeSpeed))
            magnitudeVariation: Math.max(1, Math.round(root.minDimension * 0.010 * root.modeSpeed))
        }
    }
}
