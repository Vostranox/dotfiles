import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs

RowLayout {
    id: root
    spacing: Theme.gap

    readonly property var wss: Hyprland.workspaces
    readonly property int focused: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1

    Repeater {
        model: 5
        delegate: Rectangle {
            required property int index
            readonly property int wsId: index + 1
            readonly property bool active: root.focused === wsId
            readonly property bool populated: {
                const v = root.wss ? root.wss.values : [];
                for (const w of v) if (w.id === wsId) return true;
                return false;
            }

            implicitWidth: active ? 26 : 12
            implicitHeight: 6
            radius: 3
            color: active ? Theme.accent : (populated ? Theme.textDim : Theme.surface)
            Layout.alignment: Qt.AlignVCenter

            Behavior on implicitWidth { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutQuint } }
            Behavior on color        { ColorAnimation  { duration: Theme.animFast } }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + parent.wsId + " })")
            }
        }
    }
}
