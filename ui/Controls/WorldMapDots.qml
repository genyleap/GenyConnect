import QtQuick

Item {
    id: root

    property color dotColor: "#8f95a3"
    property real dotOpacity: 0.74
    property real dotSize: 1.8
    property real spacing: 9.0

    property real centerMarkerXRatio: 0.52
    property real centerMarkerYRatio: 0.46
    property real sideMarkerXRatio: 0.15
    property real sideMarkerYRatio: 0.52

    Canvas {
        id: mapCanvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            ctx.fillStyle = Qt.rgba(root.dotColor.r, root.dotColor.g, root.dotColor.b, root.dotOpacity)

            const step = root.spacing
            const r = root.dotSize * 0.5
            const w = width
            const h = height

            for (let y = step * 0.5; y < h; y += step) {
                for (let x = step * 0.5; x < w; x += step) {
                    const nx = x / w
                    const ny = y / h
                    if (isLand(nx, ny)) {
                        ctx.beginPath()
                        ctx.arc(x, y, r, 0, Math.PI * 2)
                        ctx.fill()
                    }
                }
            }
        }

        function ellipse(nx, ny, cx, cy, rx, ry) {
            const dx = (nx - cx) / rx
            const dy = (ny - cy) / ry
            return dx * dx + dy * dy <= 1.0
        }

        function isLand(nx, ny) {
            let land = false

            // North America
            land = land || ellipse(nx, ny, 0.20, 0.32, 0.15, 0.13)
            land = land || ellipse(nx, ny, 0.30, 0.24, 0.10, 0.09)
            land = land || ellipse(nx, ny, 0.14, 0.37, 0.11, 0.10)

            // South America
            land = land || ellipse(nx, ny, 0.32, 0.68, 0.07, 0.18)

            // Europe + Asia
            land = land || ellipse(nx, ny, 0.54, 0.30, 0.08, 0.06)
            land = land || ellipse(nx, ny, 0.68, 0.36, 0.24, 0.16)
            land = land || ellipse(nx, ny, 0.84, 0.42, 0.10, 0.09)

            // Africa
            land = land || ellipse(nx, ny, 0.57, 0.53, 0.10, 0.16)

            // Australia
            land = land || ellipse(nx, ny, 0.83, 0.72, 0.09, 0.08)

            // Greenland
            land = land || ellipse(nx, ny, 0.35, 0.14, 0.06, 0.05)

            // Carve a few large oceans/gaps for silhouette clarity
            if (ellipse(nx, ny, 0.26, 0.44, 0.07, 0.06))
                land = false
            if (ellipse(nx, ny, 0.46, 0.38, 0.08, 0.08))
                land = false
            if (ellipse(nx, ny, 0.74, 0.58, 0.14, 0.10))
                land = false

            return land
        }
    }

    onWidthChanged: mapCanvas.requestPaint()
    onHeightChanged: mapCanvas.requestPaint()

    Item {
        id: centerPulse
        x: root.width * root.centerMarkerXRatio - width * 0.5
        y: root.height * root.centerMarkerYRatio - height * 0.5
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
                color: "#f27057"
                opacity: 0.0
                scale: 0.6

                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    running: true
                    PauseAnimation { duration: index * 360 }
                    NumberAnimation { from: 0.6; to: 2.2; duration: 2200; easing.type: Easing.OutCubic }
                }

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: true
                    PauseAnimation { duration: index * 360 }
                    NumberAnimation { from: 0.26; to: 0.0; duration: 2200; easing.type: Easing.OutCubic }
                }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 22
            height: 22
            radius: 11
            color: "#f17055"
            border.width: 3
            border.color: "#f7f7fa"
        }
    }

    Item {
        id: sideMarker
        x: root.width * root.sideMarkerXRatio - width * 0.5
        y: root.height * root.sideMarkerYRatio - height * 0.5
        width: 58
        height: 58

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 2
            radius: width * 0.5
            color: "#000000"
            opacity: 0.07
        }

        Rectangle {
            anchors.fill: parent
            radius: width * 0.5
            color: "#f5f7fa"
            border.width: 1
            border.color: "#d8dde7"

            Rectangle {
                width: 6
                height: 6
                radius: 3
                anchors.centerIn: parent
                color: "#252a34"
            }
        }
    }
}
