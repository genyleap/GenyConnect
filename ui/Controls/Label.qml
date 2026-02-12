import QtQuick
import GenyConnect 1.0

Text {
    property bool isBold : false
    font.family: FontSystem.getContentFont.name
    font.pixelSize: isBold ? Typography.t1 : Typography.t2
    font.weight: isBold ? Font.Bold : Font.Normal
    color: enabled ? Colors.textPrimary : Colors.textSecondary
}
