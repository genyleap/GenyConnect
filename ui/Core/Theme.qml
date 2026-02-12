pragma Singleton
import QtQuick

QtObject {
    enum Mode { Light, Dark }
    property int mode: Theme.Dark
}
