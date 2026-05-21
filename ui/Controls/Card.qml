import QtQuick
import GenyConnect 1.0

Rectangle {
    id: card

    property int padding: Metrics.cardPadding
    property bool soft: false
    property bool outlined: true
    property color fillColor: soft ? Colors.dsSurfaceSoft : Colors.dsSurface
    property color strokeColor: Colors.dsBorder

    radius: Metrics.radiusLg
    color: fillColor
    border.color: outlined ? strokeColor : "transparent"
    border.width: outlined ? 1 : 0

    default property alias content: contentItem.data
    implicitWidth: contentItem.childrenRect.width + padding * 2
    implicitHeight: contentItem.childrenRect.height + padding * 2

    Item {
        id: contentItem
        anchors.fill: parent
        anchors.margins: card.padding
    }
}
