import QtQuick as T
import GenyConnect 1.0

T.Text {
    font.family: FontSystem.getContentFontRegular.name
    horizontalAlignment: Text.AlignLeft
    wrapMode: Text.WordWrap
    font.pixelSize: Typography.t2
    color: Colors.textSecondary
    elide: if(AppGlobals.rtl == true) {
               Text.ElideLeft
           } else {
               Text.ElideRight
           }
}
