// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Controls.Basic
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts

ColumnLayout {

    property string title : "Unknown"
    property string note;


    Layout.fillWidth: true;
    spacing: 5

    RowLayout {

        width: parent.width
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        Layout.fillWidth: true

        HorizontalLine { }

        Rectangle {
            width: parent.width
            height: 1
            color: appStyle.borderActivated
        }

        Text {
            font.family: fontSystem.getContentFont.name
            font.pixelSize: appStyle.h6
            font.weight: Font.Bold
            color: appStyle.foregroundActivated
            text: title
        }

        Rectangle {
            width: parent.width
            height: 1
            color: appStyle.borderActivated
        }

        HorizontalLine { }

    }

    RowLayout {

        width: parent.width
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        Layout.fillWidth: true

        HorizontalSpacer { }

        Text {
            text: note
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            fontSizeMode: Text.Fit
            font.family: fontSystem.getContentFont.name
            Layout.fillWidth: false;
            font.pixelSize: appStyle.t2
            font.weight: Font.Light
            Layout.fillHeight: true
            font.bold: false
            color: appStyle.foregroundActivated
            visible: note ? true : false
            wrapMode: Text.WordWrap
        }

        HorizontalSpacer { }

    }
}
