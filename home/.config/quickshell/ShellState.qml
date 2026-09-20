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

    function showTip(txt, x) { root.tipText = txt; root.tipX = x; root.tipVisible = true; }
    function hideTip()       { root.tipVisible = false; }

    property bool barVisible: true
    property bool keepAwake: false
    function toggleBar() { root.barVisible = !root.barVisible; }

    property string panel: ""
    property string controlPage: ""

    function toggle(name) {
        if (root.panel === name) { root.panel = ""; return; }
        root.panel = name;
        if (name === "control") root.controlPage = "";
    }
    function openControlPage(page) {
        root.controlPage = page;
        root.panel = "control";
    }
    function open(name)   { root.panel = name; }
    function close()      { root.panel = ""; }

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
        root.panel = "overview";
    }

    function overviewPick(t) {
        const mode = root.overviewMode;
        root.overviewMode = "focus";
        if (mode === "shot")      Capture.window(t, false);
        else if (mode === "rec")  Capture.window(t, true);
        else                      root.overviewFocus(t);
    }

    function focusToplevel(t) {
        if (!t) return false;
        const o = t.lastIpcObject;
        if (!o || o.mapped !== true) return false;
        if (o.workspace && o.workspace.id !== undefined)
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + o.workspace.id + " })");
        Hyprland.dispatch("hl.dsp.focus({ window = \"address:0x" + t.address + "\" })");
        return true;
    }

    function overviewFocus(t) {
        root.panel = "";
        root.focusToplevel(t);
    }

    property bool switcherOpen: false
    property var  switcherApps: []
    property int  switcherIndex: 0

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
        delegate: Connections {
            required property var modelData
            target: modelData
            function onActivatedChanged() {
                if (modelData && modelData.activated) root.noteFocus(modelData);
            }
        }
    }

    function switchOpen() {
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
        root.switcherOpen = root.switcherApps.length > 0;
    }

    function switchStep(delta) {
        if (!root.switcherOpen) { root.switchOpen(); if (delta > 0) return; }
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
