![genyconnect-cover](https://github.com/user-attachments/assets/a65daa50-b9ce-46e4-a23b-7886b1c41258)
---
# GenyConnect

[English](../README.md) | [Persian - فارسی](README.fa.md) | [Chinese - 中文](README.zh-CN.md) | [Japanese - 日本語](README.ja.md) | [Turkish - Türkçe](README.tr.md) | [Russian - Русский](README.ru.md) | [French - Français](README.fr.md) | [Spanish - Español](README.es.md) | [Korean - 한국어](README.ko.md) | [Azerbaijani - Azərbaycanca](README.az.md) | [Hindi - हिंदी](README.hi.md) | [Portuguese - Português](README.pt.md) | [Arabic - العربية](README.ar.md) | [German - Deutsch](README.de.md)


GenyConnect; özel ağlar ve şifreli iletişim için geliştirilmiş, performans, gizlilik ve hassas trafik yönetimine güçlü biçimde odaklanan modern, çapraz platformlu güvenli bir bağlantı istemcisidir.

Güvenli ağ ve tünelleme motorları için güçlü bir orkestrasyon katmanı sağlar; güvenilirlik, gözlemlenebilirlik, operasyonel şeffaflık ve kullanıcı deneyimini vurgularken herhangi bir belirli protokole, teknolojiye veya uygulamaya bağlı kalmaz.

GenyConnect iki yönde geliştirilmektedir: bireysel kullanıcılar ve günlük bağlantı ihtiyaçları için Community Edition, merkezi yönetim, ağ politikaları, erişim kontrolü ve büyük ölçekte güvenli iletişim gerektiren kuruluşlar için Commercial & Enterprise Edition.

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

## Genel Bakış

GenyConnect, kullanıcıların yapılandırılmış sunucu profilleri ve paylaşılabilir yapılandırma bağlantıları üzerinden güvenli bağlantılar kurmasını ve yönetmesini sağlar.

Runtime yapılandırmaları dinamik olarak üretilir, bağlantı yaşam döngüleri açıkça denetlenir ve sistem durumu her zaman tamamen gözlemlenebilir kalır.

Platform bilinçli olarak engine-agnostic tasarlanmıştır; farklı tünelleme backend’leri kullanıcı akışlarını veya beklenen davranışı değiştirmeden entegre edilebilir.

GenyConnect yalnızca genel amaçlı bir tünelleme aracıyla sınırlı değildir. Uzun vadeli yönü; servisler, özel altyapılar, bulut kaynakları ve kararlı, güvenilir iletişim gerektiren dağıtık ekipler için erişimi yöneten akıllı bir bağlantı katmanı olmaktır.

1.4 ve 1.5 sürüm aralığında GenyConnect’in daha geniş genel kullanım için olgunlaşması ve güvenilir bağlantı isteyen kullanıcıların ihtiyaçlarının önemli bir bölümünü karşılaması beklenmektedir. Gelecek sürümlerde Persian ve ek uygulama içi dillerin eklenmesi planlanmaktadır.

GenyConnect’in ikinci nesli, erişim yönetimi, iletişim altyapısı özelleştirme, ağ dayanıklılığı, dış servislere bağımlılığı azaltma ve değişen ağ koşullarında bağlantı kararlılığını koruma gibi ticari ve kurumsal ihtiyaçlara daha derinden odaklanacaktır. Gelecek sürümlerde özel `gen.` biçimi ve özel ağlar ile kurumsal erişimleri tanımlayıp yönetmek için GenyConnect’in kendi iletişim mimarisinin desteklenmesi de planlanmaktadır.

---

## Temel Yetenekler

- Net operasyonel görünürlük
  - Canlı günlükler
  - Gerçek zamanlı trafik istatistikleri
  - Açık bağlantı durumu raporlaması

- Yüksek performanslı çalışma
  - Hafif runtime
  - Minimum ek yük
  - Sürekli yüklerde duyarlı çalışma

- Deterministik yaşam döngüsü yönetimi
  - Öngörülebilir başlatma
  - Temiz kapatma
  - Güvenli yeniden bağlanma mantığı

- Gelişmiş trafik yönlendirme
  - whitelist tabanlı yönlendirme
  - domain düzeyinde tunnel/direct/block kuralları
  - desteklendiğinde uygulama tabanlı yönlendirme
  - desteklendiğinde süreç tabanlı yönlendirme

- Esnek tünelleme modları
  - uygulama düzeyinde proxy
  - tam sistem tünelleme
  - tutarlı kontrol yüzeyi

- LAN Sharing
  - GenyConnect tarafından yönetilen trafiği yerel ağdaki diğer cihazlarla paylaşma
  - oyun konsolları, akıllı TV’ler, telefonlar, tabletler, dizüstü ve masaüstü bilgisayarlar gibi cihazları destekleme
  - yönetilen ağ ortamları için gelişmiş paylaşım denetimleri

- Çapraz platform mimarisi
  - paylaşılan runtime core
  - desktop ve mobile adaptörleri
  - platforma özel entegrasyonlar

---

## Power Mode

GenyConnect, sürekli iş yüklerinde bağlantı kararlılığını ve runtime tutarlılığını iyileştirmek için tasarlanmış platform farkındalıklı bir Power Mode sistemi içerir.

Power Mode, agresif güç tasarrufu, arka plan kısıtlama, boşta askıya alma ve uyku durum geçişlerinden kaynaklanan işletim sistemi müdahalesini azaltmaya yardımcı olur.

İşletim sistemine ve runtime backend’e bağlı olarak Power Mode şunları sağlayabilir:

- kritik ağ yollarını duyarlı tutmak
- beklenmeyen kopmaları azaltmak
- verim tutarlılığını iyileştirmek
- uzun süreli trafik oturumlarını optimize etmek
- yoğun etkinlik sırasında gecikme sıçramalarını azaltmak
- tünelleme sırasında runtime güvenilirliğini artırmak

Power Mode davranışı uyarlanabilirdir ve platform yetenekleri ile işletim sistemi kısıtlarına göre değişebilir.

---

## Ekran Görüntüleri

<img width="413" alt="GenyConnect screenshot 1" src="https://github.com/user-attachments/assets/c3c4fa7b-997c-4968-a019-ec8f1a88a7a1" />

<img width="422" alt="GenyConnect screenshot 2" src="https://github.com/user-attachments/assets/e8996ce9-1064-4754-8b4b-5d3c83009fa4" />

---

## Platform Desteği

GenyConnect şu anda şunları destekler:

- macOS
- Windows
- Linux
- Android

iOS desteği aktif geliştirme aşamasındadır.

---

## Teknoloji Yığını

- C++23
- Qt 6 / QML
- Çapraz platform yerel runtime mimarisi
- Çok platformlu dağıtım hatları
- Engine-agnostic tünelleme backend entegrasyonu

---

## Lisanslama

GenyConnect Community Edition, GNU General Public License sürüm 3 veya üzeri (GPL-3.0-or-later) ile lisanslanır.

Ticari lisanslama Genyleap Labs tarafından ayrıca şu kullanımlar için sunulur:

- özel dağıtımlar
- kapalı kaynak yeniden dağıtım
- kurumsal entegrasyonlar
- white-label ürünler
- App Store dağıtımı
- ticari sürümler
- Pro veya Enterprise özellikleri

Aksi açıkça belirtilmedikçe aşağıdakiler GPL lisansı kapsamında DEĞİLDİR ve All Rights Reserved olarak kalır:

- GenyConnect adı
- logolar
- ikonlar
- ekran görüntüleri
- görsel tasarım
- marka varlıkları
- tanıtım grafikleri
- UI artwork
- görsel kimlik materyalleri
- pazarlama varlıkları

Fork’lar ve yeniden dağıtımlar, açık yazılı izin olmadan Genyleap Labs tarafından onaylandığını veya ilişkili olduğunu ima edemez.

Tam lisans ayrıntıları için LICENSE ve NOTICE dosyalarına bakın.

### Lisans Özeti

Community Edition kaynak kodu:
- GPL-3.0-or-later

Ticari lisanslama:
- Ayrı özel ticari lisans

Marka ve kod dışı varlıklar:
- All Rights Reserved

---

## ❤️ GenyConnect’i Destekleyin

GenyConnect, Genyleap Labs tarafından bağımsız olarak geliştirilen bir projedir.

GenyConnect size yardımcı oluyorsa Base Network üzerinde $GENY veya USDC ile bağış yaparak sürekli geliştirmeyi destekleyebilirsiniz.

Desteğiniz şunları finanse etmeye yardımcı olur:

- sürekli geliştirme
- güvenlik iyileştirmeleri
- desktop ve mobile platform desteği
- altyapı ve test
- gelecekteki open-source yayınlar
- uzun vadeli ekosistem büyümesi

---

## 🌐 $GENY ile Destekleyin

$GENY ile bağış yaparak hem GenyConnect geliştirmesini hem de daha geniş Geny ekosistemini desteklersiniz.

### Base Mainnet

GENY Token Sözleşmesi:

`0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B`

Geliştirici Bağış Cüzdanı:

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

### Genyleap ekosistemi için $GENY satın alın veya takas edin

https://app.uniswap.org/swap?chain=base&outputCurrency=0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B

---

## 💵 USDC ile Destekleyin

USDC, geliştirmeyi doğrudan desteklemek için kararlı ve basit bir yoldur.

### Base Mainnet

Geliştirici Bağış Cüzdanı:

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

---

## Bağış Bildirimi

Bağışlar, GenyConnect geliştirmesini desteklemek için gönüllü katkılardır.

Şunları temsil etmezler:

- yatırım
- hisse
- sahiplik
- gelir paylaşımı
- menkul kıymetler
- finansal ürünler
- finansal getiri vaadi

📢 Geliştirme güncellemelerini, duyuruları ve gelecek yayınları Telegram ve Farcaster üzerinden takip edin:

• Telegram: https://t.me/compezeth
• Telegram: https://t.me/genyleap
• X/Twitter: https://x.com/genyleap
• Farcaster: https://farcaster.xyz/compez.eth
• Farcaster: https://farcaster.xyz/genyleap

Geri bildiriminiz ve desteğiniz GenyConnect’in ve daha geniş Genyleap ekosisteminin geleceğini şekillendirmeye yardımcı olur. 🚀
