import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as T
import QtQuick.Layouts
import GenyConnect 1.0

import "../Core"

T.ComboBox {
    id: control

    // Parent layouts still position this control according to the page direction.
    // Its internals are handled explicitly to keep the indicator and padding from
    // being mirrored independently and overlapping the displayed value.
    LayoutMirroring.enabled: false
    // Propagate this explicit opt-out to every internal item. With false here,
    // nested Text items can inherit the application's RTL mirroring again and
    // Qt mirrors AlignRight back to the left.
    LayoutMirroring.childrenInherit: true

    readonly property bool darkMode: Theme.mode === Theme.Dark
    property color fillColor: Colors.gcControlBg
    property color strokeColor: Colors.gcControlBorder
    property color focusColor: Colors.secondry
    property int cornerRadius: 15
    property color popupFillColor: Colors.gcPopupBg
    property color popupBorderColor: Colors.gcPopupBorder
    property color popupHoverColor: Colors.gcPopupHover

    font.family: FontSystem.contentFontFamily
    font.pixelSize: Typography.t2

    leftPadding: I18n.isRtl ? 28 : 12
    rightPadding: I18n.isRtl ? 12 : 28
    topPadding: 6
    bottomPadding: 6

    contentItem: Item {
        x: control.leftPadding
        y: control.topPadding
        width: Math.max(0, control.width - control.leftPadding - control.rightPadding)
        height: Math.max(0, control.height - control.topPadding - control.bottomPadding)
        implicitWidth: selectedText.implicitWidth
        implicitHeight: selectedText.implicitHeight

        Text {
            id: selectedText
            anchors.fill: parent
            LayoutMirroring.enabled: false
            LayoutMirroring.childrenInherit: true
            readonly property var currentData: (control.currentIndex >= 0 && control.model && control.model.length !== undefined)
                                               ? control.model[control.currentIndex]
                                               : null
            text: (currentData && typeof currentData === "object" && currentData.name !== undefined)
                  ? I18n.t(currentData.name)
                  : I18n.t(control.displayText)
            font.family: control.font.family
            font.pixelSize: control.font.pixelSize
            color: Colors.gcControlText
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: I18n.isRtl ? Text.AlignRight : Text.AlignLeft
            elide: Text.ElideRight
        }
    }

    indicator: Item {
        width: 12
        height: 8
        x: I18n.isRtl ? 10 : control.width - width - 10
        y: Math.round((control.height - height) / 2)

        Canvas {
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                ctx.strokeStyle = Colors.gcControlMuted
                ctx.lineWidth = 1.8
                ctx.lineCap = "round"
                ctx.beginPath()
                ctx.moveTo(1, 2)
                ctx.lineTo(width / 2, height - 1)
                ctx.lineTo(width - 1, 2)
                ctx.stroke()
            }
        }
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
        LayoutMirroring.enabled: false
        LayoutMirroring.childrenInherit: true
        text: {
            if (modelData && typeof modelData === "object") {
                let value = modelData.name !== undefined ? String(modelData.name) : control.textAt(index)
                if (modelData.exclusive === true)
                    value += "  •  Exclusive"
                if (modelData.badge !== undefined && String(modelData.badge).trim().length > 0)
                    value += "  •  " + String(modelData.badge).trim()
                return I18n.t(value)
            }
            return I18n.t(control.textAt(index))
        }
        font.family: control.font.family
        font.pixelSize: control.font.pixelSize
        contentItem: Item {
            x: comboDelegate.leftPadding
            y: comboDelegate.topPadding
            width: Math.max(0, comboDelegate.width - comboDelegate.leftPadding - comboDelegate.rightPadding)
            height: Math.max(0, comboDelegate.height - comboDelegate.topPadding - comboDelegate.bottomPadding)
            implicitWidth: delegateText.implicitWidth
            implicitHeight: delegateText.implicitHeight

            Text {
                id: delegateText
                anchors.fill: parent
                LayoutMirroring.enabled: false
                LayoutMirroring.childrenInherit: true
                text: comboDelegate.text
                color: comboDelegate.enabled
                       ? Colors.gcControlText
                       : Colors.gcControlMuted
                font.family: comboDelegate.font.family
                font.pixelSize: comboDelegate.font.pixelSize
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: I18n.isRtl ? Text.AlignRight : Text.AlignLeft
                elide: Text.ElideRight
            }
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
            LayoutMirroring.enabled: false
            LayoutMirroring.childrenInherit: true
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
