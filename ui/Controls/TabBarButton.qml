// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts

import GenyConnect 1.0

T.TabButton {
    id:controlTabButton
    property string title : ""
    property bool setStatus : true
    property int setSelect
    property bool isBold: false
    property string setIcon : "\uf39b"
    property int count : 0
    property bool isFocused: false
    width: 120
    height: 36

    text: title

    contentItem: RowLayout
    {
        width: parent.width
        Layout.fillWidth: true
        HorizontalSpacer { }

        Text {
            font.family: FontSystem.getAwesomeRegular.name
            color: controlTabButton.isFocused ? Colors.primary : Colors.backgroundDeactivated
            font.pixelSize: Typography.h3
            font.weight: Font.ExtraLight
            font.bold: controlTabButton.isFocused ? true : false
            font.styleName: controlTabButton.isFocused ? "Bold" : "Light"
            text: setIcon
        }

        Text {
            font.family: FontSystem.getContentFont.name
            font.pixelSize: Typography.t1
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            text: count
            color: controlTabButton.isFocused ? Colors.primary : Colors.foregroundDeactivated
            visible: title.length > 0 ? true : false
        }

        HorizontalSpacer { }

    }

    background: Rectangle {
        id: rect
        width: parent.width
        height: 2
        anchors.bottom: controlTabButton.bottom
        color: controlTabButton.isFocused ? Colors.primary : Colors.backgroundDeactivated
        radius: 5
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    }
}

