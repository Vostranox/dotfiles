pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string shots: Quickshell.env("HOME") + "/Pictures/screenshots"
    readonly property string selArea: "slurp < /dev/null"

    Timer {
        id: afterClose
        interval: 180
        property var action: null
        onTriggered: if (afterClose.action) afterClose.action()
    }
    function defer(fn) {
        ShellState.close();
        afterClose.action = fn;
        afterClose.restart();
    }

    Process { id: proc; stdinEnabled: false }
    function run(cmd) { proc.command = ["sh", "-c", cmd]; proc.running = true; }

    function path(tag) {
        return "\"" + root.shots + "/$(date +%F_%H%M%S)" + tag + ".png\"";
    }

    function shoot(sel, geom, tag) {
        root.defer(() => {
            const f = root.path(tag);
            const pick = sel ? "g=$(" + sel + ") || exit 0; " : "";
            const g = sel ? "-g \"$g\" " : (geom ? "-g \"" + geom + "\" " : "");
            root.run("mkdir -p \"" + root.shots + "\"; " + pick +
                     "f=" + f + "; grim " + g + "\"$f\" && wl-copy < \"$f\"");
        });
    }
    function record(sel, geom) {
        root.defer(() => Recorder.start(sel, geom));
    }

    Timer {
        id: afterFocus
        interval: 260
        property var action: null
        onTriggered: if (afterFocus.action) afterFocus.action()
    }

    function window(t, record) {
        root.defer(() => {
            if (!ShellState.focusToplevel(t)) return;
            afterFocus.action = () => {
                const g = root.geometryOf(t);
                if (!g) return;
                if (record) Recorder.start("", g);
                else {
                    const f = root.path("_window");
                    root.run("mkdir -p \"" + root.shots + "\"; f=" + f +
                             "; grim -g \"" + g + "\" \"$f\" && wl-copy < \"$f\"");
                }
            };
            afterFocus.restart();
        });
    }

    function geometryOf(t) {
        const o = t ? t.lastIpcObject : null;
        if (!o || !o.at || !o.size) return "";
        return o.at[0] + "," + o.at[1] + " " + o.size[0] + "x" + o.size[1];
    }
}
