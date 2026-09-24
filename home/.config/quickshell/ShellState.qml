pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property bool   osdVisible: false
    property real   osdValue: 0
    property string osdIcon: ""
    property bool   osdMuted: false

    function osd(icon, value, muted) {
        root.osdIcon    = icon;
        root.osdValue   = value;
        root.osdMuted   = muted === true;
        root.osdVisible = true;
        osdTimer.restart();
    }
    Timer { id: osdTimer; interval: 1600; onTriggered: root.osdVisible = false }

    property string tipText: ""
    property real   tipX: 0
    property bool   tipVisible: false
    property string tipScreen: ""

    function showTip(txt, x, screen) { root.tipText = txt; root.tipX = x; root.tipScreen = screen || ""; root.tipVisible = true; }
    function hideTip()               { root.tipVisible = false; }

    property bool barVisible: true
    property alias keepAwake: persist.keepAwake
    function toggleBar() { root.barVisible = !root.barVisible; }

    PersistentProperties {
        id: persist
        reloadableId: "shellState"
        property bool keepAwake: false
    }

    property bool dockAutoHide: Theme.dockAutoHide
    function toggleDockAutoHide() { root.dockAutoHide = !root.dockAutoHide; }

    property string panel: ""
    property string controlPage: ""

    readonly property string focusedScreen: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    property string panelScreen: ""
    function onScreen(name, screen) { return name === "" || name === screen.name; }
    function panelOn(name, screen)  { return root.panel === name && root.onScreen(root.panelScreen, screen); }
    function show(name, screen) {
        root.panelScreen = screen || (root.panel !== "" ? root.panelScreen : root.focusedScreen);
        root.panel = name;
    }

    function toggle(name, screen) {
        if (root.panel === name && (!screen || screen === root.panelScreen)) { root.panel = ""; return; }
        root.show(name, screen);
        if (name === "control") root.controlPage = "";
    }
    function openControlPage(page, screen) {
        root.show("control", screen);
        root.controlPage = page;
    }
    function open(name, screen) { root.show(name, screen); }
    function close()            { root.panel = ""; }

    readonly property var overviewApps: {
        const out = root.liveToplevels();
        out.sort((a, b) => {
            const oa = a.lastIpcObject || {}, ob = b.lastIpcObject || {};
            const wa = oa.workspace ? oa.workspace.id : 0, wb = ob.workspace ? ob.workspace.id : 0;
            if (wa !== wb) return wa - wb;
            const pa = oa.at || [0, 0], pb = ob.at || [0, 0];
            return pa[0] !== pb[0] ? pa[0] - pb[0] : pa[1] - pb[1];
        });
        return out;
    }

    property string overviewMode: "focus"

    signal stepOverview(int d)
    signal activateOverview()

    property bool gesturesSwapped: false
    onPanelChanged: {
        const want = root.panel === "overview";
        if (want === root.gesturesSwapped) return;
        root.gesturesSwapped = want;
        Hyprland.dispatch("overviewGestures(" + (want ? "true" : "false") + ")");
    }

    function overviewOpen(mode) {
        Hyprland.refreshToplevels();
        root.overviewMode = mode || "focus";
        root.show("overview");
    }

    function overviewPick(t) {
        const mode = root.overviewMode;
        root.overviewMode = "focus";
        if (mode === "shot")      Capture.window(t, false);
        else if (mode === "rec")  Capture.window(t, true);
        else                      root.overviewFocus(t);
    }

    function focusToplevel(t, keepCursor) {
        if (!t) return false;
        const o = t.lastIpcObject;
        if (!o || o.mapped !== true) return false;
        const steps = [];
        if (o.workspace && o.workspace.id !== undefined)
            steps.push("hl.dsp.focus({ workspace = " + o.workspace.id + " })");
        steps.push("hl.dsp.focus({ window = \"address:0x" + t.address + "\" })");
        if (!keepCursor) {
            for (const s of steps) Hyprland.dispatch(s);
            return true;
        }
        Hyprland.dispatch("(function() local p = hl.get_cursor_pos(); "
            + steps.map(s => "hl.dispatch(" + s + "); ").join("")
            + "hl.dispatch(hl.dsp.cursor.move({ x = p.x, y = p.y })); return hl.dsp.no_op() end)()");
        return true;
    }

    function overviewFocus(t) {
        root.panel = "";
        root.focusToplevel(t);
    }

    property bool   switcherOpen: false
    property var    switcherApps: []
    property int    switcherIndex: 0
    property string switcherScreen: ""

    function liveToplevels() {
        const vals = Hyprland.toplevels ? Hyprland.toplevels.values : [];
        const out = [];
        for (const t of vals) {
            if (!t) continue;
            const o = t.lastIpcObject;
            if (!o) continue;
            if (o.mapped !== true) continue;
            if (!t.wayland) continue;
            out.push(t);
        }
        return out;
    }

    Timer {
        id: toplevelSettle
        interval: 400
        repeat: true
        triggeredOnStart: false
        property int tries: 0
        onRunningChanged: if (running) tries = 0
        onTriggered: {
            Hyprland.refreshToplevels();
            if (++tries >= 4) running = false;
        }
    }
    property var mru: []

    function noteFocus(t) {
        if (!t || !t.address) return;
        const a = t.address;
        const l = [a];
        for (const x of root.mru) if (x !== a) l.push(x);
        root.mru = l;
    }

    Instantiator {
        model: Hyprland.toplevels

        onObjectAdded: toplevelSettle.restart()

        delegate: Connections {
            required property var modelData
            target: modelData
            function onActivatedChanged() {
                if (modelData && modelData.activated) root.noteFocus(modelData);
            }
        }
    }

    function switchOpen() {
        Hyprland.refreshToplevels();

        const live = root.liveToplevels();
        const byAddr = {};
        for (const t of live) byAddr[t.address] = t;

        const out = [];
        for (const a of root.mru) {
            if (byAddr[a]) { out.push(byAddr[a]); delete byAddr[a]; }
        }
        const rest = [];
        for (const a in byAddr) rest.push(byAddr[a]);
        rest.sort((x, y) => {
            const fx = x.lastIpcObject ? x.lastIpcObject.focusHistoryID : 999;
            const fy = y.lastIpcObject ? y.lastIpcObject.focusHistoryID : 999;
            return fx - fy;
        });

        root.switcherApps = out.concat(rest);
        root.switcherIndex = root.switcherApps.length > 1 ? 1 : 0;
        root.switcherScreen = root.focusedScreen;
        root.switcherOpen = root.switcherApps.length > 0;
    }

    function switchStep(delta) {
        if (!root.switcherOpen) {
            root.switchOpen();
            if (delta > 0) return;
            root.switcherIndex = 0;
        }
        const n = root.switcherApps.length;
        if (n === 0) return;
        root.switcherIndex = ((root.switcherIndex + delta) % n + n) % n;
    }

    function switchCommit() {
        if (!root.switcherOpen) return;

        const t = root.switcherApps[root.switcherIndex];
        root.switcherOpen = false;
        if (!t) return;
        const o = t.lastIpcObject;
        if (!o || o.mapped !== true) return;
        if (o && o.workspace && o.workspace.id !== undefined)
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + o.workspace.id + " })");
        Hyprland.dispatch("hl.dsp.focus({ window = \"address:0x" + t.address + "\" })");
    }

    function switchCancel() { root.switcherOpen = false; root.switcherApps = []; }
}
