import QtQuick
import GenyConnect 1.0

Rectangle {
    id: panel
    property bool soft: false
    radius: 16
    color: soft ? Colors.backgroundItemActivated : Colors.backgroundActivated
    border.color: Colors.borderActivated
}
