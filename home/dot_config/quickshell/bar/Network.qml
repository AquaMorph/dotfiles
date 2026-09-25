import QtQuick
import Quickshell

Block {
    id: root

    required property var service
    property bool connected: service.connection !== "Disconnected"
    signal detailsRequested(var anchorItem)

    blockColor: connected ? "#2980b9" : "#e91e63"
    interactive: true
    text: connected ? "\uf1eb  " + service.connection : "Disconnected !"
    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton)
            detailsRequested(root);
        else
            Quickshell.execDetached(["nm-connection-editor"]);
    }
}
