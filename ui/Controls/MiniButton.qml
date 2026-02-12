// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as T

import GenyConnect 1.0

T.TabButton {

    id:control

    property string title
    property string description
    property string setIcon : ""

    text: title

    contentItem: Text {
        width: parent.width
        Layout.fillWidth: true;
        font.family: FontSystem.getAwesomeRegular.name
        font.pixelSize: Typography.h3
        font.weight:  Font.Normal
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        opacity: enabled ? 1.0 : 0.3
        color: Colors.primary
        text: setIcon
        visible: setIcon ? true : false
        scale: control.pressed ? 0.9 : 1.0
        Behavior on scale {
            NumberAnimation {
                duration: Animations.normal;
                easing.type: Easing.Linear;
            }
        }

    }

    background: Rectangle {
        Layout.minimumWidth: 32
        implicitHeight: 32
        radius: 5
        color: control.hovered ? Colors.backgroundHovered : "#00000000"
        opacity: enabled ? 1 : 0.3
        // Behavior on color {
        //     ColorAnimation {
        //         duration: Animations.normal;
        //         easing.type: Easing.Linear;
        //     }
        // }
    }
}
