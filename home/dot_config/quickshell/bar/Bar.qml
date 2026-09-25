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

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 38
    color: "#80000000"

    PwObjectTracker {
        objects: [bar.sink, bar.source]
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Row {
        id: leftModules
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        spacing: 8

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
                    width: 34
                    height: parent.height
                    color: modelData.urgent ? "#e91e63"
                        : active ? "#0288d1" : "transparent"

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: 3
                        color: workspaceButton.active ? "#b3e5fc" : "transparent"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.id === 2 ? "\uf120"
                            : modelData.id === 13 ? "\uf001" : modelData.name
                        color: "#ffffff"
                        font.family: "SF Pro Display, Font Awesome 6 Free"
                        font.pixelSize: 18
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
            parent.width - leftModules.width - rightModules.width - 32))
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
        color: "#ffffff"
        font.family: "SF Pro Display, Helvetica, Arial, sans-serif"
        font.pixelSize: 18
    }

    Row {
        id: rightModules
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            rightMargin: 4
        }
        spacing: 8

        Block {
            id: audioBlock
            blockColor: bar.sink && bar.sink.audio && bar.sink.audio.muted
                ? "#ffffff" : "#0288d1"
            textColor: bar.sink && bar.sink.audio && bar.sink.audio.muted
                ? "#000000" : "#ffffff"
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
                if (mouse.button === Qt.MiddleButton && bar.sink && bar.sink.audio)
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

        Network {}
        Backlight {}

        Block {
            property int percentage: Math.round(bar.battery.percentage * 100)

            visible: bar.battery.ready && bar.battery.isLaptopBattery
            blockColor: percentage <= 15 && UPower.onBattery
                ? "#e91e63" : UPower.onBattery ? "#ffffff" : "#2980b9"
            textColor: UPower.onBattery && percentage > 15
                ? "#000000" : "#ffffff"
            text: {
                if (!UPower.onBattery)
                    return "\uf1e6  " + percentage + "%";
                if (percentage <= 10) return "\uf244  " + percentage + "%";
                if (percentage <= 35) return "\uf243  " + percentage + "%";
                if (percentage <= 60) return "\uf242  " + percentage + "%";
                if (percentage <= 85) return "\uf241  " + percentage + "%";
                return "\uf240  " + percentage + "%";
            }
        }

        Rectangle {
            visible: trayRepeater.count > 0
            implicitWidth: trayItems.implicitWidth + 20
            implicitHeight: 32
            color: "#0288d1"

            Row {
                id: trayItems
                anchors.centerIn: parent
                spacing: 10

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
            property bool detailed: false

            interactive: true
            text: Qt.formatDateTime(clock.date,
                detailed ? "yyyy-MM-dd hh:mm:ss" : "hh:mm")
            onClicked: detailed = !detailed
        }
    }
}
