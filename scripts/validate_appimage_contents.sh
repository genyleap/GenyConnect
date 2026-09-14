#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-squashfs-root}"
SOURCE_ROOT="${2:-}"

if [[ ! -d "${ROOT}" ]]; then
  echo "AppImage extraction root not found: ${ROOT}" >&2
  exit 2
fi
ROOT="$(cd -- "${ROOT}" && pwd)"

fail=0

require_file_glob() {
  local label="$1"
  local pattern="$2"
  if ! find "${ROOT}" -type f -path "${pattern}" -print -quit | grep -q .; then
    echo "Missing ${label}: ${pattern}" >&2
    fail=1
  fi
}

require_file_glob "relocatable Qt configuration" "*/usr/bin/qt.conf"
require_file_glob "isolated AppImage Qt environment" "*/apprun-hooks/99-genyconnect-qt.sh"
require_file_glob "Qt xcb platform plugin" "*/plugins/platforms/libqxcb.so"
require_file_glob "Qt Wayland platform plugin" "*/plugins/platforms/libqwayland*.so"
require_file_glob "Qt SVG image plugin" "*/plugins/imageformats/libqsvg.so"
for integration in wayland-decoration-client wayland-graphics-integration-client wayland-shell-integration xcbglintegrations; do
  require_file_glob "Qt ${integration} plugin" "*/plugins/${integration}/*.so"
done
require_file_glob "Qt Wayland client library" "*/usr/lib/libQt6WaylandClient.so.*"

# Empty directories do not prove a QML module was deployed. Require its import
# metadata and a plugin as well as checking the plugin's dependencies below.
for module in QtCore QtQml QtQuick QtQuick/Window QtQuick/Controls QtQuick/Controls/Basic QtQuick/Templates QtQuick/Layouts QtQuick/Dialogs QtQuick/Effects QtQuick/Particles; do
  require_file_glob "${module} QML import metadata" "*/qml/${module}/qmldir"
  require_file_glob "${module} QML plugin" "*/qml/${module}/*.so"
done

# Resolve plugin dependencies using only the bundle and normal system libraries,
# never the SDK LD_LIBRARY_PATH used during deployment. Reject host Qt libraries
# that would hide an incomplete image on the build machine.
while IFS= read -r -d '' plugin; do
  if ! dependencies="$(env -u LD_PRELOAD -u LD_AUDIT LC_ALL=C LD_LIBRARY_PATH="${ROOT}/usr/lib" ldd "${plugin}" 2>&1)"; then
    echo "Cannot inspect plugin dependencies: ${plugin}" >&2
    printf '%s\n' "${dependencies}" >&2
    fail=1
    continue
  fi
  if [[ "${dependencies}" == *"not found"* ]]; then
    echo "Missing plugin dependencies: ${plugin}" >&2
    printf '%s\n' "${dependencies}" >&2
    fail=1
  fi
  if printf '%s\n' "${dependencies}" | awk -v root="${ROOT}/" '
      $1 ~ /^libQt6/ && $2 == "=>" && index($3, root) != 1 { external = 1 }
      END { exit !external }'; then
    echo "Plugin resolves Qt outside the AppImage: ${plugin}" >&2
    printf '%s\n' "${dependencies}" >&2
    fail=1
  fi
done < <(find "${ROOT}/usr" -type f -name '*.so' \( -path '*/plugins/*' -o -path '*/qml/*' \) -print0)

if [[ -n "${SOURCE_ROOT}" ]]; then
  if [[ ! -d "${SOURCE_ROOT}/ui" ]]; then
    echo "QML source directory not found: ${SOURCE_ROOT}/ui" >&2
    fail=1
  else
    forbidden_regex='RectangularShadow|RectangularGlow|DropShadow|Qt5Compat[.]GraphicalEffects|QtGraphicalEffects|org[.]kde[.]breeze'
    if matches="$(grep -RInE --include='*.qml' "${forbidden_regex}" "${SOURCE_ROOT}/ui")"; then
      echo "Unsupported QML effect or host style dependency found:" >&2
      printf '%s\n' "${matches}" >&2
      fail=1
    else
      search_status=$?
      if [[ "${search_status}" -ne 1 ]]; then
        echo "Unable to inspect QML sources for unsupported dependencies." >&2
        fail=1
      fi
    fi
  fi
fi

if [[ "${fail}" -ne 0 ]]; then
  echo "AppImage Qt/QML validation failed." >&2
  exit 1
fi

echo "AppImage Qt/QML validation passed."
