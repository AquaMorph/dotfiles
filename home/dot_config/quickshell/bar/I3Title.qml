import QtQuick
import Quickshell.I3
import Quickshell.Io

Text {
    id: root

    function focusedTitle(node) {
        for (const child of (node.nodes || []).concat(node.floating_nodes || [])) {
            const title = focusedTitle(child);
            if (title)
                return title;
        }
        return node.focused && node.type === "con" ? node.name || "" : "";
    }

    elide: Text.ElideRight
    horizontalAlignment: Text.AlignHCenter
    color: Theme.foreground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    Connections {
        target: I3
        function onRawEvent(event) {
            if ((event.type === "window" || event.type === "workspace") && !treeQuery.running)
                treeQuery.running = true;
        }
    }

    Process {
        id: treeQuery
        command: ["i3-msg", "-t", "get_tree"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.text = root.focusedTitle(JSON.parse(text))
        }
    }
}
