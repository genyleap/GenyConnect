# Open issue review

Reviewed against the complete open issue list on 8 September 2026. There are eight open issues, including all four explicitly linked in the request. This change implements fixes for the four linked defects and related Settings UI problems. The four additional feature requests were reviewed and remain outstanding; they are not classified as resolved.

No application, helper, test suite, compiler, build configuration, QML runtime, or packaging validation script was executed during this work. Findings and changes were reviewed statically. GitHub issues were not commented on or closed.

## Defects addressed in this change

| Issue | Finding and implementation | Remaining confirmation |
| --- | --- | --- |
| [#34 — TUN mode not working in NixOS](https://github.com/genyleap/GenyConnect/issues/34) | Legacy TUN configuration keys did not establish Linux host routing. Readiness could accept the interface's own subnet route without proving that Internet destinations used it. The helper now owns separate IPv4/IPv6 policy routing, marks the core's outbound sockets to avoid re-entry, verifies actual route selection and outbound bypass, and unwinds its changes on failure or shutdown. The Nix package supplies an absolute iproute2 path; an optional NixOS module supplies the required system settings. | Actual traffic, DNS, privilege prompts, firewall behavior, and cleanup require runtime verification. Route lookup readiness establishes routing state, not end-to-end VPN connectivity. |
| [#33 — font issue windows](https://github.com/genyleap/GenyConnect/issues/33) | Register bundled text and icon fonts before QML creates text; use resolved families, explicit weights, and Arabic fallback. Remove requests for unavailable icon font styles and retain existing FontSystem accessors. The screenshot motivates this change, but its original rendering cause cannot be conclusively established from source alone. | Revisit the original Windows symptom, display scaling, language changes, and mixed-script labels. Linux and macOS rendering also remain unverified. |
| [#18 — AppImage startup dependencies](https://github.com/genyleap/GenyConnect/issues/18) | Share one deployment path between x86_64 and aarch64. Require Wayland/xcb platform and client integration plugins with their dependencies, isolate bundled Qt/QML paths, keep Linux Controls on Basic, and reject incomplete artifacts before publication. The later RectangularShadow report was reviewed; the current UI no longer references that type. | Packaging and launch on KDE Wayland and X11 were not performed. The revised packaging checks were edited but not run. |
| [#6 — game and app exclusions](https://github.com/genyleap/GenyConnect/issues/6) | Legacy rule properties and the ordered model now share persistence and runtime configuration. Preserve exact executable names/paths instead of widening full paths into basename matches. Prefer actual running executables in the picker, including Windows Toolhelp enumeration. Re-detect the prepared core before connection. Unsupported or invalid saved rules remain visible; an enabled applicable rule that cannot be applied stops connection with an explanation. | Verify real game traffic and child-process selection on Windows and Linux. The currently supported macOS runtime does not advertise process routing; stored rules remain editable and can be disabled. Domain/IP/protocol rules remain available there. |

## Settings and related UI

- Group settings into Connection, Application, and Help & Support, with search and an empty state.
- Provide separate back and close controls on desktop and mobile, with accessible names and keyboard focus.
- Use the drawer's available width for responsive controls. Wrap titles, rule targets, and explanations instead of forcing fixed-height rows.
- Fit interface choices, connection modes, DNS presets, LAN endpoint information, and routing actions within the same narrower drawer.
- Keep focused controls visible through nested scrolling, including variable-height lists and RTL scrollbar placement.
- Remove invisible legacy rule editors that could write back to settings through bindings.
- Add new navigation, grouping, rule-action, and availability strings to all eight non-English catalogs and the bundled catalog.

## Screenshot follow-up — 9 September 2026

The supplied macOS screenshots exposed additional Persian alignment and theme inconsistencies. The desktop sidebar now has symmetric insets, rounded selection states, wrapping labels, and keyboard navigation. Profile titles and metadata share the same leading edge in RTL; card actions have independent accessible buttons and move below the profile details when space is limited. Group options use labelled fields, and the profile drawer can scroll in short windows. Secondary profile tools are available through the Actions toggle.

Dark surfaces, text, borders, and status chips now use a shared charcoal/slate palette; the light Auto Ping OFF chip and several missing legacy color aliases were corrected. Shared text fields, combo boxes, and switches handle RTL alignment consistently. These changes were reviewed from source and the user-provided screenshots; the application was not run or rendered by the assistant.

## Additional open requests

### #5 — more VPN protocols

[Issue #5](https://github.com/genyleap/GenyConnect/issues/5) asks for OpenVPN, Shadowsocks, and WireGuard. Shadowsocks and WireGuard already have profile fields, import parsing, and Xray outbound construction in `src/serverprofile.cppm`, `src/linkparser.cpp`, and `src/xrayconfigbuilder.cpp`.

OpenVPN remains unimplemented. Completing the issue requires an OpenVPN backend and import path, credential/certificate handling, runtime distribution, and integration with connection, route, DNS, and shutdown ownership on each platform. Accepting an OpenVPN file without those pieces would not provide a working connection.

### #17 — SSH tunnels

[Issue #17](https://github.com/genyleap/GenyConnect/issues/17) remains unimplemented. The current code supplies no SSH profile/runtime. A complete implementation needs SSH authentication and host-key verification, connection supervision, forwarding configuration, and routing/DNS integration. The existing Xray profile pipeline alone cannot deliver this feature.

### #21 — country routing and network suggestions

[Issue #21](https://github.com/genyleap/GenyConnect/issues/21) is partly covered by existing manual rule support. The editor/backend accept `geoip:` and `geosite:` matchers and ordered rules; this change improves consistency of those manual rules.

The project still needs versioned geo data distribution and asset paths, a maintained country data source, first-launch selection, persistent country presets, precedence between custom rules and presets, and the optional network scan/suggestion workflow. A direct-access scan must account for an active TUN route; bypassing only the application's proxy setting does not make a probe direct. Direct reachability alone should not silently change routing rules.

### #28 — encrypted configurations

[Issue #28](https://github.com/genyleap/GenyConnect/issues/28) remains unimplemented. The issue and its comment do not specify an interoperable encrypted format, key derivation, nonce/authentication scheme, or how the client obtains a decryption secret. A client UUID alone does not establish a secure encryption design.

A format/service requirement and key-management decision are needed to complete an interoperable implementation. Profile imports and exports retain their established format.

## Platform limits

- The Linux routing changes are guarded from Windows and macOS helper code. The shared TUN schema uses Xray's gateway field; platform helpers continue to own system routes.
- NixOS users must enable the supplied module or equivalent system configuration. Installing only a user-profile package does not configure polkit, the TUN kernel module, or the firewall's reverse-path policy.
- Linux TUN requires explicit DNS resolvers. Xray's localhost and +local resolver modes bypass marked outbound sockets and are rejected with guidance.
- Orderly stop, startup failure, SIGTERM, and SIGINT attempt to restore owned routing and temporary kernel settings. SIGKILL cannot restore temporary sysctls; parent-death termination prevents the owned core from surviving the helper.
- The current packaged process-routing capability is Windows/Linux with Xray 26.1.23 or newer. This is the application's supported capability, not a claim about every newer upstream Xray release on macOS.

Implementation references: [Xray Linux TUN](https://raw.githubusercontent.com/XTLS/Xray-core/main/proxy/tun/tun_linux.go), [Xray outbound DNS behavior](https://raw.githubusercontent.com/XTLS/Xray-core/main/transport/internet/dialer.go), [Qt button behavior](https://doc.qt.io/qt-6/qml-qtquick-controls-abstractbutton.html), [Qt Flickable origins](https://doc.qt.io/qt-6/qml-qtquick-flickable.html#contentY-prop), and [NixOS firewall options](https://raw.githubusercontent.com/NixOS/nixpkgs/nixos-unstable/nixos/modules/services/networking/firewall.nix).
