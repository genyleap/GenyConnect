// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts

import GenyConnect 1.0

T.TabButton {
    id:control
    property string title : ""
    property bool setStatus : true
    property int setSelect
    property string setIcon : ""
    property bool isRadiused : true
    width: 135
    height: 36

    text: title

    contentItem: Text {
        text: title
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        font.family: FontSystem.getTitleFont.name
        font.pixelSize: Typography.t2
        font.bold: control.focus ? true : false
        color: control.focus ? Colors.accent : Colors.foregroundFocused
        elide: Text.ElideRight
    }

    background:Rectangle {
        id: rect
        width: control.width
        height: control.height
        color: control.focus ? Colors.primary : Colors.backgroundDeactivated
        border.width: control.focus ? 2 : 1
        border.color: control.focus ? Colors.borderFocused : Colors.borderFocused
        radius: isRadiused ? 5 : 0
    }
}
