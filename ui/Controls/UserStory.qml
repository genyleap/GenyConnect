// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

Item {
    property string name : "unknown"
    property int size : 76
    property bool hasLive : false
    property bool hasStory : false
    property bool hasNoStory : false
    property bool isSelf : false
    property string avatarUrl : ""

    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    width: size
    height: size

    property string avatarData : avatarUrl ? avatarUrl : "qrc:/Resources/image/avatar.svg"

    Column {
        spacing: 10
        StoryAvatar {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            width: size
            height: size
            userNameString: name
            url: avatarData
            addStory: hasNoStory
            avatarHasStory: hasStory
            hasNewStory: hasStory
            hasLive: hasLive
            self: isSelf
        }
        Text {
            width: parent.width
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            font.family: fontSystem.getContentFont.name
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: appStyle.t1
            font.bold: true
            font.weight: Font.Normal
            text: isSelf ? "Your Story" : name
            color: isSelf ? appStyle.foregroundDeactivated : appStyle.foregroundActivated
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }

    Rectangle {
        id: rect
        y: 60
        width: 36;
        height: 22;
        radius: appStyle.radius
        anchors.horizontalCenterOffset: 0
        anchors.horizontalCenter: parent.horizontalCenter
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        color: appStyle.primary
        border.width: 2
        border.color: appStyle.accent
        visible: hasLive

        NumberAnimation {
            id: animateScale
            target: rect
            properties: "scale"
            from: 1.0
            to: 0.9
            running: hasLive
            loops: Animation.Infinite
            duration: appStyle.duration * 6
            easing {
                 type: Easing.OutElastic
                 amplitude: 8.0
                 period: 5.5
             }
        }

        Text {
            anchors.centerIn: parent
            font.family: fontSystem.getContentFont.name
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: appStyle.t3
            font.weight: Font.Bold
            text: "LIVE"
            color: appStyle.accent
        }
    }

}
