// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import GenyConnect 1.0

RowLayout {

    id: rootFootMenu
    spacing: 0

    property var homeButton : discover_button

    Item { Layout.fillWidth: true; }

    function resetIndex() {
        discover_button.isSelected = true
        category_button.isSelected = false
        connection_button.isSelected = false
        create_button.isSelected = false
        profile_button.isSelected = false
    }

    FootButton {
        id: discover_button
        icon: "\uf015";
        title: "Home";
        isSelected: userStackLayout.currentIndex === 0 ? true : false
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

        onClick: {
            isSelected = true
            category_button.isSelected = false
            connection_button.isSelected = false
            create_button.isSelected = false
            profile_button.isSelected = false
            userStackLayout.currentIndex = 0
        }
    }

    Item { Layout.fillWidth: true; }

    FootButton {
        id:category_button
        icon: "\uf002";
        title: "Explorer";
        isSelected: userStackLayout.currentIndex === 1 ? true : false

        onClick: {
            discover_button.isSelected = false
            isSelected = true
            connection_button.isSelected = false
            create_button.isSelected = false
            profile_button.isSelected = false
            userStackLayout.currentIndex = 1
        }
    }

    Item { Layout.fillWidth: true; }

    FootButton {
        id:create_button
        icon: "\uf055";
        title: "Create";
        isSelected: userStackLayout.currentIndex === 2 ? true : false

        onClick: {
            discover_button.isSelected = false
            isSelected = true
            connection_button.isSelected = false
            category_button.isSelected = false
            profile_button.isSelected = false
            userStackLayout.currentIndex = 2
        }
    }

    Item { Layout.fillWidth: true; }

    FootButton {
        id:connection_button
        icon: "\uf004";
        title: "Likes";
        isSelected: userStackLayout.currentIndex === 3 ? true : false

        onClick: {
            discover_button.isSelected = false
            category_button.isSelected = false
            create_button.isSelected = false
            isSelected = true
            profile_button.isSelected = false
            userStackLayout.currentIndex = 3
        }
    }

    Item { Layout.fillWidth: true; }

    FootButton {
        id: profile_button
        icon: "\uf406";
        title: "Profile";
        isSelected: userStackLayout.currentIndex === 4 ? true : false

        onClick: {
            discover_button.isSelected = false
            category_button.isSelected = false
            connection_button.isSelected = false
            create_button.isSelected = false
            isSelected = true
            userStackLayout.currentIndex = 4
        }
    }

    Item { Layout.fillWidth: true; }
}


