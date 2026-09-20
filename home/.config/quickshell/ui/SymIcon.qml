import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import qs

Item {
    id: root

    property string name
    property int size: 18
    property color color: Theme.text

    implicitWidth: size
    implicitHeight: size

    readonly property var candidates: {
        if (!name) return [];
        const out = [
            "file:///usr/share/icons/Adwaita/symbolic/status/" + name + "-symbolic.svg",
            "file:///usr/share/icons/Adwaita/symbolic/devices/" + name + "-symbolic.svg",
            "file:///usr/share/icons/Adwaita/symbolic/actions/" + name + "-symbolic.svg",
            "file:///usr/share/icons/Adwaita/symbolic/ui/" + name + "-symbolic.svg"
        ];
        for (const n of [name + "-symbolic", name]) {
            const p = Quickshell.iconPath(n, true);
            if (p) out.push(p);
        }
        return out;
    }
    property int idx: 0
    onCandidatesChanged: idx = 0

    Image {
        id: img
        anchors.fill: parent
        source: root.idx < root.candidates.length ? root.candidates[root.idx] : ""
        sourceSize.width: root.size * 2
        sourceSize.height: root.size * 2
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: false
        onStatusChanged: {
            if (status !== Image.Error) return;
            if (root.idx >= root.candidates.length - 1) return;
            Qt.callLater(() => { if (img.status === Image.Error) root.idx++; });
        }
    }

    ColorOverlay {
        anchors.fill: img
        source: img
        color: root.color
        visible: img.status === Image.Ready
    }
}
