# Building GenyConnect

GenyConnect uses named C++ modules in its backend on every platform, including
Android. It requires CMake 3.28 or newer and a compiler with CMake-compatible
module scanning. There is no non-module source fallback:
`GENYCONNECT_USE_MODULES=OFF` and disabling module scanning do not make Makefiles
or Xcode generators compatible with the application.

Use **Ninja 1.11 or newer** (or Ninja Multi-Config) on Linux, macOS, and Android.
Windows also supports Visual Studio 2022 version 17.4 or newer, or Visual Studio
2026, with the corresponding CMake generator and a compatible compiler.
The generator is a build-directory setting: select a new build directory when
changing it so the previous cache and generated rules are not reused.

## Android in Qt Creator

If configuration ends with `modules are not supported by this generator: Unix
Makefiles` or `GenyConnect uses C++ modules, which 'Unix Makefiles' cannot build`,
the selected build configuration is using an unsupported generator. The failure
occurs before application compilation.

1. Make Ninja 1.11 or newer available to Qt Creator. In **Projects > Build
   Settings > Kit Configuration**, select **Change** next to **CMake generator**
   and choose **Ninja**. If Ninja is not on the kit's `PATH`, set
   `CMAKE_MAKE_PROGRAM` to the installed Ninja executable in that kit's CMake
   configuration (use `ninja.exe` on Windows).
2. For an existing build configuration, also check **Initial Configuration** in
   **Projects > Build Settings**. Its saved `CMAKE_GENERATOR` must be `Ninja`;
   changing the kit default alone can leave the project's previous value in
   place. Qt Creator stores these project-specific initial values in
   `.qtcreator/CMakeLists.txt.user`, separately from `CMakeCache.txt`.
   Keep the selected Qt for Android kit and its NDK compiler, and choose a new
   build directory, for example `build/android-arm64-ninja-debug`. Changing a
   generator entry in the old directory's cache does not replace its generated
   Makefiles.
3. Keep `GENYCONNECT_USE_MODULES=ON`. The `clang-scan-deps` executable must belong
   to the same NDK toolchain as `CMAKE_CXX_COMPILER`. The project searches beside
   the active compiler first; an explicitly configured
   `CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS` is preserved.
4. Configure the project with that kit and the new directory.

Use the SDK, NDK and host Qt versions required by the selected Qt for Android
installation. The matching host Qt supplies build-time tools; it does not
replace the Android compiler or target Qt libraries.

NDK 27.2's `cmake_minimum_required` deprecation warnings about compatibility with
CMake versions older than 3.10 are separate from the generator error. In the
reported CMake 4.4.3 log they are warnings, not the cause of the failed generate
step. Changing this project's minimum version cannot update the NDK's own CMake
files.

## Android from the command line

Use the target Qt installation's `qt-cmake` wrapper, the matching host Qt, and a
fresh build directory. For example, in a POSIX shell after setting
`GENYCONNECT_ANDROID_QT_ROOT`, `GENYCONNECT_HOST_QT_ROOT`, `ANDROID_SDK_ROOT` and
`ANDROID_NDK_ROOT` to the corresponding installed directories:

```sh
"${GENYCONNECT_ANDROID_QT_ROOT}/bin/qt-cmake" -S . -B build/android-arm64-ninja-debug \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug \
  -DQT_HOST_PATH="${GENYCONNECT_HOST_QT_ROOT}" \
  -DANDROID_SDK_ROOT="${ANDROID_SDK_ROOT}" \
  -DANDROID_NDK_ROOT="${ANDROID_NDK_ROOT}" \
  -DANDROID_ABI=arm64-v8a \
  -DGENYCONNECT_USE_MODULES=ON
```

Use the Qt target installation and ABI for the architecture you are building.
On Windows use the `qt-cmake.bat` wrapper with the same CMake arguments, adapting
environment-variable expansion and line continuation to your shell.

## References

- [CMake C++ module compiler and generator support](https://cmake.org/cmake/help/latest/manual/cmake-cxxmodules.7.html)
- [Qt Creator: using Ninja as a CMake generator](https://doc.qt.io/qtcreator/creator-build-settings-cmake.html#using-ninja-as-a-cmake-generator)
- [Qt for Android: building projects from the command line](https://doc.qt.io/qt-6/android-building-projects-from-commandline.html)
