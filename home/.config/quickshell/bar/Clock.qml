import QtQuick
import Quickshell
import qs

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 9; height: 9; radius: 4.5
            visible: Recorder.active
            color: Theme.urgent
            SequentialAnimation on opacity {
                running: Recorder.active
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 900 }
                NumberAnimation { to: 1.0; duration: 900 }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            SystemClock { id: clock; precision: SystemClock.Minutes }
            Connections {
                target: ShellState
                function onResumed() { clock.enabled = false; clock.enabled = true; }
            }
            text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
            color: ShellState.panel === "notifications" ? Theme.accent : Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 7; height: 7; radius: 3.5
            visible: Notifications.count > 0
            color: Notifications.unreadCritical > 0 ? Theme.urgent
                 : Notifications.hasUnread          ? Theme.accent
                                                    : Theme.textDim
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Recorder.active ? Recorder.stop() : ShellState.toggle("notifications", QsWindow.window.screen.name)
    }
}
