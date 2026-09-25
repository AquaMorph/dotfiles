import QtQuick
import Quickshell

Block {
    id: root

    required property var sink
    required property var source
    signal detailsRequested(var anchorItem)

    blockColor: sink && sink.audio && sink.audio.muted
        ? Theme.foreground : Theme.primary
    textColor: sink && sink.audio && sink.audio.muted
        ? Theme.foregroundDark : Theme.foreground
    interactive: true
    text: {
        if (!sink || !sink.audio)
            return "\uf026";
        return sink.audio.muted
            ? "\uf026" : "\uf028 " + Math.round(sink.audio.volume * 100) + "%";
    }
    secondaryIcon: source && source.audio
        ? (source.audio.muted
            ? "file://" + Quickshell.shellPath("icons/microphone-muted.svg")
            : "file://" + Quickshell.shellPath("icons/microphone.svg"))
        : ""
    secondaryText: source && source.audio
        ? (source.audio.muted ? "OFF"
            : Math.round(source.audio.volume * 100) + "%")
        : ""

    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton)
            detailsRequested(root);
        else if (mouse.button === Qt.MiddleButton && sink && sink.audio)
            sink.audio.muted = !sink.audio.muted;
        else
            Quickshell.execDetached(["qjackctl"]);
    }

    onWheel: wheel => {
        if (!sink || !sink.audio)
            return;
        const change = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
        sink.audio.volume = Math.max(0, Math.min(1.5,
            sink.audio.volume + change));
    }
}
