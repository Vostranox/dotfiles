import QtQuick
import qs

MouseArea {
    id: root
    required property Flickable view
    readonly property bool active: idle.running

    property var recent: []

    acceptedButtons: Qt.NoButton

    Timer { id: idle; interval: 200 }

    function coast() {
        const now = Date.now();
        const s = root.recent.filter(p => now - p[0] <= 100);
        root.recent = [];
        if (s.length < 2) return;
        const v = s.reduce((sum, p) => sum + p[1], 0) / Math.max(0.016, (now - s[0][0]) / 1000);
        if (Math.abs(v) > 200) root.view.flick(0, v);
    }

    onWheel: (e) => {
        idle.restart();
        if (e.pixelDelta.x === 0 && e.pixelDelta.y === 0 && e.angleDelta.x === 0 && e.angleDelta.y === 0) {
            if (root.recent.length > 0) root.coast();
            else root.view.cancelFlick();
            return;
        }
        root.view.cancelFlick();
        const touchpad = e.pixelDelta.y !== 0;
        const dy = touchpad ? e.pixelDelta.y * Theme.scrollSpeed : e.angleDelta.y / 120 * 72;
        if (touchpad) {
            const now = Date.now();
            root.recent = root.recent.filter(p => now - p[0] <= 100).concat([[now, dy]]);
        }
        const top = root.view.originY;
        const bottom = top + Math.max(0, root.view.contentHeight - root.view.height);
        root.view.contentY = Math.max(top, Math.min(bottom, root.view.contentY - dy));
    }
}
