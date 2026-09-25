import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Widgets

PanelWindow {
    id: bar

    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource
    property var battery: UPower.displayDevice
    property var hardware

    function formatClock(date, includeSeconds) {
        const hour = date.getHours() % 12 || 12;
        const minute = date.getMinutes().toString().padStart(2, "0");
        const second = date.getSeconds().toString().padStart(2, "0");
        return hour + ":" + minute + (includeSeconds ? ":" + second : "");
    }

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

        Row {
            height: parent.height
            spacing: 0

            Repeater {
                model: Hyprland.workspaces

                Rectangle {
                    id: workspaceButton

                    required property var modelData
                    property bool active: modelData.active

                    visible: modelData.id > 0
                    width: Theme.blockHeight + 2
                    height: parent.height
                    color: modelData.urgent ? Theme.urgent
                        : active ? Theme.primary : "transparent"

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: Theme.activeLineWidth
                        color: workspaceButton.active ? Theme.accent : "transparent"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.id === 2 ? "\uf120"
                            : modelData.id === 13 ? "\uf001" : modelData.name
                        color: Theme.foreground
                        font.family: Theme.iconFontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached([
                            "hyprctl",
                            "dispatch",
                            "hl.dsp.focus({ workspace = " + workspaceButton.modelData.id + " })"
                        ])
                    }
                }
            }
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

        Block {
            id: audioBlock
            blockColor: bar.sink && bar.sink.audio && bar.sink.audio.muted
                ? Theme.foreground : Theme.primary
            textColor: bar.sink && bar.sink.audio && bar.sink.audio.muted
                ? Theme.foregroundDark : Theme.foreground
            interactive: true
            text: {
                if (!bar.sink || !bar.sink.audio)
                    return "\uf026";
                return bar.sink.audio.muted
                    ? "\uf026" : "\uf028 " + Math.round(bar.sink.audio.volume * 100) + "%";
            }
            secondaryIcon: bar.source && bar.source.audio
                ? (bar.source.audio.muted
                    ? "file://" + Quickshell.shellPath("icons/microphone-muted.svg")
                    : "file://" + Quickshell.shellPath("icons/microphone.svg"))
                : ""
            secondaryText: bar.source && bar.source.audio
                ? (bar.source.audio.muted ? "OFF"
                    : Math.round(bar.source.audio.volume * 100) + "%")
                : ""
            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton)
                    detailsPopup.toggle("audio", audioBlock);
                else if (mouse.button === Qt.MiddleButton && bar.sink && bar.sink.audio)
                    bar.sink.audio.muted = !bar.sink.audio.muted;
                else
                    Quickshell.execDetached(["qjackctl"]);
            }
            onWheel: wheel => {
                if (!bar.sink || !bar.sink.audio)
                    return;
                const change = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                bar.sink.audio.volume = Math.max(0, Math.min(1.5,
                    bar.sink.audio.volume + change));
            }
        }

        Network {
            service: bar.hardware
            onDetailsRequested: anchorItem => detailsPopup.toggle("network", anchorItem)
        }
        Backlight { service: bar.hardware }

        Block {
            id: batteryBlock
            property int percentage: Math.round(bar.battery.percentage * 100)

            visible: bar.battery.ready && bar.battery.isLaptopBattery
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
            onClicked: detailsPopup.toggle("battery", batteryBlock)
        }

        Rectangle {
            visible: trayRepeater.count > 0
            implicitWidth: trayItems.implicitWidth + Theme.contentPadding * 2
            implicitHeight: Theme.blockHeight
            color: Theme.primary

            Row {
                id: trayItems
                anchors.centerIn: parent
                spacing: Theme.contentPadding

                Repeater {
                    id: trayRepeater
                    model: SystemTray.items

                    Item {
                        id: trayItem

                        required property var modelData
                        width: 26
                        height: 30

                        IconImage {
                            anchors {
                                fill: parent
                                margins: 3
                            }
                            source: trayItem.modelData.icon
                            opacity: trayMouse.containsMouse ? 1 : 0.82

                            Behavior on opacity {
                                NumberAnimation { duration: 120 }
                            }
                        }

                        MouseArea {
                            id: trayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.MiddleButton)
                                    trayItem.modelData.secondaryActivate();
                                else if (mouse.button === Qt.RightButton || trayItem.modelData.onlyMenu) {
                                    const point = mapToItem(bar.contentItem, 0, height);
                                    trayItem.modelData.display(bar, point.x, point.y);
                                } else {
                                    trayItem.modelData.activate();
                                }
                            }
                            onWheel: wheel => trayItem.modelData.scroll(
                                wheel.angleDelta.y, false)
                        }
                    }
                }
            }
        }

        Block {
            id: clockBlock
            property bool showSeconds: false

            interactive: true
            text: bar.formatClock(clock.date, showSeconds)
            onClicked: detailsPopup.toggle("clock", clockBlock)
            onDoubleClicked: showSeconds = !showSeconds
        }
    }
}
