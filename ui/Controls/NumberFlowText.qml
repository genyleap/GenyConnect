import QtQuick
import GenyConnect 1.0

Item {
    id: root

    property string text: ""
    property string color: "#1f2b3d"
    property bool bold: false
    property int duration: 220
    property int fontSize: 18
    property string currentText: text
    property string previousText: text

    implicitWidth: Math.max(currentLabel.implicitWidth, previousLabel.implicitWidth)
    implicitHeight: currentLabel.implicitHeight
    clip: true

    onTextChanged: {
        if (text === currentText)
            return
        previousText = currentText
        currentText = text
        flowAnimation.restart()
    }

    Text {
        id: previousLabel
        text: root.previousText
        color: root.color
        font.family: FontSystem.getContentFontBold.name
        font.pixelSize: root.fontSize
        font.bold: root.bold
        opacity: 0.0
        y: 0
    }

    Text {
        id: currentLabel
        text: root.currentText
        color: root.color
        font.family: FontSystem.getContentFontBold.name
        font.pixelSize: root.fontSize
        font.bold: root.bold
        opacity: 1.0
        y: 0
    }

    SequentialAnimation {
        id: flowAnimation

        ScriptAction {
            script: {
                previousLabel.y = 0
                previousLabel.opacity = 1.0
                currentLabel.y = root.height * 0.72
                currentLabel.opacity = 0.0
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: previousLabel
                property: "y"
                to: -root.height * 0.72
                duration: root.duration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: previousLabel
                property: "opacity"
                to: 0.0
                duration: root.duration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: currentLabel
                property: "y"
                to: 0
                duration: root.duration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: currentLabel
                property: "opacity"
                to: 1.0
                duration: root.duration
                easing.type: Easing.OutCubic
            }
        }
    }
}
