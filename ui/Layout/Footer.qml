// Copyright (C) 2026 Genyleap.
// Copyright (C) 2026 Kambiz Asadzadeh
// SPDX-License-Identifier: MIT-only

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

import GenyConnect 1.0

//![GLOBAL/HOME]
Rectangle {

    width: parent.width
    Layout.fillWidth: true
    height: 100
    Layout.preferredHeight: 100
    Layout.minimumHeight: 100
    color: Colors.footer
    radius: 40

    property bool isBold : false
    property bool mainMenu : true;
    property bool secondMenu : false;
    property alias footMenuSideAlias : footMenuSide

    QtObject {
        id:footerObject
        property bool main : mainMenu
        property bool second : secondMenu
    }

    ColumnLayout {

        width: parent.width
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        Item {
            height: 5
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }

        FootMenu {
            id: footMenuSide
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }

        Item {
            height: 5
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }

        Item { height: 15; }
    }

    Rectangle {
        width: parent.width
        height: 36
        color: Colors.footer
        Layout.fillWidth: true
        anchors.bottom: parent.bottom
        z: -2
    }
}
