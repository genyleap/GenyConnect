![genyconnect-cover](https://github.com/user-attachments/assets/a65daa50-b9ce-46e4-a23b-7886b1c41258)
---
# GenyConnect

[English](../README.md) | [Persian - فارسی](README.fa.md) | [Chinese - 中文](README.zh-CN.md) | [Japanese - 日本語](README.ja.md) | [Turkish - Türkçe](README.tr.md) | [Russian - Русский](README.ru.md) | [French - Français](README.fr.md) | [Spanish - Español](README.es.md) | [Korean - 한국어](README.ko.md) | [Azerbaijani - Azərbaycanca](README.az.md) | [Hindi - हिंदी](README.hi.md) | [Portuguese - Português](README.pt.md) | [Arabic - العربية](README.ar.md) | [German - Deutsch](README.de.md)


GenyConnect özəl şəbəkələr və şifrələnmiş rabitə üçün müasir, çoxplatformalı təhlükəsiz bağlantı müştərisidir; performans, məxfilik və dəqiq trafik idarəetməsinə güclü fokusla hazırlanır.

O, təhlükəsiz şəbəkə və tunelləmə mühərrikləri üçün güclü orkestrasiya qatı təqdim edir; etibarlılıq, müşahidə edilə bilmə, əməliyyat şəffaflığı və istifadəçi təcrübəsini önə çəkir, eyni zamanda hər hansı xüsusi protokol, texnologiya və ya tətbiqdən asılı qalmır.

GenyConnect iki istiqamətdə inkişaf etdirilir: fərdi istifadəçilər və gündəlik bağlantı ehtiyacları üçün Community Edition, mərkəzləşdirilmiş idarəetmə, şəbəkə siyasətləri, giriş nəzarəti və böyük miqyasda təhlükəsiz rabitə tələb edən təşkilatlar üçün Commercial & Enterprise Edition.

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

## Ümumi baxış

GenyConnect istifadəçilərə strukturlaşdırılmış server profilləri və paylaşılabilən konfiqurasiya linkləri ilə təhlükəsiz bağlantılar yaratmağa və idarə etməyə imkan verir.

Runtime konfiqurasiyaları dinamik yaradılır, bağlantı həyat dövrləri açıq şəkildə nəzarətdə saxlanılır və sistem vəziyyəti hər zaman tam müşahidə edilə bilir.

Platforma məqsədli şəkildə engine-agnostic qurulub; buna görə müxtəlif tunelləmə backend-ləri istifadəçi axınlarını və gözlənilən davranışı dəyişmədən inteqrasiya oluna bilər.

GenyConnect yalnız ümumi tunelləmə istifadəsi ilə məhdudlaşmır. Uzunmüddətli istiqaməti servislərə, özəl infrastruktura, bulud resurslarına və sabit, etibarlı rabitə tələb edən paylanmış komandalara girişi idarə edən ağıllı bağlantı qatına çevrilməkdir.

1.4 və 1.5 buraxılış aralığında GenyConnect-in daha geniş ictimai istifadə üçün yetkinləşməsi və etibarlı bağlantı istəyən istifadəçilərin ehtiyaclarının böyük hissəsini qarşılaması gözlənilir. Gələcək buraxılışlarda Persian və əlavə tətbiqdaxili dillərin əlavə olunması planlaşdırılır.

GenyConnect-in ikinci nəsli giriş idarəetməsi, rabitə infrastrukturu fərdiləşdirməsi, şəbəkə dayanıqlığı, xarici servislərdən asılılığın azaldılması və müxtəlif şəbəkə şəraitində bağlantı sabitliyinin qorunması kimi kommersiya və təşkilati ehtiyaclara daha dərindən fokuslanacaq. Gələcək versiyalarda özəl şəbəkələri və təşkilati girişləri müəyyən etmək və idarə etmək üçün xüsusi `gen.` formatı və GenyConnect-in öz rabitə arxitekturası da dəstəklənəcək.

---

## Əsas imkanlar

- Aydın əməliyyat görünürlüğü
  - Canlı loqlar
  - Real vaxt trafik statistikası
  - Açıq bağlantı vəziyyəti hesabatı

- Yüksək performanslı icra
  - Yüngül runtime
  - Minimal əlavə yük
  - Davamlı iş yüklərində çevik cavab

- Deterministik həyat dövrü idarəetməsi
  - Proqnozlaşdırıla bilən başlanğıc
  - Təmiz dayandırma
  - Təhlükəsiz yenidən qoşulma məntiqi

- Qabaqcıl trafik yönləndirməsi
  - whitelist əsaslı yönləndirmə
  - domen səviyyəsində tunnel/direct/block qaydaları
  - dəstəkləndikdə tətbiq əsaslı yönləndirmə
  - dəstəkləndikdə proses əsaslı yönləndirmə

- Çevik tunelləmə rejimləri
  - tətbiq səviyyəsində proxy
  - tam sistem tunelləməsi
  - ardıcıl idarəetmə səthi

- LAN Sharing
  - GenyConnect tərəfindən idarə olunan trafiki yerli şəbəkədəki digər cihazlarla paylaşmaq
  - oyun konsolları, smart TV-lər, telefonlar, planşetlər, noutbuklar və masaüstü kompüterləri dəstəkləmək
  - idarə olunan şəbəkə mühitləri üçün qabaqcıl paylaşım nəzarətləri

- Çoxplatformalı arxitektura
  - ortaq runtime core
  - desktop və mobile adapterləri
  - platformaya xas inteqrasiyalar

---

## Power Mode

GenyConnect davamlı iş yükləri zamanı bağlantı sabitliyini və runtime ardıcıllığını artırmaq üçün hazırlanmış platformadan xəbərdar Power Mode sistemini ehtiva edir.

Power Mode aqressiv enerji qənaəti, fon məhdudlaşdırması, boşdayanma dayandırılması və yuxu vəziyyətinə keçidlər nəticəsində əməliyyat sisteminin müdaxiləsini azaltmağa kömək edir.

Əməliyyat sistemi və runtime backend-dən asılı olaraq Power Mode bunları edə bilər:

- kritik şəbəkə yollarını cavabdeh saxlamaq
- gözlənilməz qopmaları azaltmaq
- ötürmə ardıcıllığını yaxşılaşdırmaq
- uzunmüddətli trafik sessiyalarını optimallaşdırmaq
- yüksək aktivlikdə gecikmə sıçrayışlarını minimuma endirmək
- tunelləmə zamanı runtime etibarlılığını artırmaq

Power Mode davranışı adaptivdir və platforma imkanlarına və əməliyyat sistemi məhdudiyyətlərinə görə dəyişə bilər.

---

## Ekran görüntüləri

<img width="413" alt="GenyConnect screenshot 1" src="https://github.com/user-attachments/assets/c3c4fa7b-997c-4968-a019-ec8f1a88a7a1" />

<img width="422" alt="GenyConnect screenshot 2" src="https://github.com/user-attachments/assets/e8996ce9-1064-4754-8b4b-5d3c83009fa4" />

---

## Platforma dəstəyi

GenyConnect hazırda bunları dəstəkləyir:

- macOS
- Windows
- Linux
- Android

iOS dəstəyi aktiv inkişaf mərhələsindədir.

---

## Texnologiya steki

- C++23
- Qt 6 / QML
- Çoxplatformalı yerli runtime arxitekturası
- Çoxplatformalı yerləşdirmə pipeline-ları
- Engine-agnostic tunelləmə backend inteqrasiyası

---

## Lisenziyalaşdırma

GenyConnect Community Edition GNU General Public License versiya 3 və ya daha yenisi (GPL-3.0-or-later) ilə lisenziyalaşdırılır.

Kommersiya lisenziyası Genyleap Labs tərəfindən ayrıca aşağıdakılar üçün təqdim olunur:

- proprietar yerləşdirmələr
- closed-source yenidən paylama
- korporativ inteqrasiyalar
- white-label məhsullar
- App Store paylanması
- kommersiya buraxılışları
- Pro və ya Enterprise funksiyaları

Açıq şəkildə başqa cür göstərilməyibsə, aşağıdakılar GPL lisenziyası ilə əhatə olunmur və All Rights Reserved olaraq qalır:

- GenyConnect adı
- loqolar
- ikonlar
- ekran görüntüləri
- vizual dizayn
- brend aktivləri
- tanıtım qrafikləri
- UI artwork
- vizual kimlik materialları
- marketinq aktivləri

Forklar və yenidən paylamalar açıq yazılı icazə olmadan Genyleap Labs tərəfindən təsdiq və ya əlaqə təəssüratı yarada bilməz.

Tam lisenziya detalları üçün LICENSE və NOTICE fayllarına baxın.

### Lisenziya xülasəsi

Community Edition mənbə kodu:
- GPL-3.0-or-later

Kommersiya lisenziyası:
- Ayrı proprietar kommersiya lisenziyası

Brendinq və kod olmayan aktivlər:
- All Rights Reserved

---

## ❤️ GenyConnect-i dəstəkləyin

GenyConnect Genyleap Labs tərəfindən müstəqil inkişaf etdirilən layihədir.

GenyConnect sizə faydalıdırsa, Base Network üzərində $GENY və ya USDC ilə ianə edərək davamlı inkişafı dəstəkləyə bilərsiniz.

Dəstəyiniz bunları maliyyələşdirməyə kömək edir:

- davamlı inkişaf
- təhlükəsizlik təkmilləşdirmələri
- desktop və mobile platforma dəstəyi
- infrastruktur və test
- gələcək open-source buraxılışlar
- uzunmüddətli ekosistem böyüməsi

---

## 🌐 $GENY ilə dəstək

$GENY ilə ianə etməklə həm GenyConnect inkişafını, həm də daha geniş Geny ekosistemini dəstəkləyirsiniz.

### Base Mainnet

GENY token müqaviləsi:

`0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B`

Tərtibatçı ianə cüzdanı:

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

### Genyleap ekosistemi üçün $GENY alın və ya dəyişdirin

https://app.uniswap.org/swap?chain=base&outputCurrency=0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B

---

## 💵 USDC ilə dəstək

USDC inkişafı birbaşa dəstəkləmək üçün sabit və sadə yoldur.

### Base Mainnet

Tərtibatçı ianə cüzdanı:

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

---

## İanə bildirişi

İanələr GenyConnect inkişafını dəstəkləmək üçün könüllü töhfələrdir.

Onlar aşağıdakıları ifadə etmir:

- investisiya
- pay
- mülkiyyət
- gəlir paylaşımı
- qiymətli kağızlar
- maliyyə məhsulları
- maliyyə gəliri vədi

📢 İnkişaf yeniləmələrini, elanları və gələcək buraxılışları Telegram və Farcaster-də izləyin:

• Telegram: https://t.me/compezeth
• Telegram: https://t.me/genyleap
• X/Twitter: https://x.com/genyleap
• Farcaster: https://farcaster.xyz/compez.eth
• Farcaster: https://farcaster.xyz/genyleap

Rəyiniz və dəstəyiniz GenyConnect-in və daha geniş Genyleap ekosisteminin gələcəyini formalaşdırmağa kömək edir. 🚀
