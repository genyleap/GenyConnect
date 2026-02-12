// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

ColumnLayout {

    property string title;
    property string icon : "";
    property string note;
    property alias value : control.text;
    property string placeHolder : "Send message";
    property string alertType;
    property bool classicTitle : true
    property bool classicMode : true
    property bool transparentMode : true
    property bool hasVisibleCheck : false

    QtObject {
        id: internalOptions
        property bool hidden : false;
    }

    property bool isValid : false

    property var digit

    function toLatinDigits(s){
        var a=["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        var p=["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"]
        for(var i=0;i<10;i++){
            s=replaceAll(s, a[i], i);
            s=replaceAll(s, p[i], i);
        }
        return s;
    }

    //replaceFunction
    function replaceAll(str, find, replace) {
        return str.replace(new RegExp(find, 'g'), replace);
    }

    //Fix number function
    function fixNumber(value){
        var separator=",";
        value=toLatinDigits(value.toString());
        value=replaceAll(value, separator, "");
        return value.replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1"+separator);
    }

    property bool language  : false
    property bool mobile    : false
    property bool email     : false
    property alias options  : control
    property bool hasError : false
    property bool hasDone : false
    property bool isMoney : false
    property bool isUrl : false
    property string alert : ""

    property int getPtValInt64Min : 0
    property int getPtValInt64Max : 0

    signal editCompleted;

    Layout.fillWidth: true;

    spacing: 2

    Item { height: 1; }

    RowLayout {

        width: parent.width
        Layout.fillWidth: true
        visible: classicTitle

        Item { width: 1; }

        Text {
            text: title
            font.family: fontSystem.getContentFont.name
            Layout.fillWidth: false;
            font.pixelSize: appStyle.t1
            color: appStyle.foregroundActivated
        }

        Item { width: 1; }
    }

    // Control
    TextField {
        id:control
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        rightPadding: icon || hasError ? appRootObjects.isLeftToRight ? 20 : 30 : 20
        leftPadding: icon || hasError ? 30 : 20
        topPadding: classicMode ? 8 : 0
        Layout.fillWidth: true;
        font.family: fontSystem.getContentFont.name
        font.pixelSize: appStyle.paragraph
        placeholderText: classicTitle ? placeHolder : title
        cursorVisible: activeFocus
        color: transparentMode? appStyle.accent : appStyle.foregroundActivated
        horizontalAlignment: appRootObjects.isRightToLeft ? Text.AlignRight : Text.AlignLeft

        onAccepted: {
            control.focus = false
        }

        onTextChanged: {
            if(isMoney) {
                text = fixNumber(text);
            }
        }

        onEditingFinished: {

        }

        onTextEdited: {

        }

        placeholderTextColor: transparentMode ? appStyle.accent : ppStyle.foregroundDeactivated

        background: Rectangle {
            id:back
            color: transparentMode ? "transparent" : appStyle.backgroundActivated
            height: 36
            border.width: 1
            border.color: classicMode ? appStyle.borderFocused : "transparent"
            radius: width
            implicitHeight: 36

            RowLayout {

                width: parent.width
                Layout.fillWidth: true

                Item { width: 5; }

                Text {
                    id: textIcon
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    visible: icon
                    font.family: fontSystem.getAwesomeRegular.name
                    font.pixelSize: appStyle.h4
                    color: appStyle.primary
                    text: icon
                }

                Text {
                    id: validationIcon
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    visible: hasError
                    font.family: fontSystem.getAwesomeRegular.name
                    font.pixelSize: appStyle.t1
                    color: appStyle.error
                    text: hasError ? "\uf06a" : "\uf06a"
                }

                HorizontalSpacer { }

                Text {
                    id: visibleIcon

                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    visible: hasVisibleCheck
                    font.family: fontSystem.getAwesomeRegular.name
                    font.pixelSize: appStyle.t1
                    color: internalOptions.hidden ? appStyle.primary : appStyle.foregroundDeactivated
                    text: internalOptions.hidden ? "\uf06e" : "\uf070"

                    MouseArea {
                        id: eyeMouseArea
                        anchors.fill: parent
                        onClicked: {
                            if(internalOptions.hidden) {
                                internalOptions.hidden = false;
                                control.echoMode = TextInput.Password
                            } else {
                                internalOptions.hidden = true;
                                control.echoMode = TextInput.Normal
                            }
                        }
                    }
                }

                Item { width: 5; }
            }
        }
    }

    HorizontalSpacer { }

    Rectangle {
        width: parent.width
        Layout.fillWidth: true
        height: 2
        visible: !classicMode
        color: control.focus ? appStyle.borderFocused :  appStyle.borderActivated
        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }
    }

    //Url
    RowLayout {

        id: urlRow

        visible: false

        Item { width: 4; }

        Text {
            id: urlPreview
            fontSizeMode: Text.Fit
            font.family: fontSystem.getContentFont.name
            Layout.fillWidth: true;
            font.pixelSize: appStyle.t2
            font.weight: Font.Light
            Layout.fillHeight: true
            font.bold: false
            color: isValid ? appStyle.success : appStyle.error
            wrapMode: Text.WordWrap
        }

        Item { width: 4; }

    }

    //Note
    RowLayout {

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
            color: appStyle.foregroundDeactivated
            visible: note ? true : false
            wrapMode: Text.WordWrap
        }

        Item { width: 1; }

    }

    //Alert
    Text {
        id: alertMessage
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        topPadding: 0
        bottomPadding: 2
        rightPadding: 10
        leftPadding: 10
        text: alert
        Layout.fillWidth: true;
        font.family: fontSystem.getContentFont.name
        font.pixelSize: 10
        color: appStyle.error

        property int count: 0
        property int minX: 10
        property int maxX:  -1

    }


}
