cmake_minimum_required(VERSION 3.28)

# -----------------------------------------------------------------------------
# GenyConnect CMakeLists
# - Cross-platform build (Qt 6.8+)
# - Packaging via CPack:
#     Windows: NSIS + ZIP
#     macOS:   DragNDrop (DMG)
#     Linux:   TGZ
#
# macOS IMPORTANT:
# - Use POST_BUILD macdeployqt
# - Copy helper into bundle BEFORE macdeployqt
# - Then codesign AFTER macdeployqt
#
# NOTE:
# - For clean packaging output, prefer running the CPack that matches the CMake
#   used to configure this build directory (avoid mixing Homebrew CPack with Qt CMake).
# -----------------------------------------------------------------------------

set(PROJECT_NAME "GenyConnect")
project(${PROJECT_NAME} VERSION 1.1.32 LANGUAGES CXX)

if(POLICY CMP0155)
  cmake_policy(SET CMP0155 NEW)
endif()

# Release/RelWithDebInfo generator-expression (works for single + multi config)
set(GENY_IS_RELEASE "$<OR:$<CONFIG:Release>,$<CONFIG:RelWithDebInfo>>")

# -------------------------
# Options
# -------------------------
option(GENYCONNECT_USE_MODULES          "Enable C++20 modules" ON)
option(GENYCONNECT_LLVM_AUTO_SCAN       "Auto-detect LLVM/clang for modules" ON)
option(GENYCONNECT_QT_AUTO_SCAN         "Auto-detect Qt installation prefix" ON)
option(GENYCONNECT_AUTO_DOWNLOAD_XRAY   "Automatically download and bundle xray-core" ON)
option(GENYCONNECT_AUTO_DOWNLOAD_WINTUN "Automatically download official wintun.dll on Windows if missing" ON)

# macOS deploy/sign (POST_BUILD)
option(GENYCONNECT_MACOS_POSTBUILD_DEPLOY   "Run macdeployqt on the build .app in POST_BUILD (recommended)" ON)
option(GENYCONNECT_MACOS_CODESIGN           "Codesign the .app after macdeployqt (recommended on modern macOS)" ON)
set(GENYCONNECT_CODESIGN_IDENTITY "-" CACHE STRING
    "macOS codesign identity. Use '-' for ad-hoc (dev), or 'Developer ID Application: ...' for release.")
set(GENYCONNECT_CODESIGN_ENTITLEMENTS "" CACHE FILEPATH
    "Optional entitlements plist path for codesign (usually empty).")

# Windows deploy (INSTALL step; required for CPack NSIS/ZIP to include dependencies)
option(GENYCONNECT_WINDOWS_INSTALL_DEPLOY
  "Run windeployqt during install() so CPack packages all Qt/QML dependencies" ON)
option(GENYCONNECT_WINDEPLOYQT_COMPILER_RUNTIME
  "Pass --compiler-runtime to windeployqt to bundle MSVC runtime" ON)
option(GENYCONNECT_WINDEPLOYQT_TRANSLATIONS
  "Include Qt translations via windeployqt" OFF)

# Bundle docs at installer/package root
option(GENYCONNECT_BUNDLE_DOCS "Install README and LICENSE at package root + NSIS wizard" ON)

# macdeployqt toggles
option(GENYCONNECT_MACDEPLOYQT_ALWAYS_OVERWRITE "Pass -always-overwrite to macdeployqt" OFF)
option(GENYCONNECT_MACDEPLOYQT_NO_STRIP         "Pass -no-strip to macdeployqt" OFF)

set(GENYCONNECT_TARGET_BUILD_ARCH "arm64" CACHE STRING "Override target arch for output build (arm64|x86_64)")

set(GENYCONNECT_XRAY_VERSION      "v26.2.6" CACHE STRING   "Xray-core release tag (e.g. v26.2.6)")
set(GENYCONNECT_XRAY_ASSET_NAME   ""        CACHE STRING   "Optional explicit Xray release asset name override")
set(GENYCONNECT_BUNDLED_XRAY_PATH ""        CACHE FILEPATH "Path to prebuilt xray-core binary to bundle with app")
set(GENYCONNECT_BUNDLED_WINTUN_PATH ""      CACHE FILEPATH "Path to wintun.dll to bundle with Windows xray-core")
set(GENYCONNECT_WINTUN_VERSION "0.14.1" CACHE STRING "Wintun version for fallback download (Windows)")
set(GENYCONNECT_WINTUN_URL "" CACHE STRING "Optional explicit wintun zip URL override")

set(GENYCONNECT_TARGET_OS   "" CACHE STRING "Override target OS for output naming (macos|linux|windows)")
set(GENYCONNECT_TARGET_ARCH "${GENYCONNECT_TARGET_BUILD_ARCH}" CACHE STRING "Override target arch for output naming (arm64|x86_64)")
set(GENYCONNECT_OUTPUT_NAME "" CACHE STRING "Optional explicit output name (overrides generated name)")

# If you want arm64 on Apple Silicon, keep this. Universal: "arm64;x86_64".
if(APPLE AND NOT DEFINED CMAKE_OSX_ARCHITECTURES)
  set(CMAKE_OSX_ARCHITECTURES "${GENYCONNECT_TARGET_BUILD_ARCH}" CACHE STRING "Build architecture")
endif()

# -------------------------
# Normalize OS / arch
# -------------------------
if(GENYCONNECT_TARGET_OS AND NOT GENYCONNECT_TARGET_OS STREQUAL "")
  string(TOLOWER "${GENYCONNECT_TARGET_OS}" GENY_OS)
else()
  if(APPLE)
    set(GENY_OS "macos")
  elseif(WIN32)
    set(GENY_OS "windows")
  else()
    set(GENY_OS "linux")
  endif()
endif()

set(GENY_ARCH_RAW "")
if(GENYCONNECT_TARGET_ARCH AND NOT GENYCONNECT_TARGET_ARCH STREQUAL "")
  set(GENY_ARCH_RAW "${GENYCONNECT_TARGET_ARCH}")
elseif(APPLE AND CMAKE_OSX_ARCHITECTURES)
  list(GET CMAKE_OSX_ARCHITECTURES 0 GENY_ARCH_RAW)
elseif(DEFINED CMAKE_SYSTEM_PROCESSOR AND CMAKE_SYSTEM_PROCESSOR)
  set(GENY_ARCH_RAW "${CMAKE_SYSTEM_PROCESSOR}")
else()
  set(GENY_ARCH_RAW "x86_64")
endif()

string(TOLOWER "${GENY_ARCH_RAW}" GENY_ARCH)
if(GENY_ARCH MATCHES "^(arm64|aarch64|arm64-v8a)$")
  set(GENY_ARCH "arm64")
elseif(GENY_ARCH MATCHES "^(x86_64|amd64|x64|64)$")
  set(GENY_ARCH "x86_64")
endif()

if(GENYCONNECT_OUTPUT_NAME AND NOT GENYCONNECT_OUTPUT_NAME STREQUAL "")
  set(GENY_OUTPUT_NAME "${GENYCONNECT_OUTPUT_NAME}")
else()
  set(GENY_OUTPUT_NAME "${PROJECT_NAME}")
endif()

message(STATUS "GenyConnect build: OS='${GENY_OS}' ARCH='${GENY_ARCH}'")
message(STATUS "Configured output name: ${GENY_OUTPUT_NAME}")

# -------------------------
# Final packages folder
# -------------------------
set(GENY_FINAL_ROOT "${CMAKE_BINARY_DIR}/final")
set(GENY_FINAL_DIR  "${GENY_FINAL_ROOT}/${GENY_OS}-${GENY_ARCH}")
file(MAKE_DIRECTORY "${GENY_FINAL_DIR}")
message(STATUS "Final output folder: ${GENY_FINAL_DIR}")

# -------------------------
# Compiler / module checks
# -------------------------
set(GENYCONNECT_LLVM_HINTS "")
if(GENYCONNECT_LLVM_AUTO_SCAN)
  if(DEFINED ENV{LLVM_ROOT})
    list(APPEND GENYCONNECT_LLVM_HINTS "$ENV{LLVM_ROOT}/bin")
  endif()
  if(DEFINED ENV{LLVM_HOME})
    list(APPEND GENYCONNECT_LLVM_HINTS "$ENV{LLVM_HOME}/bin")
  endif()
  if(DEFINED ENV{LLVM_DIR})
    list(APPEND GENYCONNECT_LLVM_HINTS "$ENV{LLVM_DIR}/bin")
  endif()

  find_program(GENYCONNECT_BREW brew HINTS /opt/homebrew/bin /usr/local/bin)
  if(GENYCONNECT_BREW)
    execute_process(
      COMMAND "${GENYCONNECT_BREW}" --prefix llvm
      OUTPUT_VARIABLE GENYCONNECT_BREW_LLVM_PREFIX
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(GENYCONNECT_BREW_LLVM_PREFIX)
      list(APPEND GENYCONNECT_LLVM_HINTS "${GENYCONNECT_BREW_LLVM_PREFIX}/bin")
    endif()
  endif()
endif()

find_program(GENYCONNECT_CLANGXX         NAMES clang++ clang-cl HINTS ${GENYCONNECT_LLVM_HINTS})
find_program(GENYCONNECT_CLANG_SCAN_DEPS NAMES clang-scan-deps HINTS ${GENYCONNECT_LLVM_HINTS})

if(NOT GENYCONNECT_CLANG_SCAN_DEPS AND CMAKE_CXX_COMPILER)
  get_filename_component(GENYCONNECT_CXX_DIR "${CMAKE_CXX_COMPILER}" DIRECTORY)
  if(GENYCONNECT_CXX_DIR)
    find_program(GENYCONNECT_CLANG_SCAN_DEPS NAMES clang-scan-deps HINTS "${GENYCONNECT_CXX_DIR}")
  endif()
endif()

set(GENYCONNECT_CLANGXX_IS_APPLE_PATH FALSE)
if(GENYCONNECT_CLANGXX MATCHES "^/usr/bin/clang\\+\\+$" OR
   GENYCONNECT_CLANGXX MATCHES "XcodeDefault\\.xctoolchain")
  set(GENYCONNECT_CLANGXX_IS_APPLE_PATH TRUE)
endif()

if(GENYCONNECT_CLANG_SCAN_DEPS AND NOT DEFINED CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS)
  set(CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS
      "${GENYCONNECT_CLANG_SCAN_DEPS}"
      CACHE FILEPATH "clang-scan-deps for C++20 modules"
  )
endif()

# -------------------------
# Standard compile flags
# -------------------------
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
if(NOT "cppm" IN_LIST CMAKE_AUTOMOC_EXTENSIONS)
  list(APPEND CMAKE_AUTOMOC_EXTENSIONS "cppm")
endif()

if(GENYCONNECT_USE_MODULES)
  if(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
    if(GENYCONNECT_CLANGXX AND GENYCONNECT_CLANG_SCAN_DEPS AND NOT GENYCONNECT_CLANGXX_IS_APPLE_PATH)
      message(FATAL_ERROR
        "AppleClang is active in this build dir. Delete build dir and reconfigure with LLVM clang:\n"
        "  -DCMAKE_CXX_COMPILER=${GENYCONNECT_CLANGXX}\n"
        "  -DCMAKE_CXX_COMPILER_CLANG_SCAN_DEPS=${GENYCONNECT_CLANG_SCAN_DEPS}\n"
        "or set -DGENYCONNECT_USE_MODULES=OFF."
      )
    else()
      message(FATAL_ERROR
        "AppleClang does not provide stable module scanning here. Install LLVM clang or set -DGENYCONNECT_USE_MODULES=OFF."
      )
    endif()
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    message(FATAL_ERROR "GCC is not supported for C++ modules here. Use Clang/MSVC or disable modules.")
  elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang" AND NOT CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS)
    message(FATAL_ERROR "C++ modules require clang-scan-deps. Install LLVM or set CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS.")
  endif()
endif()

# -------------------------
# Qt auto-scan helpers
# -------------------------
if(DEFINED ENV{QTDIR})
  list(APPEND CMAKE_PREFIX_PATH "$ENV{QTDIR}")
endif()
if(DEFINED ENV{QT_DIR})
  list(APPEND CMAKE_PREFIX_PATH "$ENV{QT_DIR}")
endif()
if(DEFINED ENV{Qt6_ROOT})
  list(APPEND CMAKE_PREFIX_PATH "$ENV{Qt6_ROOT}")
endif()
if(DEFINED ENV{QT_ROOT})
  list(APPEND CMAKE_PREFIX_PATH "$ENV{QT_ROOT}")
endif()

if(GENYCONNECT_QT_AUTO_SCAN AND NOT Qt6_DIR)
  set(_qt_candidates "")
  if(APPLE)
    file(GLOB _qt_candidates
      "${CMAKE_USER_HOME_DIRECTORY}/Qt/*/macos"
      "${CMAKE_USER_HOME_DIRECTORY}/Qt/*/clang_64"
      "/opt/Qt/*/macos"
      "/usr/local/Qt/*/macos"
    )
  elseif(WIN32)
    file(GLOB _qt_candidates
      "C:/Qt/*/msvc*_64"
      "C:/Qt/*/mingw*_64"
      "C:/Qt/*/clang_64"
    )
  else()
    file(GLOB _qt_candidates
      "${CMAKE_USER_HOME_DIRECTORY}/Qt/*/gcc_64"
      "${CMAKE_USER_HOME_DIRECTORY}/Qt/*/linux_gcc_64"
      "${CMAKE_USER_HOME_DIRECTORY}/Qt/*/clang_64"
      "/opt/Qt/*/gcc_64"
      "/opt/Qt/*/clang_64"
    )
  endif()

  foreach(_qt_prefix IN LISTS _qt_candidates)
    if(EXISTS "${_qt_prefix}/lib/cmake/Qt6/Qt6Config.cmake")
      list(APPEND CMAKE_PREFIX_PATH "${_qt_prefix}")
      if(NOT Qt6_DIR)
        set(Qt6_DIR "${_qt_prefix}/lib/cmake/Qt6" CACHE PATH "Qt6 config directory" FORCE)
      endif()
    endif()
  endforeach()
endif()

list(REMOVE_DUPLICATES CMAKE_PREFIX_PATH)
if(CMAKE_PREFIX_PATH)
  set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" CACHE STRING "Qt search prefixes" FORCE)
endif()

find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Network Qml Quick QuickControls2 Widgets)
qt_standard_project_setup(REQUIRES 6.8)

# -------------------------
# macOS RPATH policy to avoid noisy -delete_rpath during CPack install step
# -------------------------
if(APPLE)
  set(CMAKE_INSTALL_RPATH "@executable_path/../Frameworks")
  set(CMAKE_BUILD_RPATH   "@executable_path/../Frameworks")
  # Keep build-tree binaries runnable from Qt Creator by preserving build-time
  # linker rpaths to the Qt SDK. Install/package steps still use install rpath.
  set(CMAKE_BUILD_WITH_INSTALL_RPATH OFF)
  set(CMAKE_INSTALL_RPATH_USE_LINK_PATH OFF)
endif()

# -------------------------
# Sources / targets
# -------------------------
set(GENYCONNECT_MODULE_IFS
  src/connectionstate.cppm
  src/serverprofile.cppm
  src/serverprofilemodel.cppm
  src/linkparser.cppm
  src/updater.cppm
  src/xrayconfigbuilder.cppm
  src/systemproxymanager.cppm
  src/xrayprocessmanager.cppm
  src/vpncontroller.cppm
)

set(GENYCONNECT_IMPL_SOURCES
  src/serverprofile.cpp
  src/serverprofilemodel.cpp
  src/linkparser.cpp
  src/updater.cpp
  src/xrayconfigbuilder.cpp
  src/systemproxymanager.cpp
  src/xrayprocessmanager.cpp
  src/vpncontroller.cpp
)

if(APPLE)
  list(APPEND GENYCONNECT_IMPL_SOURCES
    src/platform/macosappbridge.mm
  )
endif()

qt_add_executable(${PROJECT_NAME}
  WIN32
  MACOSX_BUNDLE
  src/main.cpp
  ${GENYCONNECT_IMPL_SOURCES}
)
set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME "${GENY_OUTPUT_NAME}")

qt_add_executable(GenyConnectUpdater
  src/updaterhelper/main.cpp
)
target_link_libraries(GenyConnectUpdater PRIVATE Qt6::Core)
set_target_properties(GenyConnectUpdater PROPERTIES OUTPUT_NAME "GenyConnectUpdater")

qt_add_executable(GenyConnectTunHelper
  src/tunhelper/main.cpp
)
target_link_libraries(GenyConnectTunHelper PRIVATE Qt6::Core Qt6::Network)
set_target_properties(GenyConnectTunHelper PROPERTIES OUTPUT_NAME "GenyConnectTunHelper")

if(WIN32 AND MSVC)
  target_link_options(GenyConnectUpdater PRIVATE
    "/MANIFESTUAC:level='requireAdministrator' uiAccess='false'"
  )
  target_link_options(GenyConnectTunHelper PRIVATE
    "/MANIFESTUAC:level='requireAdministrator' uiAccess='false'"
  )
endif()

if(APPLE)
  add_dependencies(${PROJECT_NAME} GenyConnectUpdater)
  add_dependencies(${PROJECT_NAME} GenyConnectTunHelper)
  set_target_properties(GenyConnectUpdater PROPERTIES MACOSX_BUNDLE FALSE)
  set_target_properties(GenyConnectTunHelper PROPERTIES MACOSX_BUNDLE FALSE)

  add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "$<TARGET_BUNDLE_DIR:${PROJECT_NAME}>/Contents/MacOS"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:GenyConnectUpdater>"
            "$<TARGET_BUNDLE_DIR:${PROJECT_NAME}>/Contents/MacOS/GenyConnectUpdater"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:GenyConnectTunHelper>"
            "$<TARGET_BUNDLE_DIR:${PROJECT_NAME}>/Contents/MacOS/GenyConnectTunHelper"
    COMMENT "Copy helper binaries into app bundle"
    VERBATIM
  )
endif()

if(GENYCONNECT_USE_MODULES)
  set_property(TARGET ${PROJECT_NAME} PROPERTY CXX_SCAN_FOR_MODULES ON)
endif()

target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_link_libraries(${PROJECT_NAME}
  PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Network
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Widgets
)

target_compile_definitions(${PROJECT_NAME} PRIVATE APP_VERSION="${PROJECT_VERSION}")

# -------------------------
# macOS bundle props + icon
# -------------------------
set(GENY_MAC_ICON_ICNS "${CMAKE_CURRENT_SOURCE_DIR}/ui/Resources/image/GenyConnect.icns")

if(APPLE)
  set(CMAKE_OSX_DEPLOYMENT_TARGET "15.1" CACHE STRING "Minimum macOS version")
  set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} -mmacosx-version-min=15.1")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mmacosx-version-min=15.1")

  set_target_properties(${PROJECT_NAME} PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE_ICON_FILE "GenyConnect.icns"
  )

  if(EXISTS "${GENY_MAC_ICON_ICNS}")
    set_source_files_properties("${GENY_MAC_ICON_ICNS}" PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
    target_sources(${PROJECT_NAME} PRIVATE "${GENY_MAC_ICON_ICNS}")
  endif()
endif()

# -------------------------
# QML & resources
# -------------------------
set(qml_core
  ui/Core/FontSystem.qml
  ui/Core/AppGlobals.qml
  ui/Core/Colors.qml
  ui/Core/Metrics.qml
  ui/Core/Typography.qml
  ui/Core/Theme.qml
  ui/Core/Animations.qml
  ui/Core/Elevation.qml
)

set(qml_controls
  ui/Controls/Card.qml
  ui/Controls/Button.qml
  ui/Controls/ComboBox.qml
  ui/Controls/Label.qml
  ui/Controls/TextField.qml
  ui/Controls/TextArea.qml
  ui/Controls/Switch.qml
  ui/Controls/CircleIconButton.qml
  ui/Controls/PrimaryActionButton.qml
  ui/Controls/SignalBars.qml
  ui/Controls/WorldMapDots.qml
)

set(qml_main ui/Main.qml)
set(qml_files ${qml_main} ${qml_core} ${qml_controls})

set(qml_singletons
  ui/Core/AppGlobals.qml
  ui/Core/Metrics.qml
  ui/Core/Typography.qml
  ui/Core/Theme.qml
  ui/Core/Animations.qml
  ui/Core/FontSystem.qml
  ui/Core/Colors.qml
)
set_source_files_properties(${qml_singletons} PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

set(genyconnect_image_assets
  ui/Resources/image/avatar.svg
  ui/Resources/image/favicon.png
)
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/ui/Resources/image/map.png")
  list(APPEND genyconnect_image_assets ui/Resources/image/map.png)
endif()
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/images/map.png")
  list(APPEND genyconnect_image_assets images/map.png)
endif()

qt_add_resources(${PROJECT_NAME} GenyConnectAssets
  PREFIX /
  FILES
    ui/Resources/fonts/Inter-Regular.ttf
    ui/Resources/fonts/Inter-Bold.ttf
    ui/Resources/fonts/fa-brands-400.otf
    ui/Resources/fonts/fa-regular-400.otf
    ui/Resources/fonts/fa-solid-900.otf
    ${genyconnect_image_assets}
)

qt_add_qml_module(${PROJECT_NAME}
  URI GenyConnect
  VERSION 1.0
  QML_FILES ${qml_files}
  RESOURCES
    ui/Core/qmldir
    ui/Controls/qmldir
    ui/Layout/qmldir
    ui/Dashboard/qmldir
)

target_sources(${PROJECT_NAME}
  PUBLIC
    FILE_SET CXX_MODULES TYPE CXX_MODULES
    BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/src
    FILES ${GENYCONNECT_MODULE_IFS}
)

# -------------------------
# Windows resources
# -------------------------
if(WIN32)
  target_sources(${PROJECT_NAME} PRIVATE properties/Windows/app.rc)
endif()

# -------------------------
# Xray auto-download (kept)
# -------------------------
if(GENYCONNECT_AUTO_DOWNLOAD_XRAY AND NOT GENYCONNECT_BUNDLED_XRAY_PATH)

  set(_geny_xray_version "${GENYCONNECT_XRAY_VERSION}")
  if(NOT _geny_xray_version MATCHES "^v")
    set(_geny_xray_version "v${_geny_xray_version}")
  endif()

  if(GENYCONNECT_XRAY_ASSET_NAME)
    set(_geny_xray_asset "${GENYCONNECT_XRAY_ASSET_NAME}")
  else()
    if(GENY_ARCH MATCHES "^(arm64|aarch64)$")
      set(_geny_xray_arch "arm64-v8a")
    elseif(GENY_ARCH MATCHES "^(x86_64|amd64|x64)$")
      set(_geny_xray_arch "64")
    else()
      message(FATAL_ERROR "Unsupported CPU architecture for automatic Xray download: ${GENY_ARCH}")
    endif()

    if(GENY_OS STREQUAL "windows")
      set(_geny_xray_platform "windows")
    elseif(GENY_OS STREQUAL "macos")
      set(_geny_xray_platform "macos")
    else()
      set(_geny_xray_platform "linux")
    endif()

    set(_geny_xray_asset "Xray-${_geny_xray_platform}-${_geny_xray_arch}.zip")
  endif()

  if(NOT CMAKE_CONFIGURATION_TYPES)
    if(CMAKE_BUILD_TYPE MATCHES "Release|RelWithDebInfo")
      set(_geny_do_xray_download TRUE)
    else()
      message(STATUS "Skipping automatic Xray download (CMAKE_BUILD_TYPE='${CMAKE_BUILD_TYPE}').")
    endif()
  else()
    set(_geny_do_xray_download TRUE)
  endif()

  if(DEFINED _geny_do_xray_download AND _geny_do_xray_download)
    set(_geny_xray_cache_dir   "${CMAKE_BINARY_DIR}/_deps/xray")
    file(MAKE_DIRECTORY        "${_geny_xray_cache_dir}")
    set(_geny_xray_archive     "${_geny_xray_cache_dir}/${_geny_xray_asset}")
    set(_geny_xray_extract_dir "${_geny_xray_cache_dir}/extract-${_geny_xray_version}-${GENY_OS}-${GENY_ARCH}")
    set(_geny_xray_url         "https://github.com/XTLS/Xray-core/releases/download/${_geny_xray_version}/${_geny_xray_asset}")

    if(NOT EXISTS "${_geny_xray_archive}")
      message(STATUS "Downloading Xray-core: ${_geny_xray_url}")
      file(DOWNLOAD
        "${_geny_xray_url}"
        "${_geny_xray_archive}"
        STATUS _geny_xray_download_status
        SHOW_PROGRESS
        TLS_VERIFY ON
      )
      list(GET _geny_xray_download_status 0 _geny_xray_download_code)
      list(GET _geny_xray_download_status 1 _geny_xray_download_message)
      if(NOT _geny_xray_download_code EQUAL 0)
        message(FATAL_ERROR "Failed to download Xray-core: ${_geny_xray_download_message}")
      endif()
    else()
      message(STATUS "Using cached Xray archive: ${_geny_xray_archive}")
    endif()

    file(REMOVE_RECURSE "${_geny_xray_extract_dir}")
    file(MAKE_DIRECTORY "${_geny_xray_extract_dir}")

    execute_process(
      COMMAND ${CMAKE_COMMAND} -E tar xzf "${_geny_xray_archive}"
      WORKING_DIRECTORY "${_geny_xray_extract_dir}"
      RESULT_VARIABLE _geny_xray_extract_result
      ERROR_VARIABLE  _geny_xray_extract_err
    )
    if(NOT _geny_xray_extract_result EQUAL 0)
      message(FATAL_ERROR "Failed to extract Xray-core archive: ${_geny_xray_extract_err}")
    endif()

    set(_geny_xray_extracted_bin "${_geny_xray_extract_dir}/xray")
    if(_geny_xray_platform STREQUAL "windows")
      set(_geny_xray_extracted_bin "${_geny_xray_extract_dir}/xray.exe")
    endif()

    if(NOT EXISTS "${_geny_xray_extracted_bin}")
      message(FATAL_ERROR "Xray binary not found after extraction: ${_geny_xray_extracted_bin}")
    endif()

    set(GENYCONNECT_BUNDLED_XRAY_PATH "${_geny_xray_extracted_bin}")
    message(STATUS "Using auto-downloaded Xray-core binary: ${GENYCONNECT_BUNDLED_XRAY_PATH}")

    if(_geny_xray_platform STREQUAL "windows")
      set(_geny_wintun_candidate "${_geny_xray_extract_dir}/wintun.dll")
      if(EXISTS "${_geny_wintun_candidate}")
        set(GENYCONNECT_BUNDLED_WINTUN_PATH "${_geny_wintun_candidate}")
        message(STATUS "Using auto-downloaded wintun.dll: ${GENYCONNECT_BUNDLED_WINTUN_PATH}")
      else()
        file(GLOB_RECURSE _geny_wintun_matches "${_geny_xray_extract_dir}/*wintun.dll")
        if(_geny_wintun_matches)
          list(GET _geny_wintun_matches 0 _geny_wintun_first)
          set(GENYCONNECT_BUNDLED_WINTUN_PATH "${_geny_wintun_first}")
          message(STATUS "Using discovered wintun.dll: ${GENYCONNECT_BUNDLED_WINTUN_PATH}")
        else()
          set(GENYCONNECT_BUNDLED_WINTUN_PATH "")
          message(WARNING "wintun.dll was not found in Xray archive. Windows TUN mode may fail.")
        endif()
      endif()
    endif()
  endif()
endif()

if(WIN32 AND GENYCONNECT_AUTO_DOWNLOAD_WINTUN AND NOT GENYCONNECT_BUNDLED_WINTUN_PATH)
  if(GENY_ARCH STREQUAL "arm64")
    set(_geny_wintun_arch_dir "arm64")
  else()
    set(_geny_wintun_arch_dir "amd64")
  endif()

  if(GENYCONNECT_WINTUN_URL)
    set(_geny_wintun_url "${GENYCONNECT_WINTUN_URL}")
  else()
    set(_geny_wintun_url "https://www.wintun.net/builds/wintun-${GENYCONNECT_WINTUN_VERSION}.zip")
  endif()

  set(_geny_wintun_cache_dir   "${CMAKE_BINARY_DIR}/_deps/wintun")
  set(_geny_wintun_archive     "${_geny_wintun_cache_dir}/wintun-${GENYCONNECT_WINTUN_VERSION}.zip")
  set(_geny_wintun_extract_dir "${_geny_wintun_cache_dir}/extract-${GENYCONNECT_WINTUN_VERSION}-${_geny_wintun_arch_dir}")
  file(MAKE_DIRECTORY "${_geny_wintun_cache_dir}")

  if(NOT EXISTS "${_geny_wintun_archive}")
    message(STATUS "Downloading Wintun: ${_geny_wintun_url}")
    file(DOWNLOAD
      "${_geny_wintun_url}"
      "${_geny_wintun_archive}"
      STATUS _geny_wintun_download_status
      SHOW_PROGRESS
      TLS_VERIFY ON
    )
    list(GET _geny_wintun_download_status 0 _geny_wintun_download_code)
    list(GET _geny_wintun_download_status 1 _geny_wintun_download_message)
    if(NOT _geny_wintun_download_code EQUAL 0)
      message(FATAL_ERROR "Failed to download Wintun: ${_geny_wintun_download_message}")
    endif()
  else()
    message(STATUS "Using cached Wintun archive: ${_geny_wintun_archive}")
  endif()

  file(REMOVE_RECURSE "${_geny_wintun_extract_dir}")
  file(MAKE_DIRECTORY "${_geny_wintun_extract_dir}")
  execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar xf "${_geny_wintun_archive}"
    WORKING_DIRECTORY "${_geny_wintun_extract_dir}"
    RESULT_VARIABLE _geny_wintun_extract_result
    ERROR_VARIABLE  _geny_wintun_extract_err
  )
  if(NOT _geny_wintun_extract_result EQUAL 0)
    message(FATAL_ERROR "Failed to extract Wintun archive: ${_geny_wintun_extract_err}")
  endif()

  set(_geny_wintun_candidate "${_geny_wintun_extract_dir}/wintun/bin/${_geny_wintun_arch_dir}/wintun.dll")
  if(NOT EXISTS "${_geny_wintun_candidate}")
    file(GLOB_RECURSE _geny_wintun_matches "${_geny_wintun_extract_dir}/*/bin/${_geny_wintun_arch_dir}/wintun.dll")
    if(_geny_wintun_matches)
      list(GET _geny_wintun_matches 0 _geny_wintun_candidate)
    endif()
  endif()

  if(EXISTS "${_geny_wintun_candidate}")
    set(GENYCONNECT_BUNDLED_WINTUN_PATH "${_geny_wintun_candidate}")
    message(STATUS "Using fallback Wintun DLL: ${GENYCONNECT_BUNDLED_WINTUN_PATH}")
  else()
    message(FATAL_ERROR "wintun.dll not found in Wintun archive for arch '${_geny_wintun_arch_dir}'.")
  endif()
endif()

if(WIN32)
  if(GENYCONNECT_BUNDLED_XRAY_PATH)
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
              "${GENYCONNECT_BUNDLED_XRAY_PATH}"
              "$<TARGET_FILE_DIR:${PROJECT_NAME}>/xray-core.exe"
      COMMENT "Copy xray-core.exe beside GenyConnect for local Windows runs"
      VERBATIM
    )
  endif()
  if(GENYCONNECT_BUNDLED_WINTUN_PATH)
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
              "${GENYCONNECT_BUNDLED_WINTUN_PATH}"
              "$<TARGET_FILE_DIR:${PROJECT_NAME}>/wintun.dll"
      COMMENT "Copy wintun.dll beside GenyConnect for local Windows TUN runs"
      VERBATIM
    )
  endif()
endif()

# -----------------------------------------------------------------------------
# macOS: POST_BUILD bundle assembly + macdeployqt + codesign (Release-only)
# -----------------------------------------------------------------------------
if(APPLE AND GENYCONNECT_MACOS_POSTBUILD_DEPLOY)

  find_program(MACDEPLOYQT_EXECUTABLE
    NAMES macdeployqt
    HINTS
      "$ENV{QTDIR}/bin"
      "${Qt6_DIR}/../../../bin"
      "${CMAKE_USER_HOME_DIRECTORY}/Qt/*/macos/bin"
  )
  find_program(CODESIGN_EXECUTABLE NAMES codesign)

  if(NOT MACDEPLOYQT_EXECUTABLE)
    message(FATAL_ERROR "macdeployqt not found. Set QTDIR or ensure Qt bin is in PATH.")
  endif()
  if(NOT CODESIGN_EXECUTABLE AND GENYCONNECT_MACOS_CODESIGN)
    message(FATAL_ERROR "codesign not found (Xcode CLT missing?).")
  endif()

  set(_bundle_dir   "$<TARGET_BUNDLE_DIR:${PROJECT_NAME}>")
  set(_bundle_macos "${_bundle_dir}/Contents/MacOS")

  set(_macdeployqt_args "")
  if(GENYCONNECT_MACDEPLOYQT_ALWAYS_OVERWRITE)
    list(APPEND _macdeployqt_args "-always-overwrite")
  endif()
  if(GENYCONNECT_MACDEPLOYQT_NO_STRIP)
    list(APPEND _macdeployqt_args "-no-strip")
  endif()

  set(_codesign_common "--force" "--deep" "--sign" "${GENYCONNECT_CODESIGN_IDENTITY}")

  set(_codesign_ent "")
  if(GENYCONNECT_CODESIGN_ENTITLEMENTS AND EXISTS "${GENYCONNECT_CODESIGN_ENTITLEMENTS}")
    set(_codesign_ent "--entitlements" "${GENYCONNECT_CODESIGN_ENTITLEMENTS}")
  endif()

  add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND $<${GENY_IS_RELEASE}:${CMAKE_COMMAND}> -E make_directory "${_bundle_macos}"

    COMMAND $<${GENY_IS_RELEASE}:${CMAKE_COMMAND}> -E copy_if_different
            "$<TARGET_FILE:GenyConnectUpdater>"
            "${_bundle_macos}/GenyConnectUpdater"
    COMMAND $<${GENY_IS_RELEASE}:${CMAKE_COMMAND}> -E copy_if_different
            "$<TARGET_FILE:GenyConnectTunHelper>"
            "${_bundle_macos}/GenyConnectTunHelper"

    COMMAND $<${GENY_IS_RELEASE}:${CMAKE_COMMAND}> -E echo "Bundling xray (if available)..."
    COMMAND $<$<AND:${GENY_IS_RELEASE},$<BOOL:${GENYCONNECT_BUNDLED_XRAY_PATH}>>:${CMAKE_COMMAND}> -E copy_if_different
            "${GENYCONNECT_BUNDLED_XRAY_PATH}"
            "${_bundle_macos}/xray-core"

    COMMAND $<${GENY_IS_RELEASE}:${CMAKE_COMMAND}> -E echo "Running macdeployqt on build bundle..."
    COMMAND $<${GENY_IS_RELEASE}:${MACDEPLOYQT_EXECUTABLE}>
            ${_bundle_dir}
            -verbose=3
            -qmldir=${CMAKE_CURRENT_SOURCE_DIR}
            -executable=${_bundle_macos}/GenyConnectUpdater
            -executable=${_bundle_macos}/GenyConnectTunHelper
            ${_macdeployqt_args}

    COMMAND $<${GENY_IS_RELEASE}:${CMAKE_COMMAND}> -E echo "Codesigning after macdeployqt..."
    COMMAND $<$<AND:${GENY_IS_RELEASE},$<BOOL:${GENYCONNECT_MACOS_CODESIGN}>>:${CODESIGN_EXECUTABLE}>
            ${_codesign_common} ${_codesign_ent}
            "${_bundle_dir}"

    COMMAND $<${GENY_IS_RELEASE}:${CODESIGN_EXECUTABLE}> --verify --deep --strict --verbose=2 "${_bundle_dir}"

    COMMENT "macOS deploy: copy helper/xray, macdeployqt, then codesign (Release only)"
    VERBATIM
  )
endif()

# -----------------------------------------------------------------------------
# Install rules (used by CPack)
# -----------------------------------------------------------------------------
include(GNUInstallDirs)

# Windows: put exe at package root (.)
if(WIN32)
  set(_GENY_WIN_RUNTIME_DEST ".")
else()
  set(_GENY_WIN_RUNTIME_DEST "${CMAKE_INSTALL_BINDIR}")
endif()

install(TARGETS ${PROJECT_NAME}
  CONFIGURATIONS Release RelWithDebInfo
  BUNDLE  DESTINATION .
  RUNTIME DESTINATION "${_GENY_WIN_RUNTIME_DEST}"
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

# Put updater inside app on macOS, otherwise next to exe (root on Windows)
if(APPLE)
  install(TARGETS GenyConnectUpdater
    CONFIGURATIONS Release RelWithDebInfo
    RUNTIME DESTINATION "${GENY_OUTPUT_NAME}.app/Contents/MacOS"
  )
  install(TARGETS GenyConnectTunHelper
    CONFIGURATIONS Release RelWithDebInfo
    RUNTIME DESTINATION "${GENY_OUTPUT_NAME}.app/Contents/MacOS"
  )
else()
  install(TARGETS GenyConnectUpdater
    CONFIGURATIONS Release RelWithDebInfo
    RUNTIME DESTINATION "${_GENY_WIN_RUNTIME_DEST}"
  )
  install(TARGETS GenyConnectTunHelper
    CONFIGURATIONS Release RelWithDebInfo
    RUNTIME DESTINATION "${_GENY_WIN_RUNTIME_DEST}"
  )
endif()

# Install xray into package too
if(GENYCONNECT_BUNDLED_XRAY_PATH)
  if(APPLE)
    install(FILES "${GENYCONNECT_BUNDLED_XRAY_PATH}"
      CONFIGURATIONS Release RelWithDebInfo
      DESTINATION "${GENY_OUTPUT_NAME}.app/Contents/MacOS"
      RENAME "xray-core"
      PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
    )
  elseif(WIN32)
    install(FILES "${GENYCONNECT_BUNDLED_XRAY_PATH}"
      CONFIGURATIONS Release RelWithDebInfo
      DESTINATION "${_GENY_WIN_RUNTIME_DEST}"
      RENAME "xray-core.exe"
      PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
    )
  else()
    install(FILES "${GENYCONNECT_BUNDLED_XRAY_PATH}"
      CONFIGURATIONS Release RelWithDebInfo
      DESTINATION ${CMAKE_INSTALL_BINDIR}
      RENAME "xray-core"
      PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
    )
  endif()
endif()

if(WIN32 AND GENYCONNECT_BUNDLED_WINTUN_PATH)
  install(FILES "${GENYCONNECT_BUNDLED_WINTUN_PATH}"
    CONFIGURATIONS Release RelWithDebInfo
    DESTINATION "${_GENY_WIN_RUNTIME_DEST}"
    RENAME "wintun.dll"
    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
  )
endif()

# -----------------------------------------------------------------------------
# Windows deploy: run windeployqt on the *install tree* so CPack includes deps
# -----------------------------------------------------------------------------
if(WIN32 AND GENYCONNECT_WINDOWS_INSTALL_DEPLOY)

  find_program(WINDEPLOYQT_EXECUTABLE
    NAMES windeployqt
    HINTS
      "$ENV{QTDIR}/bin"
      "${Qt6_DIR}/../../../bin"
      "C:/Qt/*/*/bin"
  )

  if(NOT WINDEPLOYQT_EXECUTABLE)
    message(FATAL_ERROR "windeployqt not found. Set QTDIR or make sure Qt bin is in PATH.")
  endif()

  # Root layout: exe at $ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/GenyConnect.exe (no bin/)
  install(CODE
    "message(STATUS \"[deploy] Running windeployqt for GenyConnect (install tree, root layout)\")\n
     set(_root \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}\")\n
     file(TO_CMAKE_PATH \"\${_root}\" _root)\n
     set(_exe \"\${_root}/${GENY_OUTPUT_NAME}.exe\")\n
     if(NOT EXISTS \"\${_exe}\")\n
       message(FATAL_ERROR \"[deploy] Installed exe not found: \${_exe}\")\n
     endif()\n
     set(_args \"\${_exe}\" \"--qmldir\" \"${CMAKE_CURRENT_SOURCE_DIR}\" \"--dir\" \"\${_root}\" \"--verbose\" \"2\" \"--release\")\n
     if(${GENYCONNECT_WINDEPLOYQT_COMPILER_RUNTIME})\n
       list(APPEND _args \"--compiler-runtime\")\n
     endif()\n
     if(${GENYCONNECT_WINDEPLOYQT_TRANSLATIONS})\n
       list(APPEND _args \"--translations\")\n
     else()\n
       list(APPEND _args \"--no-translations\")\n
     endif()\n
     execute_process(\n
       COMMAND \"${WINDEPLOYQT_EXECUTABLE}\" \${_args}\n
       RESULT_VARIABLE _res\n
       OUTPUT_VARIABLE _out\n
       ERROR_VARIABLE  _err\n
     )\n
     if(NOT _res EQUAL 0)\n
       message(FATAL_ERROR \"[deploy] windeployqt failed (code=\${_res})\\n\${_out}\\n\${_err}\")\n
     endif()\n
     message(STATUS \"[deploy] windeployqt done. Output dir: \${_root}\")\n"
  )
endif()


# -----------------------------------------------------------------------------
# README + LICENSE at package root + NSIS wizard License Agreement + optional post-install README open
# -----------------------------------------------------------------------------
set(CPACK_MONOLITHIC_INSTALL ON)

set(_GENY_DOC_README_SRC "")
set(_GENY_DOC_LICENSE_SRC "")

if(GENYCONNECT_BUNDLE_DOCS)
  foreach(p
      "${CMAKE_CURRENT_SOURCE_DIR}/README.txt"
      "${CMAKE_CURRENT_SOURCE_DIR}/README.md"
      "${CMAKE_CURRENT_SOURCE_DIR}/README"
  )
    if(EXISTS "${p}")
      set(_GENY_DOC_README_SRC "${p}")
      break()
    endif()
  endforeach()

  foreach(p
      "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE.txt"
      "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE"
      "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE.md"
      "${CMAKE_CURRENT_SOURCE_DIR}/COPYING"
  )
    if(EXISTS "${p}")
      set(_GENY_DOC_LICENSE_SRC "${p}")
      break()
    endif()
  endforeach()

  # Always provide plain-text files for NSIS pages (best compatibility)
  if(_GENY_DOC_README_SRC)
    set(_GENY_DOC_README_TXT "${CMAKE_BINARY_DIR}/NSIS_README.txt")
    configure_file("${_GENY_DOC_README_SRC}" "${_GENY_DOC_README_TXT}" COPYONLY)
    install(FILES "${_GENY_DOC_README_TXT}" DESTINATION "." RENAME "README.txt")
  else()
    message(WARNING "No README file found to bundle.")
  endif()

  if(_GENY_DOC_LICENSE_SRC)
    set(_GENY_DOC_LICENSE_TXT "${CMAKE_BINARY_DIR}/NSIS_LICENSE.txt")
    configure_file("${_GENY_DOC_LICENSE_SRC}" "${_GENY_DOC_LICENSE_TXT}" COPYONLY)
    install(FILES "${_GENY_DOC_LICENSE_TXT}" DESTINATION "." RENAME "LICENSE.txt")
  else()
    message(WARNING "No LICENSE file found to bundle.")
  endif()
endif()

# -----------------------------------------------------------------------------
# CPack / Installer Packaging
# -----------------------------------------------------------------------------
set(CPACK_PACKAGE_NAME                 "${PROJECT_NAME}")
set(CPACK_PACKAGE_VENDOR               "Genyleap")
set(CPACK_PACKAGE_CONTACT              "info@genyleap.com")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY  "GenyConnect VPN Client")
set(CPACK_PACKAGE_VERSION              "${PROJECT_VERSION}")

set(CPACK_OUTPUT_FILE_PREFIX           "${GENY_FINAL_DIR}")
set(CPACK_PACKAGE_FILE_NAME            "${PROJECT_NAME}-${PROJECT_VERSION}-${GENY_OS}-${GENY_ARCH}")
set(CPACK_PACKAGING_INSTALL_PREFIX     "/")

if(WIN32)
  set(CPACK_GENERATOR "NSIS;ZIP")
  set(CPACK_NSIS_DISPLAY_NAME "${PROJECT_NAME}")
  set(CPACK_NSIS_PACKAGE_NAME "${PROJECT_NAME}")
  set(CPACK_NSIS_INSTALL_ROOT "$PROGRAMFILES64")
  set(CPACK_PACKAGE_INSTALL_DIRECTORY "${PROJECT_NAME}")

  # -------------------------
  # Shortcuts (Desktop + Start Menu)
  # -------------------------
  set(_GENY_EXE "${GENY_OUTPUT_NAME}.exe")

  # Start Menu links list (also used by CPack internally)
  set(CPACK_NSIS_MENU_LINKS
    "${_GENY_EXE}" "${PROJECT_NAME}"
  )

  # Create shortcuts during install
  set(CPACK_NSIS_CREATE_ICONS_EXTRA
    "CreateShortCut \\\"$DESKTOP\\\\${PROJECT_NAME}.lnk\\\" \\\"$INSTDIR\\\\${_GENY_EXE}\\\"\n"
    "CreateDirectory \\\"$SMPROGRAMS\\\\$STARTMENU_FOLDER\\\"\n"
    "CreateShortCut \\\"$SMPROGRAMS\\\\$STARTMENU_FOLDER\\\\${PROJECT_NAME}.lnk\\\" \\\"$INSTDIR\\\\${_GENY_EXE}\\\"\n"
    "CreateShortCut \\\"$SMPROGRAMS\\\\$STARTMENU_FOLDER\\\\Uninstall ${PROJECT_NAME}.lnk\\\" \\\"$INSTDIR\\\\Uninstall.exe\\\"\n"
  )

  # Remove shortcuts during uninstall
  set(CPACK_NSIS_DELETE_ICONS_EXTRA
    "Delete \\\"$DESKTOP\\\\${PROJECT_NAME}.lnk\\\"\n"
    "Delete \\\"$SMPROGRAMS\\\\$STARTMENU_FOLDER\\\\${PROJECT_NAME}.lnk\\\"\n"
    "Delete \\\"$SMPROGRAMS\\\\$STARTMENU_FOLDER\\\\Uninstall ${PROJECT_NAME}.lnk\\\"\n"
    "RMDir  \\\"$SMPROGRAMS\\\\$STARTMENU_FOLDER\\\"\n"
  )

  # -------------------------
  # NSIS wizard: License Agreement page
  # -------------------------
  if(EXISTS "${CMAKE_BINARY_DIR}/NSIS_LICENSE.txt")
    set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_BINARY_DIR}/NSIS_LICENSE.txt")
  endif()

  # Optional: open README after install completes
  if(EXISTS "${CMAKE_BINARY_DIR}/NSIS_README.txt")
    set(CPACK_NSIS_EXTRA_INSTALL_COMMANDS
      "ExecShell \\\"open\\\" \\\"$INSTDIR\\\\README.txt\\\""
    )
  endif()
elseif(APPLE)
  set(CPACK_GENERATOR "DragNDrop")
else()
  set(CPACK_GENERATOR "TGZ")
endif()

include(CPack)

message(STATUS "Build dir: ${CMAKE_BINARY_DIR}")
message(STATUS "Packages dir: ${GENY_FINAL_DIR}")
message(STATUS "Packaging: run cpack (multi-config add: -C Release)")
