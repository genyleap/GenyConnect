// Copyright (C) 2026 Genyleap.
// Copyright (C) 2026 Kambiz Asadzadeh
pragma Singleton
import QtQuick

Item {

    property alias getAwesomeBrand: fontAwesomeBrand
    property alias getAwesomeRegular: fontAwesomeRegular
    property alias getAwesomeLight: fontAwesomeRegular
    property alias getAwesomeSolid: fontAwesomeSolid
    property alias getContentFont: contentFontRegular
    property alias getContentFontRegular: contentFontRegular
    property alias getContentFontMedium: contentFontRegular
    property alias getFontSize: fontSize

    QtObject {
        id: fontSize
        readonly property int       h1 : 32
        readonly property int       h2 : 24
        readonly property double    h3 : 18.72
        readonly property int       h4 : 16
        readonly property double    h5 : 13.28
        readonly property double    h6 : 10.72

        readonly property int content : 14
    }

    FontLoader {
        id: fontAwesomeBrand
        source: "qrc:/ui/Resources/fonts/fa-brands-400.woff2"
    }

    FontLoader {
        id: fontAwesomeRegular
        source: "qrc:/ui/Resources/fonts/fa-solid-900.woff2"
    }


    FontLoader {
        id: fontAwesomeSolid
        source: "qrc:/ui/Resources/fonts/fa-solid-900.woff2"
    }

    FontLoader {
        id: contentFontRegular
        source: "qrc:/ui/Resources/fonts/Farhang2-Regular.ttf"
    }

}
