import QtQuick
import QtQuick.Controls.Basic

import GenyConnect 1.0 as Core

ToolTip {
    id: control
    height: 40
    text: qsTr("A descriptive tool tip of what the button does")
    contentItem: Text {
        text: control.text
        font: control.font
        color: Core.Colors.primary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        color: Core.Colors.backgroundActivated
        border.width: 1
        border.color: Core.Colors.borderActivated
        radius: Core.Colors.radius / 2
    }
}
