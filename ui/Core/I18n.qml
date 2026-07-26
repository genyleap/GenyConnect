pragma Singleton
import QtQuick
import "../Translations/catalogs.js" as TranslationCatalogs
import "../Translations/licenses.js" as LicenseCatalogs

QtObject {
    id: i18n

    // Codes are stable because the selected value is persisted in QSettings.
    readonly property var languages: [
        { code: "en", name: "English" },
        { code: "fa", name: "فارسی" },
        { code: "zh", name: "简体中文" },
        { code: "ru", name: "Русский" },
        { code: "tr", name: "Türkçe" },
        { code: "az", name: "Azərbaycanca" },
        { code: "ar", name: "العربية" },
        { code: "fr", name: "Français" },
        { code: "de", name: "Deutsch" }
    ]

    property string language: "en"
    readonly property bool isRtl: ["fa", "ar", "he", "ur"].indexOf(language) >= 0
    readonly property string localeName: language === "zh" ? "zh_CN" : language
    // Compiled into the QML module. Avoid XMLHttpRequest for qrc resources:
    // its state machine differs between Qt platforms and can reject status reads.
    readonly property var catalogs: TranslationCatalogs.catalogs || ({})
    readonly property bool catalogsReady: Object.keys(catalogs).length === 8
    readonly property var measurementUnits: [
        "GB/s", "MB/s", "KB/s", "B/s", "Gbps", "Mbps", "Kbps", "bps",
        "TB", "GB", "MB", "KB", "B", "ms", "s"
    ]

    function languageIndex(code) {
        for (let index = 0; index < languages.length; ++index) {
            if (languages[index].code === code)
                return index
        }
        return 0
    }

    function languageName(code) {
        return languages[languageIndex(code)].name
    }

    function t(source, replacements) {
        // Reading language makes every QML binding calling t() reactive.
        const activeLanguage = language
        let result = String(source === undefined || source === null ? "" : source)
        if (activeLanguage !== "en") {
            const catalog = catalogs[activeLanguage]
            if (catalog && catalog[result] !== undefined)
                result = catalog[result]
        }
        if (replacements !== undefined && replacements !== null) {
            const values = Array.isArray(replacements) ? replacements : [replacements]
            for (let index = 0; index < values.length; ++index)
                result = result.split("%" + (index + 1)).join(String(values[index]))
        }
        return localizeDisplay(result)
    }

    function localizeDigits(value) {
        let result = String(value === undefined || value === null ? "" : value)
        const digits = language === "fa" ? "۰۱۲۳۴۵۶۷۸۹"
                     : language === "ar" ? "٠١٢٣٤٥٦٧٨٩"
                     : ""
        if (digits.length === 10)
            result = result.replace(/[0-9]/g, function(digit) { return digits.charAt(Number(digit)) })
        return result
    }

    function localizeUnits(value) {
        let result = String(value === undefined || value === null ? "" : value)
        if (language === "en")
            return result
        const catalog = catalogs[language] || ({})
        for (let index = 0; index < measurementUnits.length; ++index) {
            const unit = measurementUnits[index]
            const translated = catalog[unit]
            if (!translated || translated === unit)
                continue
            const escaped = unit.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
            if (result.trim() === unit) {
                result = result.replace(unit, translated)
                continue
            }
            const matcher = new RegExp("([0-9۰-۹٠-٩][ \\t]*)" + escaped + "(?=$|[ \\t/،,.])", "g")
            result = result.replace(matcher, function(match, prefix) { return prefix + translated })
        }
        return result
    }

    function localizeDisplay(value) {
        return localizeDigits(localizeUnits(value))
    }

    // Unicode directional isolates keep profile names, versions, addresses and
    // protocol identifiers stable inside Persian/Arabic sentences.
    function ltr(value) {
        const raw = String(value === undefined || value === null ? "" : value)
        const digitLocalized = localizeDigits(raw)
        const localized = localizeUnits(digitLocalized)
        // A translated Persian/Arabic unit is natural RTL content and must not
        // be forced into an LTR isolate. Technical identifiers still are.
        if (isRtl && (localized !== digitLocalized || /[\u0600-\u06ff]/.test(localized)))
            return localized
        return "\u2066" + localized + "\u2069"
    }

    function formatWindowTitle(appName, version, osName) {
        const localizedName = t(appName)
        const displayedName = localizedName === appName ? ltr(localizedName) : localizedName
        return t("%1 (Build %2) - %3", [displayedName, ltr(version), ltr(osName)])
    }

    function localizedLicense(originalEnglish) {
        if (language === "en")
            return String(originalEnglish || "")
        const translations = LicenseCatalogs.licenses || ({})
        return localizeDigits(translations[language] || String(originalEnglish || ""))
    }
}
