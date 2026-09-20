import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.ui

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    visible: ShellState.panel === "screenshot"

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-screenshot"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    readonly property string shots: Quickshell.env("HOME") + "/Pictures/screenshots"

    property bool recordMode: false

    function fire(scope) {
        if (scope === "window") {
            ShellState.overviewOpen(win.recordMode ? "rec" : "shot");
            return;
        }
        const sel = scope === "area" ? Capture.selArea : "";
        if (win.recordMode) Capture.record(sel, "");
        else                Capture.shoot(sel, "", "_" + scope);
    }

    KeyNav { id: nav; container: card }

    readonly property int modeCount: Recorder.active ? 0 : 2
    function navTo(i) {
        const l = nav.list();
        if (!l.length) return;
        nav.index = ((i % l.length) + l.length) % l.length;
        nav.apply(l);
    }
    function stepRow(d) {
        const l = nav.list();
        if (!l.length) return;
        const top = nav.index < win.modeCount;
        const lo = top ? 0 : win.modeCount;
        const hi = top ? win.modeCount : l.length;
        const n = hi - lo;
        win.navTo(lo + (((nav.index - lo) + d) % n + n) % n);
    }
    function otherRow() {
        const l = nav.list();
        if (win.modeCount === 0 || l.length <= win.modeCount) return;
        win.navTo(nav.index < win.modeCount ? win.modeCount : (win.recordMode ? 1 : 0));
    }



    onVisibleChanged: {
        if (!visible) return;
        keys.forceActiveFocus();
        nav.index = win.modeCount;
        nav.apply(nav.list());
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.75)
        MouseArea { anchors.fill: parent; onClicked: ShellState.close() }
    }

    FocusScope {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: (e) => {
            const ctrl = (e.modifiers & Qt.ControlModifier) !== 0;
            switch (e.key) {
            case Qt.Key_Escape: ShellState.close(); break;
            case Qt.Key_Right: win.stepRow(1);  break;
            case Qt.Key_Left:  win.stepRow(-1); break;
            case Qt.Key_Up:
            case Qt.Key_Down:  win.otherRow();  break;
            case Qt.Key_I: if (!ctrl) return; win.stepRow(1);  break;
            case Qt.Key_H: if (!ctrl) return; win.stepRow(-1); break;
            case Qt.Key_A:
            case Qt.Key_E: if (!ctrl) return; win.otherRow();  break;
            case Qt.Key_Return:
            case Qt.Key_Enter: {
                const c = nav.current();
                if (c) c.navActivate();
                break;
            }
            default: return;
            }
            e.accepted = true;
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: card.implicitWidth + Theme.pad * 3
        height: card.implicitHeight + Theme.pad * 3
        radius: Theme.radius * 1.6
        color: Theme.bg
        border.color: Recorder.active ? Theme.urgent : Theme.border
        border.width: Recorder.active ? 2 : 1

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: card
            anchors.centerIn: parent
            spacing: Theme.pad

            RowLayout {
                id: modes
                Layout.alignment: Qt.AlignHCenter
                visible: !Recorder.active
                spacing: 0

                Repeater {
                    model: [{ label: "Screenshot", rec: false }, { label: "Record", rec: true }]
                    delegate: Rectangle {
                        id: mode
                        required property var modelData
                        property bool navigable: true
                        property bool navSelected: false

                        onNavSelectedChanged: if (mode.navSelected) win.recordMode = mode.modelData.rec
                        function navActivate() { win.otherRow(); }

                        readonly property bool on: win.recordMode === mode.modelData.rec
                        implicitWidth: 130
                        implicitHeight: 32
                        radius: Theme.radius
                        color: mode.on ? Theme.surfaceHi
                             : mma.containsMouse ? Theme.surface : "transparent"
                        border.color: mode.navSelected ? Theme.accent : "transparent"
                        border.width: mode.navSelected ? 2 : 0

                        Text {
                            anchors.centerIn: parent
                            text: mode.modelData.label
                            color: mode.on ? Theme.text : Theme.textDim
                            font.family: Theme.font; font.pixelSize: Theme.fontSize
                        }
                        MouseArea {
                            id: mma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.recordMode = mode.modelData.rec
                        }
                    }
                }
            }

            RowLayout {
                id: grid
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.gap

                Repeater {
                    model: Recorder.active
                        ? [{ icon: "media-playback-stop", label: "Stop", scope: "stop" }]
                        : [{ icon: "selection-mode", label: "Area",   scope: "area" },
                           { icon: "focus-windows",  label: "Window", scope: "window" },
                           { icon: "video-display",  label: "Screen", scope: "screen" }]
                    delegate: Rectangle {
                        id: btn
                        required property var modelData

                        property bool navigable: true
                        property bool navSelected: false
                        function navActivate() {
                            if (btn.modelData.scope === "stop") { Recorder.stop(); ShellState.close(); }
                            else win.fire(btn.modelData.scope);
                        }

                        readonly property bool stop: btn.modelData.scope === "stop"
                        implicitWidth: btn.stop ? 200 : 120
                        implicitHeight: 96
                        radius: Theme.radius
                        color: btn.navSelected ? Theme.surfaceHi
                             : bma.containsMouse ? Theme.surface : Theme.bgAlt
                        border.color: btn.stop ? Theme.urgent
                                    : btn.navSelected ? Theme.accent : Theme.border
                        border.width: btn.navSelected || btn.stop ? 2 : 1
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: Theme.gap
                            SymIcon {
                                Layout.alignment: Qt.AlignHCenter
                                name: btn.modelData.icon
                                size: 30
                                color: btn.stop ? Theme.urgent
                                     : win.recordMode ? Theme.accent : Theme.text
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: btn.modelData.label
                                color: btn.stop ? Theme.urgent
                                     : btn.navSelected ? Theme.text : Theme.textDim
                                font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                            }
                        }

                        MouseArea {
                            id: bma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: { const l = nav.list(); nav.index = l.indexOf(btn); nav.apply(l); }
                            onClicked: btn.navActivate()
                        }
                    }
                }
            }
        }
    }
}
