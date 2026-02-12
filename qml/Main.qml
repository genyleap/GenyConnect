import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import GenyConnect 1.0

ApplicationWindow {
    id: window
    visible: true
    width: 1120
    height: 760
    minimumWidth: 820
    minimumHeight: 620
    title: "GenyConnect"

    readonly property bool compact: width < 980

    function stateLabel() {
        if (vpnController.connectionState === ConnectionState.Connecting) {
            return "Connecting"
        }
        if (vpnController.connectionState === ConnectionState.Connected) {
            return "Connected"
        }
        if (vpnController.connectionState === ConnectionState.Error) {
            return "Error"
        }
        return "Disconnected"
    }

    FileDialog {
        id: xrayDialog
        title: "Select xray-core executable"
        fileMode: FileDialog.OpenFile
        onAccepted: vpnController.setXrayExecutableFromUrl(selectedFile)
    }

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Label {
                text: "GenyConnect"
                font.bold: true
                font.pixelSize: 22
            }

            Label {
                text: stateLabel()
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Button {
                text: vpnController.connected || vpnController.busy ? "Disconnect" : "Connect"
                enabled: vpnController.connected || vpnController.busy || vpnController.currentProfileIndex >= 0
                onClicked: vpnController.toggleConnection()
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 12
        clip: true

        GridLayout {
            width: Math.max(window.width - 24, 0)
            columns: compact ? 1 : 2
            columnSpacing: 12
            rowSpacing: 12

            Pane {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    GroupBox {
                        title: "Core"
                        Layout.fillWidth: true

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8

                            Label {
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                text: vpnController.useSystemProxy
                                    ? "Global mode routes system traffic through local Xray proxy."
                                    : "Clean mode keeps system proxy disabled. Apps must use 127.0.0.1:" + vpnController.socksPort + " manually."
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                TextField {
                                    Layout.fillWidth: true
                                    text: vpnController.xrayExecutablePath
                                    placeholderText: "Select xray/xray.exe"
                                    selectByMouse: true
                                    onEditingFinished: vpnController.xrayExecutablePath = text.trim()
                                }

                                Button {
                                    text: "Browse"
                                    onClicked: xrayDialog.open()
                                }
                            }

                            CheckBox {
                                text: "Enable system proxy on connect"
                                checked: vpnController.useSystemProxy
                                enabled: !vpnController.connected && !vpnController.busy
                                onClicked: vpnController.useSystemProxy = checked
                            }

                            CheckBox {
                                text: "Disable system proxy on disconnect (safer, may ask password more often)"
                                checked: vpnController.autoDisableSystemProxyOnDisconnect
                                enabled: !vpnController.connected && !vpnController.busy
                                onClicked: vpnController.autoDisableSystemProxyOnDisconnect = checked
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                Button {
                                    text: "Disable System Proxy Now"
                                    enabled: !vpnController.connected && !vpnController.busy
                                    onClicked: vpnController.cleanSystemProxy()
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }
                    }

                    GroupBox {
                        title: "Server Profiles"
                        Layout.fillWidth: true

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8

                            ListView {
                                id: profileList
                                Layout.fillWidth: true
                                Layout.preferredHeight: compact ? 200 : 260
                                clip: true
                                spacing: 4
                                model: vpnController.profileModel
                                currentIndex: vpnController.currentProfileIndex

                                delegate: ItemDelegate {
                                    required property int index
                                    required property string displayLabel
                                    required property string address
                                    required property int port
                                    required property string security

                                    width: ListView.view.width
                                    highlighted: ListView.isCurrentItem
                                    text: displayLabel + "\n" + address + ":" + port + " | " + (security.length ? security : "none")
                                    onClicked: vpnController.currentProfileIndex = index
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                Button {
                                    text: "Connect Selected"
                                    enabled: !vpnController.connected && !vpnController.busy && vpnController.currentProfileIndex >= 0
                                    onClicked: vpnController.connectSelected()
                                }

                                Item { Layout.fillWidth: true }

                                Button {
                                    text: "Remove"
                                    enabled: vpnController.currentProfileIndex >= 0
                                    onClicked: vpnController.removeProfile(vpnController.currentProfileIndex)
                                }
                            }

                            Label {
                                visible: vpnController.connected
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                text: "Disconnect first to switch to another profile."
                            }
                        }
                    }

                    GroupBox {
                        title: "Routing Policy"
                        Layout.fillWidth: true

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8

                            CheckBox {
                                text: "Whitelist mode (only listed domains/apps use tunnel)"
                                checked: vpnController.whitelistMode
                                enabled: !vpnController.connected && !vpnController.busy
                                onClicked: vpnController.whitelistMode = checked
                            }

                            Label {
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                text: vpnController.processRoutingSupported
                                    ? "App rules are enabled (process routing supported by xray-core)."
                                    : "App rules are stored but ignored by current xray-core (requires Xray 26.1.23+)."
                            }

                            Label { text: "Tunnel Domains (one per line)" }
                            TextArea {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 70
                                wrapMode: TextArea.WrapAnywhere
                                placeholderText: "example.com or geosite:google"
                                text: vpnController.proxyDomainRules
                                enabled: !vpnController.connected && !vpnController.busy
                                onTextChanged: vpnController.proxyDomainRules = text
                            }

                            Label { text: "Direct Domains (bypass tunnel)" }
                            TextArea {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 70
                                wrapMode: TextArea.WrapAnywhere
                                placeholderText: "lan.example or domain:local"
                                text: vpnController.directDomainRules
                                enabled: !vpnController.connected && !vpnController.busy
                                onTextChanged: vpnController.directDomainRules = text
                            }

                            Label { text: "Block Domains" }
                            TextArea {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 70
                                wrapMode: TextArea.WrapAnywhere
                                placeholderText: "ads.example"
                                text: vpnController.blockDomainRules
                                enabled: !vpnController.connected && !vpnController.busy
                                onTextChanged: vpnController.blockDomainRules = text
                            }

                            Label { text: "Tunnel Apps (process names)" }
                            TextArea {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 60
                                wrapMode: TextArea.WrapAnywhere
                                placeholderText: "Telegram"
                                text: vpnController.proxyAppRules
                                enabled: !vpnController.connected && !vpnController.busy
                                onTextChanged: vpnController.proxyAppRules = text
                            }

                            Label { text: "Direct Apps (process names)" }
                            TextArea {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 60
                                wrapMode: TextArea.WrapAnywhere
                                placeholderText: "AppStore"
                                text: vpnController.directAppRules
                                enabled: !vpnController.connected && !vpnController.busy
                                onTextChanged: vpnController.directAppRules = text
                            }

                            Label { text: "Block Apps (process names)" }
                            TextArea {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 60
                                wrapMode: TextArea.WrapAnywhere
                                placeholderText: "SomeBlockedApp"
                                text: vpnController.blockAppRules
                                enabled: !vpnController.connected && !vpnController.busy
                                onTextChanged: vpnController.blockAppRules = text
                            }
                        }
                    }

                    GroupBox {
                        title: "Import Link"
                        Layout.fillWidth: true

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8

                            TextArea {
                                id: importBox
                                Layout.fillWidth: true
                                Layout.preferredHeight: 100
                                wrapMode: TextArea.WrapAnywhere
                                placeholderText: "Paste vless:// or vmess:// link"
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                Item { Layout.fillWidth: true }

                                Button {
                                    text: "Import"
                                    onClicked: {
                                        if (vpnController.importProfileLink(importBox.text.trim())) {
                                            importBox.text = ""
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Pane {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignTop

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    GroupBox {
                        title: "Connection"
                        Layout.fillWidth: true

                        GridLayout {
                            anchors.fill: parent
                            columns: compact ? 1 : 2
                            columnSpacing: 12
                            rowSpacing: 6

                            Label { text: "State" }
                            Label {
                                text: stateLabel()
                                font.bold: true
                            }

                            Label { text: "Mode" }
                            Label {
                                text: vpnController.useSystemProxy
                                    ? "System Proxy (Global, proxy-aware apps only)"
                                    : "Clean Proxy Mode (proxy-aware apps only)"
                            }

                            Label { text: "Local Proxy" }
                            Label { text: "127.0.0.1:" + vpnController.socksPort + " (mixed)" }
                        }
                    }

                    GroupBox {
                        title: "Traffic"
                        Layout.fillWidth: true

                        RowLayout {
                            anchors.fill: parent
                            spacing: 20

                            ColumnLayout {
                                Layout.fillWidth: true

                                Label { text: "Download" }
                                Label {
                                    text: vpnController.formatBytes(vpnController.rxBytes)
                                    font.bold: true
                                    font.pixelSize: 26
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true

                                Label { text: "Upload" }
                                Label {
                                    text: vpnController.formatBytes(vpnController.txBytes)
                                    font.bold: true
                                    font.pixelSize: 26
                                }
                            }
                        }
                    }

                    Label {
                        visible: vpnController.lastError.length > 0
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: vpnController.lastError
                    }

                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: "Note: Current implementation is proxy mode. Apps that ignore system/app proxy settings require a TUN mode implementation."
                    }

                    GroupBox {
                        title: "xray-core Logs"
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true

                                Item { Layout.fillWidth: true }

                                Button {
                                    text: "Copy"
                                    enabled: vpnController.recentLogs.length > 0
                                    onClicked: vpnController.copyLogsToClipboard()
                                }
                            }

                            TextArea {
                                id: logOutput
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredHeight: compact ? 240 : 360
                                readOnly: true
                                selectByMouse: true
                                wrapMode: TextArea.WrapAnywhere
                                text: vpnController.recentLogs.join("\n")
                            }
                        }
                    }
                }
            }
        }
    }
}
