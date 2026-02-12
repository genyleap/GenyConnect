import QtQuick
import GenyConnect 1.0

Rectangle {
    id: card

    property int padding: 14
    property bool soft: false
    property bool outlined: true
    property color fillColor: soft ? Colors.backgroundItemActivated : Colors.backgroundActivated
    property color strokeColor: Colors.borderActivated

    radius: Colors.radius
    color: fillColor
    border.color: outlined ? strokeColor : "transparent"

    default property alias content: contentItem.data
    implicitWidth: contentItem.childrenRect.width + padding * 2
    implicitHeight: contentItem.childrenRect.height + padding * 2

    Item {
        id: contentItem
        anchors.fill: parent
        anchors.margins: card.padding
    }
}
