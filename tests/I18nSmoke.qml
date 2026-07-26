import QtQuick
import "../ui/Core" as Core
import "../ui/Controls" as Controls

Item {
    visible: false

    Controls.ComboBox {
        id: directionCombo
        width: 180
        height: 40
        model: ["English", "فارسی"]
    }

    Timer {
        interval: 0
        running: true
        repeat: false

        onTriggered: {
            let failed = false
            const supported = ["en", "fa", "zh", "ru", "tr", "az", "ar", "fr", "de"]

            if (!Core.I18n.catalogsReady) {
                console.error("I18n smoke test: catalogs did not load")
                failed = true
            }

            for (let index = 0; index < supported.length; ++index) {
                const code = supported[index]
                Core.I18n.language = code
                const translated = Core.I18n.t("Settings")
                if (code !== "en" && translated === "Settings") {
                    console.error("I18n smoke test: missing runtime translation for", code)
                    failed = true
                }
            }

            Core.I18n.language = "fa"
            const persianExpectations = ({
                "Settings": "تنظیمات",
                "Interface": "رابط کاربری",
                "Language & Region": "زبان و منطقه",
                "Search by profile, country, or IP": "جست‌وجو بر اساس پروفایل، کشور یا آی‌پی",
                "Sort Stable": "مرتب‌سازی ثابت",
                "Protocol": "پروتکل",
                "Port": "درگاه",
                "Jitter": "نوسان تأخیر",
                "Download": "دانلود",
                "Upload": "آپلود",
                "Logs & Diagnostics": "گزارش‌ها و عیب‌یابی"
            })
            for (const source in persianExpectations) {
                if (Core.I18n.t(source) !== persianExpectations[source]) {
                    console.error("I18n smoke test: incorrect Persian translation for", source)
                    failed = true
                }
            }
            if (!Core.I18n.isRtl) {
                console.error("I18n smoke test: Persian translation or RTL state is invalid")
                failed = true
            }
            if (Core.I18n.t("GenyConnect") !== "جنی‌کانکت"
                    || Core.I18n.localizeDigits("Build 1.4.880") !== "Build ۱.۴.۸۸۰") {
                console.error("I18n smoke test: Persian product name or digits are invalid")
                failed = true
            }
            const localizedMeasurement = Core.I18n.localizeDisplay("1.30 MB / 154 ms / 2 Kbps")
            if (localizedMeasurement !== "۱.۳۰ مگابایت / ۱۵۴ میلی‌ثانیه / ۲ کیلوبیت بر ثانیه") {
                console.error("I18n smoke test: Persian measurement units are invalid", localizedMeasurement)
                failed = true
            }
            if (directionCombo.indicator.width !== 12 || directionCombo.indicator.x !== 10) {
                console.error("I18n smoke test: RTL ComboBox indicator geometry is invalid")
                failed = true
            }
            const rtlSelectedText = directionCombo.contentItem.children[0]
            if (!rtlSelectedText
                    || rtlSelectedText.horizontalAlignment !== Text.AlignRight
                    || rtlSelectedText.effectiveHorizontalAlignment !== Text.AlignRight) {
                console.error("I18n smoke test: RTL ComboBox text alignment is invalid")
                failed = true
            }
            if (directionCombo.contentItem.x !== directionCombo.leftPadding
                    || directionCombo.contentItem.width !== directionCombo.availableWidth
                    || rtlSelectedText.width !== directionCombo.availableWidth) {
                console.error("I18n smoke test: RTL ComboBox text does not occupy the available width",
                              directionCombo.contentItem.x,
                              directionCombo.contentItem.width,
                              directionCombo.availableWidth,
                              rtlSelectedText.width)
                failed = true
            }
            const persianLicense = Core.I18n.localizedLicense("GNU GENERAL PUBLIC LICENSE")
            if (persianLicense.indexOf("مجوز عمومی GNU") !== 0 || persianLicense.length < 10000) {
                console.error("I18n smoke test: Persian bundled license is unavailable")
                failed = true
            }

            Core.I18n.language = "ar"
            if (!Core.I18n.isRtl) {
                console.error("I18n smoke test: Arabic RTL state is invalid")
                failed = true
            }
            if (Core.I18n.localizeDigits("123") !== "١٢٣") {
                console.error("I18n smoke test: Arabic digits are invalid")
                failed = true
            }

            Core.I18n.language = "en"
            if (directionCombo.indicator.width !== 12 || directionCombo.indicator.x !== 158) {
                console.error("I18n smoke test: LTR ComboBox indicator geometry is invalid")
                failed = true
            }
            if (!rtlSelectedText
                    || rtlSelectedText.horizontalAlignment !== Text.AlignLeft
                    || rtlSelectedText.effectiveHorizontalAlignment !== Text.AlignLeft) {
                console.error("I18n smoke test: LTR ComboBox text alignment is invalid")
                failed = true
            }
            Core.I18n.language = "fa"
            if (directionCombo.indicator.width !== 12 || directionCombo.indicator.x !== 10) {
                console.error("I18n smoke test: ComboBox direction switching is unstable")
                failed = true
            }
            Core.I18n.language = "en"
            console.log(failed ? "I18n smoke test FAILED" : "I18n smoke test passed")
            Qt.exit(failed ? 1 : 0)
        }
    }
}
