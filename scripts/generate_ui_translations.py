#!/usr/bin/env python3
"""Extract user-facing QML strings and update the runtime JSON catalogs.

The script keeps reviewed translations, translates only newly discovered strings,
and fails if a locale is incomplete. It intentionally uses the English QML text as
the stable catalog key so adding a new label requires no numeric ID bookkeeping.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import json
import re
import time
import unicodedata
import urllib.parse
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
UI_ROOT = ROOT / "ui"
CATALOG_ROOT = UI_ROOT / "Translations"
BUNDLED_CATALOG = CATALOG_ROOT / "catalogs.js"
LOCALES = {
    "fa": "fa",
    "zh": "zh-CN",
    "ru": "ru",
    "tr": "tr",
    "az": "az",
    "ar": "ar",
    "fr": "fr",
    "de": "de",
}
SEPARATOR = "<<<GC_SPLIT_9F3A>>>"
QUOTED = re.compile(r'"((?:\\.|[^"\\])*)"')
EXPLICIT = re.compile(r'I18n\.t\(\s*"((?:\\.|[^"\\])*)"')
PRESENTATION_MARKERS = (
    "text:", "title:", "subtitle:", "label:", "description:",
    "placeholderText:", "hint:", "message:", '"text":', '"title":',
    '"subtitle":', '"label":', '"description":', '"name":', "return ",
)

EXTRA_SOURCES = {
    "Active", "Inactive", "Protected", "Unknown", "Normal", "Default",
    "Secure DNS", "DNS Leak", "IPv6 Leak", "Proxy Connected", "Error",
    "Checking", "Enabled", "Disabled", "Reduced", "Standard", "Backoff",
    "On", "Off", "Yes", "No", "Background", "Foreground", "Restricted",
    "Exempt", "Last Usage: %1", "Current %1", "Latest %1", "Build: v%1",
    "Memory: %1", "%1 (Build %2) - %3", "Connected %1", "Disconnected %1",
    "GenyConnect %1 is available. You're on %2.", "Visible %1", "Subscriptions %1/%2",
    "Group %1", "Profiles %1", "Best %1", "Worst %1", "Score %1",
    "Profile: %1", "Version %1", "Data Usage — %1", "Download: %1",
    "Upload: %1", "Total: %1", "Down %1", "Up %1", "Overall %1",
    "Groups: %1", "Setup Guide: %1", "Scope: %1", "Xray Core %1",
    "Route stability %1", "Ping Profiles", "Refresh Subscriptions",
    "Light", "Dark", "Partial Mask", "Auto", "Auto (Recommended)",
    "Route Latency", "Power Saver", "High Performance", "Best Latency",
    "Fallback", "Small", "Medium", "Large", "Current", "History",
    "GenyConnect", "<strong>GENY</strong>CONNECT", "Battery Friendly",
    "High Power", "Balanced", "Desktop", "Wi-Fi",
    "Stable stream-oriented transports usually wake the radio and CPU less often on mobile devices.",
    "Multiplexed or UDP-heavy transports can improve latency or throughput but may keep radios and timers active more often.",
    "Balanced transports trade compatibility and performance without intentionally increasing polling or keepalive pressure.",
    "Home and status panels show *.*.*.* or Endpoint hidden instead of visible IP details.",
    "Home and status panels keep enough context for troubleshooting while masking the precise address.",
    "Visible IP and endpoint details are shown normally.",
    "Apply system proxy for compatible apps.",
    "Unavailable on this runtime (system proxy control is not supported).",
    "Keep OS proxy unchanged and route manual proxy apps only.",
    "Recommended: uses route latency when available, with endpoint latency only as a fallback.",
    "Diagnostic mode: measures only the raw server endpoint and does not represent VPN route latency.",
    "Measures through the selected VPN/proxy path and represents real user experience.",
    "Measure Profiles Now", "Measure Current Group",
    "TUN mode does not change OS proxy settings. If connect fails, run app with elevated privileges.",
    "Mobile TUN uses VPN service permissions and native runtime bridge setup.",
    "Unofficial translation — the original English license is the legally authoritative text.",
    "Show Original English", "Show Translation",
    "bps", "Kbps", "Mbps", "Gbps", "B/s", "KB/s", "MB/s", "GB/s",
    "B", "KB", "MB", "GB", "TB", "ms", "s",
    "Captured lines: %1",
    "You are up to date (%1).", "Update available: %1",
    "No published release yet. Current version %1.",
    "Checking for updates...", "Update check failed.",
    "No version info in release feed.", "Install failed.",
    "Download unavailable.", "Download failed.", "Downloading update...",
    "Update downloaded, but release checksum is missing.",
    "Update downloaded. Open installer to continue.",
    "Open installer failed.", "Open installer blocked.",
    "Closing app and launching installer...",
    "This asset requires manual install. Opening installer...",
    "Install blocked.", "Opened package installer. Confirm update to continue.",
    "Waiting for Administrator approval to install update...",
    "Installing update and restarting...",
    "Base Mainnet", "GENY Token", "Best for long-term GenyConnect support.",
    "Stable support on Base.", "USD Coin (USDC)",
}

# Reviewed wording wins over machine-generated text. In particular, Persian uses
# native-script forms for mixed-direction abbreviations where that reads better.
OVERRIDES = {
    "fa": {
        "GenyConnect": "جنی‌کانکت",
        "<strong>GENY</strong>CONNECT": "جنی‌کانکت",
        "DNS": "دی‌ان‌اس",
        "Custom DNS": "دی‌ان‌اس سفارشی",
        "Secure DNS": "دی‌ان‌اس امن",
        "DNS Leak": "نشت دی‌ان‌اس",
        "IPv6 Leak": "نشت IPv6",
        "IP Address": "نشانی آی‌پی",
        "Last Usage: %1": "آخرین مصرف: %1",
        "Current %1": "نسخهٔ فعلی %1",
        "Latest %1": "جدیدترین نسخه %1",
        "Build: v%1": "ساخت: v%1",
        "Memory: %1": "حافظه: %1",
        "%1 (Build %2) - %3": "%1 (نسخهٔ %2) - %3",
        "Enjoying GenyConnect?": "از جنی‌کانکت راضی هستید؟",
        "If it helps, you can support development with a small donation.": "اگر جنی‌کانکت برایتان مفید است، می‌توانید با یک کمک کوچک از توسعهٔ آن حمایت کنید.",
        "Support": "حمایت",
        "Not now": "فعلاً نه",
        "Active": "فعال",
        "Inactive": "غیرفعال",
        "Protected": "محافظت‌شده",
        "Unknown": "نامشخص",
        "Normal": "عادی",
        "Default": "پیش‌فرض",
        "Proxy Connected": "پروکسی متصل است",
        "Error": "خطا",
        "Checking": "در حال بررسی",
        "Connection History": "تاریخچهٔ اتصال",
        "Traffic Overview": "نمای کلی ترافیک",
        "Session Info": "اطلاعات نشست",
        "Cache Management": "مدیریت حافظهٔ پنهان",
        "Custom DNS (optional, TUN mode)": "دی‌ان‌اس سفارشی (اختیاری، حالت TUN)",
        "Refresh Group": "به‌روزرسانی گروه",
        "Refresh Subscriptions": "به‌روزرسانی اشتراک‌ها",
        "UI Refresh": "نوسازی رابط کاربری",
        "FakeDNS Sniff": "پایش FakeDNS",
        "CPU": "پردازنده",
        "Ping Profiles": "سنجش تأخیر پروفایل‌ها",
        "Light": "روشن",
        "Dark": "تیره",
        "Partial Mask": "پوشش جزئی",
        "Auto": "خودکار",
        "Auto (Recommended)": "خودکار (پیشنهادی)",
        "Route Latency": "تأخیر مسیر",
        "Power Saver": "صرفه‌جویی انرژی",
        "High Performance": "کارایی بالا",
        "Best Latency": "بهترین تأخیر",
        "Fallback": "جایگزین",
        "Small": "کوچک",
        "Medium": "متوسط",
        "Large": "بزرگ",
        "Current": "جاری",
        "History": "تاریخچه",
        "Received %1": "دریافت‌شده: %1",
        "Last %1": "آخرین سرعت: %1",
        "Paused %1": "مکث: %1",
        "Paused (%1)": "مکث (%1)",
        "Segments %1": "بخش‌ها: %1",
        "Completed • Quality %1/100": "تکمیل شد • کیفیت %1 از ۱۰۰",
        "Quality %1/100": "کیفیت: %1 از ۱۰۰",
        "Progress %1%": "پیشرفت: %1٪",
        "Phase %1": "مرحله: %1",
        "DL %1 | UL %2": "دریافت %1 | ارسال %2",
        "Resolvers: %1": "حل‌کننده‌ها: %1",
        "Resolvers: default": "حل‌کننده‌ها: پیش‌فرض",
        "Source: %1": "منبع: %1",
        "IP Privacy": "حریم خصوصی آی‌پی",
        "Search by profile, country, or IP": "جست‌وجو بر اساس پروفایل، کشور یا آی‌پی",
        "Best in Group": "بهترین پروفایل گروه",
        "Add Profile": "افزودن پروفایل",
        "Sort Stable": "مرتب‌سازی ثابت",
        "Sort by Name": "مرتب‌سازی بر اساس نام",
        "Sort by Ping": "مرتب‌سازی بر اساس تأخیر",
        "Sort Ping": "مرتب‌سازی تأخیر",
        "Export All": "خروجی گرفتن از همه",
        "Remove Dead": "حذف پروفایل‌های ازکارافتاده",
        "Remove Subs": "حذف اشتراک‌ها",
        "Delete Others": "حذف سایر پروفایل‌ها",
        "Group": "گروه",
        "Visible %1": "%1 مورد نمایان",
        "Score %1": "امتیاز %1",
        "Worst %1": "بدترین %1",
        "Best %1": "بهترین %1",
        "Profiles %1": "%1 پروفایل",
        "Group %1": "گروه %1",
        "Subscriptions %1/%2": "اشتراک‌ها %1 از %2",
        "Auto Ping OFF": "سنجش خودکار: خاموش",
        "Auto Ping ON": "سنجش خودکار: روشن",
        "Total Traffic Units": "واحد حجم کل ترافیک",
        "bps": "بیت بر ثانیه",
        "Kbps": "کیلوبیت بر ثانیه",
        "Mbps": "مگابیت بر ثانیه",
        "Gbps": "گیگابیت بر ثانیه",
        "B/s": "بایت بر ثانیه",
        "KB/s": "کیلوبایت بر ثانیه",
        "MB/s": "مگابایت بر ثانیه",
        "GB/s": "گیگابایت بر ثانیه",
        "B": "بایت",
        "KB": "کیلوبایت",
        "MB": "مگابایت",
        "GB": "گیگابایت",
        "TB": "ترابایت",
        "ms": "میلی‌ثانیه",
        "s": "ثانیه",
        "Battery Friendly": "سازگار با باتری",
        "High Power": "پرمصرف",
        "Balanced": "متعادل",
        "Desktop": "رایانهٔ رومیزی",
        "Wi-Fi": "وای‌فای",
        "Stable stream-oriented transports usually wake the radio and CPU less often on mobile devices.": "پروتکل‌های پایدار و جریان‌محور معمولاً در دستگاه‌های همراه، رادیو و پردازنده را کمتر بیدار می‌کنند.",
        "Multiplexed or UDP-heavy transports can improve latency or throughput but may keep radios and timers active more often.": "پروتکل‌های چندبخشی یا متکی بر UDP می‌توانند تأخیر یا توان عملیاتی را بهتر کنند، اما ممکن است رادیو و زمان‌سنج‌ها را بیشتر فعال نگه دارند.",
        "Balanced transports trade compatibility and performance without intentionally increasing polling or keepalive pressure.": "پروتکل‌های متعادل میان سازگاری و کارایی تعادل برقرار می‌کنند، بی‌آنکه عمداً فشار بررسی دوره‌ای یا زنده‌نگه‌داشتن اتصال را افزایش دهند.",
        "Home and status panels show *.*.*.* or Endpoint hidden instead of visible IP details.": "در صفحهٔ اصلی و پنل‌های وضعیت، به‌جای جزئیات آشکار آی‌پی، *.*.*.* یا «نشانی پنهان است» نمایش داده می‌شود.",
        "Home and status panels keep enough context for troubleshooting while masking the precise address.": "در صفحهٔ اصلی و پنل‌های وضعیت، ضمن پنهان‌کردن نشانی دقیق، اطلاعات لازم برای عیب‌یابی حفظ می‌شود.",
        "Visible IP and endpoint details are shown normally.": "جزئیات آی‌پی و نشانی مقصد به‌طور کامل نمایش داده می‌شود.",
        "Apply system proxy for compatible apps.": "پروکسی سیستم برای برنامه‌های سازگار اعمال می‌شود.",
        "Unavailable on this runtime (system proxy control is not supported).": "در این محیط در دسترس نیست؛ کنترل پروکسی سیستم پشتیبانی نمی‌شود.",
        "Keep OS proxy unchanged and route manual proxy apps only.": "پروکسی سیستم‌عامل را تغییر ندهید و فقط برنامه‌هایی را که دستی تنظیم شده‌اند مسیریابی کنید.",
        "Recommended: uses route latency when available, with endpoint latency only as a fallback.": "پیشنهادی: در صورت امکان از تأخیر مسیر استفاده می‌کند و تأخیر نقطهٔ پایانی را فقط به‌عنوان جایگزین می‌سنجد.",
        "Diagnostic mode: measures only the raw server endpoint and does not represent VPN route latency.": "حالت عیب‌یابی: فقط نقطهٔ پایانی خام سرور را می‌سنجد و نشان‌دهندهٔ تأخیر مسیر وی‌پی‌ان نیست.",
        "Measures through the selected VPN/proxy path and represents real user experience.": "اندازه‌گیری از مسیر انتخاب‌شدهٔ وی‌پی‌ان یا پروکسی انجام می‌شود و تجربهٔ واقعی کاربر را نشان می‌دهد.",
        "Measure Profiles Now": "اکنون تأخیر پروفایل‌ها را بسنجید",
        "Measure Current Group": "اکنون تأخیر گروه فعلی را بسنجید",
        "TUN mode does not change OS proxy settings. If connect fails, run app with elevated privileges.": "حالت TUN تنظیمات پروکسی سیستم‌عامل را تغییر نمی‌دهد. اگر اتصال ناموفق بود، برنامه را با دسترسی مدیر اجرا کنید.",
        "Mobile TUN uses VPN service permissions and native runtime bridge setup.": "حالت TUN در موبایل از مجوز سرویس وی‌پی‌ان و پل بومی برنامه استفاده می‌کند.",
        "Unofficial translation — the original English license is the legally authoritative text.": "این ترجمه غیررسمی است؛ متن اصلی انگلیسی مجوز، مرجع حقوقی معتبر است.",
        "Show Original English": "نمایش متن اصلی انگلیسی",
        "Show Translation": "نمایش ترجمه",

        # Reviewed Persian product glossary and the screens most exposed to users.
        "Protocol": "پروتکل",
        "Port": "درگاه",
        " and Port ": " و درگاه ",
        "Enabled": "فعال",
        "Disabled": "غیرفعال",
        "Recommended": "پیشنهادی",
        "Test": "آزمایش",
        "Jitter": "نوسان تأخیر",
        "Download": "دانلود",
        "Upload": "آپلود",
        "Running...": "در حال اجرای آزمون...",
        "Running test": "آزمون در حال اجرا",
        "Gauge Range": "بازهٔ سرعت‌سنج",
        "Overall": "نتیجهٔ کلی",
        "Overall %1": "نتیجهٔ کلی: %1",
        "Overall average": "میانگین کل",
        "Speed estimate": "برآورد سرعت",
        "Speed Test": "آزمایش سرعت",
        "Test Size": "حجم آزمون",
        "Start Test": "شروع آزمون",
        "Measuring latency and jitter...": "در حال اندازه‌گیری تأخیر و نوسان آن...",
        "Measuring live download throughput...": "در حال اندازه‌گیری سرعت دانلود...",
        "Measuring live upload throughput...": "در حال اندازه‌گیری سرعت آپلود...",
        "Analyzing connection quality...": "در حال تحلیل کیفیت اتصال...",
        "Preparing diagnostics...": "در حال آماده‌سازی آزمون...",
        "Live download": "سرعت زندهٔ دانلود",
        "Live upload": "سرعت زندهٔ آپلود",
        "Latency probe": "سنجش تأخیر",
        "Current tunnel download rate": "سرعت فعلی دانلود در تونل",
        "Current tunnel upload rate": "سرعت فعلی آپلود در تونل",
        "Collecting response-time baseline": "در حال تعیین خط پایهٔ زمان پاسخ",
        "Collecting measurements": "در حال جمع‌آوری اندازه‌گیری‌ها",
        "Mean of final download and upload results": "میانگین نتایج نهایی دانلود و آپلود",
        "Run a diagnostics pass through the active VPN": "آزمون را از مسیر وی‌پی‌ان فعال اجرا کنید",
        "Latency": "تأخیر",
        "Quality": "کیفیت",
        "Route stability %1": "پایداری مسیر: %1",
        "Ready": "آماده",
        "Completed": "تکمیل‌شده",
        "Cancelled": "لغوشده",
        "Phase %1": "مرحله: %1",
        "DL %1 | UL %2": "دانلود %1 | آپلود %2",

        "DNS": "سامانهٔ نام دامنه",
        "Custom DNS": "سامانهٔ نام دامنهٔ سفارشی",
        "Secure DNS": "سامانهٔ نام دامنهٔ امن",
        "DNS Leak": "نشت سامانهٔ نام دامنه",
        "Custom DNS (optional, TUN mode)": "سامانهٔ نام دامنهٔ سفارشی (اختیاری در حالت TUN)",
        "Enter one resolver per line. Supports IPv4, IPv6, and DNS hostnames.": "در هر خط یک حل‌کننده وارد کنید. نشانی‌های IPv4 و IPv6 و نام میزبان سامانهٔ نام دامنه پشتیبانی می‌شوند.",
        "Resolvers: %1": "حل‌کننده‌ها: %1",
        "Resolvers: default": "حل‌کننده‌ها: پیش‌فرض",
        "Apply DNS": "اعمال تنظیمات نام دامنه",
        "Cloudflare": "کلاودفلر",
        "Google": "گوگل",
        "Quad9": "کواد۹",

        "Local Network Sharing": "اشتراک‌گذاری در شبکهٔ محلی",
        "LAN Sharing": "اشتراک‌گذاری شبکهٔ محلی",
        "Port": "درگاه",
        "Sharing On": "اشتراک‌گذاری روشن",
        "Sharing Off": "اشتراک‌گذاری خاموش",
        "Proxy is available on your LAN.": "پروکسی در شبکهٔ محلی شما در دسترس است.",
        "Your proxy is available to devices on your local network.": "پروکسی شما برای دستگاه‌های شبکهٔ محلی در دسترس است.",
        "Share your proxy on local Wi-Fi.": "پروکسی را از طریق وای‌فای محلی به اشتراک بگذارید.",
        "Enable this to share the proxy on your local network.": "برای اشتراک‌گذاری پروکسی در شبکهٔ محلی، این گزینه را فعال کنید.",
        "LAN Address (Host)": "نشانی شبکهٔ محلی (میزبان)",
        "Copy Address": "کپی نشانی",
        "Test Connection": "آزمایش اتصال",
        "Test with Host ": "آزمایش با میزبان ",
        "LAN proxy unavailable in this environment.": "پروکسی شبکهٔ محلی در این محیط در دسترس نیست.",
        "Review": "نیازمند بررسی",
        "Safe": "ایمن",
        "Devices on your LAN can connect.": "دستگاه‌های شبکهٔ محلی می‌توانند متصل شوند.",
        "Only devices on your LAN can connect.": "فقط دستگاه‌های شبکهٔ محلی شما می‌توانند متصل شوند.",
        "Phone": "تلفن همراه",
        "Laptop": "لپ‌تاپ",
        "Setup Guide": "راهنمای راه‌اندازی",
        "6 Steps": "۶ مرحله",
        "Connect both devices to the same Wi-Fi.": "هر دو دستگاه را به یک شبکهٔ وای‌فای متصل کنید.",
        "Open proxy/manual network settings.": "تنظیمات دستی پروکسی شبکه را باز کنید.",
        "Set proxy to Manual.": "حالت پروکسی را روی «دستی» قرار دهید.",
        "Enter Host:": "میزبان را وارد کنید:",
        "Enter Port:": "درگاه را وارد کنید:",
        "Test connection.": "اتصال را آزمایش کنید.",
        "Advanced Options": "تنظیمات پیشرفته",
        "Collapsed by default.": "به‌طور پیش‌فرض بسته است.",
        "Advanced controls visible.": "تنظیمات پیشرفته نمایش داده می‌شوند.",
        "Advanced controls hidden.": "تنظیمات پیشرفته پنهان هستند.",
        "Expanded": "باز",
        "Collapsed": "بسته",
        "Hide": "پنهان‌کردن",
        "Sharing": "اشتراک‌گذاری",
        "Bind Mode": "محدودهٔ دسترسی",
        "LAN Wide": "همهٔ شبکهٔ محلی",
        "Private LAN": "شبکهٔ محلی خصوصی",
        "Gateway": "دروازه",
        "Sharing enabled": "اشتراک‌گذاری فعال است",
        "Sharing disabled": "اشتراک‌گذاری غیرفعال است",
        "No private LAN IP found": "هیچ نشانی خصوصی در شبکهٔ محلی پیدا نشد",
        "Refresh": "به‌روزرسانی",
        "LAN Wide (0.0.0.0)": "تمام رابط‌های شبکه (0.0.0.0)",
        "Private LAN Only": "فقط شبکهٔ محلی خصوصی",
        "Full VPN Gateway / Hotspot": "دروازهٔ کامل وی‌پی‌ان / نقطهٔ اتصال",
        "Your proxy is available on the LAN.": "پروکسی شما در شبکهٔ محلی در دسترس است.",
        "Enable to share your proxy on local Wi-Fi.": "برای اشتراک‌گذاری پروکسی در وای‌فای محلی، این گزینه را فعال کنید.",
        "LAN proxy unavailable on this runtime.": "پروکسی شبکهٔ محلی در این محیط در دسترس نیست.",
        "Security: LAN Access Allowed": "امنیت: دسترسی شبکهٔ محلی مجاز است",
        "Security: LAN Connections Allowed": "امنیت: اتصال‌های شبکهٔ محلی مجاز هستند",
        "Security: Private LAN": "امنیت: شبکهٔ محلی خصوصی",
        "Security: Private LAN Only": "امنیت: فقط شبکهٔ محلی خصوصی",
        "Only devices on your local network can connect.": "فقط دستگاه‌های شبکهٔ محلی شما می‌توانند متصل شوند.",
        "Connect both devices to same Wi-Fi.": "هر دو دستگاه را به یک شبکهٔ وای‌فای متصل کنید.",
        "Host copied.": "نشانی میزبان کپی شد.",
        "Port copied.": "شمارهٔ درگاه کپی شد.",
        "Address copied.": "نشانی کپی شد.",
        "Test with Host %1 and Port %2.": "اتصال با میزبان %1 و درگاه %2 آزمایش شود.",
        "Use Host %1 and Port %2.": "از میزبان %1 و درگاه %2 استفاده کنید.",
        "Sharing enabled.": "اشتراک‌گذاری فعال است.",
        "Sharing disabled.": "اشتراک‌گذاری غیرفعال است.",
        "Experimental: Use only when you need full-device routing. Proxy mode is recommended first.": "آزمایشی: فقط زمانی استفاده کنید که مسیریابی کامل دستگاه لازم است. ابتدا حالت پروکسی پیشنهاد می‌شود.",
        "Not available on this platform runtime (Experimental).": "در این پلتفرم در دسترس نیست (قابلیت آزمایشی).",

        "Logs & Diagnostics": "گزارش‌ها و عیب‌یابی",
        "Captured lines: %1": "تعداد سطرهای ثبت‌شده: %1",
        "Enable logging to capture connection diagnostics.": "برای ثبت اطلاعات عیب‌یابی اتصال، گزارش‌گیری را فعال کنید.",
        "Open Viewer": "مشاهدهٔ گزارش‌ها",
        "Copy": "کپی",
        "Clear": "پاک‌کردن",

        "App Updates": "به‌روزرسانی برنامه",
        "You are up to date (%1).": "برنامه به‌روز است (نسخهٔ %1).",
        "Update available: %1": "نسخهٔ %1 آمادهٔ دریافت است.",
        "No published release yet. Current version %1.": "هنوز نسخه‌ای منتشر نشده است. نسخهٔ فعلی: %1.",
        "Checking for updates...": "در حال بررسی به‌روزرسانی...",
        "Update check failed.": "بررسی به‌روزرسانی ناموفق بود.",
        "No version info in release feed.": "اطلاعات نسخه در فهرست انتشار موجود نیست.",
        "Checking...": "در حال بررسی...",
        "Check Now": "بررسی به‌روزرسانی",
        "Install Update": "نصب به‌روزرسانی",
        "Open Installer": "بازکردن نصب‌کننده",
        "Install & Restart": "نصب و راه‌اندازی مجدد",
        "Download": "دانلود",
        "Release Page": "صفحهٔ انتشار",
        "Download unavailable.": "فایل به‌روزرسانی در دسترس نیست.",
        "Download failed.": "دریافت به‌روزرسانی ناموفق بود.",
        "Downloading update...": "در حال دریافت به‌روزرسانی...",
        "Update downloaded, but release checksum is missing.": "به‌روزرسانی دریافت شد، اما مقدار صحت‌سنج انتشار موجود نیست.",
        "Update downloaded. Open installer to continue.": "به‌روزرسانی دریافت شد. برای ادامه نصب‌کننده را باز کنید.",
        "Install failed.": "نصب ناموفق بود.",
        "Open installer failed.": "بازکردن نصب‌کننده ناموفق بود.",
        "Open installer blocked.": "بازکردن نصب‌کننده مسدود شد.",
        "Install blocked.": "نصب مسدود شد.",
        "Closing app and launching installer...": "در حال بستن برنامه و اجرای نصب‌کننده...",
        "Installing update and restarting...": "در حال نصب به‌روزرسانی و راه‌اندازی مجدد...",

        "Support GenyConnect": "حمایت از جنی‌کانکت",
        "Your donation helps us improve GenyConnect, maintain infrastructure, and grow the Geny ecosystem.": "کمک شما به بهبود جنی‌کانکت، نگهداری زیرساخت‌ها و رشد زیست‌بوم جنی کمک می‌کند.",
        "Base Mainnet": "شبکهٔ اصلی Base",
        "1. Choose Token": "۱. توکن را انتخاب کنید",
        "2. Choose Amount": "۲. مبلغ را انتخاب کنید",
        "GENY": "جنی",
        "GENY Token": "توکن جنی",
        "Best for long-term GenyConnect support.": "بهترین گزینه برای حمایت بلندمدت از جنی‌کانکت.",
        "Stable support on Base.": "روشی پایدار برای حمایت در شبکهٔ Base.",
        "You are donating": "مبلغ اهدایی شما",
        "Est. value": "ارزش تقریبی",
        "Connect Wallet & Donate": "اتصال کیف پول و اهدا",
        "Secure • Non-custodial • You stay in control": "امن • غیرامانی • کنترل دارایی در اختیار شماست",
        "Useful Links": "پیوندهای مفید",
        "Copy Creator Address": "کپی نشانی سازنده",
        "Copy GENY Token CA": "کپی نشانی قرارداد توکن GENY",
        "Receiver wallet copied.": "نشانی کیف پول دریافت‌کننده کپی شد.",
        "Token contract copied.": "نشانی قرارداد توکن کپی شد.",
        "Rec.": "ویژه",
        "Setup Guide: %1": "راهنمای راه‌اندازی: %1",
        "General": "عمومی",
        "Local Port Conflict": "تداخل درگاه محلی",
        "Recommended: keep this enabled to restore system proxy cleanly after tunnel disconnect.": "پیشنهادی: برای بازگردانی درست پروکسی سیستم پس از قطع تونل، این گزینه را فعال نگه دارید.",
        "Auto-disable system proxy when disconnecting": "غیرفعال‌کردن خودکار پروکسی سیستم هنگام قطع اتصال",
        "Support Development": "حمایت از توسعه",
        "Report": "گزارش",
        "Logging is disabled": "گزارش‌گیری غیرفعال است",
        "Runtime Logs": "گزارش‌های زمان اجرا",
        "Enable xray logs in Settings to capture connection history.": "برای ثبت تاریخچهٔ اتصال، گزارش‌گیری Xray را در تنظیمات فعال کنید.",
        "Open Logs": "بازکردن گزارش‌ها",
        "Open Updates": "بازکردن به‌روزرسانی‌ها",
        "Auto-update is not available on this runtime build. Use the release page to get the latest APK or desktop package.": "به‌روزرسانی خودکار در این نسخه در دسترس نیست. جدیدترین APK یا بستهٔ دسکتاپ را از صفحهٔ انتشار دریافت کنید.",
        "Open Project": "بازکردن صفحهٔ پروژه",
        "Opened package installer. Confirm update to continue.": "نصب‌کنندهٔ بسته باز شد. برای ادامه، به‌روزرسانی را تأیید کنید.",
        "Waiting for Administrator approval to install update...": "در انتظار تأیید مدیر سیستم برای نصب به‌روزرسانی...",
        "This asset requires manual install. Opening installer...": "این بسته باید دستی نصب شود. در حال بازکردن نصب‌کننده...",
        "Choose Wallet": "انتخاب کیف پول",
        "Choose wallet app": "برنامهٔ کیف پول را انتخاب کنید",
        "Donate $GENY": "اهدای GENY",
        "Select a donation token first.": "ابتدا توکن اهدایی را انتخاب کنید.",
        "Unable to prepare donation request.": "آماده‌سازی درخواست اهدا ناموفق بود.",
        "Opened wallet. Complete donation transfer there.": "کیف پول باز شد. انتقال مبلغ اهدایی را در آن تکمیل کنید.",
        "Opened wallet deep link. Complete the transfer in your wallet.": "پیوند کیف پول باز شد. انتقال را در کیف پول خود تکمیل کنید.",
        "Opened Uniswap. Complete swap/buy then send donation.": "یونی‌سواپ باز شد. ابتدا تبدیل یا خرید را تکمیل کنید و سپس مبلغ اهدایی را بفرستید.",
        "Creator BaseScan": "نشانی سازنده در BaseScan",
        "Token BaseScan": "توکن در BaseScan",

        # Full Persian UI review: concise labels, networking terminology, and
        # natural product copy. These entries intentionally override literal
        # machine translations even when they were technically non-empty.
        "About GenyConnect": "دربارهٔ جنی‌کانکت",
        "About US": "دربارهٔ ما",
        "Actions": "عملیات",
        "Adaptive Inputs": "ورودی‌های تطبیقی",
        "Add": "افزودن",
        "Add Download": "افزودن دانلود",
        "Add Rule": "افزودن قانون",
        "Address": "نشانی",
        "address already in use": "نشانی از قبل در حال استفاده است",
        "Address is required.": "واردکردن نشانی الزامی است.",
        "already active": "از قبل فعال است",
        "already in use": "از قبل در حال استفاده است",
        "Analyzing": "در حال تحلیل",
        "Android Runtime Issue": "مشکل محیط اجرای اندروید",
        "another vpn": "وی‌پی‌ان دیگر",
        "App Version": "نسخهٔ برنامه",
        "Applying system network refresh...": "در حال نوسازی شبکهٔ سیستم...",
        "Auth password": "رمز عبور احراز هویت",
        "Auth user": "نام کاربری احراز هویت",
        "Auto measure profile latency": "اندازه‌گیری خودکار تأخیر پروفایل",
        "Background": "پس‌زمینه",
        "Backoff": "وقفهٔ افزایشی",
        "Battery Saver": "صرفه‌جویی در باتری",
        "Blocked": "مسدود",
        "Browse": "مرور",
        "Canceled": "لغوشده",
        "Category": "دسته‌بندی",
        "Charging": "در حال شارژ",
        "Checksum": "مقدار صحت‌سنج",
        "Choose a profile to view details": "برای مشاهدهٔ جزئیات، یک پروفایل را انتخاب کنید",
        "Clean Mode": "حالت بدون پروکسی سیستم",
        "Cleanup": "پاک‌سازی",
        "Clear All": "پاک‌کردن همه",
        "Clear Network Cache": "پاک‌کردن حافظهٔ پنهان شبکه",
        "Clear Selected": "پاک‌کردن موارد انتخاب‌شده",
        "Clearing...": "در حال پاک‌سازی...",
        "Client address": "نشانی کلاینت",
        "Complete": "تکمیل",
        "Connect Anyway": "اتصال با وجود هشدار",
        "Connect to view": "برای مشاهده متصل شوید",
        "Connected %1": "اتصال به %1 برقرار شد",
        "Connection Issue": "مشکل اتصال",
        "Controls": "کنترل‌ها",
        "Copy App Link": "کپی پیوند برنامه",
        "Copy as JSON": "کپی به‌صورت JSON",
        "Copy Path": "کپی مسیر",
        "Copy Repo Link": "کپی پیوند مخزن",
        "Copy System Info": "کپی اطلاعات سیستم",
        "Copy URL": "کپی نشانی اینترنتی",
        "core startup failure": "راه‌اندازی هسته ناموفق بود",
        "Could not save profile QR PNG.": "ذخیرهٔ تصویر QR پروفایل ناموفق بود.",
        "Create": "ایجاد",
        "Current Profile": "پروفایل فعلی",
        "Current Profile Usage -->": "مصرف پروفایل فعلی",
        "Custom headers (one per line)": "سربرگ‌های سفارشی (هر خط یک مورد)",
        "Data Usage — %1": "مصرف داده — %1",
        "default gateway": "دروازهٔ پیش‌فرض",
        "Del": "حذف",
        "Delay (s)": "تأخیر (ثانیه)",
        "Delete other profiles?": "پروفایل‌های دیگر حذف شوند؟",
        "Delete Rest": "حذف بقیه",
        "Deleted Profile": "پروفایل حذف‌شده",
        "Developer": "توسعه‌دهنده",
        "Disconnected": "قطع‌شده",
        "Disconnected %1": "اتصال به %1 قطع شد",
        "Down %1": "دریافت: %1",
        "Dup": "تکثیر",
        "Edit": "ویرایش",
        "Effective runtime and UI intervals after mode and adaptive tuning.": "فاصله‌های زمانی مؤثر رابط کاربری و محیط اجرا پس از اعمال حالت و تنظیم تطبیقی.",
        "Encryption (none/auto/...)": "رمزنگاری (none/auto/...)",
        "Endpoint hidden": "نشانی مقصد پنهان است",
        "Endpoint Latency": "تأخیر مقصد",
        "Exempt": "مستثنا",
        "Export": "خروجی‌گرفتن",
        "Export All": "خروجی‌گرفتن از همه",
        "Export copied to clipboard.": "خروجی در کلیپ‌بورد کپی شد.",
        "Export opened in share sheet.": "خروجی در صفحهٔ اشتراک‌گذاری باز شد.",
        "Extract archive": "استخراج بایگانی",
        "failed to start vpn runtime": "راه‌اندازی محیط وی‌پی‌ان ناموفق بود",
        "fake dns": "DNS جعلی",
        "Foreground": "پیش‌زمینه",
        "G": "ج",
        "GenyConnect Profiles Export": "خروجی پروفایل‌های جنی‌کانکت",
        "Genyleap": "جنی‌لیپ",
        "GET": "GET",
        "Group Enabled": "گروه فعال است",
        "Groups: %1": "گروه‌ها: %1",
        "Hardware": "سخت‌افزار",
        "Header: value": "سربرگ: مقدار",
        "Hide Advanced": "پنهان‌کردن تنظیمات پیشرفته",
        "Home": "صفحهٔ اصلی",
        "Import": "واردکردن",
        "Import and select a profile": "واردکردن و انتخاب پروفایل",
        "Import Profiles": "واردکردن پروفایل‌ها",
        "Import Target Group:": "گروه مقصد برای واردکردن:",
        "Importing from subscription...": "در حال واردکردن از اشتراک...",
        "Instability": "ناپایداری",
        "Interface/DashboardStats": "رابط کاربری / آمار داشبورد",
        "Interface/Language": "رابط کاربری / زبان",
        "Interface/Privacy": "رابط کاربری / حریم خصوصی",
        "Interface/Theme": "رابط کاربری / پوسته",
        "Invalid config fields.": "فیلدهای پیکربندی معتبر نیستند.",
        "Invalid endpoint fields.": "فیلدهای مقصد معتبر نیستند.",
        "Invalid endpoint format.": "قالب نشانی مقصد معتبر نیست.",
        "Invalid Shadowsocks credentials.": "اطلاعات ورود Shadowsocks معتبر نیست.",
        "IP unavailable": "آی‌پی در دسترس نیست",
        "Kill Switch (Unavailable)": "قطع اضطراری (در دسترس نیست)",
        "Laptop / Browser": "لپ‌تاپ / مرورگر",
        "Laptop / Browser Mode": "حالت لپ‌تاپ / مرورگر",
        "Last Usage": "آخرین مصرف",
        "Latency Measurement Mode": "حالت اندازه‌گیری تأخیر",
        "License copied to clipboard.": "متن مجوز در کلیپ‌بورد کپی شد.",
        "Live": "زنده",
        "Loading running and installed apps...": "در حال بارگذاری برنامه‌های در حال اجرا و نصب‌شده...",
        "Manage Groups": "مدیریت گروه‌ها",
        "Mirrors (one per line)": "آینه‌ها (هر خط یک مورد)",
        "My Stores": "فروشگاه‌های من",
        "Network cache action completed.": "عملیات حافظهٔ پنهان شبکه انجام شد.",
        "No completed tests yet.": "هنوز هیچ آزمونی تکمیل نشده است.",
        "No connection history yet.": "هنوز تاریخچهٔ اتصالی ثبت نشده است.",
        "No dead profiles to remove.": "هیچ پروفایل ازکارافتاده‌ای برای حذف وجود ندارد.",
        "No matching app found": "برنامهٔ منطبقی پیدا نشد",
        "No matching profile found.": "پروفایل منطبقی پیدا نشد.",
        "No profile config available.": "پیکربندی پروفایل در دسترس نیست.",
        "No profiles available to export.": "هیچ پروفایلی برای خروجی‌گرفتن وجود ندارد.",
        "No profiles were imported.": "هیچ پروفایلی وارد نشد.",
        "No profiles. Import one first.": "پروفایلی وجود ندارد؛ ابتدا یک پروفایل وارد کنید.",
        "No recorded sessions yet.": "هنوز نشستی ثبت نشده است.",
        "No usage history yet.": "هنوز سابقهٔ مصرفی ثبت نشده است.",
        "None": "هیچ‌کدام",
        "occupied before startup": "پیش از راه‌اندازی اشغال شده است",
        "Open": "بازکردن",
        "Open file": "بازکردن فایل",
        "Open Repository": "بازکردن مخزن",
        "Open Website": "بازکردن وب‌سایت",
        "Opened Android battery settings.": "تنظیمات باتری اندروید باز شد.",
        "Optimization": "بهینه‌سازی",
        "OS": "سیستم‌عامل",
        "OS Kernel / API": "هستهٔ سیستم‌عامل / API",
        "OS Name": "نام سیستم‌عامل",
        "OS:": "سیستم‌عامل:",
        "Pause": "مکث",
        "Paused": "متوقف‌شده",
        "Ping": "پینگ",
        "Ping Group": "پینگ گروه",
        "Platform": "پلتفرم",
        "Please wait...": "لطفاً صبر کنید...",
        "Post": "ارسال",
        "Post actions": "اقدامات پس از دانلود",
        "Post script (use {file} and {dir})": "اسکریپت پس از دانلود (با {file} و {dir})",
        "Preparing": "در حال آماده‌سازی",
        "Preparing network cache cleanup...": "در حال آماده‌سازی پاک‌سازی حافظهٔ پنهان شبکه...",
        "Process Memory": "حافظهٔ فرایند",
        "Profile": "پروفایل",
        "Profile config copied.": "پیکربندی پروفایل کپی شد.",
        "Profile export failed.": "خروجی‌گرفتن از پروفایل ناموفق بود.",
        "Profile is selected": "پروفایل انتخاب شده است",
        "Profile link copied to clipboard.": "پیوند پروفایل در کلیپ‌بورد کپی شد.",
        "Profile QR Code": "کد QR پروفایل",
        "Profile: %1": "پروفایل: %1",
        "Properties": "ویژگی‌ها",
        "Protected IP": "آی‌پی محافظت‌شده",
        "Provider:": "ارائه‌دهنده:",
        "Proxy IP": "آی‌پی پروکسی",
        "QRCode": "کد QR",
        "Qt Runtime": "محیط اجرای Qt",
        "Receive": "دریافت",
        "Recent Sessions": "نشست‌های اخیر",
        "Reconnect": "اتصال مجدد",
        "Reconnects": "اتصال‌های مجدد",
        "Reduced": "کاهش‌یافته",
        "Reel": "ریلز",
        "Remove": "حذف",
        "Remove All Groups": "حذف همهٔ گروه‌ها",
        "Resolving...": "در حال یافتن نشانی...",
        "Restricted": "محدود",
        "Resume": "ادامه",
        "Retry": "تلاش مجدد",
        "Retry policy": "سیاست تلاش مجدد",
        "Reveal folder": "نمایش پوشه",
        "route validation": "اعتبارسنجی مسیر",
        "Rule is valid.": "قانون معتبر است.",
        "Runtime Startup Failed": "راه‌اندازی محیط اجرا ناموفق بود",
        "Save Download": "ذخیرهٔ دانلود",
        "Save Rule": "ذخیرهٔ قانون",
        "Saved profile QR PNG: ": "تصویر QR پروفایل ذخیره شد: ",
        "Scope: %1": "محدوده: %1",
        "Screen": "صفحه‌نمایش",
        "Search location...": "جست‌وجوی مکان...",
        "Search running apps": "جست‌وجوی برنامه‌های در حال اجرا",
        "Sections": "بخش‌ها",
        "Select apps to apply rules": "برنامه‌های مشمول قوانین را انتخاب کنید",
        "Select visible": "انتخاب موارد قابل‌مشاهده",
        "Send": "ارسال",
        "Share": "اشتراک‌گذاری",
        "Share Now": "اشتراک‌گذاری اکنون",
        "Share sheet opened.": "صفحهٔ اشتراک‌گذاری باز شد.",
        "Show Advanced": "نمایش تنظیمات پیشرفته",
        "Side Bar": "نوار کناری",
        "SOCKS5": "SOCKS5",
        "Software": "نرم‌افزار",
        "Software Information": "اطلاعات نرم‌افزار",
        "Software Version : 0.542.23": "نسخهٔ نرم‌افزار: 0.542.23",
        "split default routes": "تقسیم مسیرهای پیش‌فرض",
        "Start paused": "شروع در حالت مکث",
        "Stats Poll": "بازهٔ دریافت آمار",
        "Stop": "توقف",
        "Story": "استوری",
        "Swap on Uniswap": "تبدیل در Uniswap",
        "System Information": "اطلاعات سیستم",
        "System follows macOS/Windows appearance. Light keeps current look.": "پوسته از ظاهر macOS یا Windows پیروی می‌کند؛ گزینهٔ «روشن» ظاهر فعلی را حفظ می‌کند.",
        "Time Left": "زمان باقی‌مانده",
        "Tool Bar": "نوار ابزار",
        "Transport Power Profile": "پروفایل مصرف انرژی انتقال",
        "TUN mode keeps unmatched traffic on VPN by default. Use Direct rules for explicit bypass targets.": "در حالت TUN، ترافیک بدون قانون به‌طور پیش‌فرض از وی‌پی‌ان عبور می‌کند. برای دورزدن صریح، قانون «مستقیم» بسازید.",
        "Unsupported": "پشتیبانی‌نشده",
        "Up %1": "ارسال: %1",
        "USD Coin (USDC)": "یواس‌دی کوین (USDC)",
        "Validate": "اعتبارسنجی",
        "Verify Checksum": "بررسی مقدار صحت‌سنج",
        "Verify on complete": "بررسی پس از تکمیل",
        "Version %1": "نسخهٔ %1",
        "Visuals": "جلوه‌های بصری",
        "VMess payload could not be decoded.": "رمزگشایی محتوای VMess ناموفق بود.",
        "VMess payload is not valid JSON.": "محتوای VMess یک JSON معتبر نیست.",
        "VPN Conflict Detected": "تداخل وی‌پی‌ان شناسایی شد",
        "VPN disconnected": "وی‌پی‌ان قطع شد",
        "vpn permission": "مجوز وی‌پی‌ان",
        "VPN Permission Required": "مجوز وی‌پی‌ان لازم است",
        "Waiting for the operating system...": "در انتظار سیستم‌عامل...",
        "Wakeups": "دفعات بیدارسازی",
        "Website": "وب‌سایت",
        "White Paper": "وایت‌پیپر",
        "Whitelist mode": "حالت فهرست مجاز",
        "Xray ": "Xray",
        "Xray Core ": "هستهٔ Xray",
        "Xray Core %1": "هستهٔ Xray %1",
        "Xray-core": "Xray-core",
        "xray-core": "xray-core",
        "xray-core could not start correctly. Open Logs for the exact runtime details.": "راه‌اندازی xray-core ناموفق بود. برای دیدن جزئیات دقیق، گزارش‌ها را باز کنید.",
        "xray-core failed to start": "راه‌اندازی xray-core ناموفق بود",
        "Block Apps\nsteam.exe\nDiscord\ncom.apple.Music": "مسدودکردن برنامه‌ها\nsteam.exe\nDiscord\ncom.apple.Music",
        "Block Domains\ngeosite:category-ads-all\nregexp:.*ads.*": "دامنه‌های مسدود\ngeosite:category-ads-all\nregexp:.*ads.*",
        "Direct Apps\nFinder\nexplorer.exe\nfirefox": "برنامه‌های مستقیم\nFinder\nexplorer.exe\nfirefox",
        "Direct Domains\nfull:localhost\ngeosite:private\nexample.org": "دامنه‌های مستقیم\nfull:localhost\ngeosite:private\nexample.org",
        "Tunnel Apps\nTelegram\nchrome.exe\ncom.apple.Safari": "برنامه‌های تونل\nTelegram\nchrome.exe\ncom.apple.Safari",
        "Tunnel Domains\nexample.com\ndomain:youtube.com\nregexp:.*\\.openai\\.com$": "دامنه‌های تونل\nexample.com\ndomain:youtube.com\nregexp:.*\\.openai\\.com$",
        "0.0.0.0 exposes proxy to the whole LAN.": "نشانی 0.0.0.0 پروکسی را در کل شبکهٔ محلی در دسترس قرار می‌دهد.",
        "A descriptive tool tip of what the button does": "راهنمای کوتاه دربارهٔ عملکرد دکمه",
        "Affects browser and proxy-aware apps.": "بر مرورگر و برنامه‌های آگاه از پروکسی اثر می‌گذارد.",
        "All pasted profiles/subscriptions will be saved here.": "همهٔ پروفایل‌ها و اشتراک‌های جای‌گذاری‌شده در این گروه ذخیره می‌شوند.",
        "Android refreshes GenyConnect's VPN network through VpnService and asks the framework to re-evaluate connectivity.": "اندروید شبکهٔ وی‌پی‌ان جنی‌کانکت را از طریق VpnService نوسازی می‌کند و از سیستم می‌خواهد اتصال را دوباره ارزیابی کند.",
        "Another VPN or proxy app is still holding a local proxy port that GenyConnect needs. If the next retry still fails, change or stop the conflicting app and then reconnect.": "یک برنامهٔ وی‌پی‌ان یا پروکسی دیگر هنوز درگاه محلی موردنیاز جنی‌کانکت را در اختیار دارد. اگر تلاش بعدی هم ناموفق بود، برنامهٔ متداخل را متوقف یا تنظیماتش را تغییر دهید و دوباره متصل شوید.",
        "Another VPN or system tunnel appears active, or macOS could not take ownership of the TUN routes. Disconnect the other tunnel first, then reconnect GenyConnect.": "به‌نظر می‌رسد وی‌پی‌ان یا تونل دیگری فعال است، یا macOS نتوانسته مسیرهای TUN را در اختیار بگیرد. ابتدا تونل دیگر را قطع و سپس جنی‌کانکت را دوباره متصل کنید.",
        "App rules are supported on this runtime. Use absolute executable paths for the most reliable matching.": "قوانین برنامه در این محیط پشتیبانی می‌شوند. برای تطبیق مطمئن‌تر، مسیر کامل فایل اجرایی را وارد کنید.",
        "Auto: route first, endpoint fallback. Route Latency: real VPN/proxy path and Best Proxy ranking. Endpoint Latency: raw server troubleshooting only.": "خودکار: ابتدا تأخیر مسیر و در صورت نیاز تأخیر مقصد را می‌سنجد. «تأخیر مسیر» تجربهٔ واقعی وی‌پی‌ان یا پروکسی و رتبه‌بندی بهترین پروکسی را نشان می‌دهد؛ «تأخیر مقصد» فقط برای عیب‌یابی سرور است.",
        "Best for login, updates, and downloads.": "مناسب ورود، به‌روزرسانی و دانلود.",
        "Best for proxy-ready streaming and TV apps.": "مناسب سرویس‌های پخش و برنامه‌های تلویزیونی دارای تنظیم پروکسی.",
        "Choose how GenyConnect balances battery use, stats refresh, reconnect pressure, and visual effects. The tunnel lifecycle stays owned by the existing VPN runtime.": "نحوهٔ تعادل جنی‌کانکت میان مصرف باتری، نوسازی آمار، تلاش‌های اتصال مجدد و جلوه‌های بصری را انتخاب کنید. مدیریت چرخهٔ تونل همچنان بر عهدهٔ محیط وی‌پی‌ان است.",
        "Choose visual behavior, privacy display, and the unit used by live transfer-rate indicators.": "جلوه‌های بصری، نحوهٔ نمایش اطلاعات خصوصی و واحد نشانگرهای زندهٔ سرعت را انتخاب کنید.",
        "Clean counters for wakeups, reconnect pressure, and adaptive state.": "شمارنده‌های بیدارسازی، تلاش اتصال مجدد و وضعیت تطبیقی را پاک کنید.",
        "Clean mode: %1 proxy stays untouched. Only apps set to %2 use the tunnel.": "حالت بدون پروکسی سیستم: پروکسی %1 تغییر نمی‌کند و فقط برنامه‌هایی که روی %2 تنظیم شده‌اند از تونل استفاده می‌کنند.",
        "Clear the OS DNS resolver cache and IP neighbor cache for this device.": "حافظهٔ پنهان حل‌کنندهٔ DNS و همسایه‌های آی‌پی سیستم‌عامل را در این دستگاه پاک کنید.",
        "Create rules with Target Type + Target Value + Action. Rules are evaluated from top to bottom.": "قانون‌ها را با «نوع مقصد»، «مقدار مقصد» و «عمل» بسازید. قانون‌ها از بالا به پایین بررسی می‌شوند.",
        "Could not open selected wallet app. Copied receiver wallet and opened Uniswap fallback.": "برنامهٔ کیف پول انتخاب‌شده باز نشد؛ نشانی کیف پول گیرنده کپی و Uniswap به‌عنوان جایگزین باز شد.",
        "Could not resolve a writable folder for PNG export.": "پوشهٔ قابل‌نوشتنی برای ذخیرهٔ PNG پیدا نشد.",
        "For desktop browsers and proxy-aware clients.": "برای مرورگرهای دسکتاپ و کلاینت‌های دارای تنظیم پروکسی.",
        "Global mode: %1 routes compatible apps through GenyConnect automatically.": "حالت سراسری: %1 برنامه‌های سازگار را به‌طور خودکار از جنی‌کانکت عبور می‌دهد.",
        "Global mode and Kill Switch require system proxy control, which is not available on this runtime. Use TUN Mode for full-device routing.": "حالت سراسری و قطع اضطراری به کنترل پروکسی سیستم نیاز دارند که در این محیط در دسترس نیست. برای مسیریابی کامل دستگاه از حالت TUN استفاده کنید.",
        "Great for browser and proxy-aware apps.": "مناسب مرورگر و برنامه‌های دارای تنظیم پروکسی.",
        "In Clean mode this option is ignored because system proxy remains disabled.": "در حالت بدون پروکسی سیستم، این گزینه نادیده گرفته می‌شود؛ زیرا پروکسی سیستم غیرفعال می‌ماند.",
        "No rules yet. Add your first rule above.\nExample: Domain example.com → Direct.": "هنوز قانونی تعریف نشده است. نخستین قانون را در بالا اضافه کنید.\nنمونه: دامنهٔ example.com ← مستقیم",
        "QR is dense. If scan is hard, use Copy as JSON.": "کد QR متراکم است. اگر اسکن آن دشوار بود، گزینهٔ «کپی به‌صورت JSON» را انتخاب کنید.",
        "Session in progress. Disconnect to record it here.": "نشست در حال اجراست؛ برای ثبت آن در این بخش، اتصال را قطع کنید.",
        "Share GenyConnect using the native share sheet on mobile or desktop integrations where available.": "در صورت پشتیبانی سیستم، جنی‌کانکت را از طریق صفحهٔ اشتراک‌گذاری بومی موبایل یا دسکتاپ به‌اشتراک بگذارید.",
        "Share sheet unavailable. App details copied to clipboard.": "صفحهٔ اشتراک‌گذاری در دسترس نیست؛ اطلاعات برنامه در کلیپ‌بورد کپی شد.",
        "Signals that can tune intervals at runtime without reconnecting.": "نشانه‌هایی که می‌توانند فاصله‌های زمانی را بدون اتصال مجدد تنظیم کنند.",
        "Some apps may bypass manual proxy.": "برخی برنامه‌ها ممکن است پروکسی دستی را نادیده بگیرند.",
        "Some apps may ignore proxy.": "برخی برنامه‌ها ممکن است از پروکسی استفاده نکنند.",
        "Speed test timed out or endpoint did not respond.": "زمان آزمایش سرعت به پایان رسید یا مقصد پاسخ نداد.",
        "The generated Xray runtime configuration is not valid for the current core/runtime settings.": "پیکربندی تولیدشدهٔ Xray با تنظیمات فعلی هسته یا محیط اجرا سازگار نیست.",
        "This app is provided without warranty. Review the full license text below before production deployment.": "این برنامه بدون ضمانت ارائه می‌شود. پیش از استفادهٔ عملیاتی، متن کامل مجوز را در ادامه بخوانید.",
        "This keeps the selected profile and any active connection, then removes the rest.": "پروفایل انتخاب‌شده و اتصال فعال حفظ می‌شوند و بقیه حذف خواهند شد.",
        "This profile can be edited using the full config text field.": "این پروفایل را می‌توان از طریق کادر متن کامل پیکربندی ویرایش کرد.",
        "This profile type can be edited using the full config text field.": "این نوع پروفایل را می‌توان از طریق کادر متن کامل پیکربندی ویرایش کرد.",
        "Track upload/download totals per profile or across all profiles.": "مجموع دانلود و آپلود را برای هر پروفایل یا همهٔ پروفایل‌ها ثبت کنید.",
        "Use GenyConnect only with profiles and networks you are authorized to access. You are responsible for complying with local laws, service terms, and network policies.": "از جنی‌کانکت فقط برای پروفایل‌ها و شبکه‌هایی استفاده کنید که اجازهٔ دسترسی به آن‌ها را دارید. رعایت قوانین محلی، شرایط خدمات و سیاست‌های شبکه بر عهدهٔ شماست.",
        "Use lowercase b for bits and uppercase B for bytes.": "برای بیت از b کوچک و برای بایت از B بزرگ استفاده کنید.",
        "We stand with IRAN, with love.": "با عشق در کنار ایران ایستاده‌ایم.",
        "Whitelist mode is OFF: unmatched traffic goes through VPN, unless a rule sends it Direct or Block.": "حالت فهرست مجاز خاموش است: ترافیک بدون قانون از وی‌پی‌ان عبور می‌کند، مگر آنکه قانونی آن را «مستقیم» یا «مسدود» کند.",
        "Whitelist mode is ON: unmatched traffic goes Direct, and only rules set to VPN/Tunnel use the VPN.": "حالت فهرست مجاز روشن است: ترافیک بدون قانون مستقیماً عبور می‌کند و فقط قانون‌های تنظیم‌شده روی «وی‌پی‌ان/تونل» از وی‌پی‌ان استفاده می‌کنند.",
        "Windows uses ipconfig and netsh and may show a UAC prompt.": "ویندوز از ipconfig و netsh استفاده می‌کند و ممکن است پنجرهٔ تأیید UAC را نمایش دهد.",
    },
    "ar": {
        "DNS": "نظام أسماء النطاقات",
        "Custom DNS": "نظام أسماء نطاقات مخصص",
        "Secure DNS": "نظام أسماء نطاقات آمن",
        "DNS Leak": "تسرّب نظام أسماء النطاقات",
        "IP Address": "عنوان IP",
        "Last Usage: %1": "آخر استخدام: %1",
        "%1 (Build %2) - %3": "%1 (الإصدار %2) - %3",
    },
}


def decode_qml_string(value: str) -> str | None:
    try:
        return json.loads(f'"{value}"')
    except json.JSONDecodeError:
        return None


def looks_user_facing(value: str) -> bool:
    stripped = value.strip()
    if not stripped or not re.search(r"[A-Za-z]", stripped):
        return False
    if stripped.startswith(("qrc:", "http:", "https:", "file:", ":/")):
        return False
    if stripped.startswith("mainHex_") or "@" in stripped:
        return False
    if re.fullmatch(r"#[0-9a-fA-F]{3,8}", stripped):
        return False
    if "\\uf" in value or "\\u25" in value:
        return False
    if re.fullmatch(r"[a-z][a-z0-9_.-]*", stripped) and stripped not in {
        "all", "current", "day", "week", "month", "direct", "block",
    }:
        return False
    if re.fullmatch(r"[a-z][A-Za-z0-9_]*", stripped):
        return False
    if stripped in {"rgba(", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"}:
        return False
    return True


def extract_sources() -> list[str]:
    sources = set(EXTRA_SOURCES)
    for path in sorted(UI_ROOT.rglob("*.qml")):
        if path.name == "I18n.qml":
            continue
        text = path.read_text(encoding="utf-8")
        for match in EXPLICIT.finditer(text):
            decoded = decode_qml_string(match.group(1))
            if decoded:
                sources.add(decoded)
        for line in text.splitlines():
            if not any(marker in line for marker in PRESENTATION_MARKERS):
                continue
            for match in QUOTED.finditer(line):
                decoded = decode_qml_string(match.group(1))
                if decoded and looks_user_facing(decoded):
                    sources.add(decoded)
        # Also include strings stored in JavaScript models, conditional branches,
        # and feedback callbacks. Those values are translated at their eventual
        # display site, but are often several lines away from the `text:` binding.
        for match in QUOTED.finditer(text):
            decoded = decode_qml_string(match.group(1))
            if decoded and looks_user_facing(decoded):
                sources.add(decoded)
    return sorted(sources, key=lambda item: (item.casefold(), item))


def load_catalog(locale: str) -> dict[str, str]:
    path = CATALOG_ROOT / f"{locale}.json"
    if path.exists():
        data = json.loads(path.read_text(encoding="utf-8"))
        return {str(key): str(value) for key, value in data.items()}

    # One-time migration path from the original inline QML catalogs.
    legacy_path = UI_ROOT / "Core" / "I18n.qml"
    if not legacy_path.exists():
        return {}
    legacy = legacy_path.read_text(encoding="utf-8")
    block_match = re.search(
        rf"\n\s*{re.escape(locale)}:\s*\{{(.*?)\n\s*\}}(?:,|\n)",
        legacy,
        re.DOTALL,
    )
    if not block_match:
        return {}
    migrated: dict[str, str] = {}
    for pair in re.finditer(
        r'"((?:\\.|[^"\\])*)"\s*:\s*"((?:\\.|[^"\\])*)"',
        block_match.group(1),
    ):
        key = decode_qml_string(pair.group(1))
        value = decode_qml_string(pair.group(2))
        if key is not None and value is not None:
            migrated[key] = value
    return migrated


def request_translation(strings: list[str], target: str) -> list[str]:
    query = (f"\n{SEPARATOR}\n").join(strings)
    params = urllib.parse.urlencode({
        "client": "gtx", "sl": "en", "tl": target, "dt": "t", "q": query,
    })
    request = urllib.request.Request(
        "https://translate.googleapis.com/translate_a/single?" + params,
        headers={"User-Agent": "GenyConnect-translation-maintainer/1.0"},
    )
    for attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                payload = json.loads(response.read().decode("utf-8"))
            translated = "".join(part[0] for part in payload[0])
            parts = [part.strip() for part in translated.split(SEPARATOR)]
            if len(parts) != len(strings):
                raise RuntimeError(f"separator mismatch: wanted {len(strings)}, got {len(parts)}")
            return parts
        except Exception:
            if attempt == 3:
                raise
            time.sleep(1.5 * (attempt + 1))
    raise AssertionError("unreachable")


def translate_missing(strings: list[str], target: str) -> dict[str, str]:
    translated: dict[str, str] = {}
    batch: list[str] = []
    batch_size = 0

    def flush() -> None:
        nonlocal batch, batch_size
        if not batch:
            return
        values = request_translation(batch, target)
        translated.update(zip(batch, values, strict=True))
        batch = []
        batch_size = 0

    for source in strings:
        estimated = len(urllib.parse.quote(source))
        if batch and (len(batch) >= 18 or batch_size + estimated > 2800):
            flush()
        batch.append(source)
        batch_size += estimated
    flush()
    return translated


def normalize_translation(source: str, value: str) -> str:
    """Preserve QML replacement tokens that translation services may space out."""
    normalized = re.sub(r"%\s+(\d+)", r"%\1", value)
    source_tokens = sorted(re.findall(r"%\d+", source))
    translated_tokens = sorted(re.findall(r"%\d+", normalized))
    if source_tokens != translated_tokens:
        raise RuntimeError(
            f"placeholder mismatch for {source!r}: "
            f"expected {source_tokens}, got {translated_tokens} in {value!r}"
        )
    return normalized


PERSIAN_TYPOGRAPHY_REPLACEMENTS = {
    "به روز رسانی": "به‌روزرسانی",
    "به روزرسانی": "به‌روزرسانی",
    "به روز": "به‌روز",
    "راه اندازی": "راه‌اندازی",
    "اندازه گیری": "اندازه‌گیری",
    "جمع آوری": "جمع‌آوری",
    "صرفه جویی": "صرفه‌جویی",
    "عیب یابی": "عیب‌یابی",
    "اعتبار سنجی": "اعتبارسنجی",
    "پیاده سازی": "پیاده‌سازی",
    "پیکربندی های": "پیکربندی‌های",
    "سیستم عامل": "سیستم‌عامل",
    "نرم افزار": "نرم‌افزار",
    "سخت افزار": "سخت‌افزار",
    "صفحه نمایش": "صفحه‌نمایش",
    "وب سایت": "وب‌سایت",
    "کلیپ بورد": "کلیپ‌بورد",
    "پس زمینه": "پس‌زمینه",
    "خط مشی": "خط‌مشی",
    "رتبه بندی": "رتبه‌بندی",
    "پاک سازی": "پاک‌سازی",
    "نقطه پایانی": "نقطهٔ پایانی",
    "به طور": "به‌طور",
    "به صورت": "به‌صورت",
    "به عنوان": "به‌عنوان",
    "در حال حاضر": "اکنون",
    "قابل مشاهده": "قابل‌مشاهده",
    "قابل اعتماد": "قابل‌اعتماد",
    "غیر فعال": "غیرفعال",
    "غیر مجاز": "غیرمجاز",
    "پروکسی آگاه": "آگاه از پروکسی",
    "پراکسی": "پروکسی",
    "نمایه ای": "پروفایلی",
    "نمایه": "پروفایل",
}


def normalize_persian_typography(value: str) -> str:
    """Apply Persian Unicode and spacing conventions to translated UI text."""
    result = unicodedata.normalize("NFC", str(value))
    result = result.translate(str.maketrans({
        "ي": "ی", "ى": "ی", "ك": "ک", "ۀ": "هٔ", "ة": "ه",
    }))
    for old, new in PERSIAN_TYPOGRAPHY_REPLACEMENTS.items():
        result = result.replace(old, new)

    # Persian progressive verb prefix: می رود / نمی شود -> می‌رود / نمی‌شود.
    result = re.sub(r"(?<![\u0600-\u06ff])(ن?می) +(?=[\u0600-\u06ff])", r"\1‌", result)
    # Plural and comparative suffixes attach with a zero-width non-joiner.
    suffix_end = r"(?=$|[\s،؛؟!:.])"
    result = re.sub(r"([\u0600-\u06ff]+) +(ها(?:ی|یم|یت|یش|مان|تان|شان)?)" + suffix_end, r"\1‌\2", result)
    result = re.sub(r"([\u0600-\u06ff]+ه) +(ام|ای|ایم|اید|اند)" + suffix_end, r"\1‌\2", result)
    result = re.sub(r"([\u0600-\u06ff]+) +(تر|ترین)" + suffix_end, r"\1‌\2", result)
    result = result.replace("آنها", "آن‌ها").replace("اینها", "این‌ها")
    # Remove spaces before Persian/Latin punctuation and normalize repeated spaces
    # without touching line breaks used by examples and multi-line editors.
    result = re.sub(r"[ \t]+([،؛؟!:.])", r"\1", result)
    result = re.sub(r"[ \t]{2,}", " ", result)
    return result


def bundled_catalog_text() -> str:
    bundle = {locale: load_catalog(locale) for locale in LOCALES}
    return (
        ".pragma library\n\n"
        "// Generated by scripts/generate_ui_translations.py. Do not edit manually.\n"
        "var catalogs = "
        + json.dumps(bundle, ensure_ascii=False, indent=2)
        + "\n"
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--audit", action="store_true", help="check catalogs without translating")
    args = parser.parse_args()

    sources = extract_sources()
    CATALOG_ROOT.mkdir(parents=True, exist_ok=True)
    print(f"Discovered {len(sources)} user-facing English strings.", flush=True)

    def update_locale(locale: str, target: str) -> tuple[str, int]:
        catalog = load_catalog(locale)
        missing = [source for source in sources if source not in catalog]
        if args.audit and missing:
            print(f"{locale}: missing {len(missing)} entries")
            return locale, len(missing)
        if missing:
            print(f"{locale}: translating {len(missing)} missing entries...", flush=True)
            catalog.update(translate_missing(missing, target))
        catalog.update(OVERRIDES.get(locale, {}))
        if locale == "fa":
            catalog = {
                source: normalize_persian_typography(
                    value.replace("GenyConnect", "جنی‌کانکت")
                )
                for source, value in catalog.items()
            }
        catalog = {
            source: normalize_translation(source, catalog[source])
            for source in sources
        }
        path = CATALOG_ROOT / f"{locale}.json"
        if not args.audit:
            path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"{locale}: {len(catalog)} entries", flush=True)
        return locale, 0

    if args.audit:
        for locale, target in LOCALES.items():
            update_locale(locale, target)
    else:
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
            futures = [executor.submit(update_locale, locale, target) for locale, target in LOCALES.items()]
            for future in concurrent.futures.as_completed(futures):
                future.result()

    if args.audit:
        incomplete = any(
            source not in load_catalog(locale)
            for locale in LOCALES
            for source in sources
        )
        bundle_is_current = (
            BUNDLED_CATALOG.exists()
            and BUNDLED_CATALOG.read_text(encoding="utf-8") == bundled_catalog_text()
        )
        if not bundle_is_current:
            print("catalogs.js is missing or out of date")
        return 1 if incomplete or not bundle_is_current else 0

    BUNDLED_CATALOG.write_text(bundled_catalog_text(), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
