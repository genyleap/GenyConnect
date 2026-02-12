import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import GenyConnect 1.0
import "." as Controls

Dialog {
    id: root
    property var downloadManager
    property var formatter
    property var theme
    property string defaultFolder: ""
    property string preferredQueue: ""

    modal: true
    width: 640
    height: 720
    focus: true
    title: "Add Download"

    property bool pathEdited: false
    property bool startPaused: false
    property bool advancedOpen: false
    property string pendingUrl: ""
    property string mirrorsText: ""
    property string checksumExpectedText: ""
    property bool verifyOnComplete: false
    property string headersText: ""
    property string cookieText: ""
    property string authUserText: ""
    property string authPasswordText: ""
    property string proxyHostText: ""
    property int proxyPortValue: 0
    property string proxyUserText: ""
    property string proxyPasswordText: ""
    property int retryMaxValue: -1
    property int retryDelayValue: -1
    property bool postOpenFileValue: false
    property bool postRevealValue: false
    property bool postExtractValue: false
    property string postScriptText: ""

    function decodeQueryValue(value) {
        if (!value) return ""
        return decodeURIComponent(value.replace(/\+/g, " "))
    }

    function filenameFromDisposition(value) {
        var decoded = decodeQueryValue(value)
        if (!decoded) return ""
        var match = decoded.match(/filename\*?=(?:UTF-8''|"?)([^";]+)/i)
        if (match && match.length > 1) return match[1]
        return ""
    }

    function fileNameFromUrl(url) {
        if (!url) return "download.bin"
        if (formatter && formatter.fileNameFromUrl) {
            var fromFormatter = formatter.fileNameFromUrl(url)
            if (fromFormatter && fromFormatter.length > 0) return fromFormatter
        }
        var query = ""
        var qIndex = url.indexOf("?")
        if (qIndex >= 0) query = url.substring(qIndex + 1)
        if (query.length > 0) {
            var parts = query.split("&")
            for (var i = 0; i < parts.length; ++i) {
                var part = parts[i]
                if (!part) continue
                var eq = part.indexOf("=")
                var key = eq >= 0 ? part.substring(0, eq) : part
                var val = eq >= 0 ? part.substring(eq + 1) : ""
                key = decodeQueryValue(key)
                if (key === "response-content-disposition" || key === "content-disposition" || key === "rscd") {
                    var name = filenameFromDisposition(val)
                    if (name) return name
                }
                if (key === "filename") {
                    var plain = decodeQueryValue(val)
                    if (plain) return plain
                }
            }
        }
        var clean = url.split("?")[0].split("#")[0]
        var segments = clean.split("/")
        var last = segments[segments.length - 1]
        return last.length > 0 ? last : "download.bin"
    }

    function hasFilenameHint(url) {
        if (!url) return false
        var qIndex = url.indexOf("?")
        if (qIndex < 0) return false
        var query = url.substring(qIndex + 1)
        if (!query || query.length === 0) return false
        var parts = query.split("&")
        for (var i = 0; i < parts.length; ++i) {
            var part = parts[i]
            if (!part) continue
            var eq = part.indexOf("=")
            var key = eq >= 0 ? part.substring(0, eq) : part
            key = decodeQueryValue(key)
            if (key === "filename" || key === "response-content-disposition" || key === "content-disposition" || key === "rscd") {
                return true
            }
        }
        return false
    }

    function looksLikeDownloadUrl(url) {
        if (!url) return false
        var u = url.trim()
        if (u.length === 0) return false
        if (!(u.indexOf("http://") === 0 || u.indexOf("https://") === 0)) return false
        var name = fileNameFromUrl(u)
        if (!name || name.length === 0) return false
        if (hasFilenameHint(u)) return true
        var dot = name.lastIndexOf(".")
        return dot > 0 && dot < name.length - 1
    }

    function ensurePathSuggestion() {
        var base = fileNameFromUrl(urlField.text.trim())
        var folder = defaultFolder
        var categoryName = categoryCombo.currentText
        if (categoryName === "Auto" && downloadManager && downloadManager.detectCategoryForName) {
            categoryName = downloadManager.detectCategoryForName(base)
        }
        if (downloadManager && downloadManager.categoryFolder) {
            var preferred = downloadManager.categoryFolder(categoryName)
            if (preferred && preferred.length > 0) folder = preferred
        }
        if (folder.indexOf("file://") === 0) folder = folder.substring(7)
        if (!folder || folder.length === 0) folder = "."
        if (folder[folder.length - 1] === "/") {
            pathField.text = folder + base
        } else {
            pathField.text = folder + "/" + base
        }
    }

    function openWithUrl(url) {
        var candidate = url && url.length > 0 ? url : ""
        if (!looksLikeDownloadUrl(candidate) && downloadManager && downloadManager.clipboardText) {
            var clip = downloadManager.clipboardText()
            if (looksLikeDownloadUrl(clip)) candidate = clip
        }
        pendingUrl = candidate
        open()
    }

    function refreshCombos() {
        if (!downloadManager) return
        if (!queueCombo || !categoryCombo) return
        var prevQueue = queueCombo.currentText
        var prevCategory = categoryCombo.currentText
        queueCombo.model = downloadManager.queueNames
        categoryCombo.model = downloadManager.categoryNames()
        var preferred = preferredQueue && preferredQueue.length > 0 ? preferredQueue : downloadManager.defaultQueueName()
        var idx = downloadManager.queueNames.indexOf(preferred)
        if (idx < 0) idx = downloadManager.queueNames.indexOf(prevQueue)
        queueCombo.currentIndex = idx >= 0 ? idx : 0
        var catIdx = downloadManager.categoryNames().indexOf(prevCategory)
        categoryCombo.currentIndex = catIdx >= 0 ? catIdx : 0
    }

    onOpened: {
        urlField.text = ""
        pathField.text = ""
        pathEdited = false
        newQueueField.text = ""
        startPaused = false
        advancedOpen = false
        mirrorsText = ""
        checksumExpectedText = ""
        verifyOnComplete = false
        headersText = ""
        cookieText = ""
        authUserText = ""
        authPasswordText = ""
        proxyHostText = ""
        proxyPortValue = 0
        proxyUserText = ""
        proxyPasswordText = ""
        retryMaxValue = -1
        retryDelayValue = -1
        postOpenFileValue = false
        postRevealValue = false
        postExtractValue = false
        postScriptText = ""
        refreshCombos()
        if (checksumAlgoCombo) checksumAlgoCombo.currentIndex = 0
        if (pendingUrl && pendingUrl.length > 0) {
            urlField.text = pendingUrl.trim()
            pendingUrl = ""
        } else if (downloadManager && downloadManager.clipboardText) {
            var clipUrl = downloadManager.clipboardText()
            if (looksLikeDownloadUrl(clipUrl)) {
                urlField.text = clipUrl.trim()
            }
        }
        ensurePathSuggestion()
        urlField.forceActiveFocus()
    }

    onPreferredQueueChanged: refreshCombos()

    Connections {
        target: downloadManager || null
        function onQueuesChanged() { refreshCombos() }
        function onCategoryFoldersChanged() { refreshCombos() }
    }

    FileDialog {
        id: saveDialog
        title: "Save Download"
        fileMode: FileDialog.SaveFile
        currentFolder: defaultFolder.length > 0 ? "file://" + defaultFolder : ""
        onAccepted: {
            var url = saveDialog.selectedFile.toString()
            if (url.indexOf("file://") === 0) {
                pathField.text = url.substring(7)
            } else {
                pathField.text = url
            }
            pathEdited = true
        }
    }

    contentItem: ScrollView {
        id: addScroll
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        contentItem: Flickable {
            id: addFlick
            clip: true
            contentWidth: addScroll.availableWidth
            contentHeight: formLayout.implicitHeight + 24

            ColumnLayout {
                id: formLayout
                width: addScroll.availableWidth
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 16
                spacing: 14

                GroupBox {
                    title: "Source"
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 8
                        Controls.TextField {
                            id: urlField
                            Layout.fillWidth: true
                            placeholderText: "https://example.com/file.zip"
                            onTextEdited: {
                                if (!pathEdited || pathField.text.length === 0) {
                                    ensurePathSuggestion()
                                }
                            }
                        }
                    }
                }

                GroupBox {
                    title: "Destination"
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 8
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Controls.TextField {
                                id: pathField
                                Layout.fillWidth: true
                                placeholderText: "Output file path"
                                onTextEdited: pathEdited = true
                            }
                            Controls.Button {
                                text: "Browse"
                                Layout.fillWidth: false
                                onClicked: saveDialog.open()
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Controls.Label { text: "Queue" }
                            Controls.ComboBox {
                                id: queueCombo
                                Layout.fillWidth: true
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Controls.Label { text: "New queue" }
                            Controls.TextField {
                                id: newQueueField
                                Layout.fillWidth: true
                                placeholderText: "Optional"
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Controls.Label { text: "Category" }
                            Controls.ComboBox {
                                id: categoryCombo
                                Layout.fillWidth: true
                                onActivated: {
                                    if (!pathEdited || pathField.text.length === 0) {
                                        ensurePathSuggestion()
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Controls.Label { text: "Start paused" }
                            Controls.Switch {
                                title: ""
                                checked: startPaused
                                onToggled: startPaused = checked
                            }
                        }
                    }
                }

                GroupBox {
                    title: "Advanced"
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 10
                        Controls.Button {
                            text: advancedOpen ? "Hide Advanced" : "Show Advanced"
                            Layout.fillWidth: false
                            onClicked: advancedOpen = !advancedOpen
                        }

                        ColumnLayout {
                            id: advancedSection
                            spacing: 10
                            Layout.fillWidth: true
                            Layout.preferredHeight: advancedOpen ? implicitHeight : 0
                            opacity: advancedOpen ? 1 : 0
                            visible: opacity > 0
                            Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                            Controls.Label { text: "Mirrors (one per line)" }
                            Controls.TextArea {
                                text: mirrorsText
                                placeholderText: "https://mirror1/file.zip\nhttps://mirror2/file.zip"
                                Layout.fillWidth: true
                                wrapMode: TextArea.Wrap
                                onTextChanged: mirrorsText = text
                            }

                            Controls.Label { text: "Checksum" }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Controls.ComboBox {
                                    id: checksumAlgoCombo
                                    Layout.preferredWidth: 140
                                    model: ["Auto", "MD5", "SHA1", "SHA256", "SHA512"]
                                }
                                Controls.TextField {
                                    Layout.fillWidth: true
                                    placeholderText: "Expected hash (optional)"
                                    text: checksumExpectedText
                                    onTextChanged: checksumExpectedText = text
                                }
                                Controls.Switch {
                                    title: "Verify on complete"
                                    checked: verifyOnComplete
                                    onToggled: verifyOnComplete = checked
                                }
                            }

                            Controls.Label { text: "Custom headers (one per line)" }
                            Controls.TextArea {
                                text: headersText
                                placeholderText: "Header: value"
                                Layout.fillWidth: true
                                wrapMode: TextArea.Wrap
                                onTextChanged: headersText = text
                            }

                            Controls.TextField {
                                Layout.fillWidth: true
                                placeholderText: "Cookie header"
                                text: cookieText
                                onTextChanged: cookieText = text
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Controls.TextField {
                                    Layout.fillWidth: true
                                    placeholderText: "Auth user"
                                    text: authUserText
                                    onTextChanged: authUserText = text
                                }
                                Controls.TextField {
                                    Layout.fillWidth: true
                                    placeholderText: "Auth password"
                                    echoMode: TextInput.Password
                                    text: authPasswordText
                                    onTextChanged: authPasswordText = text
                                }
                            }

                            Controls.Label { text: "Proxy" }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Controls.TextField {
                                    Layout.fillWidth: true
                                    placeholderText: "Host"
                                    text: proxyHostText
                                    onTextChanged: proxyHostText = text
                                }
                                Controls.SpinBox {
                                    from: 0
                                    to: 65535
                                    value: proxyPortValue
                                    editable: true
                                    onValueChanged: proxyPortValue = value
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Controls.TextField {
                                    Layout.fillWidth: true
                                    placeholderText: "Proxy user"
                                    text: proxyUserText
                                    onTextChanged: proxyUserText = text
                                }
                                Controls.TextField {
                                    Layout.fillWidth: true
                                    placeholderText: "Proxy password"
                                    echoMode: TextInput.Password
                                    text: proxyPasswordText
                                    onTextChanged: proxyPasswordText = text
                                }
                            }

                            Controls.Label { text: "Retry policy" }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Controls.Label { text: "Max" }
                                Controls.SpinBox {
                                    from: -1
                                    to: 20
                                    value: retryMaxValue
                                    editable: true
                                    onValueChanged: retryMaxValue = value
                                }
                                Controls.Label { text: "Delay (s)" }
                                Controls.SpinBox {
                                    from: -1
                                    to: 300
                                    value: retryDelayValue
                                    editable: true
                                    onValueChanged: retryDelayValue = value
                                }
                            }

                            Controls.Label { text: "Post actions" }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                Controls.Switch { title: "Open file"; checked: postOpenFileValue; onToggled: postOpenFileValue = checked }
                                Controls.Switch { title: "Reveal folder"; checked: postRevealValue; onToggled: postRevealValue = checked }
                                Controls.Switch { title: "Extract archive"; checked: postExtractValue; onToggled: postExtractValue = checked }
                            }
                            Controls.TextArea {
                                text: postScriptText
                                placeholderText: "Post script (use {file} and {dir})"
                                Layout.fillWidth: true
                                wrapMode: TextArea.Wrap
                                onTextChanged: postScriptText = text
                            }
                        }
                    }
                }
            }
        }
    }

    footer: DialogButtonBox {
        Controls.Button {
            text: "Cancel"
            Layout.fillWidth: false
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
        }
        Controls.Button {
            text: "Add"
            Layout.fillWidth: false
            enabled: urlField.text.trim().length > 0 && pathField.text.trim().length > 0
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
        }
        onAccepted: {
            if (!downloadManager) return
            var url = urlField.text.trim()
            var path = pathField.text.trim()
            if (path.indexOf("file://") === 0) path = path.substring(7)
            if (url.length === 0 || path.length === 0) return
            var queueName = newQueueField.text.trim().length > 0 ? newQueueField.text.trim() : queueCombo.currentText
            var categoryName = categoryCombo.currentText

            var options = {}
            var mirrors = mirrorsText.trim()
            if (mirrors.length > 0) {
                options.mirrors = mirrors.split(/\s+/)
            }
            var algo = checksumAlgoCombo.currentText
            options.checksumAlgo = algo === "Auto" ? "" : algo
            options.checksumExpected = checksumExpectedText.trim()
            options.verifyOnComplete = verifyOnComplete
            options.headers = headersText.trim()
            options.cookieHeader = cookieText.trim()
            options.authUser = authUserText.trim()
            options.authPassword = authPasswordText
            options.proxyHost = proxyHostText.trim()
            options.proxyPort = proxyPortValue
            options.proxyUser = proxyUserText.trim()
            options.proxyPassword = proxyPasswordText
            options.retryMax = retryMaxValue
            options.retryDelaySec = retryDelayValue
            options.postOpenFile = postOpenFileValue
            options.postRevealFolder = postRevealValue
            options.postExtract = postExtractValue
            options.postScript = postScriptText.trim()

            if (downloadManager.addDownloadAdvancedWithExtras) {
                downloadManager.addDownloadAdvancedWithExtras(url, path, queueName, categoryName, startPaused, options)
            } else if (downloadManager.addDownloadAdvancedWithOptions) {
                downloadManager.addDownloadAdvancedWithOptions(url, path, queueName, categoryName, startPaused)
            } else {
                downloadManager.addDownloadAdvanced(url, path, queueName, categoryName)
            }
        }
    }
}
