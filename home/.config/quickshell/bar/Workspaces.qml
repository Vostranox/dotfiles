import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs

RowLayout {
    id: root
    spacing: Theme.gap

    readonly property int focused: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
    readonly property var workspaces: {
        const v = Hyprland.workspaces ? Hyprland.workspaces.values : [];
        return v.filter(w => w.id > 0).sort((a, b) => a.id - b.id);
    }

    Repeater {
        model: root.workspaces
        delegate: Rectangle {
            required property var modelData
            readonly property bool active: root.focused === modelData.id
            readonly property bool populated: modelData.toplevels.values.length > 0

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
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + parent.modelData.id + " })")
            }
        }
    }
}
