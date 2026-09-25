import QtQuick
import Quickshell
import Quickshell.Io

Block {
    id: root

    property int percentage: -1

    visible: percentage >= 0
    blockColor: "#2980b9"
    interactive: true
    text: "\uf185  " + percentage + "%"
    onWheel: wheel => {
        const change = wheel.angleDelta.y > 0 ? "+5%" : "5%-";
        Quickshell.execDetached(["brightnessctl", "set", change]);
        refreshTimer.restart();
    }

    Process {
        id: brightnessQuery
        command: ["brightnessctl", "-m"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(",");
                root.percentage = fields.length >= 4
                    ? parseInt(fields[3].replace("%", ""))
                    : -1;
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 500
        repeat: true
        running: true
        onTriggered: brightnessQuery.running = true
    }
}
