// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Qt5Compat.GraphicalEffects

import "../Pages" as Pages

Rectangle {
    id: circle
    transformOrigin: Item.Center

    property int lineWidth: width / 25

    property int fontSize: width / 8

    property string url : ""
    property string userNameString : ""

    property bool hasNewStory : false
    property bool avatarHasStory : false
    property bool addStory : false
    property bool hasLive : false
    property bool self : false

    color: "transparent"
    property color circleBackgroundColor: appStyle.backgroundItemActivated
    property color circleColor: !hasNewStory ? appStyle.secondry : appStyle.primary
    property color circleShadowColor: appStyle.lightShadow

    //value parameters
    property double from:0
    property double value: hasNewStory ? 360 : 0
    property double to: 360

    //progress circle angle
    property double fromAngle: Math.PI - 1
    property double toAngle: hasNewStory ? 360 : Math.PI *2 + 1

    //progress from right to left
    property bool reverse: false

    property bool initialized : false

    UserAvatar {
        id: avatar
        width: parent.width - 12
        height: parent.height - 12
        anchors.centerIn: parent
        z:999
        source: url
    }

    Rectangle {
        width: 24
        height: 24
        radius: width
        color: !hasNewStory ? appStyle.secondry : appStyle.primary
        border.width: 2
        border.color: appStyle.accent
        x: 48
        y: 48
        z: 999
        visible: self && !hasNewStory
        Text {
            id: textIcon
            font.family: fontSystem.getAwesomeRegular.name
            font.pixelSize: appStyle.t3
            font.bold: true
            font.weight: Font.Normal
            text: !hasNewStory ? "\uf067" : "\uf00c"
            anchors.centerIn: parent
            color: appStyle.accent
        }
    }

    Rectangle {
        id: root
        property Gradient borderGradient: borderGradient
        property int borderWidth: 3
        width: circle.width
        height: circle.height
        radius: width
        rotation: 200

        visible: hasNewStory ? true : false

        property alias source: imageView.source

        property alias fillMode: imageView.fillMode

        property bool isOnline : false

        property alias control : imageView

        property string setIcon : ""

        property string codeName : ""

        property string previewFile : "";

        signal click;

        function basename(str)
        {
            return (String(str).slice(String(str).lastIndexOf("/")+1))
        }

        Loader {
            id: loader
            width: root.width
            height: root.height
            anchors.centerIn: parent
            active: borderGradient
            sourceComponent: border
        }

        Gradient {
            id: borderGradient
            GradientStop {
                position: 0.000
                color: "#ee5272"
            }
            GradientStop {
                position: 0.167
                color: "#f78e5b"
            }
            GradientStop {
                position: 0.333
                color: "#ed4976"
            }
            GradientStop {
                position: 0.500
                color: "#5034e1"
            }
            GradientStop {
                position: 0.667
                color: "#772dcb"
            }
            GradientStop {
                position: 0.833
                color: "#bc21a1"
            }
            GradientStop {
                position: 1.000
                color: "#ed4a75"
            }
        }

        Component {
            id: border
            Item {
                ConicalGradient {
                    id: borderFill
                    anchors.fill: parent
                    gradient: borderGradient
                    visible: false
                }

                Rectangle {
                    id: mask
                    radius: root.radius
                    border.width: root.borderWidth
                    anchors.fill: parent
                    color: 'transparent'
                    visible: false
                }

                OpacityMask {
                    id: opM
                    anchors.fill: parent
                    source: borderFill
                    maskSource: mask
                }
            }
        }

        Timer {
            id: uploadTimer
            interval: 2000
            onTriggered: {
                var extraKeys = [];
                var key = "member_id";
                var val = globalUserInfo.userId;
                if (key !== "" && val !== ""){
                    extraKeys.push(key);
                    extraKeys.push(val);
                }
            }
        }

        Rectangle {
            id: circleMask
            anchors.fill: parent
            smooth: true
            visible: false
            radius: root.width / 2
        }

        Image {
            id: imageView
            width: parent.width
            height: parent.height
            sourceSize.width: parent.width * 2
            sourceSize.height: parent.height * 2
            visible: false
            fillMode: Image.PreserveAspectCrop
            scale: 1.0
            cache: false
            Rectangle {
                width: 200
                height: 48
                color: "#0f1122"
                border.width: 1
                border.color: "#ccc"
                opacity: 0.8
                radius: 24
                x : -20
                y : 280
                visible: false

                Text {
                    anchors.centerIn: parent
                    font.family: fontSystem.getContentFont.name
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 14
                    text: qsTr("Unknown")
                    color: "#ffffff"
                }
            }
        }
    }

    TapHandler {
        id: tapHandler
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: {
            if(addStory) {
                addStoryPage.open();
            }
            userStory.setAvatar = url
            userStory.setUsername = userNameString;
            userStory.open()
            userStory.hasUserStory = avatarHasStory
        }
    }
}
