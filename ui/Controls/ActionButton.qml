// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import GenyConnect 1.0

T.Button {    
    id: control
    property bool isDefault : false
    property bool isBold : false

    property string setIcon : ""
    property string frontColor : Colors.primary
    property string sizeType : "normal"

    implicitHeight: 32
    implicitWidth: 32

    opacity: control.enabled ? 1 : 0.5

    contentItem: RowLayout {

        width: parent.width
        Layout.fillWidth: true
        spacing: 10

        Text {
            text: control.text
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.fillWidth: false
            font.family: FontSystem.getContentFont.name
            font.pixelSize: isBold ? Colors.h4 : Colors.h4
            font.bold: isBold ? Font.Bold : Font.Normal
            font.weight: isBold ? Font.Bold : Font.Normal
            color: frontColor
            visible: text ? true : false

            Behavior on color {
                ColorAnimation {
                    duration: Animations.normal;
                    easing.type: Easing.Linear;
                }
            }

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            scale: control.pressed ? 0.8 : 1.0
            Behavior on scale { NumberAnimation { duration: 100; } }
        }

        Text {
            font.family: FontSystem.getAwesomeLight.name
            font.pixelSize: Typography.h3
            text: setIcon
            font.weight: Font.ExtraLight
            font.bold: control.down ? true : false
            font.styleName: control.down ? "Bold" : "Light"
            color: frontColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            visible: setIcon ? true : false
            scale: control.pressed ? 0.8 : 1.0
            Behavior on scale { NumberAnimation { duration: 100; } }
        }

        Item { width: 5; }
    }

    background: Rectangle {
        implicitWidth: control.width
        implicitHeight: control.height
        Layout.fillWidth: true
        color: isDefault ? frontColor : "transparent";
        visible: false

        Behavior on color {
            ColorAnimation {
                duration: Animations.normal;
                easing.type: Easing.Linear;
            }
        }

        Rectangle {
            id: indicator
            property int mx
            property int my
            x: mx - width / 2
            y: my - height / 2
            height: width
            radius: width / 2
            color: Qt.lighter(frontColor)
        }
    }

    Rectangle {
        id: mask
        radius: Colors.radius
        anchors.fill: parent
        visible: false
    }

    OpacityMask {
        anchors.fill: background
        source: background
        maskSource: mask
    }

    MouseArea {
        id: mouseArea
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
        anchors.fill: parent
    }
}
