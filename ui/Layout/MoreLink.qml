// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

import "../Controls" as Controls

Drawer {

    id: drawer
    width:  appRoot.width
    height: 186
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
        anchors.margins: 10
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
            Layout.margins: 10
            spacing: 10

            Item { height: 2; }

            Rectangle {
                width: 72
                height: 4
                radius: 25
                color: Colors.borderActivated
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            }

            RowLayout {
                width: parent.width
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                Controls.LinkButton {
                    icon: "\uf14d"
                    title: "Share"
                }

                Controls.LinkButton {
                    icon: "\uf0c1"
                    title: "Link"
                }

                Controls.LinkButton {
                    icon: "\uf02e"
                    title: "Save"
                }

                Controls.LinkButton {
                    icon: "\uf029"
                    title: "QRCode"
                }
            }

            Controls.Button {
                text: "Report"
                style: Colors.error
                onClicked: {
                    drawer.close();
                }
            }
        }
    }
}
