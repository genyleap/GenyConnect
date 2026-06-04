![genyconnect-cover](https://github.com/user-attachments/assets/a65daa50-b9ce-46e4-a23b-7886b1c41258)
---
# GenyConnect

[English](../README.md) | [Persian - فارسی](README.fa.md) | [Chinese - 中文](README.zh-CN.md) | [Japanese - 日本語](README.ja.md) | [Turkish - Türkçe](README.tr.md) | [Russian - Русский](README.ru.md) | [French - Français](README.fr.md) | [Spanish - Español](README.es.md) | [Korean - 한국어](README.ko.md) | [Azerbaijani - Azərbaycanca](README.az.md) | [Hindi - हिंदी](README.hi.md) | [Portuguese - Português](README.pt.md) | [Arabic - العربية](README.ar.md) | [German - Deutsch](README.de.md)


GenyConnect निजी networks और encrypted communications के लिए एक आधुनिक, cross-platform secure connectivity client है, जिसे performance, privacy और precise traffic management पर मजबूत focus के साथ बनाया गया है।

यह secure networking और tunneling engines के लिए एक powerful orchestration layer देता है, जो reliability, observability, operational transparency और user experience पर जोर देता है, जबकि किसी specific protocol, technology या implementation पर निर्भर नहीं रहता।

GenyConnect दो दिशाओं में develop हो रहा है: individual users और everyday connectivity needs के लिए Community Edition, और उन organizations के लिए Commercial & Enterprise Edition जिन्हें centralized management, network policies, access control और बड़े scale पर secure communications चाहिए।

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

## अवलोकन

GenyConnect उपयोगकर्ताओं को structured server profiles और shareable configuration links के माध्यम से सुरक्षित connections बनाने और प्रबंधित करने देता है।

Runtime configurations गतिशील रूप से बनाई जाती हैं, connection lifecycles स्पष्ट रूप से supervise किए जाते हैं, और system state हमेशा पूरी तरह observable रहती है।

Platform जानबूझकर engine-agnostic है, ताकि अलग-अलग tunneling backends को user workflows या expected behavior बदले बिना integrate किया जा सके।

GenyConnect सिर्फ generic tunneling use case तक सीमित नहीं है। इसका long-term direction services, private infrastructure, cloud resources और stable, reliable communication चाहने वाली distributed teams के access को manage करने वाली intelligent connectivity layer बनना है।

1.4 और 1.5 release range तक GenyConnect के broader public use के लिए अधिक mature होने और dependable connections चाहने वाले users की ज़रूरतों का बड़ा हिस्सा cover करने की उम्मीद है। Future releases में Persian और additional in-app languages जोड़ने की योजना है।

GenyConnect की second generation commercial और organizational needs पर अधिक गहराई से focus करेगी, जिसमें access management, communication infrastructure customization, network resilience, external services पर dependency कम करना और अलग-अलग network conditions में stable connectivity बनाए रखना शामिल है। Future versions में private networks और organizational access को define और manage करने के लिए dedicated `gen.` format और GenyConnect की अपनी communication architecture का support भी planned है।

---

## मुख्य क्षमताएँ

- स्पष्ट संचालन दृश्यता
  - Live logs
  - Real-time traffic statistics
  - स्पष्ट connection-state reporting

- उच्च-प्रदर्शन निष्पादन
  - हल्का runtime
  - न्यूनतम overhead
  - लगातार workloads में responsive

- नियत lifecycle management
  - पूर्वानुमेय startup
  - स्वच्छ shutdown
  - सुरक्षित reconnection logic

- उन्नत traffic routing
  - whitelist-based routing
  - domain-level tunnel/direct/block rules
  - जहाँ समर्थित हो application-based routing
  - जहाँ समर्थित हो process-based routing

- लचीले tunneling modes
  - application-level proxying
  - full system tunneling
  - consistent control surface

- LAN Sharing
  - GenyConnect-managed traffic को local network के दूसरे devices के साथ share करना
  - game consoles, smart TVs, phones, tablets, laptops और desktop computers जैसे devices को support करना
  - managed network environments के लिए advanced sharing controls

- क्रॉस-प्लेटफ़ॉर्म architecture
  - shared runtime core
  - desktop और mobile adapters
  - platform-specific integrations

---

## Power Mode

GenyConnect में platform-aware Power Mode system शामिल है, जिसे लगातार workloads के दौरान connection stability और runtime consistency बेहतर करने के लिए बनाया गया है।

Power Mode aggressive power-saving behavior, background throttling, idle suspension और sleep-state transitions से होने वाले operating-system interference को कम करने में मदद करता है।

Operating system और runtime backend के अनुसार, Power Mode यह कर सकता है:

- critical networking paths को responsive रखना
- unexpected disconnects कम करना
- throughput consistency सुधारना
- long-running traffic sessions को optimize करना
- heavy activity के दौरान latency spikes कम करना
- tunneling के दौरान runtime reliability बढ़ाना

Power Mode का behavior adaptive है और platform capabilities तथा operating-system restrictions के अनुसार बदल सकता है।

---

## स्क्रीनशॉट

<img width="413" alt="GenyConnect screenshot 1" src="https://github.com/user-attachments/assets/c3c4fa7b-997c-4968-a019-ec8f1a88a7a1" />

<img width="422" alt="GenyConnect screenshot 2" src="https://github.com/user-attachments/assets/e8996ce9-1064-4754-8b4b-5d3c83009fa4" />

---

## प्लेटफ़ॉर्म समर्थन

GenyConnect वर्तमान में support करता है:

- macOS
- Windows
- Linux
- Android

iOS support सक्रिय development में है।

---

## टेक्नोलॉजी स्टैक

- C++23
- Qt 6 / QML
- Cross-platform native runtime architecture
- Multi-platform deployment pipelines
- Engine-agnostic tunneling backend integration

---

## लाइसेंसिंग

GenyConnect Community Edition GNU General Public License version 3 या बाद के संस्करण (GPL-3.0-or-later) के अंतर्गत licensed है।

Commercial licensing Genyleap Labs से अलग से उपलब्ध है:

- proprietary deployments
- closed-source redistribution
- enterprise integrations
- white-label products
- App Store distribution
- commercial editions
- Pro या Enterprise features

जब तक स्पष्ट रूप से अलग न कहा गया हो, निम्न GPL license के अंतर्गत शामिल नहीं हैं और All Rights Reserved रहते हैं:

- GenyConnect नाम
- logos
- icons
- screenshots
- visual design
- branding assets
- promotional graphics
- UI artwork
- visual identity materials
- marketing assets

Forks और redistributions स्पष्ट लिखित अनुमति के बिना Genyleap Labs के endorsement या affiliation का संकेत नहीं दे सकते।

पूर्ण licensing details के लिए LICENSE और NOTICE files देखें।

### लाइसेंस सारांश

Community Edition source code:
- GPL-3.0-or-later

Commercial licensing:
- अलग proprietary commercial license

Branding और non-code assets:
- All Rights Reserved

---

## ❤️ GenyConnect का समर्थन करें

GenyConnect Genyleap Labs द्वारा स्वतंत्र रूप से विकसित project है।

यदि GenyConnect आपकी मदद करता है, तो आप Base Network पर $GENY या USDC से donation करके इसके continued development का समर्थन कर सकते हैं।

आपका समर्थन इन चीज़ों को fund करने में मदद करता है:

- continued development
- security improvements
- desktop और mobile platform support
- infrastructure और testing
- future open-source releases
- long-term ecosystem growth

---

## 🌐 $GENY से समर्थन करें

$GENY से donation करके आप GenyConnect development और व्यापक Geny ecosystem दोनों का समर्थन करते हैं।

### Base Mainnet

GENY Token Contract:

`0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B`

Developer Donation Wallet:

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

### Genyleap ecosystem के लिए $GENY खरीदें या swap करें

https://app.uniswap.org/swap?chain=base&outputCurrency=0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B

---

## 💵 USDC से समर्थन करें

USDC development को सीधे support करने का stable और simple तरीका है।

### Base Mainnet

Developer Donation Wallet:

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

---

## दान सूचना

Donations GenyConnect development को support करने के लिए voluntary contributions हैं।

वे इनका प्रतिनिधित्व नहीं करते:

- investment
- equity
- ownership
- revenue sharing
- securities
- financial products
- financial return के promises

📢 Development updates, announcements और future releases को Telegram और Farcaster पर follow करें:

• Telegram: https://t.me/compezeth
• Telegram: https://t.me/genyleap
• X/Twitter: https://x.com/genyleap
• Farcaster: https://farcaster.xyz/compez.eth
• Farcaster: https://farcaster.xyz/genyleap

आपका feedback और support GenyConnect और व्यापक Genyleap ecosystem के भविष्य को आकार देने में मदद करता है। 🚀
