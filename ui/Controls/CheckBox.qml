// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Controls.Basic as T
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts

ColumnLayout {

    property var uId;
    property var parentUid;
    property string title;
    property string note;
    property string desc;
    property bool value : false
    property string placeHolder;
    property string alertType;
    property bool isEnable: true
    property bool hasNote : true

    property bool language  : false
    property bool mobile    : false
    property bool email     : false
    property alias options  : control
    property alias checked  : control.checked

    property bool hasError : false
    property bool hasDone : false
    property bool hasCheck : false
    property int getPrice : 0

    property bool minimalModel : false

    signal editCompleted;

    width: parent.width
    Layout.fillWidth: true;
    spacing: 5

    RowLayout {
        width: parent.width
        Layout.fillWidth: true
        spacing: 5

        Item { width: 5; }

        T.CheckBox {
            id: control
            checked: value
            enabled: isEnable
            implicitWidth: 26
            implicitHeight: 26

            indicator: Rectangle {
                width: 26
                height: 26
                x: control.leftPadding
                y: parent.height / 2 - height / 2
                radius: appStyle.radius
                color: "transparent"
                border.color: {
                    if(isEnable) {
                        control.checked ? appStyle.borderFocused : appStyle.borderActivated
                    } else {
                        appStyle.borderDeactivated
                    }
                }

                border.width: 2

                Behavior on border.color {
                    ColorAnimation {
                        duration: 200
                    }
                }

                Text {
                    x: 7
                    y: 7
                    font.family: fontSystem.getAwesomeSolid.name
                    font.pixelSize: appStyle.t1
                    text: control.checked ? "\uf00c" : ""
                    font.weight: control.checked ? Font.Bold : Font.Normal
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    color: {
                        if(isEnable) {
                            control.checked ? appStyle.primary : appStyle.foregroundActivated
                        } else {
                            appStyle.foregroundDeactivated
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }
            }

        }

        Text {
            font.family: fontSystem.getContentFont.name
            font.pixelSize: appStyle.t1
            text: title
            opacity: isEnable ? 1.0 : 0.3
            color: {
                if(isEnable) {
                    appStyle.foregroundActivated
                } else {
                    appStyle.foregroundDeactivated
                }
            }
            leftPadding: 5

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }
        }

        Text {
            id: noteIcon
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            font.family: fontSystem.getAwesomeRegular.name
            font.weight: Font.Light
            font.pixelSize: appStyle.h6
            color: appStyle.foregroundActivated
            text: "\uf05a"
            visible: hasNote

            MouseArea {
                anchors.fill: noteIcon
                preventStealing: true
                onClicked: {
                }
            }
        }

        HorizontalSpacer { }
    }

    RowLayout {

        visible: minimalModel ? true : false

        Item { width: 1; }

        Text {
            text: note
            fontSizeMode: Text.Fit
            font.family: fontSystem.getContentFont.name
            Layout.fillWidth: true;
            font.pixelSize: appStyle.t2
            font.weight: Font.Light
            Layout.fillHeight: true
            font.bold: false
            opacity: isEnable ? 1.0 : 0.3
            color: appStyle.foregroundDeactivated
            visible: note ? true : false
            wrapMode: Text.WordWrap
        }

        Item { width: 1; }

    }

    Text {
        id: alertMessage
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        topPadding: 2
        bottomPadding: 2
        rightPadding: 10
        leftPadding: 10
        Layout.fillWidth: true;
        font.family: fontSystem.getContentFont.name
        font.pixelSize: 10
        color: "#f23"
        visible: false

        property int count: 0
        property int minX: 10
        property int maxX:  -1

    }
}
