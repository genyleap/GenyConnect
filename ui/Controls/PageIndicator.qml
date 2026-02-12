// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Controls.Basic as T
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts

T.PageIndicator {
    id: control
    count: 5
    currentIndex: 2
    delegate: Rectangle {
        implicitWidth: 8
        implicitHeight: 8
        radius: width
        color: index === control.currentIndex ? "transparent" : appStyle.primary
        border.width: index === control.currentIndex ? 1 : 0
        border.color: index === control.currentIndex ? appStyle.primary : "transparent"
        opacity: index === control.currentIndex ? 0.95 : pressed ? 0.7 : 0.45
        Behavior on opacity {
            OpacityAnimator {
                duration: 100
            }
        }
        Rectangle {
            width: parent.width/3
            height: parent.height/3
            color: index === control.currentIndex ? appStyle.primary : "transparent"
            radius: width
            anchors.centerIn: parent
        }
    }
}
