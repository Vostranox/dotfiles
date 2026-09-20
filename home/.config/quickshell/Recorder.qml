pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/Videos/captures"
    readonly property bool active: proc.running
    property string lastFile: ""

    function start(selector, geom) {
        if (proc.running) return;
        root.lastFile = root.dir + "/" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HHmmss") + ".mp4";
        const pick = selector ? "g=$(" + selector + ") || exit 0; " : "";
        const g = selector ? "-g \"$g\" " : (geom ? "-g \"" + geom + "\" " : "");
        proc.command = ["sh", "-c",
            "mkdir -p \"" + root.dir + "\"; " + pick +
            "exec wf-recorder -p color_range=tv -p colorspace=bt709" +
            " -p color_primaries=bt709 -p color_trc=bt709 " + g +
            "-f \"" + root.lastFile + "\""];
        proc.running = true;
    }

    function stop() { if (proc.running) proc.signal(2); }

    Process { id: proc; stdinEnabled: false }
}
