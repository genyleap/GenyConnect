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
    // Compatibility with callers that supply their own selected state.
    property bool isFocused: checked
    readonly property bool selectionActive: checked || isFocused
    width: 120
    implicitHeight: 44
    padding: Metrics.gap8
    hoverEnabled: Qt.platform.os !== "android" && Qt.platform.os !== "ios"
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : 0.45

    text: title

    contentItem: RowLayout
    {
        width: parent.width
        Layout.fillWidth: true
        HorizontalSpacer { }

        Text {
            font.family: FontSystem.getAwesomeSolid.name
            color: controlTabButton.selectionActive ? Colors.dsPrimarySolid : Colors.dsTextMuted
            font.pixelSize: Typography.h3
            font.weight: Font.Black
            text: setIcon
        }

        Text {
            font.family: FontSystem.getContentFont.name
            font.pixelSize: Typography.t1
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            text: count
            color: controlTabButton.selectionActive ? Colors.dsPrimarySolid : Colors.dsTextMuted
            visible: title.length > 0 ? true : false
        }

        HorizontalSpacer { }

    }

    background: Rectangle {
        id: rect
        width: parent.width
        height: controlTabButton.height
        color: controlTabButton.selectionActive ? Colors.dsPrimaryTint
                                               : (controlTabButton.hovered || controlTabButton.down ? Colors.dsSurfaceSoft : "transparent")
        radius: Metrics.radiusXs
        border.width: controlTabButton.visualFocus ? 2 : 0
        border.color: Colors.dsPrimarySolid
    }
}
