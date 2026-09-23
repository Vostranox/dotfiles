import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import qs

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    visible: ShellState.panelOn("launcher", modelData)

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    property int selected: 0

    property var pathBins: []
    Process {
        id: scanPath
        command: ["sh", "-c",
            "IFS=:; for d in $PATH; do [ -d \"$d\" ] && find -L \"$d\" -maxdepth 1 -type f -executable -printf '%f\\n' 2>/dev/null; done | sort -u"]
        stdout: StdioCollector {
            onStreamFinished: win.pathBins = text.split("\n").filter(x => x.length > 0)
        }
    }

    readonly property var allApps: DesktopEntries.applications

    function subseqIndex(hay, needle) {
        let i = 0;
        for (let h = 0; h < hay.length && i < needle.length; h++)
            if (hay[h] === needle[i]) i++;
        return i === needle.length;
    }

    function tokenScore(hay, tok) {
        if (!hay) return -1;
        const i = hay.indexOf(tok);
        if (i === 0) return 0;
        if (i > 0)   return 1 + Math.min(i, 20);
        return win.subseqIndex(hay, tok) ? 60 : -1;
    }

    function matchScore(entry, tokens) {
        const n = (entry.name || "").toLowerCase();
        const b = (win.binPath(entry) || "").toLowerCase();
        const c = (entry.comment || "").toLowerCase();
        let total = 0;
        for (const t of tokens) {
            const sn = win.tokenScore(n, t);
            const sb = win.tokenScore(b, t);
            const sc = win.tokenScore(c, t);
            const best = Math.min(sn < 0 ? 9999 : sn,
                                  sb < 0 ? 9999 : sb + 5,
                                  sc < 0 ? 9999 : sc + 25);
            if (best >= 9999) return -1;
            total += best;
        }
        return total;
    }

    readonly property var results: {
        const q = input.text.trim().toLowerCase();
        const tokens = q === "" ? [] : q.split(/\s+/).filter(t => t.length > 0);
        const scored = [];
        const seen = {};
        const vals = allApps ? allApps.values : [];

        for (const a of vals) {
            if (a.noDisplay) continue;
            const bin = win.binPath(a);
            if (bin) seen[bin.split("/").pop()] = true;
            if (tokens.length === 0) { scored.push({ e: a, s: 0 }); continue; }
            const sc = win.matchScore(a, tokens);
            if (sc >= 0) scored.push({ e: a, s: sc });
        }

        if (tokens.length > 0) {
            for (const b of win.pathBins) {
                if (seen[b]) continue;
                const entry = { isBin: true, id: b, name: b, icon: "application-x-executable",
                                command: [b], execString: b, comment: "" };
                const sc = win.matchScore(entry, tokens);
                if (sc >= 0) scored.push({ e: entry, s: sc + 100 });
            }
        }

        scored.sort((x, y) => x.s !== y.s ? x.s - y.s
                                          : (x.e.name || "").localeCompare(y.e.name || ""));
        return scored.slice(0, 40).map(x => x.e);
    }

    onVisibleChanged: if (visible) { input.text = ""; selected = 0; scanPath.running = true; input.forceActiveFocus(); }
    onResultsChanged: selected = 0

    function binPath(a) {
        if (!a) return "";
        const c = a.command;
        if (c && c.length) return a.isBin ? "$PATH/" + c[0] : c[0];
        return (a.execString || "").split(" ")[0];
    }

    function iconFor(a) {
        if (!a || !a.icon) return "";
        return Quickshell.iconPath(a.icon, true);
    }

    function launch() {
        const a = results[selected];
        if (!a) return;
        const cmd = Array.from(a.command);
        Quickshell.execDetached(a.runInTerminal ? [Quickshell.env("TERMINAL") || "ghostty", "-e"].concat(cmd) : cmd);
        ShellState.close();
    }

    MouseArea { anchors.fill: parent; onClicked: ShellState.close() }

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        readonly property int topInset: ShellState.barVisible ? Theme.barHeight : 0
        y: topInset + Math.round((parent.height - topInset) * 0.18)
        Behavior on y { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuint } }
        width: 620
        readonly property int inputHeight: 42
        readonly property int rowHeight: 52
        readonly property int maxRows: Math.floor(430 / rowHeight)
        readonly property int listHeight: Math.min(maxRows * rowHeight, list.contentHeight)
        height: Theme.pad * 2 + inputHeight + Theme.gap + listHeight
        radius: Theme.radius * 1.6
        color: Theme.bg
        border.color: Theme.border
        border.width: 1

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.pad
            spacing: Theme.gap

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: card.inputHeight
                radius: Theme.radius
                color: Theme.surface

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: Theme.pad
                    anchors.rightMargin: Theme.pad
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 3
                    selectByMouse: true
                    selectionColor: Theme.accent
                    clip: true

                    Keys.onPressed: (e) => {
                        if (e.key === Qt.Key_Escape) { ShellState.close(); e.accepted = true; }
                        else if (e.key === Qt.Key_Down || (e.key === Qt.Key_N && (e.modifiers & Qt.ControlModifier))) {
                            win.selected = Math.min(win.selected + 1, win.results.length - 1);
                            list.positionViewAtIndex(win.selected, ListView.Contain); e.accepted = true;
                        } else if (e.key === Qt.Key_Up || (e.key === Qt.Key_P && (e.modifiers & Qt.ControlModifier))) {
                            win.selected = Math.max(win.selected - 1, 0);
                            list.positionViewAtIndex(win.selected, ListView.Contain); e.accepted = true;
                        } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { win.launch(); e.accepted = true; }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: input.text === ""
                        text: "Search applications"
                        color: Theme.textDim
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 3
                    }
                }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.preferredHeight: card.listHeight
                clip: true
                model: win.results
                currentIndex: win.selected
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: list.width
                    height: card.rowHeight
                    radius: Theme.radius
                    color: index === win.selected ? Theme.surface : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.pad
                        anchors.rightMargin: Theme.pad
                        spacing: Theme.pad

                        Item {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 28
                                source: win.iconFor(modelData)
                                visible: source !== ""
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                Layout.fillWidth: true
                                text: modelData.name || modelData.id
                                color: index === win.selected ? Theme.text : Theme.textDim
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize + 1
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: win.binPath(modelData)
                                color: Theme.textDim
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 3
                                elide: Text.ElideMiddle
                                visible: text !== ""
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { win.selected = index; win.launch(); }
                    }
                }
            }
        }
    }
}
