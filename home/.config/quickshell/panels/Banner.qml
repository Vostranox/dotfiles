import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    visible: Notifications.banners.length > 0

    anchors { top: true; left: true; right: true }
    implicitHeight: 200
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-banner"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: stack }

    ColumnLayout {
        id: stack
        anchors {
            top: parent.top; horizontalCenter: parent.horizontalCenter
            topMargin: (ShellState.barVisible ? Theme.barHeight : 0) + Theme.gap
        }
        width: 420
        spacing: Theme.gap

        Repeater {
            model: Notifications.banners
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: brow.implicitHeight + Theme.pad * 2
                radius: Theme.radius * 1.6
                color: Theme.bg
                border.color: Theme.urgent
                border.width: 1

                RowLayout {
                    id: brow
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                              leftMargin: Theme.pad * 1.4; rightMargin: Theme.pad * 1.4 }
                    spacing: Theme.pad

                    IconImage {
                        Layout.alignment: Qt.AlignTop
                        implicitSize: 28
                        source: modelData.image !== "" ? modelData.image
                              : Quickshell.iconPath(modelData.icon, true)
                        visible: source !== ""
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: modelData.summary
                            color: Theme.urgent
                            font.family: Theme.font; font.pixelSize: Theme.fontSize
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: modelData.body
                            color: Theme.text
                            font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.ack(modelData)
                    onDoubleClicked: Notifications.activate(modelData)
                }
            }
        }
    }
}
