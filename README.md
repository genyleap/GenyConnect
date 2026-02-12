# GenyConnect (Qt 6 + Xray-core)

A cross-platform desktop VPN client shell built with Qt 6 (C++) and QML.

## What this project does

- Uses official `xray-core` binary as an external process (`QProcess`)
- Dynamically generates Xray `config.json` from imported profile links
- Imports VLESS and VMESS links
- Manages VPN runtime state: `Disconnected`, `Connecting`, `Connected`, `Error`
- Captures and displays xray logs from stdout/stderr
- Tracks basic RX/TX counters from parsed log lines
- Provides a modern desktop UI for server profile management and connect/disconnect

## Architecture

### Backend (C++)

- `VpnController`
  - App-level state machine
  - Profile persistence
  - Runtime config writing
  - Connect/disconnect orchestration
- `XrayProcessManager`
  - Starts/stops xray process
  - Reads stdout/stderr logs
  - Emits lifecycle and traffic signals
- `LinkParser`
  - Parses `vless://` and `vmess://`
  - Normalizes fields into `ServerProfile`
- `XrayConfigBuilder`
  - Converts `ServerProfile` into an executable Xray JSON config
- `ServerProfileModel`
  - QML model for profile list UI

### UI (QML)

- Modern two-panel layout
- Profile list and link import panel
- Connect/disconnect state panel
- Live logs + traffic counters

## Build

Requirements:

- Qt 6.5+
- CMake 3.21+
- A local `xray-core` binary (download from official release channel)

Build steps:

```bash
cmake -S . -B build
cmake --build build
```

Optional: auto-download and bundle Xray during configure (no manual path selection in app):

```bash
cmake -S . -B build \
  -DGENYCONNECT_AUTO_DOWNLOAD_XRAY=ON \
  -DGENYCONNECT_XRAY_VERSION=v26.2.6
cmake --build build
```

Optional advanced override (if asset naming changes):

```bash
cmake -S . -B build \
  -DGENYCONNECT_AUTO_DOWNLOAD_XRAY=ON \
  -DGENYCONNECT_XRAY_VERSION=v26.2.6 \
  -DGENYCONNECT_XRAY_ASSET_NAME=Xray-macos-arm64-v8a.zip
```

Run:

```bash
./build/GenyConnect
```

If Xray is bundled (manual or auto), GenyConnect will detect `xray-core` near the app binary automatically.  
Otherwise, set path to your `xray` / `xray.exe` binary in the UI.

## Notes

- This project intentionally does not re-implement VPN protocols.
- Traffic counters are currently inferred from log patterns. For strict accounting, integrate Xray stats API endpoint polling in a later iteration.
