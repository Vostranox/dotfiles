pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string script: Quickshell.shellDir + "/brightness.sh"

    property bool  available: false
    property real  percent: 0
    property bool  quiet: false
    property string device: ""

    Process {
        id: query
        command: [root.script, "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(" ");
                if (f.length >= 5) {
                    root.device    = f[0];
                    root.available = true;
                    if (!hold.running) {
                        root.quiet   = f[4] === "1";
                        root.percent = parseFloat(f[1]);
                    }
                } else {
                    root.available = false;
                }
            }
        }
    }

    Process { id: setter }

    Timer { id: hold; interval: 300; onTriggered: query.running = true }

    function refresh() { if (!hold.running) query.running = true; }

    function set(v) {
        if (!root.available) return;
        root.quiet = false;
        root.percent = Math.max(0.05, Math.min(1, Math.round(v * 100) / 100));
        hold.restart();
        setter.exec([root.script, "set", String(Math.round(root.percent * 100))]);
    }

    Component.onCompleted: query.running = true

    FileView {
        path: root.device ? "/sys/class/backlight/" + root.device + "/brightness" : ""
        watchChanges: path !== ""
        onFileChanged: root.refresh()
    }
}
