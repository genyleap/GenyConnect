import QtQuick

Item {
    id: root

    property int level: 4
    property color activeColor: "#19cb62"
    property color inactiveColor: "#ccd2dd"

    width: 28
    height: 26

    Row {
        anchors.centerIn: parent
        spacing: 3

        Repeater {
            model: 4
            delegate: Rectangle {
                width: 4
                height: 6 + index * 5
                radius: 1.5
                y: root.height - height
                color: index < root.level ? root.activeColor : root.inactiveColor
            }
        }
    }
}
