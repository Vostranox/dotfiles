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

    readonly property int islandH: Theme.barHeight - Theme.gap
    readonly property int edge: 20

    anchors { top: true; left: true; right: true }
    visible: ShellState.barVisible
    implicitHeight: Theme.barHeight
    exclusiveZone: ShellState.barVisible ? Theme.barHeight : 0
    color: "transparent"

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qs-bar"

    mask: Region {
        Region { item: leftIsland }
        Region { item: centreIsland }
        Region { item: rightIsland }
    }

    PopupWindow {
        id: tip
        anchor.window: bar
        anchor.rect.x: Math.round(Math.max(8, Math.min(bar.width - width - 8, ShellState.tipX - width / 2)))
        anchor.rect.y: Theme.barHeight + Theme.gap
        implicitWidth: tipText.implicitWidth + Theme.pad * 2
        implicitHeight: tipText.implicitHeight + Theme.gap * 1.5
        visible: ShellState.tipVisible && ShellState.tipText !== "" && ShellState.barVisible
                 && ShellState.onScreen(ShellState.tipScreen, bar.modelData)
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

    component Island: Rectangle {
        y: Theme.gap
        implicitHeight: bar.islandH
        radius: Theme.radius
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
    }

    Island {
        id: leftIsland
        x: bar.edge
        implicitWidth: ws.implicitWidth + Theme.pad * 1.6
        Workspaces { id: ws; anchors.centerIn: parent }
    }

    Island {
        id: centreIsland
        x: Math.round((bar.width - width) / 2)
        implicitWidth: clk.implicitWidth + Theme.pad * 1.6
        Clock { id: clk; anchors.centerIn: parent }
    }

    Island {
        id: rightIsland
        readonly property int padL: 18
        readonly property int padR: Theme.gap

        x: bar.width - width - bar.edge
        implicitWidth: rightRow.implicitWidth + padL + padR

        RowLayout {
            id: rightRow
            anchors {
                left: parent.left
                leftMargin: rightIsland.padL
                verticalCenter: parent.verticalCenter
            }
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
                    onClicked: ShellState.toggle("control", bar.modelData.name)
                }
            }
        }
    }
}
