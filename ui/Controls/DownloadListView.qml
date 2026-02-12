import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import GenyConnect 1.0
import "." as Controls

Item {
    id: root
    property var model
    property var downloadManager
    property var formatter
    property var theme
    property double nowMs: 0
    property var openProperties
    property string queueFilter: "All Queues"
    property string statusFilter: "All"
    property string categoryFilter: "All"
    property string searchText: ""
    property string sortRole: ""
    property bool sortAscending: true
    property var onSortRequested
    property int sizeColumnWidth: 140
    property int statusColumnWidth: 140
    property int timeColumnWidth: 110
    property int speedColumnWidth: 140
    property int actionsColumnWidth: 220
    property bool compact: false
    property int headerHeight: compact ? 32 : 34
    property alias currentIndex: list.currentIndex
    property alias currentItem: list.currentItem
    readonly property int count: list.count

    readonly property color textColor: theme && theme.text ? theme.text : Colors.textPrimary
    readonly property color textMuted: theme && theme.textMuted ? theme.textMuted : Colors.textSecondary
    readonly property color borderColor: theme && theme.border ? theme.border : Colors.borderActivated

    ListView {
        id: list
        anchors.fill: parent
        spacing: 8
        clip: true
        model: root.model
        topMargin: root.headerHeight
        headerPositioning: ListView.OverlayHeader
        header: Item {
            width: list.width
            height: root.headerHeight
            Rectangle {
                anchors.fill: parent
                color: "transparent"
            }
            GridLayout {
                anchors.fill: parent
                anchors.margins: 10
                columns: 6
                columnSpacing: 12
                rowSpacing: 0
                visible: !root.compact

                Item {
                    Layout.fillWidth: true
                    Controls.Label {
                        text: root.sortRole === "fileName"
                            ? ("Name " + (root.sortAscending ? "▲" : "▼"))
                            : "Name"
                        font.pixelSize: Typography.t3
                        color: root.textMuted
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: if (root.onSortRequested) root.onSortRequested("fileName")
                    }
                }

                Item {
                    Layout.preferredWidth: root.statusColumnWidth
                    Layout.minimumWidth: root.statusColumnWidth
                    Controls.Label {
                        text: root.sortRole === "status"
                            ? ("Status " + (root.sortAscending ? "▲" : "▼"))
                            : "Status"
                        font.pixelSize: Typography.t3
                        color: root.textMuted
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: if (root.onSortRequested) root.onSortRequested("status")
                    }
                }

                Item {
                    Layout.preferredWidth: root.speedColumnWidth
                    Layout.minimumWidth: root.speedColumnWidth
                    Controls.Label {
                        text: "Speed"
                        font.pixelSize: Typography.t3
                        color: root.textMuted
                    }
                }

                Item {
                    Layout.preferredWidth: root.sizeColumnWidth
                    Layout.minimumWidth: root.sizeColumnWidth
                    Controls.Label {
                        text: root.sortRole === "bytesTotal"
                            ? ("Size " + (root.sortAscending ? "▲" : "▼"))
                            : "Size"
                        font.pixelSize: Typography.t3
                        color: root.textMuted
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: if (root.onSortRequested) root.onSortRequested("bytesTotal")
                    }
                }

                Controls.Label {
                    text: "Time Left"
                    Layout.preferredWidth: root.timeColumnWidth
                    Layout.minimumWidth: root.timeColumnWidth
                    font.pixelSize: Typography.t3
                    color: root.textMuted
                }

                Controls.Label {
                    text: "Actions"
                    Layout.preferredWidth: root.actionsColumnWidth
                    Layout.minimumWidth: root.actionsColumnWidth
                    font.pixelSize: Typography.t3
                    color: root.textMuted
                }
            }

            GridLayout {
                anchors.fill: parent
                anchors.margins: 10
                columns: 3
                columnSpacing: 12
                rowSpacing: 0
                visible: root.compact

                Item {
                    Layout.fillWidth: true
                    Controls.Label {
                        text: root.sortRole === "fileName"
                            ? ("Name " + (root.sortAscending ? "▲" : "▼"))
                            : "Name"
                        font.pixelSize: Typography.t3
                        color: root.textMuted
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: if (root.onSortRequested) root.onSortRequested("fileName")
                    }
                }

                Item {
                    Layout.preferredWidth: root.statusColumnWidth
                    Layout.minimumWidth: root.statusColumnWidth
                    Controls.Label {
                        text: root.sortRole === "status"
                            ? ("Status " + (root.sortAscending ? "▲" : "▼"))
                            : "Status"
                        font.pixelSize: Typography.t3
                        color: root.textMuted
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: if (root.onSortRequested) root.onSortRequested("status")
                    }
                }

                Controls.Label {
                    text: "Actions"
                    Layout.preferredWidth: root.actionsColumnWidth
                    Layout.minimumWidth: root.actionsColumnWidth
                    font.pixelSize: Typography.t3
                    color: root.textMuted
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: root.borderColor
            }
        }

        delegate: DownloadDelegate {
            width: list.width
            downloadManager: root.downloadManager
            formatter: root.formatter
            theme: root.theme
            nowMs: root.nowMs
            openProperties: root.openProperties
            queueFilter: root.queueFilter
            statusFilter: root.statusFilter
            categoryFilter: root.categoryFilter
            searchText: root.searchText
            sizeColumnWidth: root.sizeColumnWidth
            statusColumnWidth: root.statusColumnWidth
            timeColumnWidth: root.timeColumnWidth
            speedColumnWidth: root.speedColumnWidth
            actionsColumnWidth: root.actionsColumnWidth
            compact: root.compact
        }
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
    }
}
