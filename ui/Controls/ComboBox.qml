import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as T
import QtQuick.Layouts
import GenyConnect 1.0
import "../Core"

T.ComboBox {
    id: control

    readonly property bool darkMode: Theme.mode === Theme.Dark
    property color fillColor: darkMode ? "#1a2638" : Colors.backgroundItemActivated
    property color strokeColor: darkMode ? "#3a4f6c" : Colors.borderActivated
    property color focusColor: Colors.secondry
    property int cornerRadius: 15
    property color popupFillColor: darkMode ? "#1a2638" : "#ffffff"
    property color popupBorderColor: darkMode ? "#3a4f6c" : "#d8e1ef"
    property color popupHoverColor: darkMode ? "#253753" : "#edf3ff"

    font.family: FontSystem.contentFontFamily
    font.pixelSize: Typography.t2

    leftPadding: 12
    rightPadding: 28
    topPadding: 6
    bottomPadding: 6

    contentItem: Text {
        readonly property var currentData: (control.currentIndex >= 0 && control.model && control.model.length !== undefined)
                                           ? control.model[control.currentIndex]
                                           : null
        text: (currentData && typeof currentData === "object" && currentData.name !== undefined)
              ? currentData.name
              : control.displayText
        font.family: control.font.family
        font.pixelSize: control.font.pixelSize
        color: control.darkMode ? "#e1ecfb" : Colors.textPrimary
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Text {
        text: "\u25BE"
        font.family: FontSystem.contentFontFamily
        font.pixelSize: Typography.t3
        color: control.darkMode ? "#9cb2cf" : Colors.textMuted
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
    }

    background: Rectangle {
        radius: control.cornerRadius
        color: control.fillColor
        border.color: control.activeFocus ? control.focusColor : control.strokeColor
        border.width: 2
    }

    delegate: T.ItemDelegate {
        id: comboDelegate
        width: ListView.view ? ListView.view.width : control.width
        height: 34
        leftPadding: 10
        rightPadding: 10
        highlighted: control.highlightedIndex === index
        readonly property bool itemEnabled: !(modelData && typeof modelData === "object" && modelData.enabled === false)
        enabled: itemEnabled
        text: {
            if (modelData && typeof modelData === "object") {
                let value = modelData.name !== undefined ? String(modelData.name) : control.textAt(index)
                if (modelData.exclusive === true)
                    value += "  •  Exclusive"
                if (modelData.badge !== undefined && String(modelData.badge).trim().length > 0)
                    value += "  •  " + String(modelData.badge).trim()
                return value
            }
            return control.textAt(index)
        }
        font.family: control.font.family
        font.pixelSize: control.font.pixelSize
        contentItem: Text {
            text: comboDelegate.text
            color: comboDelegate.enabled
                   ? (control.darkMode ? "#d4e2f7" : "#2b3648")
                   : (control.darkMode ? "#6f84a2" : "#9aa6ba")
            font.family: comboDelegate.font.family
            font.pixelSize: comboDelegate.font.pixelSize
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            radius: 10
            color: comboDelegate.highlighted ? control.popupHoverColor : "transparent"
        }
    }

    popup: T.Popup {
        y: control.height + 6
        width: control.width
        padding: 6
        implicitHeight: Math.min(contentItem.implicitHeight + 12, 280)
        background: Rectangle {
            radius: Math.max(12, control.cornerRadius - 2)
            color: control.popupFillColor
            border.width: 1
            border.color: control.popupBorderColor
        }
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            spacing: 2
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }
    }
}
