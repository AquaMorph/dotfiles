import QtQuick
import Quickshell
import Quickshell.Io

Block {
    id: root

    property string connection: "Disconnected"
    property bool connected: connection !== "Disconnected"

    blockColor: connected ? "#2980b9" : "#e91e63"
    interactive: true
    text: connected ? "\uf1eb  " + connection : "Disconnected !"
    onClicked: Quickshell.execDetached(["nm-connection-editor"])

    Process {
        id: networkQuery
        command: ["nmcli", "-t", "-f", "TYPE,NAME", "connection", "show", "--active"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                for (let line of lines) {
                    const separator = line.indexOf(":");
                    const type = line.slice(0, separator);
                    if (type === "802-11-wireless" || type === "wifi") {
                        root.connection = line.slice(separator + 1);
                        return;
                    }
                }
                for (let line of lines) {
                    const separator = line.indexOf(":");
                    const type = line.slice(0, separator);
                    if (type === "802-3-ethernet" || type === "ethernet") {
                        root.connection = line.slice(separator + 1);
                        return;
                    }
                }
                root.connection = "Disconnected";
            }
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: networkQuery.running = true
    }
}
