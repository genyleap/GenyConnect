// Copyright (C) 2026 Genyleap.
// Copyright (C) 2026 Kambiz Asadzadeh
pragma Singleton
import QtQuick

Item {
    // main.cpp registers each bundled font before creating the QML engine.
    // Keep the established .name interface without loading the same faces again
    // or changing font availability after labels have already been shaped.
    readonly property var registeredFamilies: typeof applicationFonts !== "undefined"
        ? applicationFonts : ({})

    function resolvedFamily(key, fallback) {
        const family = registeredFamilies[key]
        return typeof family === "string" && family.length > 0 ? family : fallback
    }

    function fontStatus(key) {
        return resolvedFamily(key, "").length > 0 ? FontLoader.Ready : FontLoader.Error
    }

    property alias getAwesomeBrand: fontAwesomeBrand
    property alias getAwesomeRegular: fontAwesomeSolid
    property alias getAwesomeLight: fontAwesomeSolid
    property alias getAwesomeSolid: fontAwesomeSolid

    readonly property bool usePersianArabicFont: I18n.language === "fa" || I18n.language === "ar"
    readonly property var getContentFont: getContentFontRegular
    readonly property var getContentFontRegular: usePersianArabicFont ? vazirmatnRegular : contentFontRegular
    readonly property var getContentFontMedium: usePersianArabicFont ? vazirmatnMedium : contentFontMedium
    readonly property var getContentFontSemiBold: usePersianArabicFont ? vazirmatnBold : contentFontSemiBold
    readonly property var getContentFontBold: usePersianArabicFont ? vazirmatnBold : contentFontBold
    readonly property var getTitleFont: getContentFontBold
    property alias getFontSize: fontSize

    readonly property string contentFontFamily: getContentFontRegular.name
    readonly property string contentBoldFontFamily: getContentFontBold.name
    readonly property string technicalFontFamily: contentFontRegular.name

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

    QtObject {
        id: fontAwesomeBrand
        readonly property string name: resolvedFamily("brands", Qt.application.font.family)
        readonly property int status: fontStatus("brands")
        readonly property url source: "qrc:/ui/Resources/fonts/fa-brands-400.otf"
    }

    QtObject {
        id: fontAwesomeSolid
        readonly property string name: resolvedFamily("icons", Qt.application.font.family)
        readonly property int status: fontStatus("icons")
        readonly property url source: "qrc:/ui/Resources/fonts/fa-solid-900.otf"
    }

    QtObject {
        id: contentFontRegular
        readonly property string name: resolvedFamily("regular", Qt.application.font.family)
        readonly property int status: fontStatus("regular")
        readonly property url source: "qrc:/ui/Resources/fonts/Inter-Regular.ttf"
    }

    QtObject {
        id: contentFontMedium
        readonly property string name: resolvedFamily("medium", contentFontRegular.name)
        readonly property int status: fontStatus("medium")
        readonly property url source: "qrc:/ui/Resources/fonts/Inter-Medium.ttf"
    }

    QtObject {
        id: contentFontSemiBold
        readonly property string name: resolvedFamily("semibold", contentFontMedium.name)
        readonly property int status: fontStatus("semibold")
        readonly property url source: "qrc:/ui/Resources/fonts/Inter-SemiBold.ttf"
    }

    QtObject {
        id: contentFontBold
        readonly property string name: resolvedFamily("bold", contentFontRegular.name)
        readonly property int status: fontStatus("bold")
        readonly property url source: "qrc:/ui/Resources/fonts/Inter-Bold.ttf"
    }

    QtObject {
        id: vazirmatnRegular
        readonly property string name: resolvedFamily("arabicRegular", contentFontRegular.name)
        readonly property int status: fontStatus("arabicRegular")
        readonly property url source: "qrc:/ui/Resources/fonts/Vazirmatn-Regular.ttf"
    }

    QtObject {
        id: vazirmatnMedium
        readonly property string name: resolvedFamily("arabicMedium", vazirmatnRegular.name)
        readonly property int status: fontStatus("arabicMedium")
        readonly property url source: "qrc:/ui/Resources/fonts/Vazirmatn-Medium.ttf"
    }

    QtObject {
        id: vazirmatnBold
        readonly property string name: resolvedFamily("arabicBold", vazirmatnRegular.name)
        readonly property int status: fontStatus("arabicBold")
        readonly property url source: "qrc:/ui/Resources/fonts/Vazirmatn-Bold.ttf"
    }
}
