// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

import GenyConnect 1.0

//![GLOBAL/HOME]
Rectangle {

    width: parent.width
    height: 64
    Layout.fillWidth: true
    Layout.preferredHeight: 42
    Layout.minimumHeight: 42
    color: Colors.header

    property bool isBold : false

    ColumnLayout {

        width: parent.width
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: userStackLayout.currentIndex === 0 ? true : false

        VerticalSpacer { }

        Item { height: 5;}

        RowLayout {

            width: parent.width
            Layout.fillWidth: true

            Item { width: 10; }


            Text {
                font.family: FontSystem.getContentFontMedium.name
                font.pixelSize: Typography.h3
                font.weight: Font.Bold
                font.bold: true
                text: qsTr("Modern Social")
                color: Colors.foregroundActivated
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.fillWidth: true
            }

            ActionButton {
                id: directButton
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                setIcon: "\uf1d8"
                onClicked: {
                    rootStackViewMain.push(directPage)
                }
            }

            Item { width: 10; }

        }
    }

    ColumnLayout {

        width: parent.width
        Layout.fillWidth: true
        Layout.fillHeight: true

        Drawer {

            id: createDrawer
            width:  appRoot.width
            height: 310
            edge: Qt.BottomEdge
            interactive: true

            background: Rectangle {
                color: Colors.backgroundActivated
                radius: 25
                Rectangle {
                    width: parent.width
                    Layout.fillWidth: true
                    height: 25
                    anchors.bottom: parent.bottom
                }
            }

            contentItem: Flickable {
                id: flickable
                contentHeight: columnItem.height
                anchors.fill: parent
                interactive: false

                rebound: Transition {
                    NumberAnimation {
                        properties: "x,y"
                        duration: 500
                        easing.type: Easing.OutBounce
                    }
                }

                ColumnLayout {
                    id: columnItem
                    width: parent.width
                    Layout.fillWidth: true
                    spacing: 10

                    Item { height: 2; }

                    Rectangle {
                        width: 72
                        height: 4
                        radius: 25
                        color: Colors.borderActivated
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        text: "Create"
                    }

                    ListModel {
                        id: createMenuItem
                        ListElement {
                            title: "Reel"
                            icon: "\uf401"
                        }
                        ListElement {
                            title: "Post"
                            icon: "\uf5fd"
                        }
                        ListElement {
                            title: "Story"
                            icon: "\uf1da"
                        }
                        ListElement {
                            title: "Live"
                            icon: "\uf8dd"
                        }
                        ListElement {
                            title: "Guide"
                            icon: "\uf5da"
                        }
                    }

                    ListView {
                        width: parent.width
                        Layout.fillWidth: true
                        height: 220
                        model: createMenuItem
                        clip: true
                        interactive: false
                        spacing: 5
                        focus: true
                        delegate: Rectangle {
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                            width: parent.width
                            Layout.fillWidth: true
                            height: 42
                            color: mouseArea.containsPress ? Colors.backgroundHovered : Colors.backgroundActivated
                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
                            RowLayout {
                                width: parent.width
                                Layout.fillWidth: true
                                height: 42

                                Item { width: 15; }

                                Row {
                                    spacing: 10
                                    Text {
                                        font.family: FontSystem.getAwesomeRegular.name
                                        font.pixelSize: Typography.h4
                                        font.bold: false
                                        font.weight: Font.Normal
                                        text: icon
                                        color: Colors.foregroundActivated
                                    }
                                    Text {
                                        font.family: FontSystem.getContentFont.name
                                        font.pixelSize: Typography.h5
                                        font.bold: true
                                        font.weight: Font.Normal
                                        text: title
                                        color: Colors.foregroundActivated
                                    }
                                }

                                HorizontalSpacer { }
                            }


                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Colors.borderActivated
                                anchors.top: parent.top

                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                            }
                    }
                }
            }
        }
    }

    visible: userStackLayout.currentIndex === 4 ? true : false

    RowLayout {

        width: parent.width
        Layout.fillWidth: true
        spacing: 5

        Item { width: 15; }

        Text {
            font.family: FontSystem.getContentFontMedium.name
            font.pixelSize: Typography.h3
            font.weight: Font.Bold
            font.bold: true
            text: qsTr("Profile")
            color: Colors.foregroundActivated
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.fillWidth: true
        }

        ActionButton {
            id: addButton
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            setIcon: "\uf0fe"
            onClicked: {
                createDrawer.open()
            }
        }

        ActionButton {
            id: settingButton
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            setIcon: "\uf141"
            isBold: true
            onClicked: {
                rootStackViewMain.push(directPage)
            }
        }

        Item { width: 10; }

    }
}

}

