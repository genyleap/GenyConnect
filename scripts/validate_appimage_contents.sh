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
require_file_glob "Qt Wayland platform plugin" "*/plugins/platforms/libqwayland*.so"
require_file_glob "Qt SVG image plugin" "*/plugins/imageformats/libqsvg.so"

require_dir_glob "QtQuick QML import" "*/qml/QtQuick"
require_dir_glob "QtQuick.Controls QML import" "*/qml/QtQuick/Controls"
require_dir_glob "QtQuick.Controls.Basic QML import" "*/qml/QtQuick/Controls/Basic"
require_dir_glob "QtQuick.Layouts QML import" "*/qml/QtQuick/Layouts"
require_dir_glob "QtQuick.Dialogs QML import" "*/qml/QtQuick/Dialogs"
require_dir_glob "QtQuick.Effects QML import" "*/qml/QtQuick/Effects"
require_dir_glob "Qt5Compat.GraphicalEffects QML import" "*/qml/Qt5Compat/GraphicalEffects"

if [[ -n "${SOURCE_ROOT}" && -d "${SOURCE_ROOT}" ]]; then
  if command -v rg >/dev/null 2>&1; then
    source_dirs=()
    [[ -d "${SOURCE_ROOT}/ui" ]] && source_dirs+=("${SOURCE_ROOT}/ui")
    [[ -d "${SOURCE_ROOT}/qml" ]] && source_dirs+=("${SOURCE_ROOT}/qml")
    if [[ "${#source_dirs[@]}" -gt 0 ]] \
      && rg -n 'org\.kde\.breeze|import\s+org\.kde' "${source_dirs[@]}" >/tmp/genyconnect-kde-qml-imports.txt 2>/dev/null; then
      echo "KDE-only QML import found in source. Make it optional or bundle it:" >&2
      cat /tmp/genyconnect-kde-qml-imports.txt >&2
      fail=1
    fi
  fi
fi

if [[ "${fail}" -ne 0 ]]; then
  echo "AppImage Qt/QML validation failed." >&2
  exit 1
fi

echo "AppImage Qt/QML validation passed."
