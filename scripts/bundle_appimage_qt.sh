#!/usr/bin/env bash
# Shared by the native x64 and ARM64 release jobs. Run after cmake --install.
set -euo pipefail
shopt -s nullglob

APP_DIR="${1:?Usage: bundle_appimage_qt.sh APP_DIR QT_ROOT LINUXDEPLOY}"
QT_ROOT="${2:?Qt installation root is required}"
LINUXDEPLOY="${3:?linuxdeploy executable is required}"
SOURCE_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

QMAKE="${QT_ROOT}/bin/qmake6"
if [[ ! -x "${QMAKE}" ]]; then
  QMAKE="${QT_ROOT}/bin/qmake"
fi
if [[ ! -x "${QMAKE}" || ! -x "${LINUXDEPLOY}" ]]; then
  echo "The selected Qt installation must provide qmake and linuxdeploy must be executable." >&2
  exit 1
fi

QT_LIB_DIR="$("${QMAKE}" -query QT_INSTALL_LIBS)"
QT_PLUGIN_DIR="$("${QMAKE}" -query QT_INSTALL_PLUGINS)"
export QMAKE
export LD_LIBRARY_PATH="${QT_LIB_DIR}"
export QML_SOURCES_PATHS="${SOURCE_ROOT}/ui"
export EXTRA_QT_MODULES="svg"
export APPIMAGE_EXTRACT_AND_RUN=1

# EXTRA_PLATFORM_PLUGINS takes semicolon-separated filenames, not paths or Qt
# module names. Discover both the older split and newer unified Wayland plugin.
wayland_plugins=("${QT_PLUGIN_DIR}"/platforms/libqwayland*.so)
if (( ${#wayland_plugins[@]} == 0 )); then
  echo "Qt Wayland platform plugins are required: ${QT_PLUGIN_DIR}/platforms" >&2
  exit 1
fi
platform_names=()
for plugin in "${wayland_plugins[@]}"; do
  platform_names+=("${plugin##*/}")
done
EXTRA_PLATFORM_PLUGINS="$(IFS=';'; printf '%s' "${platform_names[*]}")"
export EXTRA_PLATFORM_PLUGINS

# Stage client integration plugins explicitly: the Qt deployment plugin does
# not deploy every Wayland graphics integration merely from a platform import.
# --deploy-deps-only also sets each plugin's RPATH without moving it into usr/lib.
dependency_args=()
stage_plugin() {
  local source="$1"
  local category="$2"
  local destination="${APP_DIR}/usr/plugins/${category}/${source##*/}"
  if [[ ! -f "${source}" ]]; then
    echo "Required Qt plugin is missing: ${source}" >&2
    exit 1
  fi
  mkdir -p "${APP_DIR}/usr/plugins/${category}"
  cp -pL -- "${source}" "${destination}"
  dependency_args+=(--deploy-deps-only "${destination}")
}

stage_plugin "${QT_PLUGIN_DIR}/platforms/libqxcb.so" platforms
stage_plugin "${QT_PLUGIN_DIR}/imageformats/libqsvg.so" imageformats
for plugin in "${wayland_plugins[@]}"; do
  stage_plugin "${plugin}" platforms
done
for category in wayland-decoration-client wayland-graphics-integration-client wayland-shell-integration xcbglintegrations; do
  plugins=("${QT_PLUGIN_DIR}/${category}"/*.so)
  if (( ${#plugins[@]} == 0 )); then
    echo "Required Qt integration plugins are missing: ${QT_PLUGIN_DIR}/${category}" >&2
    exit 1
  fi
  for plugin in "${plugins[@]}"; do
    stage_plugin "${plugin}" "${category}"
  done
done

# Qt 6 deployment does not create an AppRun hook. Keep host Qt installations
# (including KDE QML imports) out of this bundle before QApplication starts.
# linuxdeploy supplies this_dir and wraps AppRun to source these hooks.
mkdir -p "${APP_DIR}/apprun-hooks"
cat > "${APP_DIR}/apprun-hooks/99-genyconnect-qt.sh" <<'QTHOOK'
export LD_LIBRARY_PATH="${this_dir}/usr/lib"
export QT_PLUGIN_PATH="${this_dir}/usr/plugins"
export QT_QPA_PLATFORM_PLUGIN_PATH="${this_dir}/usr/plugins/platforms"
export QML_IMPORT_PATH="${this_dir}/usr/qml"
export QML2_IMPORT_PATH="${this_dir}/usr/qml"
export QT_QUICK_CONTROLS_STYLE=Basic
export QT_QUICK_CONTROLS_FALLBACK_STYLE=Basic
unset QT_QPA_PLATFORMTHEME
# Retain QT_QPA_PLATFORM and the session's display/socket variables so users can
# select xcb or Wayland and both desktop sessions remain supported.
QTHOOK

"${LINUXDEPLOY}" \
  --appdir "${APP_DIR}" \
  "${dependency_args[@]}" \
  --desktop-file "${APP_DIR}/usr/share/applications/genyconnect.desktop" \
  --icon-file "${APP_DIR}/usr/share/icons/hicolor/512x512/apps/genyconnect.png" \
  --plugin qt

# Use the Qt 6 path keys explicitly and keep the image relocatable.
cat > "${APP_DIR}/usr/bin/qt.conf" <<'QTCONF'
[Paths]
Prefix = ../
Plugins = plugins
QmlImports = qml
Translations = translations
QTCONF

# Refuse to publish a partial bundle. The extracted image is checked again by CI.
bash "${SOURCE_ROOT}/scripts/validate_appimage_contents.sh" "${APP_DIR}" "${SOURCE_ROOT}"
"${LINUXDEPLOY}" --appdir "${APP_DIR}" --output appimage
