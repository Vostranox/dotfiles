import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick.Layouts
import Quickshell.Widgets
import qs
import qs.ui

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    visible: ShellState.panelOn("overview", modelData)

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-overview"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    readonly property var allApps: ShellState.overviewApps
    property string query: ""

    readonly property var apps: {
        const q = win.query.trim().toLowerCase();
        if (q === "") return win.allApps;
        const toks = q.split(/\s+/).filter(t => t.length > 0);
        return win.allApps.filter(t => {
            const o = t.lastIpcObject || {};
            const hay = (Apps.appName(t) + " " + (o.class || "") + " " + (t.title || "")).toLowerCase();
            return toks.every(tok => hay.indexOf(tok) >= 0);
        });
    }

    readonly property int pad: Theme.pad * 3
    readonly property int labelH: 26
    readonly property int searchH: 46

    function aspect(t) {
        const o = t ? t.lastIpcObject : null;
        const s = o ? o.size : null;
        return (s && s[0] > 0 && s[1] > 0) ? s[0] / s[1] : 16 / 9;
    }

    readonly property int gap: Theme.gap * 2
    readonly property int cols: 3
    readonly property real availW: width - pad * 2
    readonly property int tileW: Math.floor((win.availW - (win.cols - 1) * win.gap) / win.cols)
    readonly property int tileH: Math.round(win.tileW * 0.62) + labelH

    function ensureVisible() {
        const c = nav.current();
        if (!c) return;
        if (c.y < flick.contentY)
            flick.contentY = c.y;
        else if (c.y + c.height > flick.contentY + flick.height)
            flick.contentY = c.y + c.height - flick.height;
    }
    function step(d) { nav.step(d); win.ensureVisible(); }

    KeyNav { id: nav; container: flow }



    onVisibleChanged: {
        if (!visible) return;
        search.text = "";
        search.forceActiveFocus();
        nav.index = win.apps.length > 1 ? 1 : 0;
        flick.contentY = 0;
        nav.apply(nav.list());
    }

    onQueryChanged: {
        nav.index = win.apps.length > 0 ? 0 : -1;
        Qt.callLater(() => { nav.apply(nav.list()); flick.contentY = 0; });
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.9)
        MouseArea { anchors.fill: parent; onClicked: ShellState.close() }
    }

    Rectangle {
        id: searchBox
        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter
                  topMargin: win.pad }
        width: Math.min(520, win.width * 0.5)
        height: win.searchH
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
            font.family: Theme.font; font.pixelSize: Theme.fontSize + 1
            onTextChanged: win.query = text

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: search.text === ""
                text: "Search"
                color: Theme.textDim
                font.family: Theme.font; font.pixelSize: Theme.fontSize
            }

            Keys.onPressed: (e) => {
                const ctrl = (e.modifiers & Qt.ControlModifier) !== 0;
                switch (e.key) {
                case Qt.Key_Escape:
                    if (search.text !== "") search.text = ""; else ShellState.close();
                    break;
                case Qt.Key_Right: win.step(1);  break;
                case Qt.Key_Left:  win.step(-1); break;
                case Qt.Key_Down:  win.step(win.cols);  break;
                case Qt.Key_Up:    win.step(-win.cols); break;
                case Qt.Key_I: if (!ctrl) return; win.step(1);  break;
                case Qt.Key_H: if (!ctrl) return; win.step(-1); break;
                case Qt.Key_A: if (!ctrl) return; win.step(win.cols);  break;
                case Qt.Key_E: if (!ctrl) return; win.step(-win.cols); break;
                case Qt.Key_Return:
                case Qt.Key_Enter: {
                    const c = nav.current();
                    if (c) c.navActivate();
                    break;
                }
                default: return;
                }
                e.accepted = true;
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: win.apps.length === 0
        text: win.query !== "" ? "No windows match" : "No open windows"
        color: Theme.textDim
        font.family: Theme.font; font.pixelSize: Theme.fontSize + 2
    }

    Flickable {
        id: flick
        anchors { top: searchBox.bottom; bottom: parent.bottom
                  horizontalCenter: parent.horizontalCenter
                  topMargin: Theme.pad * 2; bottomMargin: win.pad }
        width: win.cols * win.tileW + (win.cols - 1) * win.gap
        contentHeight: flow.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Behavior on contentY { enabled: !wheel.active; NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuint } }

    Flow {
        id: flow
        width: parent.width
        spacing: win.gap

        Repeater {
            model: win.apps
            delegate: Rectangle {
                id: tile
                required property var modelData

                property bool navigable: true
                property bool navSelected: false
                function navActivate() { ShellState.overviewPick(tile.modelData); }

                readonly property real ar: win.aspect(tile.modelData)
                width:  win.tileW
                height: win.tileH
                radius: Theme.radius * 1.4
                color: tile.navSelected ? Theme.surface : Theme.bgAlt
                border.color: tile.navSelected ? Theme.accent : Theme.border
                border.width: tile.navSelected ? 2 : 1
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Item {
                    id: thumbBox
                    anchors { left: parent.left; right: parent.right; top: parent.top
                              margins: Theme.gap }
                    height: win.tileH - win.labelH - Theme.gap

                    ScreencopyView {
                        id: shot
                        anchors.centerIn: parent
                        captureSource: tile.modelData && tile.modelData.wayland ? tile.modelData.wayland : null
                        live: true
                        paintCursor: false
                        width:  Math.max(1, Math.min(thumbBox.width, thumbBox.height * tile.ar))
                        height: Math.max(1, width / tile.ar)
                        visible: hasContent
                    }

                    IconImage {
                        anchors.centerIn: parent
                        visible: !shot.hasContent
                        implicitSize: Math.min(96, thumbBox.height * 0.6)
                        source: Apps.appIcon(tile.modelData)
                    }
                }

                RowLayout {
                    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter
                              bottomMargin: 5 }
                    spacing: Theme.gap
                    IconImage {
                        Layout.alignment: Qt.AlignVCenter
                        implicitSize: 16
                        source: Apps.appIcon(tile.modelData)
                        visible: shot.hasContent
                    }
                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.maximumWidth: tile.width - 34
                        text: Apps.appName(tile.modelData)
                        color: tile.navSelected ? Theme.text : Theme.textDim
                        font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: {
                        const l = nav.list();
                        nav.index = l.indexOf(tile);
                        nav.apply(l);
                    }
                    onClicked: tile.navActivate()
                }
            }
        }
    }
    }

    WheelScroll { id: wheel; anchors.fill: flick; view: flick }
}
