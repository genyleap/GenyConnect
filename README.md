![genyconnect-cover](https://github.com/user-attachments/assets/a65daa50-b9ce-46e4-a23b-7886b1c41258)
---
# GenyConnect
GenyConnect is a modern, cross-platform secure tunneling client and VPN designed for high performance, privacy, and precise traffic control.

It provides a robust orchestration layer for secure network engines, focusing on correctness, observability, and user experience rather than binding itself to any single protocol or implementation.
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

<img width="413" alt="GenyConnect screenshot 1" src="https://github.com/user-attachments/assets/c3c4fa7b-997c-4968-a019-ec8f1a88a7a1" />

<img width="422" alt="GenyConnect screenshot 2" src="https://github.com/user-attachments/assets/e8996ce9-1064-4754-8b4b-5d3c83009fa4" />

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