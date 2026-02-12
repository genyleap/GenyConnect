// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Layouts

import GenyConnect 1.0

ColumnLayout {

    Layout.fillHeight: true;

    Item { width: 1; }

    Rectangle {

        property int heightSize : parent.height
        property int lineSize : 1

        Layout.fillHeight: true;

        height: heightSize
        width: lineSize
        color: Colors.lineBorderActivated
    }

    Item { width: 1; }

}
