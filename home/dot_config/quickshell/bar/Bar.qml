import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

PanelWindow {
    id: bar

    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource
    property var battery: UPower.displayDevice
    property var hardware

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    color: Theme.background

    PwObjectTracker {
        objects: [bar.sink, bar.source]
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    DetailPopup {
        id: detailsPopup
        hardware: bar.hardware
        sink: bar.sink
        source: bar.source
        battery: bar.battery
        clock: clock
    }

    Row {
        id: leftModules
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        spacing: Theme.moduleSpacing

        Workspaces {
            height: parent.height
        }
    }

    Text {
        anchors.centerIn: parent
        width: Math.max(0, Math.min(implicitWidth,
            parent.width - leftModules.width - rightModules.width - Theme.blockHeight))
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }

    Row {
        id: rightModules
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            rightMargin: Theme.moduleSpacing / 2
        }
        spacing: Theme.moduleSpacing

        AudioBlock {
            sink: bar.sink
            source: bar.source
            onDetailsRequested: anchorItem => detailsPopup.toggle("audio", anchorItem)
        }

        Network {
            service: bar.hardware
            onDetailsRequested: anchorItem => detailsPopup.toggle("network", anchorItem)
        }
        Backlight { service: bar.hardware }

        BatteryBlock {
            battery: bar.battery
            onDetailsRequested: anchorItem => detailsPopup.toggle("battery", anchorItem)
        }

        Tray { barWindow: bar }

        ClockBlock {
            clock: clock
            onDetailsRequested: anchorItem => detailsPopup.toggle("clock", anchorItem)
        }
    }
}
