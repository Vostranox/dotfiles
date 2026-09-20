import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs

PanelWindow {
    id: win

    required property var modelData
    screen: modelData
    visible: ShellState.switcherOpen

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-switcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    readonly property var apps: ShellState.switcherApps
    readonly property int selected: ShellState.switcherIndex
    function commit() { ShellState.switchCommit(); }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(row.implicitWidth + Theme.pad * 4, win.width - 80)
        height: row.implicitHeight + Theme.pad * 4
        radius: Theme.radius * 2
        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.92)
        border.color: Theme.border
        border.width: 1
        visible: win.apps.length > 0

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: Theme.pad

            Repeater {
                model: win.apps
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool active: index === win.selected

                    implicitWidth: 96
                    implicitHeight: 96
                    radius: Theme.radius * 1.5
                    color: active ? Theme.surfaceHi : "transparent"
                    border.color: active ? Theme.accent : "transparent"
                    border.width: 2

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 52
                            Layout.preferredHeight: 52
                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 52
                                source: Apps.appIcon(modelData)
                                visible: source !== ""
                            }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: 84
                            text: Apps.appName(modelData)
                            color: active ? Theme.text : Theme.textDim
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { ShellState.switcherIndex = index; win.commit(); }
                    }
                }
            }
        }
    }
}
