// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Layouts

ColumnLayout {

    property string title : ""
    property string value : "0"
    signal click

    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

    Text {
        text: qsTr(value)
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        font.family: fontSystem.getContentFontBold.name
        font.pixelSize: appStyle.h4
        font.bold: true
        font.weight: Font.Bold
    }
    Text {
        text: qsTr(title)
        font.family: fontSystem.getContentFont.name
        font.pixelSize: appStyle.t1
        color: appStyle.foregroundDeactivated
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: click();
        }
    }
}
