pragma Singleton
import QtQuick
import QtQuick.Window

QtObject {
    id: globals

    /* =========================
     * Core references
     * ========================= */
    property var appWindow: null
    property var appPalette: null
    property var mainRect: null

    readonly property bool hasWindow: appWindow !== null
    property bool rtl: false

    /* =========================
     * Platform detection
     * ========================= */
    readonly property string platform: Qt.platform.os

    readonly property bool isMac         : platform === "osx"
    readonly property bool isWindows     : platform === "windows"
    readonly property bool isLinux       : platform === "linux"
    readonly property bool isIOS         : platform === "ios"
    readonly property bool isAndroid     : platform === "android"
    readonly property bool isTvOS        : platform === "tvos"
    readonly property bool isVisionOS    : platform === "visionos"
    readonly property bool isQnx         : platform === "qnx"
    readonly property bool isUnix        : platform === "unix"
    readonly property bool isWasm        : platform === "wasm"


    /* =========================
     * Window state
     * ========================= */
    readonly property bool isFullscreen:
    hasWindow && appWindow.visibility === Window.FullScreen

    /* =========================
     * Window actions (cross-platform)
     * ========================= */
    function close() {
        if (hasWindow) appWindow.close()
    }

    function minimize() {
        if (hasWindow) appWindow.showMinimized()
    }

    function toggleMaximize() {
        if (!hasWindow) return

        if (isMac) {
            appWindow.visibility =
                    isFullscreen ? Window.Windowed : Window.FullScreen
        } else {
            appWindow.visibility === Window.Maximized
                    ? appWindow.showNormal()
                    : appWindow.showMaximized()
        }
    }

    function startMove() {
        if (hasWindow)
            appWindow.startSystemMove()
    }
}
