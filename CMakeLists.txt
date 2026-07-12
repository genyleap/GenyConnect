# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Genyleap Labs.

cmake_minimum_required(VERSION 3.28)

# -----------------------------------------------------------------------------
# GenyConnect CMakeLists
# - Cross-platform build (Qt 6.8+)
# - Packaging via CPack:
#     Windows: NSIS + ZIP
#     macOS:   DragNDrop (DMG)
#     Linux:   TGZ
# -----------------------------------------------------------------------------

set(PROJECT_NAME "GenyConnect")

# Default target architecture used for package naming and macOS build arch.
# On Windows, the real compiler architecture is selected by the generator platform:
#   -A x64
#   -A ARM64
set(GENYCONNECT_TARGET_BUILD_ARCH "" CACHE STRING "Override target arch for output build/package (arm64|x86_64)")

# Must be defined before project() on macOS.
set(GENYCONNECT_MACOS_DEPLOYMENT_TARGET "14.0" CACHE STRING "Minimum macOS version")

if(APPLE AND NOT IOS)
  if(NOT GENYCONNECT_TARGET_BUILD_ARCH)
    set(GENYCONNECT_TARGET_BUILD_ARCH "arm64" CACHE STRING "Override target arch for output build/package (arm64|x86_64)" FORCE)
  endif()

  set(CMAKE_OSX_ARCHITECTURES "${GENYCONNECT_TARGET_BUILD_ARCH}" CACHE STRING "Build architecture" FORCE)
  set(CMAKE_OSX_DEPLOYMENT_TARGET "${GENYCONNECT_MACOS_DEPLOYMENT_TARGET}" CACHE STRING "Minimum macOS version" FORCE)
endif()

project(${PROJECT_NAME} VERSION 1.4.880 LANGUAGES CXX)

# -------------------------
# Detect Android generator architecture
# -------------------------
if(ANDROID)
  if(CMAKE_ANDROID_ARCH_ABI)
    set(_geny_android_abi "${CMAKE_ANDROID_ARCH_ABI}")
  elseif(ANDROID_ABI)
    set(_geny_android_abi "${ANDROID_ABI}")
  else()
    message(FATAL_ERROR "Android ABI was not detected.")
  endif()

  if(_geny_android_abi STREQUAL "arm64-v8a")
    set(GENYCONNECT_TARGET_BUILD_ARCH "arm64" CACHE STRING "Detected Android target arch" FORCE)
  elseif(_geny_android_abi STREQUAL "armeabi-v7a")
    set(GENYCONNECT_TARGET_BUILD_ARCH "armv7" CACHE STRING "Detected Android target arch" FORCE)
  elseif(_geny_android_abi STREQUAL "x86_64")
    set(GENYCONNECT_TARGET_BUILD_ARCH "x86_64" CACHE STRING "Detected Android target arch" FORCE)
  elseif(_geny_android_abi STREQUAL "x86")
    set(GENYCONNECT_TARGET_BUILD_ARCH "x86" CACHE STRING "Detected Android target arch" FORCE)
  else()
    message(FATAL_ERROR "Unsupported Android ABI: ${_geny_android_abi}")
  endif()
  # -------------------------
  # Detect Windows generator architecture
  # -------------------------
elseif(WIN32 AND NOT GENYCONNECT_TARGET_BUILD_ARCH)
  if(CMAKE_GENERATOR_PLATFORM MATCHES "^[Aa][Rr][Mm]64$")
    set(GENYCONNECT_TARGET_BUILD_ARCH "arm64" CACHE STRING "Detected Windows target arch" FORCE)
  elseif(CMAKE_GENERATOR_PLATFORM MATCHES "^[Xx]64$|^[Ww]in64$|^[Aa][Mm][Dd]64$")
    set(GENYCONNECT_TARGET_BUILD_ARCH "x86_64" CACHE STRING "Detected Windows target arch" FORCE)
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "ARM64|arm64|aarch64")
    set(GENYCONNECT_TARGET_BUILD_ARCH "arm64" CACHE STRING "Detected Windows target arch" FORCE)
  else()
    set(GENYCONNECT_TARGET_BUILD_ARCH "x86_64" CACHE STRING "Detected Windows target arch" FORCE)
  endif()
elseif(NOT GENYCONNECT_TARGET_BUILD_ARCH)
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "ARM64|arm64|aarch64")
    set(GENYCONNECT_TARGET_BUILD_ARCH "arm64" CACHE STRING "Detected target arch" FORCE)
  else()
    set(GENYCONNECT_TARGET_BUILD_ARCH "x86_64" CACHE STRING "Detected target arch" FORCE)
  endif()
endif()

if(WIN32 AND CMAKE_GENERATOR MATCHES "Visual Studio" AND NOT CMAKE_GENERATOR_PLATFORM)
  message(WARNING
    "Visual Studio generator platform is empty. "
    "Use -A x64 or -A ARM64 to avoid wrong Windows architecture/package detection."
  )
endif()

message(STATUS "CMake generator: ${CMAKE_GENERATOR}")
message(STATUS "CMake generator platform: ${CMAKE_GENERATOR_PLATFORM}")
message(STATUS "CMake system processor: ${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "GenyConnect target build arch: ${GENYCONNECT_TARGET_BUILD_ARCH}")

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
option(GENYCONNECT_BUILD_DESKTOP "Build desktop runtime and packaging flow" ON)
option(GENYCONNECT_BUILD_ANDROID "Build Android mobile runtime layer" OFF)
option(GENYCONNECT_BUILD_IOS "Build iOS mobile runtime layer" OFF)
option(GENYCONNECT_ENABLE_DESKTOP_HELPERS "Build desktop helper binaries" ON)
option(GENYCONNECT_ENABLE_MOBILE_VPN "Enable mobile VPN runtime bridge stubs" ON)
set(GENYCONNECT_ANDROID_OPENSSL_ROOT "" CACHE PATH "Android OpenSSL root containing ABI folders with libssl_3.so/libcrypto_3.so (e.g. <sdk>/android_openssl/ssl_3)")

if(ANDROID)
  set(GENYCONNECT_BUILD_DESKTOP OFF CACHE BOOL "Build desktop runtime and packaging flow" FORCE)
  set(GENYCONNECT_BUILD_ANDROID ON CACHE BOOL "Build Android mobile runtime layer" FORCE)
  set(GENYCONNECT_BUILD_IOS OFF CACHE BOOL "Build iOS mobile runtime layer" FORCE)
  set(GENYCONNECT_AUTO_DOWNLOAD_XRAY ON CACHE BOOL "Automatically download and bundle xray-core" FORCE)
elseif(IOS)
  set(GENYCONNECT_IOS_DEVELOPMENT_TEAM "7E5LUPJBMQ" CACHE STRING "Apple Development Team ID")
  set(GENYCONNECT_IOS_BUNDLE_IDENTIFIER "com.genyleap.genyconnect" CACHE STRING "iOS bundle identifier")
  set(GENYCONNECT_IOS_CODE_SIGN_STYLE "Automatic" CACHE STRING "iOS code signing style")
  set(GENYCONNECT_BUILD_DESKTOP OFF CACHE BOOL "Build desktop runtime and packaging flow" FORCE)
  set(GENYCONNECT_BUILD_ANDROID OFF CACHE BOOL "Build Android mobile runtime layer" FORCE)
  set(GENYCONNECT_BUILD_IOS ON CACHE BOOL "Build iOS mobile runtime layer" FORCE)
else()
  if(NOT GENYCONNECT_BUILD_ANDROID AND NOT GENYCONNECT_BUILD_IOS)
    set(GENYCONNECT_BUILD_DESKTOP ON CACHE BOOL "Build desktop runtime and packaging flow" FORCE)
  endif()
endif()

if(NOT GENYCONNECT_BUILD_DESKTOP)
  set(GENYCONNECT_ENABLE_DESKTOP_HELPERS OFF CACHE BOOL "Build desktop helper binaries" FORCE)
  set(GENYCONNECT_AUTO_DOWNLOAD_WINTUN OFF CACHE BOOL "Automatically download official wintun.dll on Windows if missing" FORCE)
  if(NOT GENYCONNECT_BUILD_ANDROID)
    set(GENYCONNECT_AUTO_DOWNLOAD_XRAY OFF CACHE BOOL "Automatically download and bundle xray-core" FORCE)
  endif()
endif()

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

set(_GENYCONNECT_RECOMMENDED_XRAY_VERSION "v26.3.27")
set(GENYCONNECT_XRAY_VERSION      "${_GENYCONNECT_RECOMMENDED_XRAY_VERSION}" CACHE STRING   "Xray-core release tag (e.g. v26.3.27)")
if(GENYCONNECT_BUILD_ANDROID AND GENYCONNECT_XRAY_VERSION STREQUAL "v26.3.27")
  message(STATUS
    "Upgrading cached GENYCONNECT_XRAY_VERSION from v26.3.27 to ${_GENYCONNECT_RECOMMENDED_XRAY_VERSION} "
    "to include the Android TUN UDP FullCone fix."
  )
  set(GENYCONNECT_XRAY_VERSION "${_GENYCONNECT_RECOMMENDED_XRAY_VERSION}" CACHE STRING "Xray-core release tag (e.g. v26.3.27)" FORCE)
endif()
set(GENYCONNECT_XRAY_ASSET_NAME   ""        CACHE STRING   "Optional explicit Xray release asset name override")
set(GENYCONNECT_BUNDLED_XRAY_PATH ""        CACHE FILEPATH "Path to prebuilt xray-core binary to bundle with app")
set(GENYCONNECT_BUNDLED_WINTUN_PATH ""      CACHE FILEPATH "Path to wintun.dll to bundle with Windows xray-core")
set(GENYCONNECT_WINTUN_VERSION "0.14.1" CACHE STRING "Wintun version for fallback download (Windows)")
set(GENYCONNECT_WINTUN_URL "" CACHE STRING "Optional explicit wintun zip URL override")

set(GENYCONNECT_TARGET_OS   "" CACHE STRING "Override target OS for output naming (macos|linux|windows)")
set(GENYCONNECT_TARGET_ARCH "${GENYCONNECT_TARGET_BUILD_ARCH}" CACHE STRING "Override target arch for output naming (arm64|x86_64|armv7|universal)" FORCE)
set(GENYCONNECT_OUTPUT_NAME "" CACHE STRING "Optional explicit output name (overrides generated name)")

set(GENYCONNECT_LOCAL_XRAY_ROOT
  "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/xray"
  CACHE PATH "Local prebuilt Xray binaries root"
)

set(GENYCONNECT_AUTO_BUILD_ANDROID_ARMV7_XRAY
  ON
  CACHE BOOL "Automatically build Xray-core for Android armeabi-v7a when local binary is missing"
)

if(ANDROID AND NOT GENYCONNECT_BUNDLED_XRAY_PATH)
  if(CMAKE_ANDROID_ARCH_ABI STREQUAL "armeabi-v7a")
    set(_geny_default_android_xray
      "${GENYCONNECT_LOCAL_XRAY_ROOT}/android/armeabi-v7a/xray"
    )

    if(NOT EXISTS "${_geny_default_android_xray}" AND GENYCONNECT_AUTO_BUILD_ANDROID_ARMV7_XRAY)
      find_program(GENYCONNECT_GO_EXECUTABLE go)

      if(NOT GENYCONNECT_GO_EXECUTABLE)
        message(FATAL_ERROR
          "Android armeabi-v7a requires Xray-core, but Go was not found.\n"
          "Install Go first:\n"
          "  brew install go\n"
          "Then configure again."
        )
      endif()

      if(NOT CMAKE_ANDROID_NDK)
        message(FATAL_ERROR "CMAKE_ANDROID_NDK is not set.")
      endif()

      file(MAKE_DIRECTORY "${GENYCONNECT_LOCAL_XRAY_ROOT}/android/armeabi-v7a")
      file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/_deps")

      set(_geny_xray_source_dir "${CMAKE_BINARY_DIR}/_deps/Xray-core-src")

      if(NOT EXISTS "${_geny_xray_source_dir}/go.mod")
        execute_process(
          COMMAND git clone --depth 1 --branch "${GENYCONNECT_XRAY_VERSION}"
                  https://github.com/XTLS/Xray-core.git
                  "${_geny_xray_source_dir}"
          RESULT_VARIABLE _geny_xray_git_result
        )

        if(NOT _geny_xray_git_result EQUAL 0)
          message(FATAL_ERROR "Failed to clone Xray-core ${GENYCONNECT_XRAY_VERSION}.")
        endif()
      endif()

      set(_geny_android_api "21")
      if(CMAKE_SYSTEM_VERSION)
        set(_geny_android_api "${CMAKE_SYSTEM_VERSION}")
      endif()

      set(_geny_ndk_host_tag "")

      if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
        if(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
          set(_geny_ndk_host_tag "darwin-arm64")
        else()
          set(_geny_ndk_host_tag "darwin-x86_64")
        endif()
      elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
        set(_geny_ndk_host_tag "linux-x86_64")
      elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
        set(_geny_ndk_host_tag "windows-x86_64")
      else()
        message(FATAL_ERROR "Unsupported host system for Android NDK: ${CMAKE_HOST_SYSTEM_NAME}")
      endif()

      set(_geny_ndk_prebuilt_dir
        "${CMAKE_ANDROID_NDK}/toolchains/llvm/prebuilt/${_geny_ndk_host_tag}"
      )

      if(NOT EXISTS "${_geny_ndk_prebuilt_dir}")
        message(FATAL_ERROR
          "Android NDK LLVM prebuilt directory was not found:\n"
          "  ${_geny_ndk_prebuilt_dir}"
        )
      endif()

      if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
        if(EXISTS "${_geny_ndk_prebuilt_dir}/bin/armv7a-linux-androideabi${_geny_android_api}-clang.cmd")
          set(_geny_tool_suffix ".cmd")
        else()
          set(_geny_tool_suffix ".exe")
        endif()
      else()
        set(_geny_tool_suffix "")
      endif()

      if(NOT EXISTS "${_geny_ndk_prebuilt_dir}")
        message(FATAL_ERROR
          "Android NDK LLVM prebuilt directory was not found under:\n"
          "  ${CMAKE_ANDROID_NDK}/toolchains/llvm/prebuilt"
        )
      endif()

      set(_geny_android_armv7_cc
        "${_geny_ndk_prebuilt_dir}/bin/armv7a-linux-androideabi${_geny_android_api}-clang${_geny_tool_suffix}"
      )

      set(_geny_android_armv7_cxx
        "${_geny_ndk_prebuilt_dir}/bin/armv7a-linux-androideabi${_geny_android_api}-clang++${_geny_tool_suffix}"
      )

      if(NOT EXISTS "${_geny_android_armv7_cc}")
        message(FATAL_ERROR "Android armv7 clang not found: ${_geny_android_armv7_cc}")
      endif()

      if(NOT EXISTS "${_geny_android_armv7_cxx}")
        message(FATAL_ERROR "Android armv7 clang++ not found: ${_geny_android_armv7_cxx}")
      endif()

      message(STATUS "Building Xray-core for Android armeabi-v7a...")
      message(STATUS "Android armv7 CC: ${_geny_android_armv7_cc}")

      execute_process(
        COMMAND "${CMAKE_COMMAND}" -E env
          GOOS=android
          GOARCH=arm
          GOARM=7
          CGO_ENABLED=1
          CC=${_geny_android_armv7_cc}
          CXX=${_geny_android_armv7_cxx}
          "${GENYCONNECT_GO_EXECUTABLE}" build
          -trimpath
          "-ldflags=-s -w"
          -o "${_geny_default_android_xray}"
          ./main
        WORKING_DIRECTORY "${_geny_xray_source_dir}"
        RESULT_VARIABLE _geny_xray_armv7_build_result
      )

      if(NOT _geny_xray_armv7_build_result EQUAL 0)
        message(FATAL_ERROR "Failed to build Xray-core for Android armeabi-v7a.")
      endif()
    endif()

    if(EXISTS "${_geny_default_android_xray}")
      set(GENYCONNECT_BUNDLED_XRAY_PATH
        "${_geny_default_android_xray}"
        CACHE FILEPATH "Path to bundled xray-core binary" FORCE
      )
      message(STATUS "Using local Android armeabi-v7a Xray: ${GENYCONNECT_BUNDLED_XRAY_PATH}")
    else()
      message(FATAL_ERROR
        "Android armeabi-v7a requires a locally built Xray binary.\n"
        "Expected path:\n"
        "  ${_geny_default_android_xray}"
      )
    endif()
  endif()
endif()

# -------------------------
# Normalize OS / arch
# -------------------------
if(GENYCONNECT_TARGET_OS AND NOT GENYCONNECT_TARGET_OS STREQUAL "")
  string(TOLOWER "${GENYCONNECT_TARGET_OS}" GENY_OS)
else()
  if(GENYCONNECT_BUILD_ANDROID)
    set(GENY_OS "android")
  elseif(GENYCONNECT_BUILD_IOS OR IOS)
    set(GENY_OS "ios")
  elseif(APPLE)
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
elseif(GENY_ARCH MATCHES "^(armeabi-v7a|armv7|armv7a|arm)$")
  set(GENY_ARCH "armv7")
elseif(GENY_ARCH MATCHES "^(universal|multi|fat)$")
  set(GENY_ARCH "universal")
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

find_program(GENYCONNECT_CLANG
  NAMES clang
  HINTS ${GENYCONNECT_LLVM_HINTS}
  NO_DEFAULT_PATH
)

find_program(GENYCONNECT_CLANGXX
  NAMES clang++
  HINTS ${GENYCONNECT_LLVM_HINTS}
  NO_DEFAULT_PATH
)

find_program(GENYCONNECT_CLANG_SCAN_DEPS
  NAMES clang-scan-deps
  HINTS ${GENYCONNECT_LLVM_HINTS}
  NO_DEFAULT_PATH
)

if(NOT GENYCONNECT_CLANG)
  find_program(GENYCONNECT_CLANG NAMES clang)
endif()

if(NOT GENYCONNECT_CLANGXX)
  find_program(GENYCONNECT_CLANGXX NAMES clang++ clang-cl)
endif()

if(NOT GENYCONNECT_CLANG_SCAN_DEPS)
  find_program(GENYCONNECT_CLANG_SCAN_DEPS NAMES clang-scan-deps)
endif()

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

set(GENYCONNECT_ACTIVE_CXX_IS_APPLE_PATH FALSE)
if(CMAKE_CXX_COMPILER MATCHES "^/usr/bin/clang\\+\\+$" OR
   CMAKE_CXX_COMPILER MATCHES "XcodeDefault\\.xctoolchain")
  set(GENYCONNECT_ACTIVE_CXX_IS_APPLE_PATH TRUE)
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

if(MSVC)
  add_compile_options(
    /utf-8
    /Zc:__cplusplus
    /permissive-
  )
endif()

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

if(NOT "cppm" IN_LIST CMAKE_AUTOMOC_EXTENSIONS)
  list(APPEND CMAKE_AUTOMOC_EXTENSIONS "cppm")
endif()

if(GENYCONNECT_USE_MODULES)
  if(APPLE AND CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
    if(GENYCONNECT_CLANG AND GENYCONNECT_CLANGXX AND GENYCONNECT_CLANG_SCAN_DEPS AND NOT GENYCONNECT_CLANGXX_IS_APPLE_PATH)
      message(FATAL_ERROR
        "C++ modules are enabled, but this kit is using AppleClang.\n"
        "Qt Creator must use Homebrew LLVM for this kit:\n"
        "  CMAKE_C_COMPILER=${GENYCONNECT_CLANG}\n"
        "  CMAKE_CXX_COMPILER=${GENYCONNECT_CLANGXX}\n"
        "  CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS=${GENYCONNECT_CLANG_SCAN_DEPS}\n"
        "Then delete the build directory and configure again."
      )
    else()
      message(FATAL_ERROR
        "C++ modules are enabled, but this kit is using AppleClang and Homebrew LLVM was not found.\n"
        "Run: brew install llvm"
      )
    endif()
  endif()

  if(CMAKE_CXX_COMPILER_ID MATCHES "Clang" AND NOT CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS)
    message(FATAL_ERROR
      "C++ modules require clang-scan-deps.\n"
      "Set CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS=${GENYCONNECT_CLANG_SCAN_DEPS}"
    )
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
    if(GENYCONNECT_TARGET_BUILD_ARCH STREQUAL "arm64")
      file(GLOB _qt_candidates
        "C:/Qt/*/msvc*_arm64"
        "C:/Qt/*/msvc*arm64"
        "C:/Qt/*/msvc*_64"
        "C:/Qt/*/mingw*_64"
        "C:/Qt/*/clang_64"
      )
    else()
      file(GLOB _qt_candidates
        "C:/Qt/*/msvc*_64"
        "C:/Qt/*/mingw*_64"
        "C:/Qt/*/clang_64"
        "C:/Qt/*/msvc*_arm64"
        "C:/Qt/*/msvc*arm64"
      )
    endif()
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

set(GENYCONNECT_QT_COMPONENTS Core Gui Network Qml Quick QuickControls2)
if(GENYCONNECT_BUILD_DESKTOP)
  list(APPEND GENYCONNECT_QT_COMPONENTS Widgets)
endif()

find_package(Qt6 6.8 REQUIRED COMPONENTS ${GENYCONNECT_QT_COMPONENTS})

include(CTest)
if(BUILD_TESTING AND NOT ANDROID AND NOT IOS)
  find_package(Qt6 6.8 REQUIRED COMPONENTS Test)
endif()

if(ANDROID)
  if(NOT QT_HOST_PATH AND NOT DEFINED ENV{QT_HOST_PATH})
    message(WARNING
      "QT_HOST_PATH is not set. Android Qt builds usually require a host Qt installation. "
      "Pass -DQT_HOST_PATH=<host-qt-root> from CI."
    )
  endif()
endif()

qt_standard_project_setup(REQUIRES 6.8)

message(STATUS "Qt6_DIR: ${Qt6_DIR}")
message(STATUS "CMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH}")

# -------------------------
# macOS RPATH policy to avoid noisy -delete_rpath during CPack install step
# -------------------------
if(APPLE AND NOT IOS AND GENYCONNECT_BUILD_DESKTOP)
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
  src/donationservice.cppm
  src/updater.cppm
  src/xrayconfigbuilder.cppm
  src/networkcachemanager.cppm
  src/platformactionservice.cppm
  src/routingruleservice.cppm
  src/systeminfoprovider.cppm
  src/systemproxymanager.cppm
  src/vpncontroller.cppm
)


set(GENYCONNECT_IMPL_SOURCES
  src/securitystatus.hpp
  src/securitystatus.cpp
  src/serverprofile.cpp
  src/serverprofilemodel.cpp
  src/linkparser.cpp
  src/donationservice.cpp
  src/powermodemanager.cpp
  src/thirdparty/qrcodegen/qrcodegen.cpp
  src/updater.cpp
  src/xrayconfigbuilder.cpp
  src/networkcachemanager.cpp
  src/platformactionservice.cpp
  src/routingruleservice.cpp
  src/systeminfoprovider.cpp
  src/vpncontroller.cpp
  src/runtime/vpnruntimebackend.cpp
  src/runtime/runtimefactory.cpp
  src/runtime/androidvpnruntime.cpp
  src/runtime/iosvpnruntime.cpp
)

if(GENYCONNECT_BUILD_DESKTOP)
  list(APPEND GENYCONNECT_IMPL_SOURCES
    src/systemproxymanager.cpp
    src/runtime/desktopvpnruntime.cpp
  )
else()
  list(APPEND GENYCONNECT_IMPL_SOURCES
    src/systemproxymanager_mobile.cpp
  )
endif()

if(APPLE AND NOT IOS)
  list(APPEND GENYCONNECT_IMPL_SOURCES
    src/platform/macosappbridge.mm
  )
endif()

if(IOS AND GENYCONNECT_ENABLE_MOBILE_VPN)
  list(APPEND GENYCONNECT_IMPL_SOURCES
    src/platform/ios/iosruntimebridge.mm
  )
endif()

if(GENYCONNECT_BUILD_DESKTOP)
  qt_add_executable(${PROJECT_NAME}
    WIN32
    MACOSX_BUNDLE
    src/main.cpp
    ${GENYCONNECT_IMPL_SOURCES}
  )
else()
  qt_add_executable(${PROJECT_NAME}
    src/main.cpp
    ${GENYCONNECT_IMPL_SOURCES}
  )
endif()

if(GENYCONNECT_USE_MODULES)
  target_sources(${PROJECT_NAME}
          PRIVATE
          FILE_SET genyconnect_cxx_modules
          TYPE CXX_MODULES
          BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/src
          FILES ${GENYCONNECT_MODULE_IFS}
  )

  set_property(TARGET ${PROJECT_NAME} PROPERTY CXX_SCAN_FOR_MODULES ON)
endif()

target_compile_definitions(${PROJECT_NAME} PRIVATE GENYCONNECT_CXX_STANDARD=${CMAKE_CXX_STANDARD})

set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME "${GENY_OUTPUT_NAME}"
  QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android")
set_target_properties(${PROJECT_NAME} PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
  LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
  ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
)

if(IOS)
  set_target_properties(${PROJECT_NAME} PROPERTIES
    MACOSX_BUNDLE TRUE
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${GENYCONNECT_IOS_BUNDLE_IDENTIFIER}"
    XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${GENYCONNECT_IOS_DEVELOPMENT_TEAM}"
    XCODE_ATTRIBUTE_CODE_SIGN_STYLE "${GENYCONNECT_IOS_CODE_SIGN_STYLE}"
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "Apple Development"
    XCODE_ATTRIBUTE_ENABLE_USER_SCRIPT_SANDBOXING "NO"
    XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1"
    XCODE_ATTRIBUTE_SUPPORTED_PLATFORMS "iphoneos"
    XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "14.0"
  )
endif()

if(ANDROID)
  math(EXPR GENY_ANDROID_VERSION_CODE
       "${PROJECT_VERSION_MAJOR} * 10000 + ${PROJECT_VERSION_MINOR} * 100 + ${PROJECT_VERSION_PATCH}")
  set(ANDROID_VERSION_NAME "${PROJECT_VERSION}" CACHE STRING "Android package versionName" FORCE)
  set(ANDROID_VERSION_CODE "${GENY_ANDROID_VERSION_CODE}" CACHE STRING "Android package versionCode" FORCE)
  set_property(TARGET ${PROJECT_NAME} PROPERTY QT_ANDROID_VERSION_NAME "${PROJECT_VERSION}")
  set_property(TARGET ${PROJECT_NAME} PROPERTY QT_ANDROID_VERSION_CODE "${GENY_ANDROID_VERSION_CODE}")

  set(GENY_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/properties/Android")
  set(GENY_ANDROID_PACKAGE_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/android-package")

  if(EXISTS "${GENY_ANDROID_PACKAGE_SOURCE_DIR}")
    file(REMOVE_RECURSE "${GENY_ANDROID_PACKAGE_BUILD_DIR}")
    file(MAKE_DIRECTORY "${GENY_ANDROID_PACKAGE_BUILD_DIR}")
    file(COPY "${GENY_ANDROID_PACKAGE_SOURCE_DIR}/" DESTINATION "${GENY_ANDROID_PACKAGE_BUILD_DIR}")

    if(EXISTS "${GENY_ANDROID_PACKAGE_SOURCE_DIR}/AndroidManifest.xml.in")
      configure_file(
        "${GENY_ANDROID_PACKAGE_SOURCE_DIR}/AndroidManifest.xml.in"
        "${GENY_ANDROID_PACKAGE_BUILD_DIR}/AndroidManifest.xml"
        @ONLY
      )
    endif()

    set_property(TARGET ${PROJECT_NAME} PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR "${GENY_ANDROID_PACKAGE_BUILD_DIR}")
    message(STATUS "Android package source dir: ${GENY_ANDROID_PACKAGE_BUILD_DIR}")
  else()
    message(WARNING "Android package source dir not found: ${GENY_ANDROID_PACKAGE_SOURCE_DIR}")
  endif()
endif()

if(GENYCONNECT_BUILD_DESKTOP AND GENYCONNECT_ENABLE_DESKTOP_HELPERS)
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
endif()

if(TARGET GenyConnectUpdater AND TARGET GenyConnectTunHelper AND WIN32 AND MSVC)
  target_link_options(GenyConnectUpdater PRIVATE
    "/MANIFESTUAC:level='requireAdministrator' uiAccess='false'"
  )
  target_link_options(GenyConnectTunHelper PRIVATE
    "/MANIFESTUAC:level='requireAdministrator' uiAccess='false'"
  )
endif()

if(APPLE AND TARGET GenyConnectUpdater AND TARGET GenyConnectTunHelper)
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

target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_link_libraries(${PROJECT_NAME}
  PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Network
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
)

if(WIN32 AND MSVC)
  # Qt QML cache-generated translation units can exceed MSVC COFF section limits.
  target_compile_options(${PROJECT_NAME} PRIVATE /bigobj)
endif()

if(GENYCONNECT_BUILD_DESKTOP)
  target_link_libraries(${PROJECT_NAME} PRIVATE Qt6::Widgets)
endif()

target_compile_definitions(${PROJECT_NAME}
  PRIVATE
    APP_VERSION="${PROJECT_VERSION}"
    GENYCONNECT_BUNDLED_XRAY_VERSION="${GENYCONNECT_XRAY_VERSION}"
)

# -------------------------
# macOS bundle props + icon
# -------------------------
set(GENY_MAC_ICON_ICNS "${CMAKE_CURRENT_SOURCE_DIR}/ui/Resources/image/GenyConnect.icns")

if(APPLE AND NOT IOS AND GENYCONNECT_BUILD_DESKTOP)
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
  ui/Controls/NumberFlowText.qml
  ui/Controls/TextArea.qml
  ui/Controls/Switch.qml
  ui/Controls/CircleIconButton.qml
  ui/Controls/PrimaryActionButton.qml
  ui/Controls/SignalBars.qml
  ui/Controls/SoftShadow.qml
  ui/Controls/SpeedTestGauge.qml
  ui/Controls/PowerModeParticleEffect.qml
  ui/Controls/AppPage.qml
  ui/Controls/AppHeader.qml
  ui/Controls/GlassCard.qml
  ui/Controls/PrimaryButton.qml
  ui/Controls/SecondaryButton.qml
  ui/Controls/OutlineButton.qml
  ui/Controls/DialogCard.qml
  ui/Controls/InfoBanner.qml
  ui/Controls/SelectableCard.qml
  ui/Controls/StatusPill.qml
  ui/Controls/SettingRow.qml
  ui/Controls/LinkRow.qml
  ui/Controls/StatCard.qml
  ui/Controls/SegmentedSelector.qml
  ui/Controls/SupportHeroCard.qml
  ui/Controls/TokenOptionCard.qml
  ui/Controls/AmountButton.qml
  ui/Controls/DonationSummaryCard.qml
  ui/Controls/UsefulLinkCard.qml
)

set(qml_sections
  ui/Sections/CacheSettings.qml
  ui/Sections/ConnectionModeSettings.qml
  ui/Sections/CustomDnsSettings.qml
  ui/Sections/InterfaceSettings.qml
  ui/Sections/LanSharingSettings.qml
  ui/Sections/DesktopMainSurface.qml
  ui/Sections/LogsSettings.qml
  ui/Sections/MainSurface.qml
  ui/Sections/PowerModeSettings.qml
  ui/Sections/PowerSectionCard.qml
  ui/Sections/RoutingRulesSettings.qml
  ui/Sections/SettingsMainList.qml
  ui/Sections/UpdatesSettings.qml
)

set(qml_main ui/Main.qml)
set(qml_files ${qml_main} ${qml_core} ${qml_controls} ${qml_sections})

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
)

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/ui/Resources/image/GenyConnect.ico")
  list(APPEND genyconnect_image_assets ui/Resources/image/GenyConnect.ico)
endif()
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/ui/Resources/image/GenyConnect-Circle.png")
  list(APPEND genyconnect_image_assets ui/Resources/image/GenyConnect-Circle.png)
endif()
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/ui/Resources/image/GenyConnect.png")
  list(APPEND genyconnect_image_assets ui/Resources/image/GenyConnect.png)
endif()

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/ui/Resources/image/map.png")
  list(APPEND genyconnect_image_assets ui/Resources/image/map.png)
endif()
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/ui/Resources/image/power-orb-particle.svg")
  list(APPEND genyconnect_image_assets ui/Resources/image/power-orb-particle.svg)
endif()
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/images/map.png")
  list(APPEND genyconnect_image_assets images/map.png)
endif()
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/ui/Resources/image/token-white.png")
  list(APPEND genyconnect_image_assets ui/Resources/image/token-white.png)
endif()
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/ui/Resources/image/token-dark.png")
  list(APPEND genyconnect_image_assets ui/Resources/image/token-dark.png)
endif()

set(genyconnect_text_assets)
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
  list(APPEND genyconnect_text_assets LICENSE)
endif()
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE.txt")
  list(APPEND genyconnect_text_assets LICENSE.txt)
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
    ${genyconnect_text_assets}
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
    ui/Sections/qmldir
)

# -------------------------
# Windows resources
# -------------------------
if(WIN32)
  string(TIMESTAMP GENYCONNECT_COPYRIGHT_YEAR "%Y")

  set(GENYCONNECT_WINDOWS_ICON_SOURCE
    "${CMAKE_CURRENT_SOURCE_DIR}/ui/Resources/image/GenyConnect.ico"
  )

  if(NOT EXISTS "${GENYCONNECT_WINDOWS_ICON_SOURCE}")
    message(FATAL_ERROR
      "Windows icon file not found: ${GENYCONNECT_WINDOWS_ICON_SOURCE}"
    )
  endif()

  # Important:
  # Do NOT use file(TO_NATIVE_PATH) here.
  # Windows .rc files can misinterpret backslash escapes like \a in D:\a\...
  file(TO_CMAKE_PATH
    "${GENYCONNECT_WINDOWS_ICON_SOURCE}"
    GENYCONNECT_WINDOWS_ICON_PATH
  )

  set(GENYCONNECT_WINDOWS_RC_IN
    "${CMAKE_CURRENT_SOURCE_DIR}/properties/Windows/app.rc.in"
  )

  set(GENYCONNECT_WINDOWS_RC_OUT
    "${CMAKE_CURRENT_BINARY_DIR}/GenyConnect.rc"
  )

  configure_file(
    "${GENYCONNECT_WINDOWS_RC_IN}"
    "${GENYCONNECT_WINDOWS_RC_OUT}"
    @ONLY
  )

  target_sources(${PROJECT_NAME} PRIVATE
    "${GENYCONNECT_WINDOWS_RC_OUT}"
  )
endif()
# -------------------------
# Xray auto-download
# -------------------------
if(BUILD_TESTING AND NOT ANDROID AND NOT IOS)
  add_executable(genyconnect_securitystatus_tests
    tests/securitystatus_tests.cpp
    src/securitystatus.hpp
    src/securitystatus.cpp
  )
  target_include_directories(genyconnect_securitystatus_tests PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
  target_link_libraries(genyconnect_securitystatus_tests PRIVATE Qt6::Core Qt6::Test)
  add_test(NAME genyconnect_securitystatus_tests COMMAND genyconnect_securitystatus_tests)
endif()

if(GENYCONNECT_AUTO_DOWNLOAD_XRAY AND NOT GENYCONNECT_BUNDLED_XRAY_PATH)

  set(_geny_xray_version "${GENYCONNECT_XRAY_VERSION}")
  if(NOT _geny_xray_version MATCHES "^v")
    set(_geny_xray_version "v${_geny_xray_version}")
  endif()

  if(GENYCONNECT_XRAY_ASSET_NAME)
    set(_geny_xray_asset "${GENYCONNECT_XRAY_ASSET_NAME}")
  else()
    if(GENY_OS STREQUAL "windows")
      set(_geny_xray_platform "windows")
      if(GENY_ARCH MATCHES "^(arm64|aarch64)$")
        set(_geny_xray_arch "arm64-v8a")
      elseif(GENY_ARCH MATCHES "^(x86_64|amd64|x64)$")
        set(_geny_xray_arch "64")
      else()
        message(FATAL_ERROR "Unsupported CPU architecture for automatic Xray download: ${GENY_ARCH}")
      endif()
    elseif(GENY_OS STREQUAL "macos")
      set(_geny_xray_platform "macos")
      if(GENY_ARCH MATCHES "^(arm64|aarch64)$")
        set(_geny_xray_arch "arm64-v8a")
      elseif(GENY_ARCH MATCHES "^(x86_64|amd64|x64)$")
        set(_geny_xray_arch "64")
      else()
        message(FATAL_ERROR "Unsupported CPU architecture for automatic Xray download: ${GENY_ARCH}")
      endif()
    elseif(GENY_OS STREQUAL "android")
      set(_geny_xray_platform "android")
      if(GENY_ARCH MATCHES "^(arm64|aarch64|arm64-v8a)$")
        set(_geny_xray_arch "arm64-v8a")
      elseif(GENY_ARCH MATCHES "^(x86_64|amd64|x64)$")
        set(_geny_xray_arch "amd64")
      elseif(GENY_ARCH MATCHES "^(armv7|armv7a|armeabi-v7a|arm)$")
        set(_geny_do_xray_download FALSE)
        message(STATUS "Skipping official Xray download for Android armeabi-v7a; using local built binary.")
      endif()
    else()
      set(_geny_xray_platform "linux")
      if(GENY_ARCH MATCHES "^(arm64|aarch64)$")
        set(_geny_xray_arch "arm64-v8a")
      elseif(GENY_ARCH MATCHES "^(x86_64|amd64|x64)$")
        set(_geny_xray_arch "64")
      else()
        message(FATAL_ERROR "Unsupported CPU architecture for automatic Xray download: ${GENY_ARCH}")
      endif()
    endif()

    set(_geny_xray_asset "Xray-${_geny_xray_platform}-${_geny_xray_arch}.zip")
  endif()

  if(GENYCONNECT_BUILD_ANDROID)
    set(_geny_do_xray_download TRUE)
  elseif(NOT CMAKE_CONFIGURATION_TYPES)
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
    set(_geny_xray_archive     "${_geny_xray_cache_dir}/${_geny_xray_version}-${_geny_xray_asset}")
    set(_geny_xray_extract_dir "${_geny_xray_cache_dir}/extract-${_geny_xray_version}-${GENY_OS}-${GENY_ARCH}")
    set(_geny_xray_url         "https://github.com/XTLS/Xray-core/releases/download/${_geny_xray_version}/${_geny_xray_asset}")

    set(_geny_need_xray_download FALSE)
    if(NOT EXISTS "${_geny_xray_archive}")
      set(_geny_need_xray_download TRUE)
    else()
      file(SIZE "${_geny_xray_archive}" _geny_xray_archive_size)
      if(_geny_xray_archive_size LESS_EQUAL 0)
        message(STATUS "Cached Xray archive is empty; forcing re-download: ${_geny_xray_archive}")
        file(REMOVE "${_geny_xray_archive}")
        set(_geny_need_xray_download TRUE)
      endif()
    endif()

    if(_geny_need_xray_download)
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
      file(SIZE "${_geny_xray_archive}" _geny_xray_downloaded_size)
      if(_geny_xray_downloaded_size LESS_EQUAL 0)
        message(FATAL_ERROR "Downloaded Xray-core archive is empty: ${_geny_xray_archive}")
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
    set(_geny_xray_expected_name "xray")
    if(_geny_xray_platform STREQUAL "windows")
      set(_geny_xray_extracted_bin "${_geny_xray_extract_dir}/xray.exe")
      set(_geny_xray_expected_name "xray.exe")
    endif()

    if(NOT EXISTS "${_geny_xray_extracted_bin}")
      file(GLOB_RECURSE _geny_xray_discovered LIST_DIRECTORIES FALSE "${_geny_xray_extract_dir}/*")
      foreach(_geny_candidate IN LISTS _geny_xray_discovered)
        get_filename_component(_geny_candidate_name "${_geny_candidate}" NAME)
        if(_geny_candidate_name STREQUAL "${_geny_xray_expected_name}")
          set(_geny_xray_extracted_bin "${_geny_candidate}")
          break()
        endif()
      endforeach()
    endif()

    if(NOT EXISTS "${_geny_xray_extracted_bin}")
      message(FATAL_ERROR "Xray binary not found after extraction: ${_geny_xray_extract_dir}")
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

if(ANDROID AND DEFINED GENY_ANDROID_PACKAGE_BUILD_DIR AND NOT GENY_ANDROID_PACKAGE_BUILD_DIR STREQUAL "")
  set(_geny_android_abis "")

  if(DEFINED QT_ANDROID_ABIS AND NOT QT_ANDROID_ABIS STREQUAL "")
    set(_geny_android_abis ${QT_ANDROID_ABIS})
  elseif(DEFINED CMAKE_ANDROID_ARCH_ABI AND NOT CMAKE_ANDROID_ARCH_ABI STREQUAL "")
    list(APPEND _geny_android_abis "${CMAKE_ANDROID_ARCH_ABI}")
  endif()

  if(NOT _geny_android_abis)
    message(WARNING "No Android ABI detected; skipping Android xray asset bundle.")
  endif()

  if(GENYCONNECT_BUNDLED_XRAY_PATH AND EXISTS "${GENYCONNECT_BUNDLED_XRAY_PATH}")
    foreach(_geny_android_abi IN LISTS _geny_android_abis)
      if(NOT _geny_android_abi STREQUAL "${CMAKE_ANDROID_ARCH_ABI}")
        message(WARNING
          "Skipping Xray asset for ABI '${_geny_android_abi}' because this configure only has '${CMAKE_ANDROID_ARCH_ABI}'."
        )
        continue()
      endif()

      set(_geny_android_xray_assets_dir
        "${GENY_ANDROID_PACKAGE_BUILD_DIR}/assets/xray/${_geny_android_abi}"
      )

      file(MAKE_DIRECTORY "${_geny_android_xray_assets_dir}")

      file(COPY_FILE
        "${GENYCONNECT_BUNDLED_XRAY_PATH}"
        "${_geny_android_xray_assets_dir}/xray"
        ONLY_IF_DIFFERENT
      )

      set(_geny_android_libs_dir "${GENY_ANDROID_PACKAGE_BUILD_DIR}/libs/${_geny_android_abi}")
      file(MAKE_DIRECTORY "${_geny_android_libs_dir}")
      file(COPY_FILE
        "${GENYCONNECT_BUNDLED_XRAY_PATH}"
        "${_geny_android_libs_dir}/libxraycore.so"
        ONLY_IF_DIFFERENT
      )

      message(STATUS
        "Bundled Android Xray executable asset for ${_geny_android_abi}: "
        "${_geny_android_xray_assets_dir}/xray"
      )
      message(STATUS
        "Bundled Android Xray native exec shim for ${_geny_android_abi}: "
        "${_geny_android_libs_dir}/libxraycore.so"
      )
    endforeach()
  else()
    message(WARNING "GENYCONNECT_BUNDLED_XRAY_PATH is empty or missing; Android Xray asset not bundled.")
  endif()

  foreach(_geny_android_abi IN LISTS _geny_android_abis)
    set(_geny_android_ssl_root "${GENYCONNECT_ANDROID_OPENSSL_ROOT}")

    if(_geny_android_ssl_root STREQUAL "")
      set(_geny_android_sdk_root "")

      if(DEFINED CMAKE_ANDROID_NDK AND NOT CMAKE_ANDROID_NDK STREQUAL "")
        get_filename_component(_geny_android_ndk_parent "${CMAKE_ANDROID_NDK}" DIRECTORY)
        get_filename_component(_geny_android_sdk_root "${_geny_android_ndk_parent}" DIRECTORY)
      elseif(DEFINED ENV{ANDROID_SDK_ROOT} AND NOT "$ENV{ANDROID_SDK_ROOT}" STREQUAL "")
        set(_geny_android_sdk_root "$ENV{ANDROID_SDK_ROOT}")
      elseif(DEFINED ENV{ANDROID_HOME} AND NOT "$ENV{ANDROID_HOME}" STREQUAL "")
        set(_geny_android_sdk_root "$ENV{ANDROID_HOME}")
      endif()

      if(NOT _geny_android_sdk_root STREQUAL "")
        set(_geny_android_ssl_root "${_geny_android_sdk_root}/android_openssl/ssl_3")
      endif()
    endif()

    if(NOT _geny_android_ssl_root STREQUAL "")
      set(_geny_android_ssl_abi_dir "${_geny_android_ssl_root}/${_geny_android_abi}")
      set(_geny_android_ssl_lib "${_geny_android_ssl_abi_dir}/libssl_3.so")
      set(_geny_android_crypto_lib "${_geny_android_ssl_abi_dir}/libcrypto_3.so")

      if(EXISTS "${_geny_android_ssl_lib}" AND EXISTS "${_geny_android_crypto_lib}")
        set(_geny_android_libs_dir "${GENY_ANDROID_PACKAGE_BUILD_DIR}/libs/${_geny_android_abi}")

        file(MAKE_DIRECTORY "${_geny_android_libs_dir}")

        file(COPY_FILE
          "${_geny_android_ssl_lib}"
          "${_geny_android_libs_dir}/libssl_3.so"
          ONLY_IF_DIFFERENT
        )

        file(COPY_FILE
          "${_geny_android_crypto_lib}"
          "${_geny_android_libs_dir}/libcrypto_3.so"
          ONLY_IF_DIFFERENT
        )

        message(STATUS "Bundled Android OpenSSL libs for ${_geny_android_abi} from: ${_geny_android_ssl_abi_dir}")
      else()
        message(WARNING
          "Android OpenSSL libs not found for ABI '${_geny_android_abi}' under '${_geny_android_ssl_abi_dir}'. "
          "Qt TLS backend may fail to load."
        )
      endif()
    endif()
  endforeach()
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
if(APPLE AND GENYCONNECT_BUILD_DESKTOP AND TARGET GenyConnectUpdater AND TARGET GenyConnectTunHelper AND GENYCONNECT_MACOS_POSTBUILD_DEPLOY)

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

  if(GENYCONNECT_CODESIGN_IDENTITY STREQUAL "-")
    set(_codesign_common
      "--force"
      "--deep"
      "--sign" "${GENYCONNECT_CODESIGN_IDENTITY}"
    )
  else()
    set(_codesign_common
      "--force"
      "--deep"
      "--options" "runtime"
      "--timestamp"
      "--sign" "${GENYCONNECT_CODESIGN_IDENTITY}"
    )
  endif()

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
    COMMAND $<$<AND:${GENY_IS_RELEASE},$<BOOL:${GENYCONNECT_BUNDLED_XRAY_PATH}>>:/bin/chmod>
            755
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

    COMMAND $<$<AND:${GENY_IS_RELEASE},$<BOOL:${GENYCONNECT_MACOS_CODESIGN}>>:${CODESIGN_EXECUTABLE}>
            --verify --deep --strict --verbose=2
            "${_bundle_dir}"

    COMMENT "macOS deploy: copy helper/xray, macdeployqt, then codesign (Release only)"
    VERBATIM
  )
endif()

# -----------------------------------------------------------------------------
# Install rules (used by CPack)
# -----------------------------------------------------------------------------
if(GENYCONNECT_BUILD_DESKTOP)
if(WIN32 AND MSVC)
  set(CMAKE_INSTALL_SYSTEM_RUNTIME_DESTINATION ".")
  set(CMAKE_INSTALL_UCRT_LIBRARIES TRUE)

  include(InstallRequiredSystemLibraries)

  message(STATUS "MSVC runtime libraries:")
  foreach(_geny_runtime_lib IN LISTS CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS)
    message(STATUS "  ${_geny_runtime_lib}")
  endforeach()
endif()

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
if(TARGET GenyConnectUpdater)
  if(APPLE)
    install(TARGETS GenyConnectUpdater
      CONFIGURATIONS Release RelWithDebInfo
      RUNTIME DESTINATION "${GENY_OUTPUT_NAME}.app/Contents/MacOS"
    )
  else()
    install(TARGETS GenyConnectUpdater
      CONFIGURATIONS Release RelWithDebInfo
      RUNTIME DESTINATION "${_GENY_WIN_RUNTIME_DEST}"
    )
  endif()
endif()

if(TARGET GenyConnectTunHelper)
  if(APPLE)
    install(TARGETS GenyConnectTunHelper
      CONFIGURATIONS Release RelWithDebInfo
      RUNTIME DESTINATION "${GENY_OUTPUT_NAME}.app/Contents/MacOS"
    )
  else()
    install(TARGETS GenyConnectTunHelper
      CONFIGURATIONS Release RelWithDebInfo
      RUNTIME DESTINATION "${_GENY_WIN_RUNTIME_DEST}"
    )
  endif()
endif()

# Install xray into package too
if(GENYCONNECT_BUILD_DESKTOP AND GENYCONNECT_BUNDLED_XRAY_PATH)
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
# Linux desktop integration assets (.desktop launcher + icon)
# -----------------------------------------------------------------------------
option(GENYCONNECT_LINUX_INSTALL_DESKTOP_ASSETS "Install Linux desktop entry and icon assets" ON)

if(UNIX AND NOT APPLE AND GENYCONNECT_BUILD_DESKTOP AND GENYCONNECT_LINUX_INSTALL_DESKTOP_ASSETS)
  set(_geny_linux_desktop_in
    "${CMAKE_CURRENT_SOURCE_DIR}/properties/Linux/genyconnect.desktop.in")
  set(_geny_linux_desktop_out
    "${CMAKE_CURRENT_BINARY_DIR}/genyconnect.desktop")

  if(EXISTS "${_geny_linux_desktop_in}")
    configure_file("${_geny_linux_desktop_in}" "${_geny_linux_desktop_out}" @ONLY)
    install(FILES "${_geny_linux_desktop_out}"
      DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/applications")
  else()
    message(WARNING
      "Linux desktop entry template not found: ${_geny_linux_desktop_in}")
  endif()

  set(_geny_linux_icon_source
    "${CMAKE_CURRENT_SOURCE_DIR}/ui/Resources/image/GenyConnect.png")

  if(EXISTS "${_geny_linux_icon_source}")
    install(FILES "${_geny_linux_icon_source}"
      DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/512x512/apps"
      RENAME "genyconnect.png")
    install(FILES "${_geny_linux_icon_source}"
      DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/pixmaps"
      RENAME "genyconnect.png")
  else()
    message(WARNING
      "Linux application icon not found: ${_geny_linux_icon_source}")
  endif()
endif()

# -----------------------------------------------------------------------------
# Linux deploy: collect Qt/QML runtime dependencies into the install tree
# -----------------------------------------------------------------------------
option(GENYCONNECT_LINUX_INSTALL_DEPLOY "Run Qt Linux deployment during install() so CPack TGZ includes Qt/QML dependencies" ON)
option(GENYCONNECT_LINUX_DEPLOY_TRANSLATIONS "Include Qt translations in Linux deployment package" OFF)

if(UNIX AND NOT APPLE AND GENYCONNECT_LINUX_INSTALL_DEPLOY)
  set(_geny_linux_deploy_args "")
  if(NOT GENYCONNECT_LINUX_DEPLOY_TRANSLATIONS)
    list(APPEND _geny_linux_deploy_args NO_TRANSLATIONS)
  endif()
  qt_generate_deploy_qml_app_script(
    TARGET ${PROJECT_NAME}
    OUTPUT_SCRIPT GENYCONNECT_LINUX_DEPLOY_SCRIPT
    NO_UNSUPPORTED_PLATFORM_ERROR
    ${_geny_linux_deploy_args}
  )
  install(SCRIPT ${GENYCONNECT_LINUX_DEPLOY_SCRIPT})
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

if(UNIX AND NOT APPLE)
  set(_GENY_DOC_INSTALL_DEST "${CMAKE_INSTALL_DOCDIR}")
else()
  set(_GENY_DOC_INSTALL_DEST ".")
endif()

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
    install(FILES "${_GENY_DOC_README_TXT}" DESTINATION "${_GENY_DOC_INSTALL_DEST}" RENAME "README.txt")
  else()
    message(WARNING "No README file found to bundle.")
  endif()

  if(_GENY_DOC_LICENSE_SRC)
    set(_GENY_DOC_LICENSE_TXT "${CMAKE_BINARY_DIR}/NSIS_LICENSE.txt")
    configure_file("${_GENY_DOC_LICENSE_SRC}" "${_GENY_DOC_LICENSE_TXT}" COPYONLY)
    install(FILES "${_GENY_DOC_LICENSE_TXT}" DESTINATION "${_GENY_DOC_INSTALL_DEST}" RENAME "LICENSE.txt")
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
  set(CPACK_GENERATOR "TGZ;RPM")
  set(CPACK_RPM_PACKAGE_NAME "genyconnect")
  set(CPACK_RPM_PACKAGE_RELEASE "1")
  set(CPACK_RPM_PACKAGE_RELEASE_DIST ON)
  set(CPACK_RPM_PACKAGE_LICENSE "GPL-3.0-or-later")
  set(CPACK_RPM_PACKAGE_GROUP "Applications/Internet")
  set(CPACK_RPM_PACKAGE_URL "https://github.com/genyleap/GenyConnect")
  set(CPACK_RPM_PACKAGE_REQUIRES "qt6-qtbase-gui, qt6-qtdeclarative, qt6-qtsvg")
  set(CPACK_RPM_PACKAGE_AUTOREQPROV ON)
  set(CPACK_RPM_FILE_NAME "RPM-DEFAULT")
  set(CPACK_RPM_EXCLUDE_FROM_AUTO_FILELIST_ADDITION
    "/usr/share/applications"
    "/usr/share/doc"
    "/usr/share/icons"
    "/usr/share/icons/hicolor"
    "/usr/share/icons/hicolor/512x512"
    "/usr/share/icons/hicolor/512x512/apps"
    "/usr/share/pixmaps"
  )
endif()

include(CPack)

message(STATUS "Build dir: ${CMAKE_BINARY_DIR}")
message(STATUS "Packages dir: ${GENY_FINAL_DIR}")
message(STATUS "Packaging: run cpack (multi-config add: -C Release)")
endif()
