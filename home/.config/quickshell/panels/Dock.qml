import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.ui

PanelWindow {
    id: dock
    required property var modelData
    screen: modelData

    readonly property bool autoHide: ShellState.dockAutoHide
    readonly property int  iconSize: Theme.dockIcon
    readonly property int  slot:     Theme.dockSlot
    readonly property int  spacing:  Theme.dockSpacing
    readonly property int  pitch:    Theme.dockPitch
    readonly property int  inset:    Theme.dockInset
    readonly property int  bodyH:    Theme.dockBodyH
    readonly property int  edge:     Theme.dockEdge
    readonly property int  thumbH:   Math.round(110 * Theme.dockScale)

    anchors { bottom: true; left: true; right: true }
    implicitHeight: thumbH + 60 + bodyH + edge
    exclusiveZone: autoHide ? 0 : bodyH + edge
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qs-dock"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    readonly property var apps: {
        const entries = {};
        for (const e of DesktopEntries.applications.values) entries[e.id] = e;
        const out = {};
        for (const id of Apps.pinned)
            if (entries[id]) out[id] = { entry: entries[id], windows: [] };
        for (const t of ShellState.liveToplevels()) {
            const e = Apps.entryFor(t);
            const key = e ? e.id : (Apps.appClass(t) || t.address);
            if (!out[key]) out[key] = { entry: e, windows: [] };
            out[key].windows.push(t);
        }
        return out;
    }
    readonly property var pinnedKeys: Object.keys(dock.apps).filter(k => Apps.isPinned(k))
    readonly property var otherKeys:  Theme.dockRunning ? Object.keys(dock.apps).filter(k => !Apps.isPinned(k)) : []

    property bool revealed: false
    readonly property bool shown: !autoHide || revealed || menu.visible || dragKey !== ""

    Timer { id: showDelay; interval: 150; onTriggered: dock.revealed = true }
    Timer { id: hideDelay; interval: 100; onTriggered: { dock.revealed = false; dock.previewCell = null; } }

    function isActive(t) { return !!(t && t.wayland && t.wayland.activated); }

    function launch(cell) {
        if (!cell || !cell.app.entry) return;
        cell.launchBase = cell.windows.length;
        cell.launching = true;
        Apps.launch(cell.app.entry);
    }

    function activate(cell) {
        previewDelay.stop();
        dock.previewCell = null;
        const ws = cell.windows;
        if (ws.length === 0) { dock.launch(cell); return; }
        const i = ws.findIndex(w => dock.isActive(w));
        if (i >= 0) {
            if (ws.length > 1) ShellState.focusToplevel(ws[(i + 1) % ws.length], true);
            return;
        }
        const recent = ShellState.mru.find(a => ws.some(w => w.address === a));
        ShellState.focusToplevel(ws.find(w => w.address === recent) || ws[0], true);
    }

    function openMenu(cell) {
        previewDelay.stop();
        dock.previewCell = null;
        menu.visible = false;
        menu.cell = cell;
        menu.at = cell.mapToItem(null, cell.width / 2, 0).x;
        menu.visible = true;
    }

    property Item hoverCell: null
    property Item previewCell: null
    property real previewAt: 0

    function hoverChanged(cell, inside) {
        if (inside) dock.hoverCell = cell;
        else if (dock.hoverCell === cell) dock.hoverCell = null;
    }

    onHoverCellChanged: {
        if (dock.dragKey !== "" || menu.visible) return;
        if (dock.hoverCell && dock.hoverCell.running) {
            if (dock.previewCell) dock.previewCell = dock.hoverCell;
            else previewDelay.restart();
        } else {
            previewDelay.stop();
            if (dock.previewCell) previewClose.restart();
        }
    }
    onPreviewCellChanged: if (previewCell) previewAt = previewCell.mapToItem(null, previewCell.width / 2, 0).x

    Timer {
        id: previewDelay
        interval: 400
        onTriggered: if (dock.hoverCell && dock.hoverCell.running && !menu.visible && dock.dragKey === "") dock.previewCell = dock.hoverCell
    }
    Timer {
        id: previewClose
        interval: 150
        onTriggered: if (!previewHover.hovered && dock.hoverCell !== dock.previewCell) dock.previewCell = null
    }

    property string dragKey: ""
    property Item dragCell: null
    property real dragDx: 0
    property bool settling: false
    readonly property int dragFrom: pinnedKeys.indexOf(dragKey)
    readonly property int dragTo: dragKey === "" ? -1 : dragFrom + Math.round(dragDx / pitch)

    function startDrag(cell) {
        previewDelay.stop();
        dock.previewCell = null;
        dock.dragDx = 0;
        dock.dragCell = cell;
        dock.dragKey = cell.modelData;
    }

    function dragMove(dx) {
        const f = dock.dragFrom;
        dock.dragDx = Math.max(-f * dock.pitch, Math.min((dock.pinnedKeys.length - 1 - f) * dock.pitch, dx));
    }

    function endDrag(commit) {
        const cell = dock.dragCell, from = dock.dragFrom, to = dock.dragTo;
        dock.settling = true;
        if (commit && to !== from) Apps.movePin(dock.dragKey, to);
        if (cell) cell.settleFrom(dock.dragDx - (commit ? to - from : 0) * dock.pitch);
        dock.dragKey = "";
        dock.dragCell = null;
        dock.dragDx = 0;
        Qt.callLater(() => dock.settling = false);
    }

    mask: Region {
        Region { item: hot }
        Region { item: previewHot }
    }

    Item {
        anchors.fill: parent

        HoverHandler {
            onHoveredChanged: {
                if (hovered) { hideDelay.stop(); showDelay.start(); }
                else         { showDelay.stop(); hideDelay.restart(); }
            }
        }

        Item {
            id: hot
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width, Math.max(Math.round(parent.width * Theme.dockTrigger), body.width + dock.pitch))
            height: dock.shown ? dock.bodyH + dock.edge : 2
        }

        Item {
            id: previewHot
            x: preview.x
            y: preview.y
            width: preview.visible ? preview.width : 0
            height: preview.visible ? hot.y - preview.y : 0
        }

        Rectangle {
            id: body
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: dock.shown ? dock.edge : -height
            Behavior on anchors.bottomMargin { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutQuint } }
            width: row.implicitWidth + 2 * Theme.dockSide
            height: dock.bodyH
            radius: Theme.dockRadius
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.92)
            border.color: Theme.border
            border.width: 1

            RowLayout {
                id: row
                anchors.centerIn: parent
                spacing: 0

                Repeater {
                    model: ScriptModel { values: dock.pinnedKeys }
                    delegate: AppCell {}
                }

                Rectangle {
                    visible: dock.pinnedKeys.length > 0 && dock.otherKeys.length > 0
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: Math.round(dock.iconSize * 0.7)
                    Layout.leftMargin: dock.spacing / 2
                    Layout.rightMargin: dock.spacing / 2
                    color: Theme.border
                }

                Repeater {
                    model: ScriptModel { values: dock.otherKeys }
                    delegate: AppCell {}
                }
            }
        }

        Rectangle {
            id: preview
            readonly property var wins: dock.previewCell ? dock.previewCell.windows : []
            visible: wins.length > 0 && dock.shown
            x: Math.round(Math.max(Theme.gap, Math.min(parent.width - width - Theme.gap, dock.previewAt - width / 2)))
            anchors.bottom: body.top
            anchors.bottomMargin: Theme.gap
            width: previewRow.implicitWidth + Theme.gap * 2
            height: previewRow.implicitHeight + Theme.gap * 2
            radius: Theme.radius * 1.6
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.95)
            border.color: Theme.border
            border.width: 1
            NumberAnimation on opacity { running: preview.visible; from: 0; to: 1; duration: Theme.animFast }

            HoverHandler {
                id: previewHover
                onHoveredChanged: if (!hovered) previewClose.restart()
            }

            RowLayout {
                id: previewRow
                anchors.centerIn: parent
                spacing: Theme.gap

                Repeater {
                    model: preview.wins
                    delegate: PreviewTile {}
                }
            }
        }
    }

    component AppCell: Item {
        id: cell
        required property string modelData
        readonly property var app: dock.apps[modelData] || ({ entry: null, windows: [] })
        readonly property var windows: app.windows
        readonly property bool running: windows.length > 0
        readonly property bool pinned: Apps.isPinned(modelData)
        readonly property bool focused: windows.some(w => dock.isActive(w))
        readonly property bool urgent: windows.some(w => w.urgent)
        readonly property bool dragging: dock.dragKey === modelData
        readonly property string name: app.entry ? app.entry.name : Apps.appName(windows[0])
        readonly property string icon: (app.entry ? Apps.entryIcon(app.entry) : "")
            || (running ? Apps.appIcon(windows[0]) : Quickshell.iconPath("application-x-executable", true))

        // bounce from launch until a new window of the app shows up
        property bool launching: false
        property int launchBase: 0
        onWindowsChanged: if (launching && windows.length > launchBase) launching = false
        Timer { running: cell.launching; interval: 8000; onTriggered: cell.launching = false }

        property real bounce: 0
        SequentialAnimation on bounce {
            running: cell.launching
            loops: Animation.Infinite
            alwaysRunToEnd: true
            NumberAnimation { to: -10 * Theme.dockScale; duration: 240; easing.type: Easing.OutQuad }
            NumberAnimation { to: 0; duration: 240; easing.type: Easing.InQuad }
        }

        readonly property real shift: {
            if (dock.dragKey === "" || !cell.pinned) return 0;
            if (cell.dragging) return dock.dragDx;
            const i = dock.pinnedKeys.indexOf(cell.modelData), f = dock.dragFrom, t = dock.dragTo;
            if (f < t && i > f && i <= t) return -dock.pitch;
            if (t < f && i >= t && i < f) return dock.pitch;
            return 0;
        }
        property real settle: 0
        NumberAnimation { id: settleAnim; target: cell; property: "settle"; to: 0; duration: Theme.animFast; easing.type: Easing.OutQuad }
        function settleFrom(v) { cell.settle = v; settleAnim.restart(); }

        implicitWidth: dock.pitch
        implicitHeight: dock.bodyH
        z: dragging ? 1 : 0
        transform: Translate {
            x: cell.shift + cell.settle
            Behavior on x {
                enabled: !dock.settling && dock.dragKey !== "" && !cell.dragging
                NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuad }
            }
        }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            y: dock.inset
            width: dock.slot
            height: dock.slot
            scale: cell.dragging ? 1.1 : 1
            Behavior on scale { NumberAnimation { duration: Theme.animFast } }

            Rectangle {
                anchors.fill: parent
                radius: Math.round(Theme.radius * Theme.dockScale)
                color: Theme.surface
                opacity: mouse.containsMouse && !cell.dragging ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
            }

            IconImage {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: cell.bounce
                implicitSize: dock.iconSize
                source: cell.icon
                opacity: mouse.pressed && !cell.dragging ? 0.6 : 1
            }
        }

        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.round(3 * Theme.dockScale)
            spacing: Math.max(2, Math.round(3 * Theme.dockScale))

            Repeater {
                model: Math.min(cell.windows.length, 4)
                delegate: Rectangle {
                    implicitHeight: Math.max(3, Math.round(4 * Theme.dockScale))
                    implicitWidth: cell.focused ? implicitHeight * 2 : implicitHeight
                    radius: implicitHeight / 2
                    color: cell.urgent ? Theme.urgent : cell.focused ? Theme.accent : Theme.textDim
                    Behavior on implicitWidth { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutQuint } }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: Theme.gap
            implicitWidth: tipText.implicitWidth + Theme.pad * 2
            implicitHeight: tipText.implicitHeight + Theme.gap * 1.5
            radius: Theme.radius
            color: Theme.surface
            border.color: Theme.border
            border.width: 1
            opacity: mouse.containsMouse && dock.shown && !menu.visible && dock.dragKey === "" && dock.previewCell !== cell ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

            Text {
                id: tipText
                anchors.centerIn: parent
                text: cell.name
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            cursorShape: cell.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
            property real pressX: 0
            property bool dragged: false

            onContainsMouseChanged: dock.hoverChanged(cell, containsMouse)
            onPressed: (e) => {
                dragged = false;
                if (e.button === Qt.RightButton) { dock.openMenu(cell); return; }
                menu.visible = false;
                pressX = mapToItem(null, e.x, e.y).x;
            }
            onPositionChanged: (e) => {
                if (!(pressedButtons & Qt.LeftButton) || !cell.pinned) return;
                const dx = mapToItem(null, e.x, e.y).x - pressX;
                if (!dragged) {
                    if (Math.abs(dx) < 6) return;
                    dragged = true;
                    dock.startDrag(cell);
                }
                dock.dragMove(dx);
            }
            onReleased: if (dragged) dock.endDrag(true)
            onCanceled: if (dragged) { dragged = false; dock.endDrag(false); }
            onClicked: (e) => {
                if (dragged) { dragged = false; return; }
                if (e.button === Qt.LeftButton) dock.activate(cell);
                else if (e.button === Qt.MiddleButton) dock.launch(cell);
            }
        }
    }

    component PreviewTile: Rectangle {
        id: tile
        required property var modelData
        readonly property real ar: {
            const o = tile.modelData.lastIpcObject;
            const sz = o ? o.size : null;
            return sz && sz[0] > 0 && sz[1] > 0 ? Math.max(0.6, Math.min(2, sz[0] / sz[1])) : 1.6;
        }
        readonly property bool hovered: tileMouse.containsMouse || closeMouse.containsMouse

        implicitWidth: Math.round(dock.thumbH * ar) + Theme.gap
        implicitHeight: dock.thumbH + title.implicitHeight + Theme.gap * 1.5
        radius: Theme.radius
        color: tile.hovered ? Theme.surface : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        ScreencopyView {
            id: shot
            anchors.top: parent.top
            anchors.topMargin: Theme.gap / 2
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.round(dock.thumbH * tile.ar)
            height: dock.thumbH
            captureSource: tile.modelData.wayland
            live: true
            paintCursor: false
        }

        IconImage {
            anchors.centerIn: shot
            visible: !shot.hasContent
            implicitSize: Math.round(dock.thumbH * 0.5)
            source: Apps.appIcon(tile.modelData)
        }

        Text {
            id: title
            anchors.top: shot.bottom
            anchors.topMargin: Theme.gap / 2
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - Theme.gap
            horizontalAlignment: Text.AlignHCenter
            text: tile.modelData.title || Apps.appName(tile.modelData)
            color: dock.isActive(tile.modelData) ? Theme.accent : Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 2
            elide: Text.ElideRight
        }

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onClicked: (e) => {
                if (e.button === Qt.MiddleButton) {
                    if (tile.modelData.wayland) tile.modelData.wayland.close();
                    return;
                }
                dock.previewCell = null;
                ShellState.focusToplevel(tile.modelData, true);
            }
        }

        Rectangle {
            anchors { top: parent.top; right: parent.right; margins: 2 }
            width: 20
            height: 20
            radius: 10
            color: closeMouse.containsMouse ? Theme.urgent : Theme.surfaceHi
            visible: tile.hovered

            Text {
                anchors.centerIn: parent
                text: "󰅖"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
            }
            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (tile.modelData.wayland) tile.modelData.wayland.close()
            }
        }
    }

    PopupWindow {
        id: menu
        property Item cell: null
        property real at: 0
        readonly property var app: cell ? cell.app : null
        readonly property bool running: !!app && app.windows.length > 0
        readonly property var actions: app && app.entry ? Array.from(app.entry.actions) : []

        anchor.window: dock
        anchor.rect.x: Math.round(menu.at)
        anchor.rect.y: dock.height - dock.edge - dock.bodyH - Theme.gap
        anchor.rect.w: 1
        anchor.rect.h: 1
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Top
        grabFocus: true
        implicitWidth: 280
        implicitHeight: menuCol.implicitHeight + Theme.gap * 2
        color: "transparent"

        onVisibleChanged: if (!visible) menu.cell = null
        onAppChanged: if (visible && !app) visible = false

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius * 1.6
            color: Theme.bg
            border.color: Theme.border
            border.width: 1
            focus: true
            Keys.onEscapePressed: menu.visible = false

            ColumnLayout {
                id: menuCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.gap }
                spacing: 2

                Repeater {
                    model: menu.app ? menu.app.windows : []
                    delegate: Row {
                        required property var modelData
                        label: modelData.title || Apps.appName(modelData)
                        detail: modelData.workspace && modelData.workspace.id > 0 ? String(modelData.workspace.id) : ""
                        highlight: dock.isActive(modelData)
                        onClicked: { menu.visible = false; ShellState.focusToplevel(modelData, true); }
                    }
                }

                Rectangle {
                    visible: !!menu.app && menu.app.windows.length > 0
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    Layout.bottomMargin: 2
                    implicitHeight: 1
                    color: Theme.surface
                }

                Row {
                    visible: !!(menu.app && menu.app.entry) && !(menu.running && menu.actions.some(a => a.id === "new-window"))
                    label: menu.running ? "New Window" : "Open"
                    onClicked: { const c = menu.cell; menu.visible = false; dock.launch(c); }
                }
                Repeater {
                    model: menu.actions
                    delegate: Row {
                        required property var modelData
                        label: modelData.name
                        onClicked: { menu.visible = false; modelData.execute(); }
                    }
                }

                Rectangle {
                    visible: !!(menu.app && menu.app.entry)
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    Layout.bottomMargin: 2
                    implicitHeight: 1
                    color: Theme.surface
                }

                Row {
                    visible: !!(menu.app && menu.app.entry)
                    label: menu.cell && Apps.isPinned(menu.cell.modelData) ? "Remove from Dock" : "Keep in Dock"
                    onClicked: { const k = menu.cell.modelData; menu.visible = false; Apps.togglePin(k); }
                }
                Row {
                    visible: !!menu.app && menu.app.windows.length > 0
                    label: "Quit"
                    onClicked: {
                        const ws = menu.app.windows;
                        menu.visible = false;
                        for (const t of ws) if (t.wayland) t.wayland.close();
                    }
                }
            }
        }
    }
}
