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

    readonly property real scrollSpeed: 2.5     // touchpad scrolling in the launcher and app grid

    readonly property real dockScale:    0.9    // 1.0 = 40px icons; spacing and previews follow
    readonly property bool dockAutoHide: true   // false: always shown, windows keep clear of it like the bar
    readonly property real dockTrigger:  0.5    // share of the bottom edge, centred, that reveals it
    readonly property bool dockRunning:  true   // also show running apps that aren't pinned

    readonly property int dockIcon:    Math.round(40 * dockScale)
    readonly property int dockPad:     Math.round(4 * dockScale)
    readonly property int dockSpacing: Math.round(8 * dockScale)
    readonly property int dockInset:   Math.round(6 * dockScale)
    readonly property int dockSlot:    dockIcon + dockPad * 2
    readonly property int dockPitch:   dockSlot + dockSpacing
    readonly property int dockBodyH:   dockInset + dockSlot + Math.round(10 * dockScale)
    readonly property int dockEdge:    Math.round(gap * dockScale)
    readonly property int dockSide:    Math.max(0, dockInset - dockSpacing / 2)
    readonly property int dockRadius:  Math.round(radius * 2 * dockScale)

    readonly property int animFast:    120
    readonly property int animNormal:  200
}
