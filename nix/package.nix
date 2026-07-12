{
  lib,
  cmake,
  ninja,
  pkg-config,
  llvmPackages,
  qt6,
  libglvnd,
  libxkbcommon,
  xray,
}:

assert lib.versionAtLeast qt6.qtbase.version "6.8";

llvmPackages.stdenv.mkDerivation {
  pname = "genyconnect";
  version = "1.4.801";

  src = lib.cleanSourceWith {
    src = ../.;
    filter = path: type:
      let
        name = baseNameOf (toString path);
      in
      !(
        lib.elem name [
          ".git"
          ".idea"
          ".qtcreator"
          "build"
        ]
        || lib.hasPrefix "cmake-build-" name
      );
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    llvmPackages.clang-tools
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtsvg
    qt6.qtwayland
    libglvnd
    libxkbcommon
  ];

  cmakeBuildType = "Release";

  cmakeFlags =
    let
      targetArch = if llvmPackages.stdenv.hostPlatform.isAarch64 then "arm64" else "x86_64";
    in
    [
      "-DBUILD_TESTING=OFF"
      "-DGENYCONNECT_AUTO_DOWNLOAD_XRAY=OFF"
      "-DGENYCONNECT_AUTO_DOWNLOAD_WINTUN=OFF"
      "-DGENYCONNECT_BUNDLED_XRAY_PATH=${lib.getExe xray}"
      "-DGENYCONNECT_LINUX_INSTALL_DEPLOY=OFF"
      "-DGENYCONNECT_LLVM_AUTO_SCAN=OFF"
      "-DGENYCONNECT_QT_AUTO_SCAN=OFF"
      "-DGENYCONNECT_TARGET_OS=linux"
      "-DGENYCONNECT_TARGET_ARCH=${targetArch}"
      "-DGENYCONNECT_TARGET_BUILD_ARCH=${targetArch}"
      "-DGENYCONNECT_USE_MODULES=ON"
      "-DCMAKE_CXX_COMPILER_CLANG_SCAN_DEPS=${llvmPackages.clang-tools}/bin/clang-scan-deps"
    ];

  postInstall = ''
    rm -f "$out/bin/xray-core"
    ln -s ${lib.getExe xray} "$out/bin/xray-core"
  '';

  meta = {
    description = "Cross-platform open-source network connection client";
    homepage = "https://github.com/genyleap/GenyConnect";
    license = lib.licenses.gpl3Plus;
    mainProgram = "GenyConnect";
    platforms = lib.platforms.linux;
  };
}
