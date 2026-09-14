# Changelog

All notable changes to GenyConnect are documented in this file.

## 1.4.950

### Improved

- Searchable, grouped Settings and responsive desktop/mobile layouts with more consistent spacing, wrapping text, and Persian/Arabic alignment.
- Shared dark-theme colors, bundled font loading, keyboard focus, tab selection, and touch interaction.
- Profile selection and import controls, including a wrapping placeholder, a scrollable editor, and mobile system-bar clearance.

### Fixed

- Import editor height binding loop and recursive import target layout calculation.
- Routing-rule persistence and runtime consistency, exact executable matching, and application discovery on Windows.
- Linux TUN policy routing, core outbound bypass, route-readiness checks, and cleanup; added NixOS system integration.
- AppImage Qt/Wayland/X11 dependency deployment for x86_64 and ARM64.
- Conditional C++ module declarations rejected by Clang dependency scanning, with clearer CMake generator diagnostics and Android NDK scanner selection.

See the [v1.4.950 release notes](release-notes/v1.4.950.md) for platform requirements and validation status. Full cross-platform build and runtime validation remains pending.

## 1.2.860 - 2026-05-13

### Fixed

- Cross-platform TUN helper stability fix (`macOS`, `Windows`, `Linux`):
  privileged helper idle-timeout could previously terminate an active tunnel session, causing disconnects and repeated elevation/password prompts on reconnect.
- Helper lifecycle behavior changed:
  the privileged helper now stays alive while an active runtime session exists, and idle-timeout cleanup applies only when no active runtime/session is present.
- Owner watchdog hardening:
  helper shutdown now requires `3` consecutive failed owner-process checks before stopping runtime, reducing risk of silent disconnect from transient probe failures.
