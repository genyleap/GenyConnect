# GenyConnect

GenyConnect is a modern, cross-platform secure tunneling client designed for high performance, privacy, and precise traffic control.

- It orchestrates encrypted connections with remote servers, allowing users to import shareable links, manage multiple server profiles, dynamically generate runtime configurations, and control connection lifecycles safely and reliably. Live logs, real-time traffic statistics, and clear connection-state reporting provide full visibility into network activity.
- GenyConnect delivers lightweight, efficient performance, ensuring minimal overhead even under heavy traffic, making it responsive and reliable for both everyday use and demanding workloads. It supports clean application-level proxying and system-wide tunneling, with a polished user experience that reduces repeated authentication prompts, provides readable and copyable logs, and guarantees deterministic connection behavior.
- Advanced routing controls give power users fine-grained command over traffic flows, including whitelist-based routing, domain-level tunnel/direct/block rules, and application- or process-based routing. This combination of speed, security, transparency, and flexibility makes GenyConnect ideal for users who demand maximum control without compromising performance, all within a streamlined, responsive interface.

## Build

Requirements:

- C++20
- Qt 6.10+
- CMake 4.x+

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
