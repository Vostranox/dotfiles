import QtQuick
import qs

Item {
    id: root
    property real value: 0
    signal moved(real v)
    implicitHeight: 18

    property bool navigable: true
    property bool navSelected: false
    function clamp(v)    { return Math.max(0, Math.min(1, v)); }
    function navLeft()   { root.moved(root.clamp(root.value - 0.05)); }
    function navRight()  { root.moved(root.clamp(root.value + 0.05)); }
    function navActivate() {}

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width; height: 5; radius: 3
        color: Theme.surface
        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: parent.height; radius: 3
            color: Theme.accent
        }
    }
    Rectangle {
        x: (parent.width - width) * Math.max(0, Math.min(1, root.value))
        anchors.verticalCenter: parent.verticalCenter
        width: root.navSelected ? 18 : 14
        height: width; radius: height / 2
        color: root.navSelected ? Theme.accent : Theme.text
    }
    MouseArea {
        anchors.fill: parent
        onPressed:        (m) => root.moved(Math.max(0, Math.min(1, m.x / width)))
        onPositionChanged:(m) => { if (pressed) root.moved(Math.max(0, Math.min(1, m.x / width))); }
    }
}
