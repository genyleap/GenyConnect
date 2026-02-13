cmake_minimum_required(VERSION 3.28)

# -----------------------------------------------------------------------------
# GenyConnect CMakeLists - single-file, cross-platform, single-arch build
# Notes:
#  - CMake build directory => one toolchain/one architecture. Create separate
#    build directories for other archs (use cmake presets or scripts).
#  - This file detects host OS/arch by default but accepts GENYCONNECT_TARGET_OS
#    and GENYCONNECT_TARGET_ARCH cache variables to override detection.
# -----------------------------------------------------------------------------

set(PROJECT_NAME "GenyConnect")
project(${PROJECT_NAME} VERSION 1.0.0 LANGUAGES CXX)

if(POLICY CMP0155)
    cmake_policy(SET CMP0155 NEW)
endif()

# -------------------------
# User options (same as before)
# -------------------------
option(GENYCONNECT_USE_MODULES "Enable C++20 modules" ON)
option(GENYCONNECT_LLVM_AUTO_SCAN "Auto-detect LLVM/clang for modules" ON)
option(GENYCONNECT_QT_AUTO_SCAN "Auto-detect Qt installation prefix" ON)
option(GENYCONNECT_AUTO_DOWNLOAD_XRAY "Automatically download and bundle xray-core" ON)

set(GENYCONNECT_XRAY_VERSION "v26.2.6" CACHE STRING "Xray-core release tag (e.g. v26.2.6)")
set(GENYCONNECT_XRAY_ASSET_NAME "" CACHE STRING "Optional explicit Xray release asset name override")
set(GENYCONNECT_BUNDLED_XRAY_PATH "" CACHE FILEPATH "Path to prebuilt xray-core binary to bundle with app")

# Optional overrides (useful for cross-build or explicit naming)
set(GENYCONNECT_TARGET_OS "" CACHE STRING "Override target OS for output naming (macos|linux|windows)")
set(GENYCONNECT_TARGET_ARCH "arm64" CACHE STRING "Override target arch for output naming (arm64|x86_64)")
set(GENYCONNECT_OUTPUT_NAME "" CACHE STRING "Optional explicit output name (overrides generated name)")
set(CMAKE_OSX_ARCHITECTURES "arm64" CACHE STRING "Build architecture" FORCE)

# -------------------------
# Detect/normalise OS and arch for naming & xray selection
# -------------------------
# Normalise OS
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

# Normalise arch
if(GENYCONNECT_TARGET_ARCH AND NOT GENYCONNECT_TARGET_ARCH STREQUAL "")
    string(TOLOWER "${GENYCONNECT_TARGET_ARCH}" GENY_ARCH_RAW)
else()
    if(DEFINED CMAKE_SYSTEM_PROCESSOR AND CMAKE_SYSTEM_PROCESSOR)
        set(GENY_ARCH_RAW "${CMAKE_SYSTEM_PROCESSOR}")
    else()
        # fallback
        set(GENY_ARCH_RAW "x86_64")
    endif()
endif()

# Map common variants to canonical names
string(TOLOWER "${GENY_ARCH_RAW}" GENY_ARCH)
if(GENY_ARCH MATCHES "^(arm64|aarch64|arm64-v8a)$")
    set(GENY_ARCH "arm64")
elseif(GENY_ARCH MATCHES "^(x86_64|amd64|x64|64)$")
    set(GENY_ARCH "x86_64")
endif()

# Compose output name unless user supplied explicit GENYCONNECT_OUTPUT_NAME
if(GENYCONNECT_OUTPUT_NAME AND NOT GENYCONNECT_OUTPUT_NAME STREQUAL "")
    set(GENY_OUTPUT_NAME "${GENYCONNECT_OUTPUT_NAME}")
else()
    set(GENY_OUTPUT_NAME "${PROJECT_NAME}")
endif()

message(STATUS "GenyConnect build: OS='${GENY_OS}' ARCH='${GENY_ARCH}'")
message(STATUS "Configured output name: ${GENY_OUTPUT_NAME}")

# -------------------------
# Compiler / module checks (kept from original)
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

find_program(GENYCONNECT_CLANGXX
    NAMES clang++ clang-cl
    HINTS ${GENYCONNECT_LLVM_HINTS}
)
find_program(GENYCONNECT_CLANG_SCAN_DEPS
    NAMES clang-scan-deps
    HINTS ${GENYCONNECT_LLVM_HINTS}
)
if(NOT GENYCONNECT_CLANG_SCAN_DEPS AND CMAKE_CXX_COMPILER)
    get_filename_component(GENYCONNECT_CXX_DIR "${CMAKE_CXX_COMPILER}" DIRECTORY)
    if(GENYCONNECT_CXX_DIR)
        find_program(GENYCONNECT_CLANG_SCAN_DEPS
            NAMES clang-scan-deps
            HINTS "${GENYCONNECT_CXX_DIR}"
        )
    endif()
endif()

set(GENYCONNECT_CXX_COMPILER_HINT "")
if(DEFINED CACHE{CMAKE_CXX_COMPILER})
    get_property(GENYCONNECT_CXX_COMPILER_HINT CACHE CMAKE_CXX_COMPILER PROPERTY VALUE)
elseif(DEFINED CMAKE_CXX_COMPILER)
    set(GENYCONNECT_CXX_COMPILER_HINT "${CMAKE_CXX_COMPILER}")
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
# Standard project compile flags
# -------------------------
set(CMAKE_CXX_STANDARD 20)
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
                "AppleClang is active in this build directory (CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}). "
                "LLVM clang is available at ${GENYCONNECT_CLANGXX}, but CMake cannot switch compilers in-place. "
                "Delete the build directory and reconfigure with "
                "-DCMAKE_CXX_COMPILER=${GENYCONNECT_CLANGXX} "
                "-DCMAKE_CXX_COMPILER_CLANG_SCAN_DEPS=${GENYCONNECT_CLANG_SCAN_DEPS}, "
                "or set -DGENYCONNECT_USE_MODULES=OFF."
            )
        else()
            message(FATAL_ERROR
                "AppleClang does not provide stable C++20 module scanning for this target. "
                "Install LLVM clang (clang++ + clang-scan-deps) or configure with -DGENYCONNECT_USE_MODULES=OFF."
            )
        endif()
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        message(FATAL_ERROR
            "GCC is not supported for C++20 modules in this project. "
            "Use Clang (with clang-scan-deps) or MSVC, or set -DGENYCONNECT_USE_MODULES=OFF."
        )
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang" AND NOT CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS)
        message(FATAL_ERROR
            "C++20 modules require clang-scan-deps. Install LLVM and ensure it is on PATH "
            "or set -DCMAKE_CXX_COMPILER_CLANG_SCAN_DEPS=/path/to/clang-scan-deps."
        )
    endif()
endif()

# -------------------------
# Qt auto-scan helpers (unchanged)
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

find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Network Qml Quick QuickControls2)
qt_standard_project_setup(REQUIRES 6.8)

# -------------------------
# Sources
# -------------------------
set(GENYCONNECT_MODULE_IFS
    src/connectionstate.cppm
    src/serverprofile.cppm
    src/serverprofilemodel.cppm
    src/linkparser.cppm
    src/xrayconfigbuilder.cppm
    src/systemproxymanager.cppm
    src/xrayprocessmanager.cppm
    src/vpncontroller.cppm
)

set(GENYCONNECT_IMPL_SOURCES
    src/serverprofile.cpp
    src/serverprofilemodel.cpp
    src/linkparser.cpp
    src/xrayconfigbuilder.cpp
    src/systemproxymanager.cpp
    src/xrayprocessmanager.cpp
    src/vpncontroller.cpp
)

qt_add_executable(${PROJECT_NAME}
    WIN32
    MACOSX_BUNDLE
    src/main.cpp
    ${GENYCONNECT_IMPL_SOURCES}
)

# Set OUTPUT_NAME so the produced binary/bundle has OS+ARCH+version in its file name
set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME "${GENY_OUTPUT_NAME}")

# Apply C++ modules scanning if requested
if(GENYCONNECT_USE_MODULES)
    set_property(TARGET ${PROJECT_NAME} PROPERTY CXX_SCAN_FOR_MODULES ON)
endif()

target_include_directories(${PROJECT_NAME}
    PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(${PROJECT_NAME}
    PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Network
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
)

# macOS bundle properties if building for macOS
if(GENY_OS STREQUAL "macos")
    # Optional: user may choose to set a different macOS deployment target before configure
    set(CMAKE_OSX_DEPLOYMENT_TARGET "15.1" CACHE STRING "Minimum macOS version")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mmacosx-version-min=15.1")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mmacosx-version-min=15.1")
    set(CMAKE_OSX_DEPLOYMENT_TARGET "15.1")
    set_target_properties(${PROJECT_NAME} PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
        MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
        MACOSX_BUNDLE_ICON_FILE "GenyConnect.icns"
    )
else()
    # Keep properties consistent across platforms
    set_target_properties(${PROJECT_NAME} PROPERTIES
        WIN32_EXECUTABLE TRUE
    )
endif()

# -------------------------
# QML & resources (unchanged)
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
    ui/Resources/fonts/Farhang2-Regular.ttf
    ui/Resources/fonts/fa-brands-400.woff2
    ui/Resources/fonts/fa-regular-400.woff2
    ui/Resources/fonts/fa-solid-900.woff2
    ${genyconnect_image_assets}
)

qt_add_qml_module(${PROJECT_NAME}
    URI GenyConnect
    VERSION 1.0
    QML_FILES
    ${qml_files}
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
# Xray asset selection (uses GENY_OS + GENY_ARCH)
# -------------------------
if(GENYCONNECT_AUTO_DOWNLOAD_XRAY AND NOT GENYCONNECT_BUNDLED_XRAY_PATH)
    set(_geny_xray_version "${GENYCONNECT_XRAY_VERSION}")
    if(NOT _geny_xray_version MATCHES "^v")
        set(_geny_xray_version "v${_geny_xray_version}")
    endif()

    if(GENYCONNECT_XRAY_ASSET_NAME)
        set(_geny_xray_asset "${GENYCONNECT_XRAY_ASSET_NAME}")
    else()
        # Map arch to Xray naming
        if(GENY_ARCH MATCHES "^(arm64|aarch64)$")
            set(_geny_xray_arch "arm64-v8a")
        elseif(GENY_ARCH MATCHES "^(x86_64|amd64|x64)$")
            set(_geny_xray_arch "64")
        else()
            message(FATAL_ERROR "Unsupported CPU architecture for automatic Xray download: ${GENY_ARCH}. Please set GENYCONNECT_XRAY_ASSET_NAME or GENYCONNECT_BUNDLED_XRAY_PATH manually.")
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

    set(_geny_xray_cache_dir "${CMAKE_BINARY_DIR}/_deps/xray")
    file(MAKE_DIRECTORY "${_geny_xray_cache_dir}")
    set(_geny_xray_archive "${_geny_xray_cache_dir}/${_geny_xray_asset}")
    set(_geny_xray_extract_dir "${_geny_xray_cache_dir}/extract-${_geny_xray_version}-${GENY_OS}-${GENY_ARCH}")
    set(_geny_xray_url "https://github.com/XTLS/Xray-core/releases/download/${_geny_xray_version}/${_geny_xray_asset}")

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
            message(FATAL_ERROR
                "Failed to download Xray-core (${_geny_xray_url}): ${_geny_xray_download_message}. "
                "Set GENYCONNECT_XRAY_ASSET_NAME or GENYCONNECT_BUNDLED_XRAY_PATH."
            )
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
        OUTPUT_VARIABLE _geny_xray_extract_out
        ERROR_VARIABLE _geny_xray_extract_err
    )
    if(NOT _geny_xray_extract_result EQUAL 0)
        message(FATAL_ERROR "Failed to extract Xray-core archive ${_geny_xray_archive}: ${_geny_xray_extract_err}")
    endif()

    set(_geny_xray_extracted_bin "${_geny_xray_extract_dir}/xray")
    if(_geny_xray_platform STREQUAL "windows")
        set(_geny_xray_extracted_bin "${_geny_xray_extract_dir}/xray.exe")
    endif()
    if(NOT EXISTS "${_geny_xray_extracted_bin}")
        message(FATAL_ERROR "Xray binary not found after extraction: ${_geny_xray_extracted_bin}. Asset may be incorrect. Try setting GENYCONNECT_XRAY_ASSET_NAME manually.")
    endif()

    set(GENYCONNECT_BUNDLED_XRAY_PATH "${_geny_xray_extracted_bin}")
    message(STATUS "Using auto-downloaded Xray-core binary: ${GENYCONNECT_BUNDLED_XRAY_PATH}")
endif()

# -------------------------
# Bundle/copy Xray after build and install entry
# -------------------------
if(GENYCONNECT_BUNDLED_XRAY_PATH)
    if(NOT EXISTS "${GENYCONNECT_BUNDLED_XRAY_PATH}")
        message(FATAL_ERROR "GENYCONNECT_BUNDLED_XRAY_PATH does not exist: ${GENYCONNECT_BUNDLED_XRAY_PATH}")
    endif()

    get_filename_component(_geny_xray_file_name "${GENYCONNECT_BUNDLED_XRAY_PATH}" NAME)
    if(GENY_OS STREQUAL "windows")
        set(_geny_xray_target_name "xray-core.exe")
    else()
        set(_geny_xray_target_name "xray-core")
    endif()

    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${GENYCONNECT_BUNDLED_XRAY_PATH}"
            "$<TARGET_FILE_DIR:${PROJECT_NAME}>/${_geny_xray_target_name}"
        COMMENT "Bundling xray-core into app output directory"
    )

    if(NOT (GENY_OS STREQUAL "windows"))
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND chmod +x "$<TARGET_FILE_DIR:${PROJECT_NAME}>/${_geny_xray_target_name}"
            COMMENT "Setting execute permission on bundled xray-core"
        )
    endif()

    install(FILES "${GENYCONNECT_BUNDLED_XRAY_PATH}"
        DESTINATION ${CMAKE_INSTALL_BINDIR}
        RENAME ${_geny_xray_target_name}
        PERMISSIONS
            OWNER_READ OWNER_WRITE OWNER_EXECUTE
            GROUP_READ GROUP_EXECUTE
            WORLD_READ WORLD_EXECUTE
    )
endif()

# -------------------------
# macOS icon & macdeployqt (only when building for macos)
# -------------------------
if(GENY_OS STREQUAL "macos")
    # Copy icon inside bundle
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_CURRENT_SOURCE_DIR}/ui/Resources/image/GenyConnect.icns"
            "$<TARGET_FILE_DIR:${PROJECT_NAME}>/../Resources/GenyConnect.icns"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_CURRENT_SOURCE_DIR}/ui/Resources/image/GenyConnect.png"
            "$<TARGET_FILE_DIR:${PROJECT_NAME}>/../Resources/GenyConnect.png"
        COMMENT "Copying GenyConnect icons into bundle Resources"
    )

    find_program(MACDEPLOYQT_EXECUTABLE
        NAMES macdeployqt
        HINTS $ENV{QTDIR} "$ENV{HOME}/Qt" "$ENV{HOME}/Qt/*/macos/bin"
    )

    if(MACDEPLOYQT_EXECUTABLE)
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND "${MACDEPLOYQT_EXECUTABLE}" "$<TARGET_BUNDLE_DIR:${PROJECT_NAME}>" -dmg -verbose=3 -qmldir=${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Bundling Qt frameworks and QML modules for macOS"
        )
    else()
        message(WARNING "macdeployqt not found; mac bundle/dmg won't be created automatically.")
    endif()
endif()

# -------------------------
# Install rules (standard)
# -------------------------
include(GNUInstallDirs)
install(TARGETS ${PROJECT_NAME}
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

# -------------------------
# Helpful status output
# -------------------------
message(STATUS "Build files written to: ${CMAKE_BINARY_DIR}")
message(STATUS "To inspect produced binary after build run:")

if(GENY_OS STREQUAL "macos")
    message(STATUS "  file \"${CMAKE_BINARY_DIR}/${GENY_OUTPUT_NAME}.app/Contents/MacOS/${GENY_OUTPUT_NAME}\"  (or check the bundle)")
else()
    message(STATUS "  file \"${CMAKE_BINARY_DIR}/${GENY_OUTPUT_NAME}\"")
endif()

# End of CMakeLists.txt
