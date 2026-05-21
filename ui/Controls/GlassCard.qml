import QtQuick
import GenyConnect 1.0

Rectangle {
    id: root

    property int cardRadius: Metrics.radiusLg
    property int cardPadding: Metrics.cardPadding
    property bool elevated: true
    property bool outlined: true
    property color fillColor: Colors.dsGlass
    property color strokeColor: Colors.dsBorder

    default property alias content: contentItem.data

    radius: cardRadius
    color: fillColor
    border.width: outlined ? 1 : 0
    border.color: outlined ? strokeColor : "transparent"

    layer.enabled: elevated
    layer.smooth: true

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: elevated ? 4 : 0
        radius: root.radius
        color: Colors.dsShadowSoft
        z: -1
        visible: elevated
    }

    Item {
        id: contentItem
        anchors.fill: parent
        anchors.margins: cardPadding
    }
}
