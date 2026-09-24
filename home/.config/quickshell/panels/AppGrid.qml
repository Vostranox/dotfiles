import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.ui

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    visible: ShellState.panelOn("apps", modelData)

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-apps"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    readonly property int iconSize: 64
    readonly property int cellW:    136
    readonly property int cellH:    128

    property string query: ""
    readonly property var entries: {
        const m = {};
        for (const e of DesktopEntries.applications.values) m[e.id] = e;
        return m;
    }
    readonly property var apps: {
        const q = win.query.trim().toLowerCase();
        const name = e => (e.name || "").toLowerCase();
        let l = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        if (q !== "")
            l = l.filter(e => (name(e) + " " + (e.genericName || "") + " " + Array.from(e.keywords || []).join(" "))
                              .toLowerCase().indexOf(q) >= 0);
        l.sort((a, b) => {
            if (q !== "") {
                const sa = name(a).startsWith(q), sb = name(b).startsWith(q);
                if (sa !== sb) return sa ? -1 : 1;
            }
            return name(a).localeCompare(name(b));
        });
        return l;
    }
    readonly property var barKeys: Apps.pinned.filter(id => !!win.entries[id])

    onVisibleChanged: {
        if (!visible) return;
        search.text = "";
        win.menuEntry = null;
        win.dragEntry = null;
        grid.currentIndex = 0;
        grid.positionViewAtBeginning();
        search.forceActiveFocus();
    }

    function launch(e) {
        if (!e) return;
        Apps.launch(e);
        ShellState.close();
    }

    function openApp(id) {
        const ws = ShellState.liveToplevels().filter(t => { const e = Apps.entryFor(t); return e && e.id === id; });
        const recent = ShellState.mru.find(a => ws.some(w => w.address === a));
        const t = ws.find(w => w.address === recent) || ws[0];
        ShellState.close();
        if (t) ShellState.focusToplevel(t, true);
        else Apps.launch(win.entries[id]);
    }

    property var dragEntry: null
    property real dragX: 0
    property real dragY: 0
    readonly property bool overBar: dragEntry !== null && dragY >= height - Theme.dockEdge - Theme.dockBodyH - 48
    readonly property int dropIndex: {
        if (!win.overBar) return -1;
        const n = win.barKeys.length;
        const left = (win.width - n * Theme.dockPitch) / 2;
        return Math.max(0, Math.min(n, Math.round((win.dragX - left) / Theme.dockPitch)));
    }

    function drop() {
        const e = win.dragEntry, at = win.dropIndex;
        win.dragEntry = null;
        if (!e || at < 0) return;
        const next = win.barKeys[at];
        if (next === e.id) return;
        const rest = Apps.pinned.filter(k => k !== e.id);
        const to = next === undefined ? rest.length : rest.indexOf(next);
        Apps.movePin(e.id, to < 0 ? rest.length : to);
    }

    property var menuEntry: null
    property point menuAt
    function openMenu(e, p) {
        win.menuEntry = e;
        win.menuAt = p;
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.9)
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: ShellState.close()
        }
    }

    Rectangle {
        id: searchBox
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: (ShellState.barVisible ? Theme.barHeight : 0) + Theme.pad * 2
        }
        width: Math.min(520, parent.width * 0.5)
        height: 46
        radius: Theme.radius * 1.4
        color: Theme.bgAlt
        border.color: search.activeFocus ? Theme.accent : Theme.border
        border.width: 1

        TextInput {
            id: search
            anchors.fill: parent
            anchors.leftMargin: Theme.pad * 1.4
            anchors.rightMargin: Theme.pad * 1.4
            verticalAlignment: TextInput.AlignVCenter
            focus: true
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 1
            onTextChanged: {
                win.query = text;
                grid.currentIndex = 0;
                grid.positionViewAtBeginning();
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: search.text === ""
                text: "Search"
                color: Theme.textDim
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }

            Keys.onPressed: (e) => {
                const ctrl = (e.modifiers & Qt.ControlModifier) !== 0;
                switch (e.key) {
                case Qt.Key_Escape:
                    if (win.menuEntry) win.menuEntry = null;
                    else if (search.text !== "") search.text = "";
                    else ShellState.close();
                    break;
                case Qt.Key_Right: grid.moveCurrentIndexRight(); break;
                case Qt.Key_Left:  grid.moveCurrentIndexLeft();  break;
                case Qt.Key_Down:  grid.moveCurrentIndexDown();  break;
                case Qt.Key_Up:    grid.moveCurrentIndexUp();    break;
                case Qt.Key_I: if (!ctrl) return; grid.moveCurrentIndexRight(); break;
                case Qt.Key_H: if (!ctrl) return; grid.moveCurrentIndexLeft();  break;
                case Qt.Key_A: if (!ctrl) return; grid.moveCurrentIndexDown();  break;
                case Qt.Key_E: if (!ctrl) return; grid.moveCurrentIndexUp();    break;
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    win.launch(win.apps[grid.currentIndex]);
                    break;
                default: return;
                }
                e.accepted = true;
            }
        }
    }

    GridView {
        id: grid
        readonly property int cols: Math.max(1, Math.min(8, Math.floor((win.width - Theme.pad * 8) / win.cellW)))
        anchors {
            top: searchBox.bottom
            topMargin: Theme.pad * 2
            bottom: bar.top
            bottomMargin: Theme.pad * 2
            horizontalCenter: parent.horizontalCenter
        }
        width: cols * win.cellW
        cellWidth: win.cellW
        cellHeight: win.cellH
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: win.apps
        delegate: AppTile {}
    }

    WheelScroll { anchors.fill: grid; view: grid }

    Text {
        anchors.centerIn: grid
        visible: win.apps.length === 0
        text: "No apps match"
        color: Theme.textDim
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 2
    }

    Rectangle {
        id: bar
        readonly property bool gap: win.dropIndex >= 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.dockEdge
        width: Math.max(1, win.barKeys.length + (gap ? 1 : 0)) * Theme.dockPitch + 2 * Theme.dockSide
        height: Theme.dockBodyH
        radius: Theme.dockRadius
        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.92)
        border.color: win.overBar ? Theme.accent : Theme.border
        border.width: 1
        Behavior on width { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuad } }

        RowLayout {
            x: Theme.dockSide
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Repeater {
                model: win.barKeys
                delegate: Item {
                    id: pin
                    required property string modelData
                    required property int index
                    readonly property var entry: win.entries[modelData] || null
                    implicitWidth: Theme.dockPitch
                    implicitHeight: Theme.dockBodyH
                    transform: Translate {
                        x: bar.gap && pin.index >= win.dropIndex ? Theme.dockPitch : 0
                        Behavior on x { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuad } }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: Theme.dockInset
                        width: Theme.dockSlot
                        height: Theme.dockSlot
                        radius: Math.round(Theme.radius * Theme.dockScale)
                        color: Theme.surface
                        opacity: pinMouse.containsMouse && !win.dragEntry ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                    }

                    IconImage {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: Theme.dockInset + Theme.dockPad
                        implicitSize: Theme.dockIcon
                        source: Apps.entryIcon(pin.entry)
                        opacity: win.dragEntry === pin.entry ? 0.3 : 1
                    }

                    AppMouse {
                        id: pinMouse
                        anchors.fill: parent
                        entry: pin.entry
                        onActivated: win.openApp(pin.modelData)
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: win.barKeys.length === 0 && !bar.gap
            text: "󰐃"
            color: Theme.textDim
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 4
        }
    }

    IconImage {
        visible: win.dragEntry !== null
        x: win.dragX - width / 2
        y: win.dragY - height / 2
        z: 10
        implicitSize: win.iconSize
        source: win.dragEntry ? Apps.entryIcon(win.dragEntry) : ""
        opacity: 0.9
    }

    MouseArea {
        anchors.fill: parent
        visible: win.menuEntry !== null
        z: 19
        acceptedButtons: Qt.AllButtons
        onPressed: win.menuEntry = null
    }

    Rectangle {
        id: menu
        visible: win.menuEntry !== null
        x: Math.round(Math.max(Theme.gap, Math.min(win.width - width - Theme.gap, win.menuAt.x)))
        y: Math.round(Math.max(Theme.gap, Math.min(win.height - height - Theme.gap, win.menuAt.y)))
        z: 20
        width: 260
        height: menuCol.implicitHeight + Theme.gap * 2
        radius: Theme.radius * 1.6
        color: Theme.bg
        border.color: Theme.border
        border.width: 1

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: menuCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.gap }
            spacing: 2

            Row {
                label: "Open"
                onClicked: win.launch(win.menuEntry)
            }
            Repeater {
                model: win.menuEntry ? Array.from(win.menuEntry.actions) : []
                delegate: Row {
                    required property var modelData
                    label: modelData.name
                    onClicked: { modelData.execute(); ShellState.close(); }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                implicitHeight: 1
                color: Theme.surface
            }

            Row {
                label: win.menuEntry && Apps.isPinned(win.menuEntry.id) ? "Remove from Dock" : "Pin to Dock"
                onClicked: {
                    const id = win.menuEntry.id;
                    win.menuEntry = null;
                    Apps.togglePin(id);
                }
            }
        }
    }

    component AppTile: Item {
        id: tile
        required property var modelData
        required property int index
        width: win.cellW
        height: win.cellH

        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: Theme.radius * 1.4
            color: tileMouse.containsMouse || grid.currentIndex === tile.index ? Theme.surface : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        IconImage {
            id: icon
            anchors.horizontalCenter: parent.horizontalCenter
            y: 14
            implicitSize: win.iconSize
            source: Apps.entryIcon(tile.modelData) || Quickshell.iconPath("application-x-executable", true)
            opacity: win.dragEntry === tile.modelData ? 0.3 : 1
        }

        Rectangle {
            visible: Apps.isPinned(tile.modelData.id)
            anchors { top: icon.top; right: icon.right; topMargin: -2; rightMargin: -2 }
            width: 8
            height: 8
            radius: 4
            color: Theme.accent
        }

        Text {
            anchors { top: icon.bottom; topMargin: 8; horizontalCenter: parent.horizontalCenter }
            width: parent.width - 16
            horizontalAlignment: Text.AlignHCenter
            text: tile.modelData.name
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        AppMouse {
            id: tileMouse
            anchors.fill: parent
            entry: tile.modelData
            onActivated: win.launch(tile.modelData)
            onContainsMouseChanged: if (containsMouse && !win.dragEntry) grid.currentIndex = tile.index
        }
    }

    component AppMouse: MouseArea {
        required property var entry
        signal activated()
        property point pressAt
        property bool dragged: false

        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: win.dragEntry ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        preventStealing: true

        onPressed: (e) => {
            dragged = false;
            pressAt = mapToItem(null, e.x, e.y);
            if (e.button === Qt.RightButton) win.openMenu(entry, pressAt);
        }
        onPositionChanged: (e) => {
            if (!(pressedButtons & Qt.LeftButton) || !entry) return;
            const p = mapToItem(null, e.x, e.y);
            if (!dragged) {
                if (Math.abs(p.x - pressAt.x) + Math.abs(p.y - pressAt.y) < 8) return;
                dragged = true;
                win.menuEntry = null;
                win.dragEntry = entry;
            }
            win.dragX = p.x;
            win.dragY = p.y;
        }
        onReleased: if (dragged) win.drop()
        onCanceled: if (dragged) { dragged = false; win.dragEntry = null; }
        onClicked: (e) => {
            if (dragged) { dragged = false; return; }
            if (e.button === Qt.LeftButton) activated();
        }
    }
}
