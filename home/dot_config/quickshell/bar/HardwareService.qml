import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property string connection: "Disconnected"
    property int brightness: -1
    property var wifiNetworks: []

    function setBrightness(change) {
        Quickshell.execDetached(["brightnessctl", "set", change]);
    }

    function refreshNetwork() {
        if (!networkQuery.running)
            networkQuery.running = true;
    }

    function refreshWifi() {
        if (!wifiQuery.running)
            wifiQuery.running = true;
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

    Process {
        id: networkMonitor
        command: ["nmcli", "monitor"]
        running: true

        stdout: SplitParser {
            onRead: {
                root.refreshNetwork();
                if (root.wifiNetworks.length > 0)
                    root.refreshWifi();
            }
        }

        onExited: networkRestart.start()
    }

    Timer {
        id: networkRestart
        interval: 1000
        onTriggered: networkMonitor.running = true
    }

    function updateBrightness() {
        if (!brightnessFile.loaded || !maximumBrightnessFile.loaded)
            return;
        const current = parseInt(brightnessFile.text().trim());
        const maximum = parseInt(maximumBrightnessFile.text().trim());
        root.brightness = maximum > 0 && !isNaN(current)
            ? Math.round(current / maximum * 100) : -1;
    }

    FileView {
        id: brightnessFile
        path: "file:///sys/class/backlight/intel_backlight/brightness"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.updateBrightness()
    }

    FileView {
        id: maximumBrightnessFile
        path: "file:///sys/class/backlight/intel_backlight/max_brightness"
        onLoaded: root.updateBrightness()
    }

    Process {
        id: wifiQuery
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL", "device", "wifi", "list", "--rescan", "auto"]

        stdout: StdioCollector {
            onStreamFinished: {
                const networks = [];
                const seen = {};
                for (let line of text.trim().split("\n")) {
                    const fields = line.split(":");
                    if (fields.length < 3)
                        continue;
                    const active = fields.shift() === "*";
                    const signal = parseInt(fields.pop());
                    const ssid = fields.join(":").replace(/\\:/g, ":");
                    if (!ssid || seen[ssid])
                        continue;
                    seen[ssid] = true;
                    networks.push({
                        "ssid": ssid,
                        "signal": signal,
                        "active": active
                    });
                    if (networks.length >= 8)
                        break;
                }
                root.wifiNetworks = networks;
            }
        }
    }
}
