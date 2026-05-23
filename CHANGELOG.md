# Changelog

All notable changes to GenyConnect are documented in this file.

## 1.2.860 - 2026-05-13

### Fixed

- Cross-platform TUN helper stability fix (`macOS`, `Windows`, `Linux`):
  privileged helper idle-timeout could previously terminate an active tunnel session, causing disconnects and repeated elevation/password prompts on reconnect.
- Helper lifecycle behavior changed:
  the privileged helper now stays alive while an active runtime session exists, and idle-timeout cleanup applies only when no active runtime/session is present.
- Owner watchdog hardening:
  helper shutdown now requires `3` consecutive failed owner-process checks before stopping runtime, reducing risk of silent disconnect from transient probe failures.

