pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    property var last: null
    readonly property var player: root.pick(Mpris.players ? Mpris.players.values : [], root.last)

    function pick(players, last) {
        const kept = players.indexOf(last) >= 0 ? last : null;
        if (kept && kept.isPlaying) return kept;
        return players.find(p => p.isPlaying) || kept || players[0] || null;
    }

    Instantiator {
        model: Mpris.players
        delegate: Connections {
            required property var modelData
            target: modelData
            function onPlaybackStateChanged() { root.last = modelData; }
        }
    }

    function toggle() { if (root.player) root.player.togglePlaying(); }
    function next()   { if (root.player) root.player.next(); }
    function prev()   { if (root.player) root.player.previous(); }
}
