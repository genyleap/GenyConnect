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
    implicitHeight: Math.max(44, implicitContentHeight + topPadding + bottomPadding)
    padding: Metrics.gap8
    hoverEnabled: Qt.platform.os !== "android" && Qt.platform.os !== "ios"
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : 0.45

    text: title

    contentItem: Text {
        text: title
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        font.family: FontSystem.contentFontFamily
        font.pixelSize: Typography.t2
        font.weight: control.checked ? Font.DemiBold : Font.Normal
        color: control.checked ? Colors.dsPrimarySolid : Colors.dsTextMuted
        wrapMode: Text.WordWrap
    }

    background:Rectangle {
        id: rect
        width: control.width
        height: control.height
        color: control.checked ? Colors.dsPrimaryTint
                               : (control.hovered || control.down ? Colors.dsSurfaceSoft : "transparent")
        border.width: control.visualFocus ? 2 : 0
        border.color: Colors.dsPrimarySolid
        radius: control.isRadiused ? Metrics.radiusXs : 0
    }
}
