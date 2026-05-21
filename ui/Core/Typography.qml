pragma Singleton
import QtQuick

QtObject {
    readonly property int       t1 : 16
    readonly property int       t2 : 14
    readonly property int       t3 : 12
    readonly property int       t4 : 10

    readonly property int       h1 : 32
    readonly property int       h2 : 24
    readonly property double    h3 : 18.72
    readonly property int       h4 : 16
    readonly property double    h5 : 13.28
    readonly property double    h6 : 10.72

    readonly property int       display1 : 96
    readonly property int       display2 : 88
    readonly property int       display3 : 72
    readonly property int       display4 : 56
    readonly property int       display5 : 40
    readonly property int       display6 : 24

    readonly property int       paragraph : 14

    // Unified naming used by shared app components
    readonly property int uiCaption: 11
    readonly property int uiBodySm: 12
    readonly property int uiBody: 13
    readonly property int uiBodyLg: 14
    readonly property int uiTitleSm: 16
    readonly property int uiTitle: 18
    readonly property int uiTitleLg: 22
    readonly property int uiHero: 30
}
