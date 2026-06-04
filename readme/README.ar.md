![genyconnect-cover](https://github.com/user-attachments/assets/a65daa50-b9ce-46e4-a23b-7886b1c41258)
---
# جنی‌کانکت (GenyConnect)

[English](../README.md) | [Persian - فارسی](README.fa.md) | [Chinese - 中文](README.zh-CN.md) | [Japanese - 日本語](README.ja.md) | [Turkish - Türkçe](README.tr.md) | [Russian - Русский](README.ru.md) | [French - Français](README.fr.md) | [Spanish - Español](README.es.md) | [Korean - 한국어](README.ko.md) | [Azerbaijani - Azərbaycanca](README.az.md) | [Hindi - हिंदी](README.hi.md) | [Portuguese - Português](README.pt.md) | [Arabic - العربية](README.ar.md) | [German - Deutsch](README.de.md)

<div dir="rtl" align="right" style="font-family: 'Noto Naskh Arabic', Tahoma, sans-serif;">

جنی‌کانکت (GenyConnect) عميل اتصال آمن وحديث ومتعدد المنصات للشبكات الخاصة والاتصالات المشفّرة، صُمم مع تركيز قوي على الأداء والخصوصية والإدارة الدقيقة لحركة المرور.

يوفر طبقة تنسيق قوية لمحركات الشبكات الآمنة والتوجيه النفقي، مع التركيز على الموثوقية وقابلية المراقبة والشفافية التشغيلية وتجربة المستخدم، مع البقاء مستقلاً عن أي بروتوكول أو تقنية أو تنفيذ محدد.

يجري تطوير جنی‌کانکت (GenyConnect) في مسارين: Community Edition للمستخدمين الأفراد واحتياجات الاتصال اليومية، و Commercial & Enterprise Edition للمؤسسات التي تحتاج إلى إدارة مركزية وسياسات شبكة وتحكم في الوصول واتصالات آمنة على نطاق واسع.

<p align="left">
  <a href="https://en.cppreference.com/w/cpp/23">
    <img
      alt="C++23"
      src="https://img.shields.io/badge/C%2B%2B-23-00599C?style=for-the-badge&logo=cplusplus"
    />
  </a>

  <a href="https://cmake.org/">
    <img
    alt="CMake 4.2+"
    src="https://img.shields.io/badge/CMake-4.2%2B-00599C?style=for-the-badge&logo=cmake"
    />
  </a>

  <a href="https://www.qt.io/">
    <img
      alt="Qt 6"
      src="https://img.shields.io/badge/Qt-6-41CD52?style=for-the-badge&logo=qt"
    />
  </a>

  <a href="../LICENSE">
    <img
      alt="License GPL-3.0-or-later"
      src="https://img.shields.io/badge/License-GPL--3.0--or--later-8E44AD?style=for-the-badge"
    />
  </a>

  <a href="https://github.com/thecompez/genyconnect/actions">
    <img
      alt="Build Passing"
      src="https://img.shields.io/badge/Build-Passing-27AE60?style=for-the-badge"
    />
  </a>

  <a href="https://github.com/thecompez/genyconnect/pulls">
    <img
      alt="PRs Welcome"
      src="https://img.shields.io/badge/PRs-Welcome-F39C12?style=for-the-badge"
    />
  </a>
</p>


---

## نظرة عامة

يمكّن جنی‌کانکت (GenyConnect) المستخدمين من إنشاء الاتصالات الآمنة وإدارتها عبر ملفات تعريف خوادم منظمة وروابط إعدادات قابلة للمشاركة.

تُنشأ إعدادات runtime ديناميكيًا، وتُدار دورات حياة الاتصال بشكل صريح، وتبقى حالة النظام قابلة للمراقبة بالكامل في كل وقت.

صُممت المنصة عمدًا لتكون engine-agnostic، مما يسمح بدمج backends مختلفة للتوجيه النفقي دون تغيير سير عمل المستخدم أو السلوك المتوقع.

لا يقتصر جنی‌کانکت (GenyConnect) على حالة استخدام عامة للتوجيه النفقي. اتجاهه طويل المدى هو أن يكون طبقة اتصال ذكية لإدارة الوصول إلى الخدمات والبنى التحتية الخاصة وموارد السحابة والفرق الموزعة التي تحتاج إلى اتصال ثابت وموثوق.

من المتوقع أن يصل جنی‌کانکت (GenyConnect)، ضمن نطاق الإصدارات 1.4 و 1.5، إلى مستوى أعلى من النضج للاستخدام العام الأوسع، وأن يغطي جزءًا كبيرًا من احتياجات المستخدمين الذين يتطلبون اتصالًا موثوقًا. ومن المخطط أن تضيف الإصدارات المستقبلية Persian ولغات إضافية داخل التطبيق.

سيركز الجيل الثاني من جنی‌کانکت (GenyConnect) بصورة أعمق على الاحتياجات التجارية والمؤسسية، بما في ذلك إدارة الوصول، وتخصيص بنية الاتصال، وزيادة مرونة الشبكة، وتقليل الاعتماد على الخدمات الخارجية، والحفاظ على استقرار الاتصال في ظروف الشبكة المختلفة. كما تخطط الإصدارات المستقبلية لدعم صيغة `gen.` المخصصة وبنية الاتصال الخاصة بجنی‌کانکت (GenyConnect) لتعريف الشبكات الخاصة وإدارة الوصول المؤسسي.

---

## القدرات الرئيسية

- وضوح تشغيلي كامل
  - سجلات مباشرة
  - إحصاءات حركة مرور فورية
  - تقارير صريحة عن حالة الاتصال

- تنفيذ عالي الأداء
  - runtime خفيف
  - عبء إضافي منخفض
  - استجابة جيدة تحت الأحمال المستمرة

- إدارة حتمية لدورة الحياة
  - بدء يمكن التنبؤ به
  - إيقاف نظيف
  - منطق إعادة اتصال آمن

- توجيه مرور متقدم
  - توجيه قائم على whitelist
  - قواعد tunnel/direct/block على مستوى النطاق
  - توجيه حسب التطبيق عند الدعم
  - توجيه حسب العملية عند الدعم

- أوضاع توجيه نفقي مرنة
  - proxy على مستوى التطبيق
  - توجيه نفقي كامل للنظام
  - سطح تحكم متسق

- LAN Sharing
  - مشاركة حركة المرور التي يديرها جنی‌کانکت (GenyConnect) مع أجهزة أخرى على الشبكة المحلية
  - دعم أجهزة مثل منصات الألعاب والتلفزيونات الذكية والهواتف والأجهزة اللوحية والحواسيب المحمولة والمكتبية
  - عناصر تحكم متقدمة للمشاركة في بيئات الشبكات المُدارة

- معمارية متعددة المنصات
  - runtime core مشترك
  - محولات desktop و mobile
  - تكاملات خاصة بكل منصة

---

## Power Mode

يتضمن جنی‌کانکت (GenyConnect) نظام Power Mode واعيًا بالمنصة، مصممًا لتحسين استقرار الاتصال واتساق runtime أثناء الأحمال المستمرة.

يساعد Power Mode على تقليل تدخل نظام التشغيل الناتج عن سياسات توفير الطاقة الشديدة، وخنق الخلفية، والتعليق عند الخمول، والانتقال إلى حالات السكون.

اعتمادًا على نظام التشغيل و runtime backend، قد يقوم Power Mode بما يلي:

- إبقاء مسارات الشبكة الحرجة مستجيبة
- تقليل الانقطاعات غير المتوقعة
- تحسين اتساق معدل النقل
- تحسين جلسات المرور طويلة المدى
- تقليل طفرات زمن الاستجابة أثناء النشاط الكثيف
- تحسين موثوقية runtime أثناء التوجيه النفقي

سلوك Power Mode تكيفي وقد يختلف حسب قدرات المنصة وقيود نظام التشغيل.

---

## لقطات الشاشة

<img width="413" alt="جنی‌کانکت (GenyConnect) screenshot 1" src="https://github.com/user-attachments/assets/c3c4fa7b-997c-4968-a019-ec8f1a88a7a1" />

<img width="422" alt="جنی‌کانکت (GenyConnect) screenshot 2" src="https://github.com/user-attachments/assets/e8996ce9-1064-4754-8b4b-5d3c83009fa4" />

---

## دعم المنصات

يدعم جنی‌کانکت (GenyConnect) حاليًا:

- macOS
- Windows
- Linux
- Android

دعم iOS قيد التطوير النشط.

---

## حزمة التقنيات

- C++23
- Qt 6 / QML
- معمارية runtime أصلية متعددة المنصات
- مسارات نشر متعددة المنصات
- تكامل backend للتوجيه النفقي بنهج engine-agnostic

---

## الترخيص

جنی‌کانکت (GenyConnect) Community Edition مرخّص بموجب GNU General Public License الإصدار 3 أو الأحدث (GPL-3.0-or-later).

يتوفر الترخيص التجاري بشكل منفصل من Genyleap Labs من أجل:

- عمليات نشر مملوكة
- إعادة توزيع closed-source
- تكاملات مؤسسية
- منتجات white-label
- توزيع App Store
- إصدارات تجارية
- ميزات Pro أو Enterprise

ما لم يُذكر خلاف ذلك صراحة، فإن العناصر التالية غير مشمولة بترخيص GPL وتظل All Rights Reserved:

- اسم جنی‌کانکت (GenyConnect)
- الشعارات
- الأيقونات
- لقطات الشاشة
- التصميم المرئي
- أصول العلامة التجارية
- الرسومات الترويجية
- أعمال UI الفنية
- مواد الهوية البصرية
- أصول التسويق

لا يجوز للفروع وإعادة التوزيع الإيحاء بتأييد Genyleap Labs أو الارتباط بها دون إذن كتابي صريح.

راجع ملفات LICENSE و NOTICE للحصول على تفاصيل الترخيص الكاملة.

### ملخص الترخيص

كود مصدر Community Edition:
- GPL-3.0-or-later

الترخيص التجاري:
- ترخيص تجاري مملوك منفصل

أصول العلامة التجارية والأصول غير البرمجية:
- All Rights Reserved

---

## ❤️ ادعم جنی‌کانکت (GenyConnect)

جنی‌کانکت (GenyConnect) مشروع مستقل تطوره Genyleap Labs.

إذا كان جنی‌کانکت (GenyConnect) مفيدًا لك، يمكنك دعم تطويره المستمر بالتبرع باستخدام $GENY أو USDC على Base Network.

يساعد دعمك في تمويل:

- التطوير المستمر
- تحسينات الأمان
- دعم منصات desktop و mobile
- البنية التحتية والاختبارات
- إصدارات open-source مستقبلية
- نمو طويل الأمد للمنظومة

---

## 🌐 الدعم باستخدام $GENY

عند التبرع باستخدام $GENY، فأنت تدعم تطوير جنی‌کانکت (GenyConnect) والمنظومة الأوسع لـ Geny.

### Base Mainnet

عقد توكن GENY:

`0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B`

محفظة تبرعات المطوّر:

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

### شراء أو مبادلة $GENY لمنظومة Genyleap

https://app.uniswap.org/swap?chain=base&outputCurrency=0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B

---

## 💵 الدعم باستخدام USDC

USDC طريقة مستقرة وبسيطة لدعم التطوير مباشرة.

### Base Mainnet

محفظة تبرعات المطوّر:

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

---

## إشعار التبرعات

التبرعات مساهمات طوعية لدعم تطوير جنی‌کانکت (GenyConnect).

ولا تمثل:

- استثمارًا
- حقوق ملكية
- ملكية
- مشاركة في الإيرادات
- أوراقًا مالية
- منتجات مالية
- وعودًا بعائد مالي

📢 تابع تحديثات التطوير والإعلانات والإصدارات المستقبلية على Telegram و Farcaster:

• Telegram: https://t.me/compezeth
• Telegram: https://t.me/genyleap
• X/Twitter: https://x.com/genyleap
• Farcaster: https://farcaster.xyz/compez.eth
• Farcaster: https://farcaster.xyz/genyleap

تساعد ملاحظاتك ودعمك في تشكيل مستقبل جنی‌کانکت (GenyConnect) ومنظومة Genyleap الأوسع. 🚀

</div>
