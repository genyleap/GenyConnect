// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../Controls" as Controls

Drawer {
    id: drawer
    width: parent.width
    height: appRoot.height
    edge: Qt.BottomEdge
    z:2

    property bool hasBack : false

    ListModel {
        id: menuModel

        ListElement {
            icon: "\uf2bd"
            name: "My Account"
            url: 0
        }

        ListElement {
            icon: "\uf14e"
            name: "My Stores"
            url: 1
        }

        ListElement {
            icon: "\uf004"
            name: "Liked Post"
            url: 2
        }

        ListElement {
            icon: "\uf02d"
            name: "Rules"
            url: 3
        }

        ListElement {
            icon: "\uf21b"
            name: "Privacy"
            url: 4
        }

        ListElement {
            icon: "\uf2bb"
            name: "About US"
            url: 5
        }

        ListElement {
            icon: "\uf82d"
            name: "Support"
            url: 6
        }
    }

    ColumnLayout {

        width: parent.width
        Layout.fillWidth: true
        height: parent.height
        Layout.fillHeight: true

        spacing: 0

        Item { height: 30; }

        Item {
            id: rectangle
            width: parent.width
            Layout.fillWidth: true;
            height: 64

            RowLayout {

                width: parent.width
                Layout.fillWidth: true
                spacing: 5

                Item { width: 5; }

                Text {
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: Typography.h4
                    font.weight: Font.Bold
                    color: Colors.foregroundActivated
                    text: qsTr("Settings")
                }

                Item { Layout.fillWidth: true; }

                Item {

                    width: 32
                    height: 32
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                    Text {
                        text: hasBack ? "\uf054" :"\uf00d"
                        font.family: FontSystem.getAwesomeRegular.name
                        font.weight: Font.ExtraLight
                        font.bold: false
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Typography.h2
                        color: Colors.foregroundActivated
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if(!hasBack) {
                                drawer.close();
                            }
                        }
                    }
                }

                Item { width: 5; }
            }

        }

        Rectangle {
            width: parent.width
            Layout.fillWidth: true;
            height: 2
            color: Colors.borderActivated
        }

        ListView {
            id: listViewSide
            width: parent.width
            height: parent.height
            Layout.fillWidth: true
            Layout.fillHeight: true
            keyNavigationWraps: true
            clip: true
            focus: true
            ScrollBar.vertical: ScrollBar { }

            model: menuModel

            delegate: ColumnLayout {

                id: delegateItem
                width: parent.width
                Layout.fillWidth: true
                height: 72
                spacing: 2

                Controls.VerticalSpacer { }

                Rectangle {
                    width: parent.width
                    Layout.fillWidth: true
                    height: 72
                    color: ListView.isCurrentItem ?  Colors.backgroundHovered : Colors.backgroundActivated
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                    Behavior on color { ColorAnimation { duration: 200} }

                    RowLayout {

                        anchors.fill: parent

                        Item { width: 10; }

                        Item {

                            width: 40
                            visible: model.icon ? true : false
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                            Text {
                                anchors.fill: parent
                                font.family: FontSystem.getAwesomeRegular.name
                                font.pixelSize: Typography.h5
                                font.weight: Font.Light
                                text: model.icon
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                color: Colors.foregroundActivated
                                Behavior on color { ColorAnimation { duration: 500} }
                            }
                        }

                        Item { width: 5; }

                        Text {
                            width: parent.width
                            Layout.fillWidth: true
                            font.family: FontSystem.getContentFont.name
                            font.pixelSize: Typography.h6
                            font.weight: Font.Light
                            text: model.name
                            color: mouseAreaTwo.containsMouse ? Colors.primary : Colors.foregroundActivated
                            verticalAlignment: Text.AlignVCenter
                            Behavior on color { ColorAnimation { duration: 200} }

                            MouseArea {
                                id: mouseAreaTwo
                                anchors.fill: parent
                                hoverEnabled: true
                                preventStealing: false

                                onClicked: {
                                    if(model.url === 0) {
                                        stackLayout.forceActiveFocus()
                                        stackLayout.currentIndex = 2
                                        drawer.close();
                                    } else if(model.url === 1) {
                                        stackLayout.forceActiveFocus()
                                        stackLayout.currentIndex = 0
                                        drawer.close();
                                    } else if(model.url === 2) {
                                        myAds.open();
                                        drawer.close();
                                    } else if(model.url === 3) {
                                        likedAds.open();
                                        drawer.close();
                                    } else if(model.url === 4) {
                                        privacy.open();
                                        drawer.close();
                                    } else if(model.url === 5) {
                                        rules.open();
                                        drawer.close();
                                    } else if(model.url === 6) {
                                        privacy.open();
                                        drawer.close();
                                    } else if(model.url === 7) {
                                        about.open();
                                        drawer.close();
                                    } else if(model.url === 8) {
                                        support.open();
                                        drawer.close();
                                    }

                                }
                            }
                        }

                        Controls.HorizontalSpacer { }

                        Text {
                            width: parent.width
                            font.family: FontSystem.getAwesomeRegular.name
                            font.weight: Font.ExtraLight
                            font.pixelSize: Typography.h1
                            text: appRootObjects.isRightToLeft ? "\uf104" : "\uf105"
                            color: Colors.foregroundDeactivated
                            verticalAlignment: Text.AlignVCenter

                            Behavior on color { ColorAnimation { duration: 200} }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                preventStealing: true

                                onClicked: {
                                    //                                        if(modal.url === 1) {
                                    //                                            myAbrDrawer.open();
                                    //                                        }
                                }
                            }
                        }

                        Item { width: 10; }

                    }

                }

                Controls.VerticalSpacer { }

                Rectangle {
                    width: parent.width
                    Layout.fillWidth: true;
                    height: 1
                    color: Colors.borderActivated
                }
            }
        }

        Item { height: 30; }

        ColumnLayout {
            width: parent.width
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            Item { width: 5; }

            RowLayout {
                width: parent.width
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                Controls.Avatar {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    width: 24
                    height: 24
                    source: "qrc:/resources/images/medal.svg" //appIcon
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    font.family: FontSystem.getContentFont.name
                    font.pixelSize: Typography.h6
                    font.weight: Font.Bold
                    color: Colors.foregroundFocused
                    text: qsTr("Gorfeh")
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                font.family: FontSystem.getContentFont.name
                font.pixelSize: Typography.t2
                font.weight: Font.Light
                color: Colors.foregroundDeactivated
                text: qsTr("Software Version : 0.542.23")
            }

            Item { width: 5; }
        }

        Item { height: 15; }
    }

}
