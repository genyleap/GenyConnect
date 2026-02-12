// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import "../Controls" as Controls

T.Button {    
    id: control
    property bool isDefault : false
    property bool isBold : false
    property bool isSelected : false
    property string setIcon : ""
    property string frontColor : Colors.primary
    property string sizeType : "normal"

    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

    Layout.preferredWidth: 64
    Layout.preferredHeight: 64

    opacity: control.enabled ? 1 : 0.5

    contentItem: ColumnLayout {

        width: parent.width
        height: parent.height
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 10


        Text {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            font.family: FontSystem.getAwesomeLight.name
            font.pixelSize: Typography.h3
            text: setIcon
            font.weight: Font.ExtraLight
            font.bold: control.down ? true : false
            font.styleName: control.down ? "Bold" : "Light"
            color: isSelected ? Colors.foregroundFocused : Colors.primary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            visible: setIcon ? true : false
            scale: control.pressed ? 0.8 : 1.0
            Behavior on scale { NumberAnimation { duration: 100; } }
        }

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
    }

    background: Rectangle {
        implicitWidth: control.width
        implicitHeight: control.height
        Layout.fillWidth: true
        color: isSelected ? Colors.primaryBack : "transparent";
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
}
