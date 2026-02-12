// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    id: control
    width: 80
    height: 80
    radius: appStyle.radius
    color: appStyle.backgroundItemActivated
    property string icon : ""
    property string title : "Link"
    signal click();
    ColumnLayout {
        anchors.centerIn: parent
        Item { height: 5; }
        Text {
            id: textIcon
            font.family: fontSystem.getAwesomeSolid.name
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            font.pixelSize: appStyle.h3
            font.bold: mouseArea.containsPress ? true : false
            font.weight: Font.Light
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: appStyle.foregroundActivated
            text: icon

            Behavior on scale { NumberAnimation { duration: 100; } }
            scale: mouseArea.containsPress ? 0.9 : 1.0

            Behavior on text {
                SequentialAnimation {
                    NumberAnimation { target: textIcon; property: "opacity"; to: 0; duration: 100; }
                    NumberAnimation { target: textIcon; property: "scale"; to: 0.6; duration: 100; }
                    //PropertyAction {}
                    NumberAnimation { target: textIcon; property: "opacity"; to: 1; duration: 100; }
                    NumberAnimation { target: textIcon; property: "scale"; to: 1.0; duration: 100; }

                }
            }
        }
        Text {
            font.family: fontSystem.getContentFont.name
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: appStyle.t2
            font.bold: false
            font.weight: Font.Normal
            color: appStyle.foregroundActivated
            text: title
        }
        Item { height: 5; }
    }
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: {
            click()
        }
    }
}
