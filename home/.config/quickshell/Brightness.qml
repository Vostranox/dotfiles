pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool  available: false
    property real  percent: 0
    property int   rawMax: 0
    property string device: ""

    Process {
        id: query
        command: ["brightnessctl", "-c", "backlight", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim().split("\n")[0] || "";
                const f = line.split(",");
                if (f.length >= 5) {
                    root.device    = f[0];
                    root.rawMax    = parseInt(f[4]) || 0;
                    root.percent   = root.rawMax > 0 ? (parseInt(f[2]) || 0) / root.rawMax : 0;
                    root.available = root.rawMax > 0;
                } else {
                    root.available = false;
                }
            }
        }
    }

    Process { id: setter; onExited: query.running = true }

    function refresh() { query.running = true; }

    function set(v) {
        if (!root.available) return;
        const pct = Math.max(1, Math.min(100, Math.round(v * 100)));
        root.percent = pct / 100;
        setter.command = ["brightnessctl", "-c", "backlight", "set", pct + "%"];
        setter.running = true;
    }

    Component.onCompleted: query.running = true

    FileView {
        path: root.device ? "/sys/class/backlight/" + root.device + "/brightness" : ""
        watchChanges: path !== ""
        onFileChanged: query.running = true
    }
}
