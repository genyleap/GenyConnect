cmake_minimum_required(VERSION 3.28)

set(PROJECT_NAME "GenyConnect")
set(APP_NAME "${PROJECT_NAME}")
project(${PROJECT_NAME} VERSION 0.1.0 LANGUAGES CXX)

if(POLICY CMP0155)
    cmake_policy(SET CMP0155 NEW)
endif()

option(GENYCONNECT_USE_MODULES "Enable C++20 modules" ON)
option(GENYCONNECT_LLVM_AUTO_SCAN "Auto-detect LLVM/clang for modules" ON)
option(GENYCONNECT_QT_AUTO_SCAN "Auto-detect Qt installation prefix" ON)
option(GENYCONNECT_AUTO_DOWNLOAD_XRAY "Automatically download and bundle xray-core" ON)
set(GENYCONNECT_XRAY_VERSION "v26.2.6" CACHE STRING "Xray-core release tag (e.g. v26.2.6)")
set(GENYCONNECT_XRAY_ASSET_NAME "" CACHE STRING "Optional explicit Xray release asset name override")
set(GENYCONNECT_BUNDLED_XRAY_PATH "" CACHE FILEPATH "Path to prebuilt xray-core binary to bundle with app")

if(APPLE)
    execute_process(
        COMMAND xcrun --sdk macosx --show-sdk-path
        OUTPUT_VARIABLE GENYCONNECT_MACOS_SDK
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(GENYCONNECT_MACOS_SDK)
        set(CMAKE_OSX_SYSROOT "${GENYCONNECT_MACOS_SDK}" CACHE PATH "macOS SDK" FORCE)
    endif()
endif()

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

qt_add_executable(${APP_NAME}
    WIN32
    MACOSX_BUNDLE
    src/main.cpp
    ${GENYCONNECT_IMPL_SOURCES}
)

# ---- QML Files ----
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

set(qml_main
    ui/Main.qml
)

set(qml_files
    ${qml_main}
    ${qml_core}
    ${qml_controls}
)

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

qt_add_resources(${APP_NAME} GenyConnectAssets
    PREFIX /
    FILES
    ui/Resources/fonts/Farhang2-Regular.ttf
    ui/Resources/fonts/fa-brands-400.woff2
    ui/Resources/fonts/fa-regular-400.woff2
    ui/Resources/fonts/fa-solid-900.woff2
    ${genyconnect_image_assets}
)

qt_add_qml_module(${APP_NAME}
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

target_sources(${APP_NAME}
    PUBLIC
    FILE_SET CXX_MODULES TYPE CXX_MODULES
    BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/src
    FILES ${GENYCONNECT_MODULE_IFS}
)

if(GENYCONNECT_USE_MODULES)
    set_property(TARGET ${APP_NAME} PROPERTY CXX_SCAN_FOR_MODULES ON)
endif()

target_include_directories(${APP_NAME}
    PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(${APP_NAME}
    PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Network
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
)

set_target_properties(${APP_NAME} PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

if(GENYCONNECT_AUTO_DOWNLOAD_XRAY AND NOT GENYCONNECT_BUNDLED_XRAY_PATH)
    set(_geny_xray_version "${GENYCONNECT_XRAY_VERSION}")
    if(NOT _geny_xray_version MATCHES "^v")
        set(_geny_xray_version "v${_geny_xray_version}")
    endif()

    if(GENYCONNECT_XRAY_ASSET_NAME)
        set(_geny_xray_asset "${GENYCONNECT_XRAY_ASSET_NAME}")
    else()
        set(_geny_xray_arch "")
        if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(arm64|aarch64|ARM64)$")
            set(_geny_xray_arch "arm64-v8a")
        elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|AMD64|amd64|x64)$")
            set(_geny_xray_arch "64")
        endif()

        if(WIN32)
            set(_geny_xray_platform "windows")
        elseif(APPLE)
            set(_geny_xray_platform "macos")
        else()
            set(_geny_xray_platform "linux")
        endif()

        if(NOT _geny_xray_arch)
            message(FATAL_ERROR
                "Unsupported CPU architecture for automatic Xray download: ${CMAKE_SYSTEM_PROCESSOR}. "
                "Set GENYCONNECT_XRAY_ASSET_NAME manually or provide GENYCONNECT_BUNDLED_XRAY_PATH."
            )
        endif()

        set(_geny_xray_asset "Xray-${_geny_xray_platform}-${_geny_xray_arch}.zip")
    endif()

    set(_geny_xray_cache_dir "${CMAKE_BINARY_DIR}/_deps/xray")
    file(MAKE_DIRECTORY "${_geny_xray_cache_dir}")
    set(_geny_xray_archive "${_geny_xray_cache_dir}/${_geny_xray_asset}")
    set(_geny_xray_extract_dir "${_geny_xray_cache_dir}/extract-${_geny_xray_version}")
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
        message(FATAL_ERROR
            "Failed to extract Xray-core archive ${_geny_xray_archive}: ${_geny_xray_extract_err}"
        )
    endif()

    set(_geny_xray_extracted_bin "${_geny_xray_extract_dir}/xray")
    if(WIN32)
        set(_geny_xray_extracted_bin "${_geny_xray_extract_dir}/xray.exe")
    endif()
    if(NOT EXISTS "${_geny_xray_extracted_bin}")
        message(FATAL_ERROR
            "Xray binary not found after extraction: ${_geny_xray_extracted_bin}. "
            "Asset may be incorrect. Try setting GENYCONNECT_XRAY_ASSET_NAME manually."
        )
    endif()

    set(GENYCONNECT_BUNDLED_XRAY_PATH "${_geny_xray_extracted_bin}")
    message(STATUS "Using auto-downloaded Xray-core binary: ${GENYCONNECT_BUNDLED_XRAY_PATH}")
endif()

if(GENYCONNECT_BUNDLED_XRAY_PATH)
    if(NOT EXISTS "${GENYCONNECT_BUNDLED_XRAY_PATH}")
        message(FATAL_ERROR "GENYCONNECT_BUNDLED_XRAY_PATH does not exist: ${GENYCONNECT_BUNDLED_XRAY_PATH}")
    endif()

    get_filename_component(_geny_xray_file_name "${GENYCONNECT_BUNDLED_XRAY_PATH}" NAME)
    if(WIN32)
        set(_geny_xray_target_name "xray-core.exe")
    else()
        set(_geny_xray_target_name "xray-core")
    endif()

    add_custom_command(TARGET ${APP_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${GENYCONNECT_BUNDLED_XRAY_PATH}"
            "$<TARGET_FILE_DIR:${APP_NAME}>/${_geny_xray_target_name}"
        COMMENT "Bundling xray-core into app output directory"
    )
    if(NOT WIN32)
        add_custom_command(TARGET ${APP_NAME} POST_BUILD
            COMMAND chmod +x "$<TARGET_FILE_DIR:${APP_NAME}>/${_geny_xray_target_name}"
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

include(GNUInstallDirs)
install(TARGETS ${APP_NAME}
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
