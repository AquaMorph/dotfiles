import QtQuick
import Quickshell.I3

Row {
    spacing: 0

    Repeater {
        model: I3.workspaces

        Rectangle {
            id: workspaceButton

            required property var modelData
            property bool active: modelData.active

            visible: modelData.number > 0
            width: visible ? Theme.blockHeight + 2 : 0
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
                text: modelData.number === 2 ? "\uf120"
                    : modelData.number === 13 ? "\uf001" : modelData.name
                color: Theme.foreground
                font.family: Theme.iconFontFamily
                font.pixelSize: Theme.fontSize
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: workspaceButton.modelData.activate()
            }
        }
    }
}
