import QtQuick
import QtQuick.Layouts
import qs
import qs.ui

Rectangle {
    id: root
    property string label: ""
    property string detail: ""
    property bool highlight: false
    property bool hasToggle: false
    property bool toggled: false
    signal clicked()
    signal switched()

    property bool navigable: true
    property bool navSelected: false
    function navActivate() { if (root.hasToggle) root.switched(); else root.clicked(); }

    Layout.fillWidth: true
    implicitHeight: 38
    radius: Theme.radius
    color: root.navSelected ? Theme.surfaceHi
         : ma.containsMouse  ? Theme.surface : "transparent"

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.pad
        anchors.rightMargin: Theme.pad
        spacing: Theme.pad
        Text {
            Layout.fillWidth: true
            text: root.label
            color: root.highlight ? Theme.accent : Theme.text
            font.family: Theme.font; font.pixelSize: Theme.fontSize
            elide: Text.ElideRight
        }
        Text {
            visible: !root.hasToggle
            text: root.detail
            color: Theme.textDim
            font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
            Layout.maximumWidth: root.width * 0.62
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
        }
        Toggle {
            visible: root.hasToggle
            checked: root.toggled
            onToggled: root.switched()
        }
    }
}
