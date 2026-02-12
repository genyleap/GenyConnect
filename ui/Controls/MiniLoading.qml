import QtQuick 2.14
import QtQuick.Layouts 1.14

Rectangle {

    id: loadingBox

    property int setWidth: 42
    property int setHeight: 42
    property int setDuration: 500
    property bool running: false

    Layout.maximumWidth: setWidth
    Layout.maximumHeight: setHeight

    implicitWidth: setWidth
    implicitHeight: setHeight

    visible: running

    width: setWidth
    height: setHeight
    radius: setWidth / 2
    color: appStyle.primary

    ScaleAnimator {
        id: animatorOneBack
        target: loadingBox
        from: 0.5
        to: 1
        duration: setDuration
        running: true

        onStopped: {
            animatorTwoBack.start()
        }
    }

    ScaleAnimator {
        id: animatorTwoBack
        target: loadingBox
        from: 1
        to: 0.5
        duration: setDuration
        running: false

        onStarted: {
            animatorTwoBack.start()
        }

        onStopped: {
            animatorOneBack.start()
        }
    }

    Rectangle {
        id: secondBox
        width: setWidth
        height: setHeight
        radius: setWidth / 2
        color: appStyle.backgroundActivated
        opacity: 0.6

        ScaleAnimator {
            id: animatorOne
            target: secondBox
            from: 0.5
            to: 1
            duration: setDuration
            running: true

            onStopped: {
                animatorTwo.start()
            }
        }

        ScaleAnimator {
            id: animatorTwo
            target: secondBox
            from: 1
            to: 0.5
            duration: setDuration
            running: false

            onStarted: {
                animatorTwo.start()
            }

            onStopped: {
                animatorOne.start()
            }
        }

        Behavior on opacity {
            OpacityAnimator {
                duration: 1250
            }
        }
    }
}
