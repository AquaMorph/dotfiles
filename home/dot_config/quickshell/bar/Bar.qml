import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

PanelWindow {
    id: bar

    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource
    property var battery: UPower.displayDevice
    property var hardware
    property bool isWayland: Quickshell.env("XDG_SESSION_TYPE") === "wayland"
        || Quickshell.env("WAYLAND_DISPLAY") !== ""

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
            verticalCenter: parent.verticalCenter
        }
        height: Theme.blockHeight
        spacing: Theme.moduleSpacing

        Loader {
            height: parent.height
            source: bar.isWayland ? "Workspaces.qml" : "I3Workspaces.qml"
        }
    }

    Loader {
        anchors.centerIn: parent
        width: Math.max(0, Math.min(implicitWidth,
            parent.width - leftModules.width - rightModules.width - Theme.blockHeight))
        source: bar.isWayland ? "HyprlandTitle.qml" : "I3Title.qml"
    }

    Row {
        id: rightModules
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
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
