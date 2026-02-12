// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Controls.Basic
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts

ColumnLayout {

    property string title;
    property string note;
    property alias value : control.text;
    property string placeHolder;
    property string alertType;
    property string icon : ""

    property bool language  : false
    property bool mobile    : false
    property bool email     : false
    property alias options  : control
    property bool isPassword : false

    property color colorLevelOne : "#ecf0f1"
    property color colorLevelTwo : "#ecf0f1"
    property color colorLevelThree : "#ecf0f1"
    property color colorLevelFour : "#ecf0f1"

    property bool hasError : false
    property bool hasDone : false
    property bool hasCheck : false

    property bool isMoney : false

    property string alert : ""

    signal editCompleted;

    function getValue() {
        if(!isMoney) {
            if(control.text) {
                return control.text;
            } else {
                return "";
            }
        } else {
            if(control.text) {
                return control.text;
            } else {
                return 0;
            }
        }
    }

    function checkPasswordStrength() {
        //if textBox is empty
        if(control.length===0){
            control.text = "";
            return;
        }

        //Regular Expressions
        var regex = new Array;
        regex.push("[A-Z]"); //For Uppercase Alphabet
        regex.push("[a-z]"); //For Lowercase Alphabet
        regex.push("[0-9]"); //For Numeric Digits
        regex.push("[$@$!%*#?&]"); //For Special Characters

        var passed = 0;

        //Validation for each Regular Expression
        for (var i = 0; i < regex.length; i++) {
            if((new RegExp (regex[i])).test(control.text)){
                passed++;
            }
        }

        //Validation for Length of Password
        if(passed > 2 && control.length > 8){
            passed++;
        }

        switch(passed){
        case 0:
            break;
        case 1:
            colorLevelOne =  appStyle.error
            colorLevelTwo = "#ecf0f1"
            colorLevelThree = "#ecf0f1"
            colorLevelFour = "#ecf0f1"
            break;
        case 2:
            colorLevelOne = "#f1c40f"
            colorLevelTwo = "#f1c40f"
            colorLevelThree = "#ecf0f1"
            colorLevelFour = "#ecf0f1"
            break;
        case 3:
            break;
        case 4:
            colorLevelOne = "#2ecc71"
            colorLevelTwo = "#2ecc71"
            colorLevelThree = "#2ecc71"
            colorLevelFour = "#ecf0f1"
            break;
        case 5:
            colorLevelOne = appStyle.success
            colorLevelTwo = appStyle.success
            colorLevelThree = appStyle.success
            colorLevelFour = appStyle.success
            break;
        }
    }

    function reset() {
        control.clear();
        moneyRow.visible = false;
        pricePreview.text = "";
    }

    function toLatinDigits(s){
        var a=["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        var p=["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"]
        for(var i=0;i<10;i++){
            s=s.replace(new RegExp(a[i],'g'),i)
            .replace(new RegExp(p[i],'g'),i)
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
        value=value.toString();
        value=replaceAll(toLatinDigits(value), separator, "");
        return value.replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1"+separator);
    }


    Layout.fillWidth: true;
    spacing: 5

    //Item { height: 1; }

    RowLayout {

        Item { width: 1; }

        Text {
            text: title
            font.family: fontSystem.getContentFont.name
            Layout.fillWidth: true;
            font.pixelSize: appStyle.h6
            font.bold: true
            color: "#33475b"
        }

        Item { width: 1; }

    }

    TextField {
        id:control
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        rightPadding: icon ? 40 : 10
        Layout.fillWidth: true;
        font.family: fontSystem.getContentFont.name
        font.pixelSize: appStyle.paragraph
        placeholderText: placeHolder
        cursorVisible: activeFocus
        selectByMouse: true

        onTextChanged: {
            if(isMoney) {
                text = fixNumber(text);
                pricePreview.text = CurrencyType.num2Persian(getValue()) + " - Rial";
                moneyRow.visible = true
            }
        }

        onTextEdited: {
            checkPasswordStrength();
            if(control.text === "") {
                colorLevelOne = "#ecf0f1"
                colorLevelTwo = "#ecf0f1"
                colorLevelThree = "#ecf0f1"
                colorLevelFour = "#ecf0f1"
            }
        }

        onAccepted: {
            control.focus = false
        }

        onEditingFinished: {
            if(isMoney) {
                pricePreview.text = CurrencyType.num2Persian(getValue()) + " - Rial";
                moneyRow.visible = true
            }
        }

        placeholderTextColor: appStyle.foregroundDeactivated

        background: Rectangle {
            id:back
            color: !control.enabled ? appStyle.borderActivated : appStyle.backgroundActivated
            height: Qt.platform.os === "android" || Qt.platform.os === "ios" ? 56 : 48
            implicitHeight: Qt.platform.os === "android" || Qt.platform.os === "ios" ? 56 : 48
            border.color: {
                if(hasError) {
                    appStyle.error
                } else if (!hasError && !control.focus) {
                    appStyle.borderActivated
                } else if (!hasError && control.focus) {
                  appStyle.primary
                }
            }
            border.width: 2
            radius: 4

            Behavior on border.color {
                ColorAnimation {
                    duration: 200
                }
            }

            RowLayout {

                anchors.fill: parent

                visible: icon ? true : false

                Item { width: 5; }

                Item {

                    width: 24
                    height: 24
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        font.family: fontSystem.getAwesomeRegular.name
                        font.pixelSize: appStyle.h6
                        color: appStyle.foregroundActivated
                        text: icon
                    }
                }

                HorizontalSpacer { }

            }

        }

    }

    RowLayout {

        id: moneyRow

        visible: false

        Item { width: 1; }

        Text {
            id: pricePreview
            fontSizeMode: Text.Fit
            font.family: fontSystem.getContentFont.name
            Layout.fillWidth: true;
            font.pixelSize: appStyle.t2
            font.weight: Font.Light
            Layout.fillHeight: true
            font.bold: false
            color: appStyle.error
            wrapMode: Text.WordWrap
        }

        Item { width: 1; }

    }

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

    RowLayout {
        id: passwordLevelRow
        width: parent.width
        Layout.fillWidth: true
        visible: isPassword ? true : false

        Rectangle {
            id: levelOne
            width: 32
            height: 2
            color: colorLevelOne
        }
        Rectangle {
            id: levelTwo
            width: 32
            height: 2
            color: colorLevelTwo
        }
        Rectangle {
            id: levelThree
            width: 32
            height: 2
            color: colorLevelThree
        }
        Rectangle {
            id: levelFour
            width: 32
            height: 2
            color: colorLevelFour
        }

        HorizontalSpacer { }
    }

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
        visible: {
            if(getValue() === 0) {
                hasError ? true : false
            } else {
                false
            }
        }
        property int count: 0
        property int minX: 10
        property int maxX:  -1

    }
}
