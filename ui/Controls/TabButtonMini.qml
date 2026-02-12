// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as T
import QtQuick.Effects

import GenyConnect 1.0

T.TabButton {

    id:control

    property string title
    property string description
    property string setIcon : ""

    text: title

    contentItem: ColumnLayout {
        Text {
            width: parent.width
            Layout.fillWidth: true;
            font.family: FontSystem.getAwesomeRegular.name
            font.pixelSize: Typography.h3
            font.weight:  Font.Normal
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: enabled ? 1.0 : 0.3
            color: checked
                   ? Colors.staticPrimary
                   : (enabled ? Colors.textPrimary : Colors.textMuted)

            text: setIcon
            visible: setIcon ? true : false
        }

        Text {
            width: parent.width
            Layout.fillWidth: true;
            font.family: FontSystem.getContentFontRegular.name
            font.pixelSize: Typography.t2
            font.weight:  Font.Normal
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: enabled ? 1.0 : 0.3
            color: checked
                   ? Colors.staticPrimary
                   : (enabled ? Colors.textPrimary : Colors.textMuted)
            text: control.text
        }
    }

    background: ColumnLayout {
        anchors.fill: parent
        spacing: 0
        VerticalSpacer { }
        Rectangle {
            Layout.minimumWidth: 86
            implicitHeight: 64
            radius: 5

            RectangularShadow {
                width: 64
                height: 64
                blur: 64
                spread: 24
                offset.x: 5
                offset.y: -5
                anchors.centerIn: parent
                color: control.checked ? Colors.primaryBack : "transparent"
                opacity: 0.5

                Behavior on color {
                    ColorAnimation {
                        duration: Animations.normal
                        easing.type: Easing.InOutQuad
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Animations.normal
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            color: control.checked
                   ? Colors.primaryBack
                   : Colors.lightMode ? Qt.lighter(Colors.backgroundHovered, 1.6) : Qt.darker(Colors.backgroundHovered, 1.6)

            opacity: control.checked
                     ? 1
                     : control.hovered
                       ? 1
                       : 0

            Behavior on color {
                ColorAnimation {
                    duration: Animations.normal
                    easing.type: Easing.InOutQuad
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Animations.normal
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
