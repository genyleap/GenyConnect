// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Layouts

import GenyConnect 1.0

ColumnLayout {

    Layout.fillWidth: true;

    property string setColor : Colors.lineBorderActivated

    Rectangle {

        property int widthSize : parent.width
        property int lineSize : 1

        Layout.fillWidth: true;

        width: widthSize
        height: lineSize
        color: setColor
    }

}
