import QtQuick
import Quickshell
import Quickshell.Hyprland

Row {
    spacing: 0

    Repeater {
        model: Hyprland.workspaces

        Rectangle {
            id: workspaceButton

            required property var modelData
            property bool active: modelData.active

            visible: modelData.id > 0
            width: Theme.blockHeight + 2
            height: parent.height
            color: modelData.urgent ? Theme.urgent
                : active ? Theme.primary : "transparent"

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: Theme.activeLineWidth
                color: workspaceButton.active ? Theme.accent : "transparent"
            }

            Text {
                anchors.centerIn: parent
                text: modelData.id === 2 ? "\uf120"
                    : modelData.id === 13 ? "\uf001" : modelData.name
                color: Theme.foreground
                font.family: Theme.iconFontFamily
                font.pixelSize: Theme.fontSize
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached([
                    "hyprctl",
                    "dispatch",
                    "hl.dsp.focus({ workspace = " + workspaceButton.modelData.id + " })"
                ])
            }
        }
    }
}
