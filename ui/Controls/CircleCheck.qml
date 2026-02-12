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
        Layout.fillWidth: false
        spacing: 5

        Item { width: 5; }

        T.CheckBox {
            id: control
            checked: value
            enabled: isEnable
            implicitWidth: 26
            implicitHeight: 26

            indicator: Rectangle {
                width: appStyle.h2
                height: appStyle.h2
                x: control.leftPadding
                y: parent.height / 2 - height / 2
                radius: width
                color: "transparent"
                border.color: {
                    if(isEnable) {
                        control.checked ? appStyle.borderFocused : appStyle.borderActivated
                    } else {
                        appStyle.borderDeactivated
                    }
                }

                border.width: control.checked ? false : true

                Behavior on border.color {
                    ColorAnimation {
                        duration: 200
                    }
                }

                Text {
                    anchors.centerIn: parent
                    font.family: fontSystem.getAwesomeSolid.name
                    font.pixelSize: appStyle.h2
                    text: control.checked ? "\uf058" : ""
                    font.bold: true
                    font.weight: control.checked ? Font.Bold : Font.Normal
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    color: {
                        if(isEnable) {
                            control.checked ? appStyle.secondry : appStyle.foregroundActivated
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

        HorizontalSpacer { }
    }
}
