#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-squashfs-root}"
SOURCE_ROOT="${2:-}"

if [[ ! -d "${ROOT}" ]]; then
  echo "AppImage extraction root not found: ${ROOT}" >&2
  exit 2
fi

fail=0

require_file_glob() {
  local label="$1"
  local pattern="$2"
  if ! find "${ROOT}" -type f -path "${pattern}" -print -quit | grep -q .; then
    echo "Missing ${label}: ${pattern}" >&2
    fail=1
  fi
}

require_dir_glob() {
  local label="$1"
  local pattern="$2"
  if ! find "${ROOT}" -type d -path "${pattern}" -print -quit | grep -q .; then
    echo "Missing ${label}: ${pattern}" >&2
    fail=1
  fi
}

require_file_glob "Qt xcb platform plugin" "*/plugins/platforms/libqxcb.so"
if ! find "${ROOT}" -path "*/plugins/platforms/libqwayland*.so" -type f | grep -q .; then
  echo "WARNING: Qt Wayland platform plugin not bundled; continuing with xcb-only AppImage."
fi
require_file_glob "Qt SVG image plugin" "*/plugins/imageformats/libqsvg.so"

require_dir_glob "QtQuick QML import" "*/qml/QtQuick"
require_dir_glob "QtQuick.Controls QML import" "*/qml/QtQuick/Controls"
require_dir_glob "QtQuick.Controls.Basic QML import" "*/qml/QtQuick/Controls/Basic"
require_dir_glob "QtQuick.Layouts QML import" "*/qml/QtQuick/Layouts"
require_dir_glob "QtQuick.Dialogs QML import" "*/qml/QtQuick/Dialogs"
require_dir_glob "QtQuick.Effects QML import" "*/qml/QtQuick/Effects"

if [[ -n "${SOURCE_ROOT}" && -d "${SOURCE_ROOT}" ]]; then
  if command -v rg >/dev/null 2>&1; then
    forbidden_patterns=(
      'Rectangular''Shadow'
      'Rectangular''Glow'
      'Drop''Shadow'
      'Qt5''Compat[.]Graphical''Effects'
      'Qt''Graphical''Effects'
      'org[.]kde[.]''breeze'
    )
    forbidden_regex="$(IFS='|'; printf '%s' "${forbidden_patterns[*]}")"
    if rg --hidden -n \
      --glob '!.git/**' \
      --glob '!build/**' \
      --glob '!cmake-build-*/**' \
      --glob '!*.AppDir/**' \
      "${forbidden_regex}" "${SOURCE_ROOT}" >/tmp/genyconnect-forbidden-qml-effects.txt 2>/dev/null; then
      echo "Forbidden legacy or host-specific QML effect/style dependency found:" >&2
      cat /tmp/genyconnect-forbidden-qml-effects.txt >&2
      fail=1
    fi
  fi
fi

if [[ "${fail}" -ne 0 ]]; then
  echo "AppImage Qt/QML validation failed." >&2
  exit 1
fi

echo "AppImage Qt/QML validation passed."
