![genyconnect-cover](https://github.com/user-attachments/assets/a65daa50-b9ce-46e4-a23b-7886b1c41258)
---
# GenyConnect

[English](../README.md) | [Persian - فارسی](README.fa.md) | [Chinese - 中文](README.zh-CN.md) | [Japanese - 日本語](README.ja.md) | [Turkish - Türkçe](README.tr.md) | [Russian - Русский](README.ru.md) | [French - Français](README.fr.md) | [Spanish - Español](README.es.md) | [Korean - 한국어](README.ko.md) | [Azerbaijani - Azərbaycanca](README.az.md) | [Hindi - हिंदी](README.hi.md) | [Portuguese - Português](README.pt.md) | [Arabic - العربية](README.ar.md) | [German - Deutsch](README.de.md)


GenyConnect ist ein moderner, plattformübergreifender Client für sichere Konnektivität in privaten Netzwerken und verschlüsselter Kommunikation, entwickelt mit starkem Fokus auf Leistung, Datenschutz und präzises Traffic-Management.

Er stellt eine leistungsfähige Orchestrierungsschicht für sichere Netzwerk- und Tunneling-Engines bereit und betont Zuverlässigkeit, Beobachtbarkeit, operative Transparenz und Benutzererfahrung, während er unabhängig von einem bestimmten Protokoll, einer Technologie oder einer Implementierung bleibt.

GenyConnect wird in zwei Richtungen entwickelt: als Community Edition für einzelne Nutzer und alltägliche Konnektivitätsanforderungen sowie als Commercial & Enterprise Edition für Organisationen, die zentrale Verwaltung, Netzwerkrichtlinien, Zugriffskontrolle und sichere Kommunikation im großen Maßstab benötigen.

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

## Überblick

GenyConnect ermöglicht es Benutzern, sichere Verbindungen über strukturierte Serverprofile und teilbare Konfigurationslinks einzurichten und zu verwalten.

Runtime-Konfigurationen werden dynamisch erzeugt, Verbindungslebenszyklen werden explizit überwacht, und der Systemzustand bleibt jederzeit vollständig beobachtbar.

Die Plattform ist bewusst engine-agnostic angelegt, sodass verschiedene Tunneling-Backends integriert werden können, ohne Benutzerabläufe oder erwartetes Verhalten zu ändern.

GenyConnect ist nicht auf einen allgemeinen Tunneling-Anwendungsfall beschränkt. Die langfristige Ausrichtung ist eine intelligente Konnektivitätsschicht zur Verwaltung des Zugriffs auf Dienste, private Infrastruktur, Cloud-Ressourcen und verteilte Teams, die stabile und zuverlässige Kommunikation benötigen.

Im Bereich der Versionen 1.4 und 1.5 soll GenyConnect für eine breitere öffentliche Nutzung reifen und einen wesentlichen Teil der Anforderungen von Nutzern abdecken, die zuverlässige Verbindungen benötigen. Für künftige Versionen sind außerdem Persian und weitere In-App-Sprachen geplant.

Die zweite Generation von GenyConnect wird sich stärker auf geschäftliche und organisatorische Anforderungen konzentrieren, darunter Zugriffsverwaltung, Anpassung der Kommunikationsinfrastruktur, Netzwerkresilienz, geringere Abhängigkeit von externen Diensten und stabile Konnektivität unter verschiedenen Netzwerkbedingungen. Künftige Versionen sollen außerdem das dedizierte `gen.`-Format und die eigene Kommunikationsarchitektur von GenyConnect unterstützen, um private Netzwerke und organisatorische Zugriffe zu definieren und zu verwalten.

---

## Kernfunktionen

- Klare operative Sichtbarkeit
  - Live-Logs
  - Traffic-Statistiken in Echtzeit
  - Explizite Berichte zum Verbindungsstatus

- Leistungsstarke Ausführung
  - Leichtgewichtige Runtime
  - Minimale Zusatzlast
  - Reaktionsfähig unter dauerhafter Last

- Deterministisches Lebenszyklusmanagement
  - Vorhersehbarer Start
  - Sauberes Herunterfahren
  - Sichere Wiederverbindungslogik

- Erweitertes Traffic-Routing
  - whitelist-basiertes Routing
  - domainbasierte tunnel/direct/block-Regeln
  - anwendungsbasiertes Routing, wo unterstützt
  - prozessbasiertes Routing, wo unterstützt

- Flexible Tunneling-Modi
  - Proxying auf Anwendungsebene
  - vollständiges System-Tunneling
  - konsistente Steueroberfläche

- LAN Sharing
  - von GenyConnect verwalteten Traffic mit anderen Geräten im lokalen Netzwerk teilen
  - Geräte wie Spielkonsolen, Smart-TVs, Telefone, Tablets, Laptops und Desktop-Computer unterstützen
  - erweiterte Freigabesteuerung für verwaltete Netzwerkumgebungen

- Plattformübergreifende Architektur
  - gemeinsamer runtime core
  - Desktop- und Mobile-Adapter
  - plattform­spezifische Integrationen

---

## Power Mode

GenyConnect enthält ein plattformbewusstes Power Mode-System, das die Verbindungsstabilität und Runtime-Konsistenz bei dauerhaften Workloads verbessert.

Power Mode hilft, Eingriffe des Betriebssystems durch aggressive Energiesparmechanismen, Hintergrunddrosselung, Leerlauf-Suspendierung und Übergänge in den Schlafzustand zu reduzieren.

Je nach Betriebssystem und runtime backend kann Power Mode:

- kritische Netzwerkpfade reaktionsfähig halten
- unerwartete Verbindungsabbrüche reduzieren
- die Durchsatzkonsistenz verbessern
- lange Traffic-Sitzungen optimieren
- Latenzspitzen bei hoher Aktivität minimieren
- die Runtime-Zuverlässigkeit beim Tunneling verbessern

Das Verhalten von Power Mode ist adaptiv und kann je nach Plattformfähigkeiten und Betriebssystembeschränkungen variieren.

---

## Screenshots

<img width="413" alt="GenyConnect screenshot 1" src="https://github.com/user-attachments/assets/c3c4fa7b-997c-4968-a019-ec8f1a88a7a1" />

<img width="422" alt="GenyConnect screenshot 2" src="https://github.com/user-attachments/assets/e8996ce9-1064-4754-8b4b-5d3c83009fa4" />

---

## Plattformunterstützung

GenyConnect unterstützt derzeit:

- macOS
- Windows
- Linux
- Android

iOS-Unterstützung befindet sich in aktiver Entwicklung.

---

## Technologie-Stack

- C++23
- Qt 6 / QML
- Plattformübergreifende native Runtime-Architektur
- Bereitstellungspipelines für mehrere Plattformen
- Engine-agnostic Tunneling-Backend-Integration

---

## Lizenzierung

GenyConnect Community Edition ist unter der GNU General Public License Version 3 oder höher (GPL-3.0-or-later) lizenziert.

Kommerzielle Lizenzen sind separat von Genyleap Labs verfügbar für:

- proprietäre Bereitstellungen
- Closed-Source-Weiterverteilung
- Enterprise-Integrationen
- white-label Produkte
- App Store-Verteilung
- kommerzielle Editionen
- Pro- oder Enterprise-Funktionen

Sofern nicht ausdrücklich anders angegeben, sind die folgenden Elemente NICHT von der GPL-Lizenz abgedeckt und bleiben All Rights Reserved:

- Name GenyConnect
- Logos
- Icons
- Screenshots
- visuelles Design
- Branding-Assets
- Werbegrafiken
- UI-Artwork
- Materialien der visuellen Identität
- Marketing-Assets

Forks und Weiterverteilungen dürfen ohne ausdrückliche schriftliche Genehmigung keine Unterstützung durch oder Zugehörigkeit zu Genyleap Labs suggerieren.

Vollständige Lizenzdetails finden Sie in den Dateien LICENSE und NOTICE.

### Lizenzübersicht

Quellcode der Community Edition:
- GPL-3.0-or-later

Kommerzielle Lizenzierung:
- Separate proprietäre kommerzielle Lizenz

Branding- und Nicht-Code-Assets:
- All Rights Reserved

---

## ❤️ GenyConnect unterstützen

GenyConnect ist ein unabhängig entwickeltes Projekt von Genyleap Labs.

Wenn GenyConnect Ihnen hilft, können Sie die laufende Entwicklung mit $GENY oder USDC im Base Network unterstützen.

Ihre Unterstützung finanziert:

- laufende Entwicklung
- Sicherheitsverbesserungen
- Desktop- und Mobile-Plattformunterstützung
- Infrastruktur und Tests
- zukünftige Open-Source-Veröffentlichungen
- langfristiges Wachstum des Ökosystems

---

## 🌐 Mit $GENY unterstützen

Mit einer Spende in $GENY unterstützen Sie sowohl die Entwicklung von GenyConnect als auch das breitere Geny-Ökosystem.

### Base Mainnet

GENY-Token-Vertrag:

`0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B`

Entwickler-Spenden-Wallet:

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

### $GENY für das Genyleap-Ökosystem kaufen oder tauschen

https://app.uniswap.org/swap?chain=base&outputCurrency=0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B

---

## 💵 Mit USDC unterstützen

USDC ist eine stabile und einfache Möglichkeit, die Entwicklung direkt zu unterstützen.

### Base Mainnet

Entwickler-Spenden-Wallet:

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

---

## Hinweis zu Spenden

Spenden sind freiwillige Beiträge zur Unterstützung der Entwicklung von GenyConnect.

Sie stellen Folgendes nicht dar:

- Investition
- Eigenkapital
- Eigentum
- Umsatzbeteiligung
- Wertpapiere
- Finanzprodukte
- Versprechen finanzieller Rendite

📢 Folgen Sie Entwicklungsupdates, Ankündigungen und zukünftigen Veröffentlichungen auf Telegram und Farcaster:

• Telegram: https://t.me/compezeth
• Telegram: https://t.me/genyleap
• X/Twitter: https://x.com/genyleap
• Farcaster: https://farcaster.xyz/compez.eth
• Farcaster: https://farcaster.xyz/genyleap

Ihr Feedback und Ihre Unterstützung helfen, die Zukunft von GenyConnect und des breiteren Genyleap-Ökosystems zu gestalten. 🚀
