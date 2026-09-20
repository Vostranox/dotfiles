pragma Singleton
import QtQuick
import Quickshell
Singleton {
    readonly property color bg:        "#181818"
    readonly property color bgAlt:     "#141414"
    readonly property color surface:   "#282828"
    readonly property color surfaceHi: "#353a39"
    readonly property color text:      "#c8c8d5"
    readonly property color textDim:   "#8a8a95"
    readonly property color accent:    "#95a99f"
    readonly property color accent2:   "#96a6c8"
    readonly property color urgent:    "#e45457"
    readonly property color warn:      "#e5a458"
    readonly property color border:    "#3e3b3c"

    readonly property string font:     "JetBrainsMono Nerd Font"

    readonly property int fontSize:    13
    readonly property int barHeight:   34
    readonly property int radius:      8
    readonly property int pad:         14
    readonly property int gap:         8

    readonly property int animFast:    120
    readonly property int animNormal:  200
}
