pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Services.UPower
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property var  live: server.trackedNotifications ? server.trackedNotifications.values : []
    property var  localAlerts: []
    property int  unread: 0
    property int  unreadCritical: 0
    property int  ackGen: 0
    property int  bannerTimeout: 10000

    property var acked: ({})
    property var deadline: ({})

    PersistentProperties {
        id: seen
        reloadableId: "notificationBannerState"
        property string ackedJson: "{}"
        onLoaded:   root.restoreAcked()
        onReloaded: root.restoreAcked()
    }

    function restoreAcked() {
        try { root.acked = JSON.parse(seen.ackedJson || "{}"); }
        catch (e) { root.acked = ({}); }
        root.ackGen++;
    }
    function persistAcked() {
        const live = {};
        for (const e of root.entries) if (root.acked[e.key]) live[e.key] = true;
        root.acked = live;
        seen.ackedJson = JSON.stringify(live);
    }

    readonly property var entries: {
        const out = [];
        for (const a of root.localAlerts) out.push(a);
        for (const n of root.live)
            out.push({
                key: "d" + n.id, summary: n.summary, body: n.body,
                appName: n.appName, icon: n.appIcon || "", image: n.image || "",
                critical: n.urgency === NotificationUrgency.Critical, notif: n
            });
        return out.reverse();
    }
    readonly property int  count: root.entries.length
    readonly property bool hasUnread: root.unread > 0
    readonly property var  banners: {
        root.ackGen;
        return root.entries.filter(e => e.critical && !root.acked[e.key]);
    }

    function markRead()    { root.unread = 0; root.unreadCritical = 0; }
    function ack(entry)    { root.acked[entry.key] = true; root.ackGen++; root.persistAcked(); }
    function dismiss(entry) {
        root.ack(entry);
        delete root.deadline[entry.key];
        if (entry.notif) { entry.notif.dismiss(); return; }
        root.localAlerts = root.localAlerts.filter(a => a.key !== entry.key);
    }

    function activate(entry) {
        const n = entry.notif;
        if (!n) { root.dismiss(entry); return; }

        const def = n.actions.find(a => a.identifier === "default");
        if (def) def.invoke();

        root.focusApp(n.desktopEntry, n.appName);

        if (def && n.resident) return;
        Qt.callLater(() => root.dismissIfPresent(entry.key));
    }

    function dismissIfPresent(key) {
        const e = root.entries.find(x => x.key === key);
        if (e) root.dismiss(e);
    }

    function focusApp(id, appName) {
        const norm = v => (v || "").toLowerCase().replace(/[^a-z0-9]/g, "");
        const cands = [];
        if (id) {
            cands.push(norm(id));
            if (id.toLowerCase().endsWith(".desktop")) cands.push(norm(id.slice(0, -8)));
        }
        if (appName) cands.push(norm(appName));

        const needles = cands.filter(c => c.length > 0);
        if (!needles.length) return false;

        const vals = Hyprland.toplevels ? Hyprland.toplevels.values : [];
        for (const t of vals) {
            const o = t ? t.lastIpcObject : null;
            if (!o || o.mapped !== true) continue;
            const cls = norm(o.initialClass || o.class || "");
            if (!cls) continue;
            const hit = needles.some(c => cls === c
                                       || (c.length   >= 4 && cls.indexOf(c) >= 0)
                                       || (cls.length >= 4 && c.indexOf(cls) >= 0));
            if (!hit) continue;

            if (o.workspace && o.workspace.id !== undefined)
                Hyprland.dispatch("hl.dsp.focus({ workspace = " + o.workspace.id + " })");
            Hyprland.dispatch("hl.dsp.focus({ window = \"address:0x" + t.address + "\" })");
            return true;
        }
        return false;
    }

    function clearAll() {
        for (const e of root.entries.slice()) root.dismiss(e);
        root.acked = ({});
        root.deadline = ({});
        seen.ackedJson = "{}";
        root.unread = 0;
        root.unreadCritical = 0;
    }
    function alert(key, summary, body, icon, critical) {
        root.localAlerts = root.localAlerts.filter(a => a.key !== key).concat([{
            key: key, summary: summary, body: body, appName: "System",
            icon: icon, image: "", critical: critical, notif: null
        }]);
        root.unread++;
        if (critical) root.unreadCritical++;
    }

    Timer {
        interval: 500
        repeat: true
        running: root.banners.length > 0
        onTriggered: {
            const now = Date.now();
            for (const b of root.banners) {
                let d = root.deadline[b.key];
                if (d === undefined) {
                    const want = b.notif && b.notif.expireTimeout > 0 ? b.notif.expireTimeout
                                                                      : root.bannerTimeout;
                    d = now + Math.max(3000, Math.min(30000, want));
                    root.deadline[b.key] = d;
                }
                if (now >= d) root.ack(b);
            }
        }
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true

        onNotification: (n) => {
            n.tracked = true;
            root.unread++;
            if (n.urgency === NotificationUrgency.Critical) root.unreadCritical++;
        }
    }

    readonly property var bat: UPower.displayDevice
    property bool lowFired: false
    property bool critFired: false

    function checkBattery() {
        const b = root.bat;
        if (!b || !b.isLaptopBattery) return;
        if (b.state !== UPowerDeviceState.Discharging) {
            root.lowFired = false; root.critFired = false; return;
        }
        const pct = Math.round(b.percentage * 100);
        if (b.percentage <= 0.10 && !root.critFired) {
            root.critFired = true;
            root.alert("battery-critical", "Battery critically low",
                       pct + "% remaining -- plug in now", "battery-caution", true);
        } else if (b.percentage <= 0.20 && !root.lowFired) {
            root.lowFired = true;
            root.alert("battery-low", "Battery low", pct + "% remaining", "battery-caution", false);
        }
    }

    Connections {
        target: root.bat
        function onPercentageChanged() { root.checkBattery(); }
        function onStateChanged()      { root.checkBattery(); }
    }
}
