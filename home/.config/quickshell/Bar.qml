import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.bar
import qs

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    visible: ShellState.barVisible
    implicitHeight: Theme.barHeight
    exclusiveZone: ShellState.barVisible ? Theme.barHeight : 0
    color: "transparent"

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qs-bar"

    PopupWindow {
        id: tip
        anchor.window: bar
        anchor.rect.x: Math.round(Math.max(8, Math.min(bar.width - width - 8, ShellState.tipX - width / 2)))
        anchor.rect.y: Theme.barHeight + 4
        implicitWidth: tipText.implicitWidth + Theme.pad * 2
        implicitHeight: tipText.implicitHeight + Theme.gap * 1.5
        visible: ShellState.tipVisible && ShellState.tipText !== "" && ShellState.barVisible
        color: "transparent"
        mask: Region {}

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.surface
            border.color: Theme.border
            border.width: 1
            Text {
                id: tipText
                anchors.centerIn: parent
                text: ShellState.tipText
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 1
            color: Theme.surface
        }

        Workspaces {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: Theme.pad * 1.6 }
        }

        Clock { anchors.centerIn: parent }

        RowLayout {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: Theme.pad }
            spacing: Theme.pad * 1.4

            Status {}

            Rectangle {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignVCenter
                radius: Theme.radius
                color: ShellState.panel === "control" ? Theme.surfaceHi
                     : cc.containsMouse ? Theme.surface : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: "󰅀"
                    color: ShellState.panel === "control" ? Theme.accent : Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 3
                }
                MouseArea {
                    id: cc
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellState.toggle("control")
                }
            }
        }
    }
}
