// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Item {
    width: parent.width;
    Layout.fillWidth: true
    height: 100

    ListModel {
        id: contactItem
        ListElement {
            source: "https://avatars.githubusercontent.com/u/4066299?v=4"
            fullname: "Kambiz Asadzadeh"
            addNew : false
            live: false
            story: false
            self: true
        }
        ListElement {
            source: "https://avatars.githubusercontent.com/u/105925065?s=200&v=4"
            fullname : "Genyleap"
            addNew : false
            live: false
            story: true
            self: false
        }
        ListElement {
            source: "https://avatars.githubusercontent.com/u/10933044?v=4"
            fullname : "Bjarne Stroustrup"
            addNew : false
            live: false
            story: true
            self: false
        }
        ListElement {
            source: "https://avatars.githubusercontent.com/u/1801526?v=4"
            fullname: "Herb Sutter"
            addNew : false
            live: true
            story: true
            self: false
        }
        ListElement {
            source: "https://avatars.githubusercontent.com/u/586816?v=4"
            fullname: "Arash Milani"
            addNew : false
            live: false
            story: true
            self: false
        }
        ListElement {
            source: "https://avatars.githubusercontent.com/u/1024025?v=4"
            fullname : "Linus Torvalds"
            addNew : false
            live: false
            story: true
            self: false
        }
        ListElement {
            source: "https://avatars.githubusercontent.com/u/6557263?v=4"
            fullname : "Hana Dusíková"
            addNew : false
            live: false
            story: true
            self: false
        }
        ListElement {
            source: "https://avatars.githubusercontent.com/u/177011?v=4"
            fullname : "Daniel Stenberg"
            addNew : false
            live: false
            story: true
            self: false
        }
    }

    ListView {
        id: listView
        width: parent.width;
        Layout.fillWidth: true
        orientation: Qt.Horizontal
        height: parent.height
        spacing: 10
        model: contactItem
        contentWidth: 320

        Component {
            id: contactsDelegate
            UserStory {
                name : fullname
                avatarUrl: source
                hasStory: story
                hasNoStory: addNew
                hasLive: live
                isSelf : self
            }
        }

        delegate: contactsDelegate
        focus: true
    }

}
