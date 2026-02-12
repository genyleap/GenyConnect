// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import GenyConnect 1.0

Item {

    property bool isEnable : true
    property string icon : ""
    property string title : ""
    property bool fontBold: false
    property bool isSelected : false

    width: 46
    height: 46

    signal click
    signal hover

    ColumnLayout {
        id: rowLayout
        anchors.fill: parent
        layoutDirection: Qt.LeftToRight
        spacing: 20

        Item { Layout.fillHeight: true; }

        Text {
            Layout.fillWidth: true
            Layout.fillHeight: true
            font.family: FontSystem.getAwesomeLight.name
            font.pixelSize: Typography.h2
            font.weight: Font.ExtraLight
            font.bold: isSelected ? true : false
            font.styleName: isSelected ? "Bold" : "Light"
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            color: isSelected ? "#ffffff" : "#BEC0C8"
            text: icon
            Behavior on scale {
                NumberAnimation {
                    duration: Animations.normal;
                    easing.type: Easing.InOutQuad;
                }
            }

            scale : clickArea.containsPress ? 1.3 : 1.0
        }

        Rectangle {
            visible: isSelected ? true : false
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            width: 10
            height: 2
        }

        Item { Layout.fillHeight: true; }
    }

    MouseArea {
        id:clickArea
        enabled: isSelected ? false : true
        anchors.fill: parent
        preventStealing: true
        hoverEnabled: true
        onClicked: click();
        onHoveredChanged: hover();
    }
}

