import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs
import qs.panels
import qs.ui

ShellRoot {
    id: root
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    Variants {
        model: Quickshell.screens
        delegate: Launcher {}
    }

    Variants {
        model: Quickshell.screens
        delegate: Switcher {}
    }

    Variants {
        model: Quickshell.screens
        delegate: Overview {}
    }

    Variants {
        model: Quickshell.screens
        delegate: Screenshot {}
    }

    Variants {
        model: Quickshell.screens
        delegate: ControlPanel {}
    }

    Variants {
        model: Quickshell.screens
        delegate: Osd {}
    }

    Variants {
        model: Quickshell.screens
        delegate: NotificationCenter {}
    }

    Variants {
        model: Quickshell.screens
        delegate: Banner {}
    }

    Variants {
        model: Quickshell.screens
        delegate: Dock {}
    }

    Variants {
        model: Quickshell.screens
        delegate: AppGrid {}
    }

    PanelWindow {
        id: awakeHolder
        implicitWidth: 1
        implicitHeight: 1
        color: "transparent"
        mask: Region {}
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "qs-keepawake"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        IdleInhibitor { window: awakeHolder; enabled: ShellState.keepAwake }
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    property bool ready: false
    Timer { running: true; interval: 1500; onTriggered: root.ready = true }

    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
        function onVolumeChanged() {
            if (!root.ready) return;
            const a = Pipewire.defaultAudioSink.audio;
            ShellState.osd(a.muted ? "󰝟" : "󰕾", a.volume, a.muted);
        }
        function onMutedChanged() {
            if (!root.ready) return;
            const a = Pipewire.defaultAudioSink.audio;
            ShellState.osd(a.muted ? "󰝟" : "󰕾", a.volume, a.muted);
        }
    }

    Connections {
        target: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio : null
        function onMutedChanged() {
            if (!root.ready) return;
            const a = Pipewire.defaultAudioSource.audio;
            ShellState.osd(a.muted ? "󰍭" : "󰍬", a.volume, a.muted);
        }
    }

    Connections {
        target: Brightness
        function onPercentChanged() {
            if (!root.ready || !Brightness.available) return;
            if (!Brightness.quiet) ShellState.osd("󰃠", Brightness.percent, false);
            else if (ShellState.osdVisible && ShellState.osdIcon === "󰃠") ShellState.osdValue = Brightness.percent;
        }
    }

    IpcHandler {
        target: "shell"
        function launcher(): void { ShellState.toggle("launcher"); }
        function apps():     void { ShellState.toggle("apps"); }
        function control():  void { ShellState.toggle("control"); }
        function close():    void { ShellState.close(); }
        function bar():      void { ShellState.toggleBar(); }
        function dock():     void { ShellState.toggleDockAutoHide(); }
        function notifications(): void { ShellState.toggle("notifications"); }
        function clearNotifications(): void { Notifications.clearAll(); }
        function wifiPage(): void { ShellState.openControlPage("wifi"); }
        function powerPage(): void { ShellState.openControlPage("power"); }

        function screenshot(): void { ShellState.toggle("screenshot"); }
        function stopRecording(): void { Recorder.stop(); }

        function mediaToggle(): void { Media.toggle(); }
        function mediaNext():   void { Media.next(); }
        function mediaPrev():   void { Media.prev(); }

        function overviewStep(d: int): void { ShellState.stepOverview(d); }
        function overviewActivate(): void { ShellState.activateOverview(); }

        function overview(): void {
            if (ShellState.panel === "overview") ShellState.close(); else ShellState.overviewOpen();
        }

        function switchOpen(): void { ShellState.switchOpen(); }
        function switchNext(): void { ShellState.switchStep(1); }
        function switchPrev(): void { ShellState.switchStep(-1); }
        function switchCommit(): void { ShellState.switchCommit(); }
        function switchCancel(): void { ShellState.switchCancel(); }
    }
}
