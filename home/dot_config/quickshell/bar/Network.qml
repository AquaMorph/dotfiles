import QtQuick
import Quickshell

Block {
    id: root

    required property var service
    property bool connected: service.connection !== "Disconnected"

    blockColor: connected ? "#2980b9" : "#e91e63"
    interactive: true
    text: connected ? "\uf1eb  " + service.connection : "Disconnected !"
    onClicked: Quickshell.execDetached(["nm-connection-editor"])
}
