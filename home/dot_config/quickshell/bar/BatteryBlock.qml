import Quickshell.Services.UPower

Block {
    id: root

    required property var battery
    property int percentage: Math.round(battery.percentage * 100)
    signal detailsRequested(var anchorItem)

    visible: battery.ready && battery.isLaptopBattery
    interactive: true
    blockColor: percentage <= 15 && UPower.onBattery
        ? Theme.urgent : UPower.onBattery ? Theme.foreground : Theme.secondary
    textColor: UPower.onBattery && percentage > 15
        ? Theme.foregroundDark : Theme.foreground
    text: {
        if (!UPower.onBattery)
            return "\uf1e6  " + percentage + "%";
        if (percentage <= 10) return "\uf244  " + percentage + "%";
        if (percentage <= 35) return "\uf243  " + percentage + "%";
        if (percentage <= 60) return "\uf242  " + percentage + "%";
        if (percentage <= 85) return "\uf241  " + percentage + "%";
        return "\uf240  " + percentage + "%";
    }
    onClicked: detailsRequested(root)
}
