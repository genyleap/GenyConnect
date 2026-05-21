import QtQuick
import QtQuick.Layouts
import GenyConnect 1.0

Item {
    id: root

    property bool compact: false
    property string title: ""
    property bool showBack: true
    property bool showTrailing: false
    property string trailingGlyph: ""
    property bool useFlickable: true
    property real contentBottomPadding: 0

    signal backClicked()
    signal trailingClicked()

    default property alias content: contentColumn.data
    property alias flickable: pageFlick

    Rectangle {
        anchors.fill: parent
        color: Colors.dsWindow
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: compact ? Metrics.pagePaddingMobile : Metrics.pagePaddingDesktop
        spacing: Metrics.gap12

        AppHeader {
            Layout.fillWidth: true
            compact: root.compact
            title: root.title
            showBack: root.showBack
            showTrailing: root.showTrailing
            trailingGlyph: root.trailingGlyph
            onBackClicked: root.backClicked()
            onTrailingClicked: root.trailingClicked()
        }

        Flickable {
            id: pageFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: contentColumn.implicitHeight + root.contentBottomPadding
            boundsBehavior: Flickable.DragAndOvershootBounds
            flickableDirection: Flickable.VerticalFlick
            interactive: root.useFlickable

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: function(event) {
                    pageFlick.contentY = Math.max(
                        0,
                        Math.min(pageFlick.contentHeight - pageFlick.height,
                                 pageFlick.contentY - event.angleDelta.y * 0.35))
                    event.accepted = true
                }
            }

            ColumnLayout {
                id: contentColumn
                width: pageFlick.width
                spacing: Metrics.gap12
            }
        }
    }
}
