// Copyright (C) 2026 Genyleap.
// Copyright (C) 2026 Kambiz Asadzadeh
pragma Singleton
import QtQuick

Item {
    property alias getAwesomeBrand: fontAwesomeBrand
    property alias getAwesomeRegular: fontAwesomeRegular
    property alias getAwesomeLight: fontAwesomeRegular
    property alias getAwesomeSolid: fontAwesomeSolid

    readonly property bool usePersianArabicFont: I18n.language === "fa" || I18n.language === "ar"
    readonly property var getContentFont: usePersianArabicFont ? vazirmatnRegular : contentFontRegular
    readonly property var getContentFontRegular: usePersianArabicFont ? vazirmatnRegular : contentFontRegular
    readonly property var getContentFontMedium: usePersianArabicFont ? vazirmatnMedium : contentFontRegular
    readonly property var getContentFontBold: usePersianArabicFont ? vazirmatnBold : contentFontBold
    property alias getFontSize: fontSize

    readonly property string contentFontFamily:
        getContentFontRegular.status === FontLoader.Ready && getContentFontRegular.name.length > 0
            ? getContentFontRegular.name
            : Qt.application.font.family

    readonly property string contentBoldFontFamily:
        getContentFontBold.status === FontLoader.Ready && getContentFontBold.name.length > 0
            ? getContentFontBold.name
            : contentFontFamily

    readonly property string technicalFontFamily:
        contentFontRegular.status === FontLoader.Ready && contentFontRegular.name.length > 0
            ? contentFontRegular.name
            : Qt.application.font.family

    QtObject {
        id: fontSize

        readonly property int h1: 32
        readonly property int h2: 24
        readonly property double h3: 18.72
        readonly property int h4: 16
        readonly property double h5: 13.28
        readonly property double h6: 10.72

        readonly property int content: 14
    }

    FontLoader {
        id: fontAwesomeBrand
        source: "qrc:/ui/Resources/fonts/fa-brands-400.otf"
    }

    FontLoader {
        id: fontAwesomeRegular
        source: "qrc:/ui/Resources/fonts/fa-solid-900.otf"
    }

    FontLoader {
        id: fontAwesomeSolid
        source: "qrc:/ui/Resources/fonts/fa-solid-900.otf"
    }

    FontLoader {
        id: contentFontRegular
        source: "qrc:/ui/Resources/fonts/Inter-Regular.ttf"
    }

    FontLoader {
        id: contentFontBold
        source: "qrc:/ui/Resources/fonts/Inter-Bold.ttf"
    }

    FontLoader {
        id: vazirmatnRegular
        source: "qrc:/ui/Resources/fonts/Vazirmatn-Regular.ttf"
    }

    FontLoader {
        id: vazirmatnMedium
        source: "qrc:/ui/Resources/fonts/Vazirmatn-Medium.ttf"
    }

    FontLoader {
        id: vazirmatnBold
        source: "qrc:/ui/Resources/fonts/Vazirmatn-Bold.ttf"
    }

    Component.onCompleted: {
        if (contentFontRegular.status === FontLoader.Error)
            console.warn("Failed to load Inter-Regular.ttf")

        if (contentFontBold.status === FontLoader.Error)
            console.warn("Failed to load Inter-Bold.ttf")

        if (vazirmatnRegular.status === FontLoader.Error
                || vazirmatnMedium.status === FontLoader.Error
                || vazirmatnBold.status === FontLoader.Error)
            console.warn("Failed to load one or more Vazirmatn fonts")
    }
}
