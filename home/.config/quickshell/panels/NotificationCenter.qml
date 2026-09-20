import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.ui

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    visible: ShellState.panel === "notifications"

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-notifications"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    KeyNav { id: nav; container: col }

    onVisibleChanged: {
        if (!visible) return;
        keys.forceActiveFocus();
        Notifications.markRead();
        nav.reset();
    }

    MouseArea { anchors.fill: parent; onClicked: ShellState.close() }

    FocusScope {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: (e) => {
            const cur = nav.current();
            switch (e.key) {
            case Qt.Key_Escape: ShellState.close(); break;
            case Qt.Key_Down:   nav.step(1);  break;
            case Qt.Key_Up:     nav.step(-1); break;
            case Qt.Key_Left:   ShellState.close(); break;
            case Qt.Key_Right:
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (cur) cur.navActivate();
                break;
            case Qt.Key_Delete:
            case Qt.Key_Backspace:
                if (cur && cur.navDismiss) cur.navDismiss();
                break;
            default: return;
            }
            e.accepted = true;
        }
    }

    Rectangle {
        id: card
        anchors {
            top: parent.top; horizontalCenter: parent.horizontalCenter
            topMargin: (ShellState.barVisible ? Theme.barHeight : 0) + Theme.gap
        }
        Behavior on anchors.topMargin { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuint } }
        width: 420
        height: Math.min(col.implicitHeight + Theme.pad * 2, win.height * 0.7)
        radius: Theme.radius * 1.6
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuint } }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.pad }
            spacing: Theme.gap

            Row {
                visible: Notifications.count > 0
                label: "Clear all"
                detail: Notifications.count + " notification" + (Notifications.count === 1 ? "" : "s")
                onClicked: Notifications.clearAll()
            }

            Rectangle { visible: Notifications.count > 0; Layout.fillWidth: true; height: 1; color: Theme.surface }

            Text {
                visible: Notifications.count === 0
                Layout.fillWidth: true
                Layout.margins: Theme.pad
                text: "No notifications"
                color: Theme.textDim
                horizontalAlignment: Text.AlignHCenter
                font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
            }

            Flickable {
                visible: Notifications.count > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(rows.implicitHeight, win.height * 0.7 - 110)
                contentHeight: rows.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: rows
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: Notifications.entries
                        delegate: Rectangle {
                            id: entry
                            required property var modelData

                            property bool navigable: true
                            property bool navSelected: false
                            function navActivate() {
                                const e = entry.modelData;
                                ShellState.close();
                                Notifications.activate(e);
                            }
                            function navDismiss()  { Notifications.dismiss(entry.modelData); }

                            Layout.fillWidth: true
                            implicitHeight: erow.implicitHeight + Theme.pad
                            radius: Theme.radius
                            color: entry.navSelected ? Theme.surfaceHi
                                 : ema.containsMouse ? Theme.surface : "transparent"

                            MouseArea {
                                id: ema
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: entry.navActivate()
                            }

                            RowLayout {
                                id: erow
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                                          leftMargin: Theme.pad; rightMargin: Theme.pad }
                                spacing: Theme.pad

                                IconImage {
                                    Layout.alignment: Qt.AlignTop
                                    implicitSize: 24
                                    source: entry.modelData.image !== "" ? entry.modelData.image
                                          : Quickshell.iconPath(entry.modelData.icon, true)
                                    visible: source !== ""
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        Layout.fillWidth: true
                                        text: entry.modelData.summary
                                        color: entry.modelData.critical ? Theme.urgent : Theme.text
                                        font.family: Theme.font; font.pixelSize: Theme.fontSize
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                        text: entry.modelData.body
                                        color: Theme.textDim
                                        font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                        textFormat: Text.PlainText
                                    }
                                    Text {
                                        visible: entry.modelData.appName !== ""
                                        text: entry.modelData.appName
                                        color: Theme.textDim
                                        font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                                    }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignTop
                                    text: "×"
                                    color: entry.navSelected || ema.containsMouse ? Theme.urgent : Theme.textDim
                                    font.family: Theme.font; font.pixelSize: Theme.fontSize + 2
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
