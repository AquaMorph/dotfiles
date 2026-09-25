pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property color background: "#80000000"
    readonly property color popupBackground: "#e0000000"
    readonly property color primary: "#0288d1"
    readonly property color secondary: "#2980b9"
    readonly property color accent: "#b3e5fc"
    readonly property color urgent: "#e91e63"
    readonly property color foreground: "#ffffff"
    readonly property color foregroundDark: "#000000"
    readonly property color muted: "#7aa6da"
    readonly property color track: "#40000000"

    readonly property string fontFamily: "SF Pro Display, Helvetica, Arial, sans-serif"
    readonly property string iconFontFamily: "SF Pro Display, Font Awesome 6 Free"

    readonly property int barHeight: 38
    readonly property int blockHeight: 32
    readonly property int fontSize: 18
    readonly property int fontTiny: 11
    readonly property int fontCaption: 13
    readonly property int fontSmall: 14
    readonly property int fontBody: 15
    readonly property int fontDisplay: 25
    readonly property int fontClock: 30
    readonly property int moduleSpacing: 8
    readonly property int contentPadding: 10
    readonly property int activeLineWidth: 3
    readonly property int popupWidth: 320
    readonly property int popupPadding: 12
    readonly property int popupContentWidth: popupWidth - popupPadding * 2
}
