import QtQuick

Item {
    id: root

    property int level: 4
    property color activeColor: "#19cb62"
    property color inactiveColor: "#ccd2dd"

    width: 28
    height: 26

    // Symmetric signal mark: it conveys strength without implying a reading
    // direction, so RTL mirroring cannot accidentally reverse its meaning.
    LayoutMirroring.enabled: false

    Row {
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: 5
            delegate: Rectangle {
                readonly property int distanceFromCenter: Math.abs(index - 2)
                readonly property int activeRadius: root.level <= 0 ? -1
                                                   : root.level === 1 ? 0
                                                   : root.level === 2 ? 1 : 2
                width: 3
                height: [8, 15, 23, 15, 8][index]
                radius: 1.5
                y: root.height - height
                color: distanceFromCenter <= activeRadius ? root.activeColor : root.inactiveColor
            }
        }
    }
}
