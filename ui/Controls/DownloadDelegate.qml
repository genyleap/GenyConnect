import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import GenyConnect 1.0
import "." as Controls

Item {
    id: row
    property var downloadManager
    property var formatter
    property var theme
    property double nowMs: 0
    property var openProperties
    property string queueFilter: "All Queues"
    property string statusFilter: "All"
    property string categoryFilter: "All"
    property string searchText: ""
    property int rowIndex: index
    property bool selected: ListView.isCurrentItem
    property int sizeColumnWidth: 140
    property int statusColumnWidth: 140
    property int timeColumnWidth: 110
    property int speedColumnWidth: 140
    property int actionsColumnWidth: 80
    property bool compact: false

    readonly property color textColor: theme && theme.text ? theme.text : Colors.textPrimary
    readonly property color textMuted: theme && theme.textMuted ? theme.textMuted : Colors.textSecondary
    readonly property color borderColor: theme && theme.border ? theme.border : Colors.borderActivated
    readonly property color panelColor: theme && theme.panel ? theme.panel : Colors.backgroundActivated
    readonly property color panelSoft: theme && theme.panelSoft ? theme.panelSoft : Colors.backgroundItemActivated
    readonly property color accentColor: theme && theme.accent ? theme.accent : Colors.secondry
    readonly property color successColor: theme && theme.success ? theme.success : Colors.success
    readonly property color warningColor: theme && theme.warning ? theme.warning : Colors.warning
    readonly property color dangerColor: theme && theme.danger ? theme.danger : Colors.error

    readonly property real safeBytesReceived: isFinite(bytesReceived) ? bytesReceived : 0
    readonly property real safeBytesTotal: isFinite(bytesTotal) ? bytesTotal : 0
    readonly property bool hasTotal: safeBytesTotal > 0
    readonly property real progressValue: {
        var p = Number(progress)
        if (isFinite(p) && p > 0) {
            if (p > 1.0) p = p / 100.0
            return Math.max(0, Math.min(1, p))
        }
        if (hasTotal) return Math.max(0, Math.min(1, safeBytesReceived / safeBytesTotal))
        if (task && task.stateString === "Done") return 1
        return 0
    }
    readonly property int progressPercent: Math.round(progressValue * 100)
    readonly property bool isActive: !!(task && (task.stateString === "Active" || task.stateString === "Downloading"))
    readonly property bool showProgressBar: hasTotal || safeBytesReceived > 0 || isActive
    readonly property bool showPercent: hasTotal
    readonly property string progressLabel: {
        if (isActive && showPercent) return progressPercent + "%"
        if (isActive) return "Downloading"
        return statusLabel
    }
    readonly property int statusVisualWidth: compact ? 120 : 140
    readonly property int statusVisualHeight: 20

    readonly property string sizeText: formatter
        ? (hasTotal
            ? formatter.bytes(safeBytesReceived) + " / " + formatter.bytes(safeBytesTotal)
            : formatter.bytes(safeBytesReceived))
        : ""

    readonly property string sizeTotalText: formatter && hasTotal
        ? formatter.bytes(safeBytesTotal)
        : "-"

    readonly property string sizeReceivedText: formatter && hasTotal
        ? ("Received " + formatter.bytes(safeBytesReceived))
        : ""

    readonly property string speedText: {
        if (!formatter || !task) return "-"
        if (task.stateString === "Active") return formatter.speed(task.speed)
        if (task.lastSpeed > 0) return "Last " + formatter.speed(task.lastSpeed)
        return "-"
    }

    readonly property string etaText: {
        if (!formatter || !task) return "-"
        if (task.stateString === "Paused") {
            if (task.pausedAt > 0 && nowMs > 0) {
                var diffSec = Math.floor(Math.max(0, nowMs - task.pausedAt) / 1000)
                return "Paused " + formatter.eta(diffSec)
            }
            return "Paused"
        }
        return formatter.eta(task.eta)
    }

    readonly property string progressInfoText: {
        if (!formatter) return "-"
        if (hasTotal) return formatter.bytes(safeBytesReceived) + " / " + formatter.bytes(safeBytesTotal)
        if (safeBytesReceived > 0) return formatter.bytes(safeBytesReceived)
        return "-"
    }

    readonly property string statusLabel: {
        if (!task) return status && status.length > 0 ? status : "Unknown"
        if (task.stateString === "Paused" && task.pauseReason && task.pauseReason !== "User") {
            return "Paused (" + task.pauseReason + ")"
        }
        if (task.stateString === "Queued") return "Waiting"
        if (task.stateString === "Done") return "Complete"
        return task.stateString
    }

    readonly property color progressFill: {
        if (!task) return accentColor
        if (task.stateString === "Done") return successColor
        if (task.stateString === "Error") return dangerColor
        if (task.stateString === "Paused") return warningColor
        return accentColor
    }
    readonly property color progressTrack: Qt.rgba(progressFill.r, progressFill.g, progressFill.b, 0.18)
    readonly property color progressGlow: Qt.rgba(progressFill.r, progressFill.g, progressFill.b, 0.35)

    component StatusProgress: Item {
        id: bar
        property real value: 0
        property string text: ""
        property color fillColor: accentColor
        property color trackColor: panelSoft
        property color textColor: Colors.textPrimary
        implicitWidth: statusVisualWidth
        implicitHeight: statusVisualHeight

        Rectangle {
            id: track
            anchors.fill: parent
            radius: height / 2
            color: trackColor
            border.color: Qt.rgba(fillColor.r, fillColor.g, fillColor.b, 0.25)
            border.width: 1
        }

        Rectangle {
            id: fillRect
            height: parent.height
            width: Math.max(height, Math.min(parent.width, parent.width * Math.max(0, Math.min(1, value))))
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.lighter(fillColor, 1.15) }
                GradientStop { position: 1.0; color: fillColor }
            }
            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: "transparent"
            border.color: Qt.rgba(fillColor.r, fillColor.g, fillColor.b, 0.12)
            border.width: 1
        }

        Controls.Label {
            anchors.centerIn: parent
            text: bar.text
            font.pixelSize: Typography.t4
            color: textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    readonly property color pillBorderColor: {
        var c = stateColor(task ? task.stateString : status)
        return Qt.rgba(c.r, c.g, c.b, 0.35)
    }

    readonly property color pillFillColor: {
        var c = stateColor(task ? task.stateString : status)
        return Qt.rgba(c.r, c.g, c.b, 0.14)
    }

    readonly property string compactMetaText: {
        var parts = []
        if (speedText.length > 0 && speedText !== "-") parts.push(speedText)
        if (sizeText.length > 0 && sizeText !== "-") parts.push(sizeText)
        if (etaText.length > 0 && etaText !== "-") parts.push(etaText)
        return parts.join(" • ")
    }

    implicitHeight: compact ? 94 : 80

    function matchesFilters() {
        var queueValue = (queueName !== undefined && queueName !== null) ? String(queueName) : ""
        var categoryValue = (category !== undefined && category !== null) ? String(category) : ""
        var passQueue = queueFilter === "All Queues" || queueValue.length === 0 || queueValue === queueFilter
        var state = status || (task ? task.stateString : "")
        var passStatus = true
        if (statusFilter === "All") passStatus = true
        else if (statusFilter === "Unfinished") passStatus = (state !== "Done" && state !== "Canceled" && state !== "Error")
        else if (statusFilter === "History") passStatus = (state === "Done" || state === "Canceled" || state === "Error")
        else passStatus = !state || state.length === 0 ? true : (state === statusFilter)
        var passCategory = categoryFilter === "All" || categoryValue.length === 0 || categoryValue === categoryFilter
        var base = formatter ? formatter.baseName(fileName) : fileName
        var query = searchText.trim().toLowerCase()
        var passSearch = query.length === 0
            || (base && base.toLowerCase().indexOf(query) !== -1)
            || (task && task.url && task.url().toLowerCase().indexOf(query) !== -1)
        return passQueue && passStatus && passCategory && passSearch
    }

    function displayName() {
        var base = formatter ? formatter.baseName(fileName) : fileName
        if (task && formatter && formatter.fileNameFromUrl) {
            var maybe = formatter.fileNameFromUrl(task.url())
            if (maybe && maybe.length > 0) {
                var isGuid = base.length >= 32 && base.indexOf(".") === -1
                if (isGuid) return maybe
            }
        }
        return base
    }

    function stateColor(state) {
        if (state === "Active") return accentColor
        if (state === "Queued") return accentColor
        if (state === "Paused") return warningColor
        if (state === "Done") return successColor
        if (state === "Error") return dangerColor
        if (state === "Canceled") return textMuted
        return textMuted
    }

    visible: matchesFilters()
    height: visible ? implicitHeight : 0

    Rectangle {
        anchors.fill: parent
        radius: Colors.radius
        color: selected ? panelSoft : panelColor
        border.color: selected ? accentColor : borderColor
    }

    GridLayout {
        id: fullLayout
        visible: !compact
        anchors.fill: parent
        anchors.margins: 10
        columns: 6
        columnSpacing: 12
        rowSpacing: 0

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Controls.Label {
                text: displayName()
                font.pixelSize: Typography.t3
                color: textColor
                elide: Text.ElideRight
            }
            Controls.Label {
                text: fileName
                font.pixelSize: Typography.t4
                color: textMuted
                elide: Text.ElideMiddle
            }
        }

        ColumnLayout {
            Layout.preferredWidth: statusColumnWidth
            Layout.minimumWidth: statusColumnWidth
            spacing: 4
            Item {
                Layout.fillWidth: true
                height: statusVisualHeight
                StatusProgress {
                    width: statusVisualWidth
                    height: statusVisualHeight
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    value: showProgressBar ? progressValue : 0
                    text: progressLabel
                    fillColor: progressFill
                    trackColor: progressTrack
                    textColor: row.textColor
                }
            }
            Controls.Label {
                text: progressInfoText
                font.pixelSize: Typography.t4
                color: textMuted
                elide: Text.ElideRight
                visible: showProgressBar
            }
        }

        ColumnLayout {
            Layout.preferredWidth: speedColumnWidth
            Layout.minimumWidth: speedColumnWidth
            spacing: 4
            Controls.Label {
                text: speedText
                font.pixelSize: Typography.t3
                color: textColor
            }
            Controls.Label {
                text: task ? ("Segments " + task.segments()) : ""
                font.pixelSize: Typography.t4
                color: textMuted
                visible: !!task
            }
        }

        ColumnLayout {
            Layout.preferredWidth: sizeColumnWidth
            Layout.minimumWidth: sizeColumnWidth
            spacing: 4
            Controls.Label {
                text: sizeTotalText
                font.pixelSize: Typography.t3
                color: textColor
            }
            Controls.Label {
                text: sizeReceivedText
                font.pixelSize: Typography.t4
                color: textMuted
                visible: formatter && hasTotal
            }
        }

        ColumnLayout {
            Layout.preferredWidth: timeColumnWidth
            Layout.minimumWidth: timeColumnWidth
            spacing: 4
            Controls.Label {
                text: etaText
                font.pixelSize: Typography.t3
                color: textColor
            }
            Controls.Label {
                text: task && task.stateString === "Done" ? "Finished" : ""
                font.pixelSize: Typography.t4
                color: textMuted
                visible: !!task && task.stateString === "Done"
            }
        }

        RowLayout {
            Layout.preferredWidth: actionsColumnWidth
            Layout.minimumWidth: actionsColumnWidth
            spacing: 6
            Controls.IconButton {
                id: rowMenuButton
                compact: true
                text: ""
                glyph: "\uf142"
                glyphFallback: "..."
                enabled: true
                onClicked: {
                    if (!contextMenu) return
                    var p = rowMenuButton.mapToItem(contextMenu.parent, rowMenuButton.width / 2, rowMenuButton.height)
                    contextMenu.x = p.x
                    contextMenu.y = p.y
                    contextMenu.open()
                }
            }
        }
    }

    GridLayout {
        id: compactLayout
        visible: compact
        anchors.fill: parent
        anchors.margins: 10
        columns: 3
        columnSpacing: 12
        rowSpacing: 6

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Controls.Label {
                text: displayName()
                font.pixelSize: Typography.t3
                color: textColor
                elide: Text.ElideRight
            }
            Controls.Label {
                text: fileName
                font.pixelSize: Typography.t4
                color: textMuted
                elide: Text.ElideMiddle
            }
            Item {
                Layout.fillWidth: true
                height: statusVisualHeight
                StatusProgress {
                    width: statusVisualWidth
                    height: statusVisualHeight
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    value: showProgressBar ? progressValue : 0
                    text: progressLabel
                    fillColor: progressFill
                    trackColor: progressTrack
                    textColor: row.textColor
                }
            }
            Controls.Label {
                text: compactMetaText.length > 0 ? compactMetaText : "-"
                font.pixelSize: Typography.t4
                color: textMuted
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            Layout.preferredWidth: statusColumnWidth
            Layout.minimumWidth: statusColumnWidth
            spacing: 4
            Item {
                Layout.fillWidth: true
                height: statusVisualHeight
                Rectangle {
                    width: statusVisualWidth
                    height: statusVisualHeight
                    radius: statusVisualHeight / 2
                    color: pillFillColor
                    border.color: pillBorderColor
                    border.width: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    Controls.Label {
                        anchors.centerIn: parent
                        text: statusLabel
                        font.pixelSize: Typography.t4
                        color: stateColor(task ? task.stateString : status)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }
            }
        }

        RowLayout {
            Layout.preferredWidth: actionsColumnWidth
            Layout.minimumWidth: actionsColumnWidth
            spacing: 6
            Controls.IconButton {
                id: compactMenuButton
                compact: true
                text: ""
                glyph: "\uf142"
                glyphFallback: "..."
                enabled: true
                onClicked: {
                    if (!contextMenu) return
                    var p = compactMenuButton.mapToItem(contextMenu.parent, compactMenuButton.width / 2, compactMenuButton.height)
                    contextMenu.x = p.x
                    contextMenu.y = p.y
                    contextMenu.open()
                }
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.ReleaseWithinBounds
        grabPermissions: PointerHandler.TakeOverForbidden
        onTapped: {
            if (tapCount >= 2) {
                if (downloadManager && task && task.stateString === "Done" && downloadManager.fileExists(rowIndex)) {
                    downloadManager.openFile(rowIndex)
                }
            } else {
                if (ListView.view) ListView.view.currentIndex = rowIndex
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                if (contextMenu) {
                    var p = row.mapToItem(contextMenu.parent, mouse.x, mouse.y)
                    contextMenu.x = p.x
                    contextMenu.y = p.y
                    contextMenu.open()
                }
            }
        }
    }

    Menu {
        id: contextMenu
        parent: row
        MenuItem {
            text: task && task.stateString === "Active" ? "Pause" : "Resume"
            enabled: !!(task && (task.stateString === "Active" || task.stateString === "Paused"))
            onTriggered: {
                if (!downloadManager || !task) return
                if (task.stateString === "Active") downloadManager.pauseTask(rowIndex)
                else downloadManager.resumeTask(rowIndex)
            }
        }
        MenuItem {
            text: "Retry"
            enabled: !!(task && task.stateString === "Error")
            onTriggered: if (task) task.restart()
        }
        MenuItem {
            text: "Stop"
            enabled: !!(task && task.stateString !== "Done" && task.stateString !== "Canceled")
            onTriggered: if (task) task.cancel()
        }
        MenuSeparator {}
        MenuItem {
            text: "Open"
            enabled: !!(downloadManager && task && task.stateString === "Done" && downloadManager.fileExists(rowIndex))
            onTriggered: if (downloadManager) downloadManager.openFile(rowIndex)
        }
        MenuItem {
            text: "Show in Folder"
            enabled: !!(downloadManager && task)
            onTriggered: if (downloadManager) downloadManager.revealInFolder(rowIndex)
        }
        MenuSeparator {}
        MenuItem {
            text: "Copy URL"
            enabled: !!(downloadManager && task)
            onTriggered: if (downloadManager && task) downloadManager.copyText(task.url())
        }
        MenuItem {
            text: "Copy Path"
            enabled: !!(downloadManager && task)
            onTriggered: if (downloadManager && task) downloadManager.copyText(task.fileName())
        }
        MenuSeparator {}
        MenuItem {
            text: "Properties"
            enabled: !!(openProperties && task)
            onTriggered: if (openProperties && task) openProperties(task, bytesReceived, bytesTotal, queueName, category, rowIndex)
        }
        MenuItem {
            text: "Verify Checksum"
            enabled: !!(downloadManager && task)
            onTriggered: if (downloadManager) downloadManager.verifyTask(rowIndex)
        }
        MenuItem {
            text: "Remove"
            enabled: !!downloadManager
            onTriggered: if (downloadManager) downloadManager.removeDownload(rowIndex)
        }
    }
}
