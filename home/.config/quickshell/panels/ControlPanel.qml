import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import qs
import qs.ui

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    visible: ShellState.panel === "control"

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-control"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    readonly property var sink:    Pipewire.defaultAudioSink
    readonly property var source:  Pipewire.defaultAudioSource
    readonly property var battery: UPower.displayDevice
    readonly property var wifiDev: {
        const d = Networking.devices ? Networking.devices.values : [];
        for (const x of d) if (x.type === DeviceType.Wifi) return x;
        return null;
    }

    readonly property var activeAp: {
        const d = win.wifiDev;
        if (!d) return null;
        if (d.networks) for (const n of d.networks.values) if (n.connected) return n;
        return d.network || null;
    }
    readonly property var player: {
        const p = Mpris.players ? Mpris.players.values : [];
        return p.length ? p[0] : null;
    }

    property string page: ShellState.controlPage
    property var pskFor: null

    Process { id: proc }
    function run(cmd) { proc.command = ["sh", "-c", cmd]; proc.running = true; ShellState.close(); }

    function audioNodes(sink) {
        const out = [];
        const v = Pipewire.nodes ? Pipewire.nodes.values : [];
        for (const n of v) {
            if (!n || n.isStream) continue;
            if (n.isSink !== sink) continue;
            if (!n.audio) continue;
            out.push(n);
        }
        return out;
    }
    function audioLabel(n) {
        if (!n) return "none";
        return n.description || n.nickname || n.name || "unknown";
    }

    PwObjectTracker { objects: win.audioNodes(true).concat(win.audioNodes(false)) }

    Process { id: audioProc }
    function setAudioDevice(node, sink) {
        if (!node || !node.name) return;
        audioProc.command = ["pactl", sink ? "set-default-sink" : "set-default-source", node.name];
        audioProc.running = true;
    }

    readonly property int profile: PowerProfiles.profile
    function profileName(p) {
        return p === PowerProfile.PowerSaver ? "Power saver"
             : p === PowerProfile.Balanced   ? "Balanced"
             : "Performance";
    }

    KeyNav { id: nav; container: col }

    function navReset() { nav.reset(); }

    onVisibleChanged: {
        if (visible) { keys.forceActiveFocus(); win.navReset(); }
        else { win.pskFor = null; }
    }
    onPageChanged: {
        win.navReset();
        if (win.wifiDev) win.wifiDev.scannerEnabled = (win.page === "wifi") && Networking.wifiEnabled;
        const a = Bluetooth.defaultAdapter;
        if (a && a.enabled) a.discovering = (win.page === "bluetooth");
        win.pskFor = null;
    }

    MouseArea { anchors.fill: parent; onClicked: ShellState.close() }

    FocusScope {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: (e) => {
            const cur = nav.current();
            switch (e.key) {
            case Qt.Key_Escape:
                if (win.page !== "") ShellState.controlPage = ""; else ShellState.close();
                break;
            case Qt.Key_Down:  nav.step(1);  break;
            case Qt.Key_Up:    nav.step(-1); break;
            case Qt.Key_Right:
                if (cur && cur.navRight) cur.navRight();
                else if (cur && cur.hasToggle !== true) cur.navActivate();
                break;
            case Qt.Key_Left:
                if (cur && cur.navLeft) cur.navLeft();
                else if (win.page !== "") ShellState.controlPage = "";
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (cur) cur.navActivate();
                break;
            case Qt.Key_Tab:
            case Qt.Key_Backtab:
                if (cur && cur.hasToggle === true) cur.navActivate();
                break;
            default: return;
            }
            e.accepted = true;
        }
    }

    Rectangle {
        id: card
        anchors {
            top: parent.top; right: parent.right
            topMargin: (ShellState.barVisible ? Theme.barHeight : 0) + Theme.gap
            rightMargin: Theme.gap
        }
        Behavior on anchors.topMargin { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuint } }
        width: 380
        height: col.implicitHeight + Theme.pad * 2
        radius: Theme.radius * 1.6
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuint } }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.pad }
            spacing: Theme.gap

            Row {
                visible: win.page !== ""
                label: "‹   " + (win.page === "wifi"      ? "Wi-Fi"
                               : win.page === "power"     ? "Power mode"
                               : win.page === "audio"     ? "Audio"
                                                          : "Bluetooth")
                highlight: true
                onClicked: ShellState.controlPage = ""
            }
            Row {
                visible: win.page === "wifi"
                label: "   Wi-Fi"
                hasToggle: true
                toggled: Networking.wifiEnabled
                onSwitched: {
                    Networking.wifiEnabled = !Networking.wifiEnabled;
                    if (win.wifiDev) win.wifiDev.scannerEnabled = Networking.wifiEnabled;
                }
            }
            Row {
                visible: win.page === "bluetooth"
                label: "   Bluetooth"
                hasToggle: true
                toggled: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                onSwitched: {
                    const a = Bluetooth.defaultAdapter;
                    if (!a) return;
                    a.enabled = !a.enabled;
                    a.discovering = a.enabled;
                }
            }
            Rectangle { visible: win.page !== ""; Layout.fillWidth: true; height: 1; color: Theme.surface }

            Repeater {
                model: {
                    if (win.page !== "wifi" || !Networking.wifiEnabled) return null;
                    if (!win.wifiDev || !win.wifiDev.networks) return null;
                    const n = win.wifiDev.networks.values.slice();
                    n.sort((a, b) => (b.signalStrength || 0) - (a.signalStrength || 0));
                    return n;
                }
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 0

                    Row {
                        label: "   " + (modelData.name || "(hidden)")
                        detail: (modelData.connected ? "connected  " : (modelData.known ? "saved  " : ""))
                              + Math.round((modelData.signalStrength || 0) * 100) + "%"
                        highlight: modelData.connected
                        onClicked: {
                            if (modelData.connected) { modelData.disconnect(); return; }
                            if (modelData.known || !modelData.security) modelData.connect();
                            else win.pskFor = (win.pskFor === modelData) ? null : modelData;
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: Theme.pad * 2
                        Layout.rightMargin: Theme.pad
                        implicitHeight: 34
                        radius: Theme.radius
                        color: Theme.surface
                        visible: win.pskFor === modelData
                        TextInput {
                            id: psk
                            anchors.fill: parent
                            anchors.leftMargin: Theme.pad
                            anchors.rightMargin: Theme.pad
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            color: Theme.text
                            font.family: Theme.font; font.pixelSize: Theme.fontSize
                            onVisibleChanged: if (visible) { text = ""; forceActiveFocus(); }
                            Keys.onPressed: (e) => {
                                if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                                    modelData.connectWithPsk(text); win.pskFor = null; e.accepted = true;
                                } else if (e.key === Qt.Key_Escape) { win.pskFor = null; e.accepted = true; }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: psk.text === ""
                                text: "password, Enter to connect"
                                color: Theme.textDim
                                font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                            }
                        }
                    }
                }
            }
            Text {
                visible: win.page === "wifi" && Networking.wifiEnabled
                      && (!win.wifiDev || !win.wifiDev.networks || win.wifiDev.networks.values.length === 0)
                Layout.fillWidth: true
                Layout.margins: Theme.pad
                text: "scanning…"
                color: Theme.textDim
                font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
            }

            Repeater {
                model: (win.page === "bluetooth" && Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled)
                     ? Bluetooth.devices : null
                delegate: Row {
                    required property var modelData
                    label: "   " + (modelData.name || modelData.deviceName || modelData.address)
                    detail: modelData.connected ? "connected"
                          : modelData.pairing   ? "pairing…"
                          : modelData.paired    ? "paired" : "available"
                    highlight: modelData.connected
                    onClicked: {
                        if (modelData.connected) modelData.disconnect();
                        else if (modelData.paired) modelData.connect();
                        else modelData.pair();
                    }
                }
            }
            Text {
                visible: win.page === "bluetooth" && Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                      && (!Bluetooth.devices || Bluetooth.devices.values.length === 0)
                Layout.fillWidth: true
                Layout.margins: Theme.pad
                text: "searching…"
                color: Theme.textDim
                font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
            }

            Text {
                visible: win.page === "audio"
                Layout.fillWidth: true
                Layout.leftMargin: Theme.pad
                Layout.topMargin: Theme.gap
                text: "Output"
                color: Theme.textDim
                font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
            }
            Repeater {
                model: win.page === "audio" ? win.audioNodes(true) : null
                delegate: Row {
                    required property var modelData
                    readonly property bool sel: Pipewire.defaultAudioSink === modelData
                    label: (sel ? "  ●  " : "  ○  ") + win.audioLabel(modelData)
                    highlight: sel
                    onClicked: win.setAudioDevice(modelData, true)
                }
            }

            Text {
                visible: win.page === "audio" && win.audioNodes(false).length > 0
                Layout.fillWidth: true
                Layout.leftMargin: Theme.pad
                Layout.topMargin: Theme.gap
                text: "Input"
                color: Theme.textDim
                font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
            }
            Repeater {
                model: win.page === "audio" ? win.audioNodes(false) : null
                delegate: Row {
                    required property var modelData
                    readonly property bool sel: Pipewire.defaultAudioSource === modelData
                    label: (sel ? "  ●  " : "  ○  ") + win.audioLabel(modelData)
                    highlight: sel
                    onClicked: win.setAudioDevice(modelData, false)
                }
            }
            Text {
                visible: win.page === "audio" && win.audioNodes(true).length === 0
                Layout.fillWidth: true
                Layout.margins: Theme.pad
                text: "No devices"
                color: Theme.textDim
                font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
            }

            Repeater {
                model: win.page === "power"
                     ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
                     : null
                delegate: Row {
                    required property var modelData
                    readonly property bool sel: PowerProfiles.profile === modelData
                    readonly property bool avail: modelData !== PowerProfile.Performance
                                               || PowerProfiles.hasPerformanceProfile
                    visible: avail
                    label: (sel ? "  ●  " : "  ○  ") + win.profileName(modelData)
                    highlight: sel
                    onClicked: PowerProfiles.profile = modelData
                }
            }
            Text {
                visible: win.page === "power" && PowerProfiles.degradationReason !== 0
                Layout.fillWidth: true
                Layout.margins: Theme.pad
                text: "performance unavailable (thermal or lap detection)"
                color: Theme.textDim
                font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                wrapMode: Text.WordWrap
            }

            RowLayout {
                visible: win.page === ""
                Layout.fillWidth: true
                spacing: Theme.pad
                Text {
                    text: win.sink && win.sink.audio && win.sink.audio.muted ? "󰝟" : "󰕾"
                    color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize + 4
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: if (win.sink && win.sink.audio) win.sink.audio.muted = !win.sink.audio.muted
                    }
                }
                Slider {
                    Layout.fillWidth: true
                    value: win.sink && win.sink.audio ? win.sink.audio.volume : 0
                    onMoved: (v) => { if (win.sink && win.sink.audio) win.sink.audio.volume = v; }
                }
                Text {
                    text: (win.sink && win.sink.audio ? Math.round(win.sink.audio.volume * 100) : 0) + "%"
                    color: Theme.textDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                }
            }

            RowLayout {
                visible: win.page === "" && win.source !== null
                Layout.fillWidth: true
                spacing: Theme.pad
                Text {
                    text: win.source && win.source.audio && win.source.audio.muted ? "󰍭" : "󰍬"
                    color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize + 4
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: if (win.source && win.source.audio) win.source.audio.muted = !win.source.audio.muted
                    }
                }
                Slider {
                    Layout.fillWidth: true
                    value: win.source && win.source.audio ? win.source.audio.volume : 0
                    onMoved: (v) => { if (win.source && win.source.audio) win.source.audio.volume = v; }
                }
                Text {
                    text: (win.source && win.source.audio ? Math.round(win.source.audio.volume * 100) : 0) + "%"
                    color: Theme.textDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                }
            }

            RowLayout {
                visible: win.page === "" && Brightness.available
                Layout.fillWidth: true
                spacing: Theme.pad
                Text { text: "󰃠"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize + 4 }
                Slider {
                    Layout.fillWidth: true
                    value: Brightness.percent
                    onMoved: (v) => Brightness.set(v)
                }
                Text {
                    text: Math.round(Brightness.percent * 100) + "%"
                    color: Theme.textDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                }
            }

            Row {
                visible: win.page === ""
                label: "Audio"
                detail: win.audioLabel(win.sink) + "   ›"
                onClicked: ShellState.controlPage = "audio"
            }

            Rectangle { visible: win.page === ""; Layout.fillWidth: true; height: 1; color: Theme.surface }

            Row {
                visible: win.page === ""
                label: "Wi-Fi"
                detail: (!Networking.wifiHardwareEnabled ? "no adapter"
                      : !Networking.wifiEnabled ? "off"
                      : (win.activeAp ? win.activeAp.name : "not connected")) + "   ›"
                highlight: Networking.wifiEnabled
                onClicked: ShellState.controlPage = "wifi"
            }
            Row {
                visible: win.page === ""
                label: "Bluetooth"
                detail: (Bluetooth.defaultAdapter ? (Bluetooth.defaultAdapter.enabled ? "on" : "off") : "no adapter") + "   ›"
                highlight: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                onClicked: ShellState.controlPage = "bluetooth"
            }

            Rectangle { visible: win.page === "" && win.player !== null; Layout.fillWidth: true; height: 1; color: Theme.surface }
            ColumnLayout {
                visible: win.page === "" && win.player !== null
                Layout.fillWidth: true
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: win.player ? (win.player.trackTitle || "") : ""
                    color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: win.player ? (win.player.trackArtist || "") : ""
                    color: Theme.textDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                    elide: Text.ElideRight
                }
                RowLayout {
                    id: mediaRow
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Theme.gap
                    Layout.bottomMargin: Theme.gap
                    spacing: Theme.pad * 1.8

                    property bool navigable: true
                    property bool navSelected: false
                    property int  navCol: 1
                    readonly property var actions: [["󰒮", "prev"], ["󰐊", "play"], ["󰒭", "next"]]
                    function navLeft()  { navCol = (navCol + actions.length - 1) % actions.length; }
                    function navRight() { navCol = (navCol + 1) % actions.length; }
                    function navActivate() { mediaRow.fire(actions[navCol][1]); }
                    function fire(what) {
                        if (!win.player) return;
                        if (what === "prev") win.player.previous();
                        else if (what === "next") win.player.next();
                        else win.player.togglePlaying();
                    }

                    Repeater {
                        model: mediaRow.actions
                        delegate: Text {
                            required property var modelData
                            required property int index
                            readonly property bool sel: mediaRow.navSelected && mediaRow.navCol === index

                            text: modelData[1] !== "play" ? modelData[0]
                                : (win.player && win.player.isPlaying ? "󰏤" : modelData[0])
                            color: sel ? Theme.accent : Theme.text
                            font.family: Theme.font
                            font.pixelSize: modelData[1] === "play" ? Theme.fontSize + 18
                                                                    : Theme.fontSize + 12
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: mediaRow.fire(modelData[1])
                            }
                        }
                    }
                }
            }

            Rectangle { visible: win.page === ""; Layout.fillWidth: true; height: 1; color: Theme.surface }

            Row {
                visible: win.page === ""
                label: "Keep awake"
                hasToggle: true
                toggled: ShellState.keepAwake
                onSwitched: ShellState.keepAwake = !ShellState.keepAwake
            }
            Row {
                visible: win.page === ""
                label: "Power mode"
                detail: win.profileName(win.profile) + "   ›"
                onClicked: ShellState.controlPage = "power"
            }
            Row {
                visible: win.page === "" && win.battery && win.battery.isLaptopBattery
                label: "Battery"
                detail: win.battery ? Math.round(win.battery.percentage * 100) + "%" : ""
            }

            Rectangle { visible: win.page === ""; Layout.fillWidth: true; height: 1; color: Theme.surface }

            RowLayout {
                id: powerRow
                visible: win.page === ""
                Layout.fillWidth: true
                spacing: Theme.gap

                property bool navigable: true
                property bool navSelected: false
                property int  navCol: 0
                readonly property var actions: [["󰌾", "loginctl lock-session"],
                                               ["󰤄", "loginctl lock-session && systemctl suspend"],
                                               ["󰜉", "systemctl reboot"],
                                               ["󰐥", "systemctl poweroff"]]
                function navLeft()  { navCol = (navCol + actions.length - 1) % actions.length; }
                function navRight() { navCol = (navCol + 1) % actions.length; }
                function navActivate() { win.run(actions[navCol][1]); }

                Repeater {
                    model: powerRow.actions
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool sel: powerRow.navSelected && powerRow.navCol === index
                        Layout.fillWidth: true
                        implicitHeight: 38
                        radius: Theme.radius
                        color: sel || pma.containsMouse ? Theme.surface : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: modelData[0]
                            color: sel || pma.containsMouse ? Theme.urgent : Theme.text
                            font.family: Theme.font; font.pixelSize: Theme.fontSize + 5
                        }
                        MouseArea {
                            id: pma
                            anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.run(modelData[1])
                        }
                    }
                }
            }
        }
    }
}
