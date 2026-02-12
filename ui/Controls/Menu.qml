import QtQuick
import QtQuick.Controls.Basic as T
import GenyConnect 1.0

T.Menu {
    id: menu

    T.Action { text: qsTr("Tool Bar"); checkable: true }
    T.Action { text: qsTr("Side Bar"); checkable: true; checked: true }
    T.Action { text: qsTr("Status Bar"); checkable: true; checked: true }

    T.MenuSeparator {
        contentItem: Rectangle {
            implicitWidth: 200
            implicitHeight: 1
            color: Colors.backgroundItemActivated
        }
    }

    T.Menu {
        title: qsTr("Advanced")
        // ...
    }

    topPadding: 2
    bottomPadding: 2

    delegate: T.MenuItem {
        id: menuItem
        implicitWidth: 200
        implicitHeight: 40

        arrow: Canvas {
            x: parent.width - width
            implicitWidth: 40
            implicitHeight: 40
            visible: menuItem.subMenu
            onPaint: {
                var ctx = getContext("2d")
                ctx.fillStyle = menuItem.highlighted ? Colors.backgroundItemActivated : Colors.primary
                ctx.moveTo(15, 15)
                ctx.lineTo(width - 15, height / 2)
                ctx.lineTo(15, height - 15)
                ctx.closePath()
                ctx.fill()
            }
        }

        indicator: Item {
            implicitWidth: 40
            implicitHeight: 40
            Rectangle {
                width: 26
                height: 26
                anchors.centerIn: parent
                visible: menuItem.checkable
                radius: 3
                color: Colors.backgroundItemActivated
                border.color: Colors.borderActivated
                Rectangle {
                    width: 14
                    height: 14
                    anchors.centerIn: parent
                    visible: menuItem.checked
                    color: Colors.primary
                    radius: 2
                }
            }
        }

        contentItem: Text {
            leftPadding: menuItem.indicator.width
            rightPadding: menuItem.arrow.width
            text: menuItem.text
            font: menuItem.font
            opacity: enabled ? 1.0 : 0.3
            color: menuItem.highlighted ? Colors.backgroundItemActivated : Colors.primary
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            implicitWidth: 200
            implicitHeight: 40
            opacity: enabled ? 1 : 0.3
            color: menuItem.highlighted ? Colors.primary : "transparent"
        }
    }

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 40
        color: Colors.backgroundItemActivated
        border.color: Colors.primary
        radius: 2
    }
}
