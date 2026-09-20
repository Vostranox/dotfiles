import QtQuick
import qs

Item {
    id: root
    property bool checked: false
    signal toggled()

    implicitWidth: 40
    implicitHeight: 22

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.accent : Theme.surface
        border.color: root.checked ? Theme.accent : Theme.border
        border.width: 1
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    Rectangle {
        id: knob
        y: 3
        x: root.checked ? root.width - width - 3 : 3
        width: root.height - 6
        height: width
        radius: height / 2
        color: root.checked ? Theme.bg : Theme.textDim
        Behavior on x     { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuint } }
        Behavior on color { ColorAnimation  { duration: Theme.animFast } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
