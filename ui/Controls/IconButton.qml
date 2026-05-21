import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts
import GenyConnect 1.0

T.Button {
    id: control

    // New API
    property string glyph: ""
    property color accentColor: Colors.dsPrimarySolid
    property bool ghost: false
    property bool compact: false
    property bool rounded: true
    property color fillColor: Colors.dsSurface
    property color strokeColor: Colors.dsBorder
    property color glyphColor: Colors.dsText

    // Backward compatibility
    property string glyphFallback: ""
    property string setIcon: ""
    property string frontColor: Colors.dsText
    property bool isDefault: false

    hoverEnabled: true
    padding: compact ? 6 : 8
    implicitHeight: compact ? Metrics.rowHeight : Metrics.rowHeightLarge
    implicitWidth: Math.max(implicitHeight, contentItem.implicitWidth + 18)

    contentItem: RowLayout {
        spacing: 7
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

        Text {
            text: {
                if (control.glyph.length > 0) return control.glyph
                if (control.setIcon.length > 0) return control.setIcon
                return control.glyphFallback
            }
            font.family: FontSystem.getAwesomeSolid.name.length > 0
                ? FontSystem.getAwesomeSolid.name
                : FontSystem.getAwesomeRegular.name
            font.pixelSize: compact ? Typography.t3 : Typography.t2
            color: control.enabled ? control.glyphColor : Colors.dsTextSubtle
            visible: text.length > 0
        }

        Text {
            text: control.text
            font.family: FontSystem.getContentFont.name
            font.pixelSize: compact ? Typography.t3 : Typography.t2
            color: control.enabled ? (control.isDefault ? Colors.dsPrimaryText : control.frontColor) : Colors.dsTextSubtle
            visible: control.text.length > 0
        }
    }

    background: Rectangle {
        radius: rounded ? Metrics.radiusPill : Metrics.radiusSm
        color: {
            if (control.ghost) return "transparent"
            if (control.isDefault) {
                return control.down ? Colors.dsPrimaryPressed : Colors.dsPrimarySolid
            }
            return control.down ? Colors.dsSurfaceElevated : control.fillColor
        }
        border.color: control.isDefault
                      ? Colors.dsPrimarySolid
                      : (control.hovered ? control.accentColor : control.strokeColor)
        border.width: ghost ? 0 : 1
    }
}
