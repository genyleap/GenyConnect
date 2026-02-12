import QtQuick
import QtQuick.Controls.Basic as T
import GenyConnect 1.0

T.ProgressBar {
    id: control

    property color fillColor: Colors.secondry
    property color trackColor: Colors.backgroundItemActivated

    background: Rectangle {
        radius: height / 2
        color: control.trackColor
    }

    contentItem: Rectangle {
        radius: height / 2
        height: parent.height
        width: Math.max(4, control.visualPosition * control.availableWidth)
        color: control.fillColor
        opacity: control.indeterminate ? 0.6 : 1
    }
}
