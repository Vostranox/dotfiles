import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    visible: ShellState.osdVisible

    anchors { left: true; right: true; bottom: true }
    implicitHeight: 160
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        width: 320
        height: 64
        radius: Theme.radius * 2
        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.95)
        border.color: Theme.border
        border.width: 1
        opacity: ShellState.osdVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.pad * 1.5
            anchors.rightMargin: Theme.pad * 1.5
            spacing: Theme.pad

            Text {
                text: ShellState.osdIcon
                color: ShellState.osdMuted ? Theme.textDim : Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 10
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 6
                radius: 3
                color: Theme.surface
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, ShellState.osdValue))
                    height: parent.height
                    radius: 3
                    color: ShellState.osdMuted ? Theme.textDim : Theme.accent
                    Behavior on width { NumberAnimation { duration: Theme.animFast } }
                }
            }

            Text {
                text: ShellState.osdMuted ? "off" : Math.round(ShellState.osdValue * 100) + "%"
                color: Theme.textDim
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                Layout.minimumWidth: 38
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
