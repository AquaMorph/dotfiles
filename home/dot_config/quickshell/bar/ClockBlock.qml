Block {
    id: root

    required property var clock
    property bool showSeconds: false
    signal detailsRequested(var anchorItem)

    function formattedTime() {
        const date = clock.date;
        const hour = date.getHours() % 12 || 12;
        const minute = date.getMinutes().toString().padStart(2, "0");
        const second = date.getSeconds().toString().padStart(2, "0");
        return hour + ":" + minute + (showSeconds ? ":" + second : "");
    }

    interactive: true
    text: formattedTime()
    onClicked: detailsRequested(root)
    onDoubleClicked: showSeconds = !showSeconds
}
