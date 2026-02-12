import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import GenyConnect 1.0

Item {

    id: item

    width: 72
    height: 72

    property alias source: imageView.source

    property alias fillMode: imageView.fillMode

    property int setRadius : 25

    property bool isOnline : false

    property alias control : imageView

    property string setIcon : ""

    property alias controlArea : mouseArea

    property string codeName : ""

    property string previewFile : "";

    signal click;

    function basename(str)
    {
        return (String(str).slice(String(str).lastIndexOf("/")+1))
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
        radius: item.setRadius
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
        cache: true
        Rectangle {
            width: 200
            height: 48
            color: "#0f1122"
            border.width: 1
            border.color: "#ccc"
            opacity: 0.8
            radius: item.setRadius
            x : -20
            y : 280
            visible: false

            Text {
                anchors.centerIn: parent
                font.family: FontSystem.getContentFont.name
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 14
                text: qsTr("Unknown")
                color: "#ffffff"
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: "transparent"

        OpacityMask {

            anchors.fill: parent
            maskSource: circleMask
            source: imageView

            Rectangle {
                id:front
                anchors.fill: parent
                anchors.margins: 1
                radius: width
                color: "transparent"

                Text {
                    visible: setIcon && source.toString() === "" ? true : false
                    font.family: FontSystem.getAwesomeRegular.name
                    font.pixelSize: Typography.h2
                    font.bold: false
                    font.weight: Font.Light
                    text: setIcon
                    color: Colors.foregroundDeactivated
                    anchors.centerIn: parent
                }

                BusyIndicator {
                    id: control
                    width: 32
                    height: 32
                    anchors.centerIn: parent
                    running: imageView.status === Image.Loading

                    contentItem: Item {
                        implicitWidth: 16
                        implicitHeight: 16

                        Item {
                            id: itemProgress
                            x: parent.width / 2 - 16
                            y: parent.height / 2 - 16
                            width: 32
                            height: 32
                            opacity: control.running ? 1 : 0

                            Behavior on opacity {
                                OpacityAnimator {
                                    duration: 250
                                }
                            }

                            RotationAnimator {
                                target: itemProgress
                                running: control.visible && control.running
                                from: 0
                                to: 360
                                loops: Animation.Infinite
                                duration: 1250
                            }

                            Repeater {
                                id: repeater
                                model: 3

                                Rectangle {
                                    x: itemProgress.width / 2 - width / 2
                                    y: itemProgress.height / 2 - height / 2
                                    implicitWidth: 5
                                    implicitHeight: 5
                                    radius: 2.5
                                    color: Colors.accent
                                    transform: [
                                        Translate {
                                            y: -Math.min(itemProgress.width, itemProgress.height) * 0.5 + 7
                                        },
                                        Rotation {
                                            angle: index / repeater.count * 360
                                            origin.x: 2.5
                                            origin.y: 2.5
                                        }
                                    ]
                                }
                            }
                        }
                    }

                    onRunningChanged: {
                        if (imageView.status == Image.Ready) {
                            front.visible = false
                        } else {
                            front.visible = true
                        }
                    }
                }

            }

        }

    }

    Item { Layout.fillHeight: true; }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: {
            click();
        }
    }
}
