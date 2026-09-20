pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    function appClass(t) {
        if (!t) return "";
        const o = t.lastIpcObject;
        if (o) {
            if (o.class && o.class !== "") return o.class;
            if (o.initialClass && o.initialClass !== "") return o.initialClass;
        }
        if (t.wayland && t.wayland.appId && t.wayland.appId !== "") return t.wayland.appId;
        return "";
    }

    function iconCandidates(cls) {
        if (!cls) return [];
        const out = [];
        const e = DesktopEntries.heuristicLookup(cls);
        if (e && e.icon) out.push(e.icon);
        out.push(cls);
        out.push(cls.toLowerCase());
        const parts = cls.split(".");
        if (parts.length > 1) {
            out.push(parts[parts.length - 1]);
            out.push(parts[parts.length - 1].toLowerCase());
        }
        return out;
    }

    function appIcon(t) {
        for (const c of root.iconCandidates(root.appClass(t))) {
            const p = Quickshell.iconPath(c, true);
            if (p !== "") return p;
        }
        return Quickshell.iconPath("application-x-executable", true);
    }

    function appName(t) {
        const cls = root.appClass(t);
        if (cls) {
            const e = DesktopEntries.heuristicLookup(cls);
            if (e && e.name) return e.name;
            const parts = cls.split(".");
            return parts.length > 2 ? parts[parts.length - 2] : cls;
        }
        const ttl = t && t.title ? String(t.title) : "";
        return ttl !== "" ? ttl.slice(0, 14) : "app";
    }
}
