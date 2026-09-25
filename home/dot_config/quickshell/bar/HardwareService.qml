import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property string connection: "Disconnected"
    property int brightness: -1

    function setBrightness(change) {
        Quickshell.execDetached(["brightnessctl", "set", change]);
        brightnessRefresh.restart();
    }

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

    Process {
        id: brightnessQuery
        command: ["brightnessctl", "-m"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(",");
                root.brightness = fields.length >= 4
                    ? parseInt(fields[3].replace("%", ""))
                    : -1;
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: brightnessQuery.running = true
    }

    Timer {
        id: brightnessRefresh
        interval: 250
        onTriggered: brightnessQuery.running = true
    }
}
