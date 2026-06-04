<img width="1983" height="793" alt="IMG_2823" src="https://github.com/user-attachments/assets/8e1b1d9d-9ba6-4c47-b2b0-f5629951b532" />

---
# GenyConnect

[English](README.md) | [Persian - فارسی](readme/README.fa.md) | [Chinese - 中文](readme/README.zh-CN.md) | [Japanese - 日本語](readme/README.ja.md) | [Turkish - Türkçe](readme/README.tr.md) | [Russian - Русский](readme/README.ru.md) | [French - Français](readme/README.fr.md) | [Spanish - Español](readme/README.es.md) | [Korean - 한국어](readme/README.ko.md) | [Azerbaijani - Azərbaycanca](readme/README.az.md) | [Hindi - हिंदी](readme/README.hi.md) | [Portuguese - Português](readme/README.pt.md) | [Arabic - العربية](readme/README.ar.md) | [German - Deutsch](readme/README.de.md)

GenyConnect is a modern, cross-platform secure connectivity client for private networks and encrypted communications, built with a strong focus on performance, privacy, and precise traffic management.

It provides a powerful orchestration layer for secure networking and tunneling engines, emphasizing reliability, observability, operational transparency, and user experience, while remaining independent of any specific protocol, technology, or implementation.

GenyConnect is being developed in two directions: a Community Edition for individual users and everyday connectivity needs, and a Commercial & Enterprise Edition designed for organizations that require centralized management, network policies, access control, and secure communications at scale.
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

  <a href="./LICENSE">
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

## Overview

GenyConnect enables users to establish and manage secure connections through structured server profiles and shareable configuration links.

Runtime configurations are generated dynamically, connection lifecycles are supervised explicitly, and system state remains fully observable at all times.

The platform is intentionally engine-agnostic, allowing different tunneling backends to be integrated without altering user workflows or expected behavior.

GenyConnect is not limited to a generic tunneling use case. Its long-term direction is an intelligent connectivity layer for managing access to services, private infrastructure, cloud resources, and distributed teams that require stable and reliable communication.

By the 1.4 and 1.5 release range, GenyConnect is expected to mature for broader public use and cover a substantial set of needs for users who require dependable connections. Future releases are planned to add Persian and additional in-app languages.

The second generation of GenyConnect will focus more deeply on commercial and organizational needs, including access management, communication infrastructure customization, network resilience, reduced dependence on external services, and stable connectivity under varying network conditions. Future versions are also planned to support the dedicated `gen.` format and GenyConnect's own communication architecture for defining and managing private networks and organizational access.

---

## Key Capabilities

- Clear operational visibility
  - Live logs
  - Real-time traffic statistics
  - Explicit connection-state reporting

- High-performance execution
  - Lightweight runtime
  - Minimal overhead
  - Responsive under sustained workloads

- Deterministic lifecycle management
  - Predictable startup
  - Clean shutdown
  - Safe reconnection logic

- Advanced traffic routing
  - whitelist-based routing
  - domain-level tunnel/direct/block rules
  - application-based routing where supported
  - process-based routing where supported

- Flexible tunneling modes
  - application-level proxying
  - full system tunneling
  - consistent control surface

- LAN Sharing
  - share GenyConnect-managed traffic with other devices on the local network
  - support devices such as game consoles, smart TVs, phones, tablets, laptops, and desktop computers
  - advanced sharing controls for managed network environments

- Cross-platform architecture
  - shared runtime core
  - desktop and mobile adapters
  - platform-specific integrations

---

## Power Mode

GenyConnect includes a platform-aware Power Mode system designed to improve connection stability and runtime consistency during sustained workloads.

Power Mode helps reduce operating-system interference caused by aggressive power-saving behavior, background throttling, idle suspension, and sleep-state transitions.

Depending on the operating system and runtime backend, Power Mode may:

- keep critical networking paths responsive
- reduce unexpected disconnects
- improve throughput consistency
- optimize long-running traffic sessions
- minimize latency spikes during heavy activity
- improve runtime reliability while tunneling

Power Mode behavior is adaptive and may vary depending on platform capabilities and operating-system restrictions.

---

## Screenshots
<img width="420" height="754" alt="Screenshot 2026-06-04 at 23 35 19" src="https://github.com/user-attachments/assets/ca927696-f2fe-445d-93ed-2da8a40e3d2e" />
<img width="423" height="753" alt="Screenshot 2026-06-04 at 23 35 29" src="https://github.com/user-attachments/assets/aadde2a8-03d9-4c12-8875-31ee81d4ff2c" />

---

## Platform Support

GenyConnect currently supports:

- macOS
- Windows
- Linux
- Android

iOS support is under active development.

---

## Technology Stack

- C++23
- Qt 6 / QML
- Cross-platform native runtime architecture
- Multi-platform deployment pipelines
- Engine-agnostic tunneling backend integration

---

## Licensing

GenyConnect Community Edition is licensed under the GNU General Public License version 3 or later (GPL-3.0-or-later).

Commercial licensing is available separately from Genyleap Labs for:

- proprietary deployments
- closed-source redistribution
- enterprise integrations
- white-label products
- App Store distribution
- commercial editions
- Pro or Enterprise features

Unless explicitly stated otherwise, the following are NOT covered by the GPL license and remain All Rights Reserved:

- GenyConnect name
- logos
- icons
- screenshots
- visual design
- branding assets
- promotional graphics
- UI artwork
- visual identity materials
- marketing assets

Forks and redistributions may not imply endorsement by or affiliation with Genyleap Labs without explicit written permission.

See the LICENSE and NOTICE files for full licensing details.

### License Summary

Community Edition source code:
- GPL-3.0-or-later

Commercial licensing:
- Separate proprietary commercial license

Branding and non-code assets:
- All Rights Reserved

---

## ❤️ Support GenyConnect

GenyConnect is an independently developed project by Genyleap Labs.

If GenyConnect helps you, you can support its continued development by donating with $GENY or USDC on the Base Network.

Your support helps fund:

- continued development
- security improvements
- desktop and mobile platform support
- infrastructure and testing
- future open-source releases
- long-term ecosystem growth

---

## 🌐 Support with $GENY

By donating with $GENY, you are supporting both GenyConnect development and the broader Geny ecosystem.

### Base Mainnet

GENY Token Contract:

`0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B`

Developer Donation Wallet:

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

### Buy or Swap $GENY for Genyleap ecosystem

https://app.uniswap.org/swap?chain=base&outputCurrency=0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B

---

## 💵 Support with USDC

USDC is a stable and simple way to support development directly.

### Base Mainnet

Developer Donation Wallet:

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

---

## Donation Notice

Donations are voluntary contributions to support GenyConnect development.

They do not represent:

- investment
- equity
- ownership
- revenue sharing
- securities
- financial products
- promises of financial return

📢 Follow development updates, announcements, and future releases on Telegram and Farcaster:

• Telegram: https://t.me/compezeth
• Telegram: https://t.me/genyleap
• X/Twitter: https://x.com/genyleap
• Farcaster: https://farcaster.xyz/compez.eth
• Farcaster: https://farcaster.xyz/genyleap

Your feedback and support help shape the future of GenyConnect and the broader Genyleap ecosystem. 🚀
