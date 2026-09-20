import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Widgets
import qs
import qs.ui

RowLayout {
    id: root
    spacing: Theme.pad * 1.3

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    function tip(item, txt) {
        const p = item.mapToItem(null, item.width / 2, 0);
        ShellState.showTip(txt, p.x);
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var battery: UPower.displayDevice
    readonly property var wifiDev: {
        const d = Networking.devices ? Networking.devices.values : [];
        for (const x of d) if (x.type === DeviceType.Wifi) return x;
        return null;
    }
    readonly property var activeAp: {
        const d = root.wifiDev;
        if (!d) return null;
        if (d.networks) for (const n of d.networks.values) if (n.connected) return n;
        return d.network || null;
    }

    Repeater {
        model: SystemTray.items
        delegate: Item {
            required property var modelData
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            Layout.alignment: Qt.AlignVCenter
            IconImage {
                anchors.centerIn: parent
                implicitSize: 18
                source: modelData.icon
                visible: source !== ""
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (m) => m.button === Qt.LeftButton ? modelData.activate() : modelData.secondaryActivate()
            }
        }
    }

    Item {
        id: wifi
        visible: Networking.wifiHardwareEnabled
        Layout.preferredWidth: 18
        Layout.preferredHeight: 18
        Layout.alignment: Qt.AlignVCenter

        readonly property bool live: Networking.wifiEnabled && root.activeAp
        readonly property string iconName: {
            if (!Networking.wifiEnabled) return "network-wireless-disabled";
            if (!root.activeAp)          return "network-wireless-offline";
            const s = root.activeAp.signalStrength || 0;      // 0..1
            return s > 0.80 ? "network-wireless-signal-excellent"
                 : s > 0.55 ? "network-wireless-signal-good"
                 : s > 0.30 ? "network-wireless-signal-ok"
                 : s > 0.05 ? "network-wireless-signal-weak"
                            : "network-wireless-signal-none";
        }

        SymIcon {
            anchors.centerIn: parent
            name: wifi.iconName
            opacity: wifi.live ? 1.0 : 0.55
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.openControlPage("wifi")
            onEntered: root.tip(wifi, !Networking.wifiEnabled ? "Wi-Fi off"
                        : root.activeAp ? root.activeAp.name + "  " + Math.round((root.activeAp.signalStrength || 0) * 100) + "%"
                        : "not connected")
            onExited: ShellState.hideTip()
        }
    }

    Item {
        id: vol
        Layout.preferredWidth: 18
        Layout.preferredHeight: 18
        Layout.alignment: Qt.AlignVCenter

        readonly property bool muted: root.sink && root.sink.audio ? root.sink.audio.muted : false
        readonly property real v: root.sink && root.sink.audio ? root.sink.audio.volume : 0
        readonly property string iconName:
              muted      ? "audio-volume-muted"
            : v > 0.65   ? "audio-volume-high"
            : v > 0.30   ? "audio-volume-medium"
                         : "audio-volume-low"

        SymIcon {
            anchors.centerIn: parent
            name: vol.iconName
            opacity: vol.muted ? 0.55 : 1.0
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted
            onEntered: root.tip(vol, vol.muted ? "muted" : Math.round(vol.v * 100) + "%")
            onExited: ShellState.hideTip()
        }
    }

    Item {
        id: bat
        readonly property bool has: root.battery && root.battery.isLaptopBattery
        readonly property real pct: root.battery ? root.battery.percentage : 0
        readonly property bool charging: root.battery && root.battery.state === UPowerDeviceState.Charging
        readonly property string iconName: {
            const step = Math.max(0, Math.min(10, Math.round(bat.pct * 10))) * 10;
            if (bat.charging) return step === 100 ? "battery-level-100-charged"
                                                  : "battery-level-" + step + "-charging";
            return "battery-level-" + step;
        }

        visible: has
        Layout.preferredWidth: 18
        Layout.preferredHeight: 18
        Layout.alignment: Qt.AlignVCenter

        SymIcon {
            anchors.centerIn: parent
            name: bat.iconName
            color: bat.charging      ? Theme.text
                 : bat.pct <= 0.10   ? Theme.urgent
                 : bat.pct <= 0.20   ? Theme.warn
                                     : Theme.text
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.openControlPage("power")
            onEntered: root.tip(bat, Math.round(bat.pct * 100) + "%" + (bat.charging ? " charging" : ""))
            onExited: ShellState.hideTip()
        }
    }
}
