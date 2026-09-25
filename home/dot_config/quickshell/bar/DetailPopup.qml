import QtQuick
import Quickshell
import Quickshell.Services.UPower

PopupWindow {
    id: root

    property var hardware
    property var sink
    property var source
    property var battery
    property var clock
    property var anchorItem: null
    property string page: ""

    function toggle(nextPage, item) {
        if (visible && page === nextPage) {
            visible = false;
            return;
        }
        page = nextPage;
        anchorItem = item;
        if (page === "network")
            hardware.refreshWifi();
        anchor.updateAnchor();
        visible = true;
    }

    function duration(seconds) {
        if (seconds <= 0)
            return "Calculating";
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return hours + "h " + minutes + "m";
    }

    function batteryState() {
        switch (battery.state) {
        case UPowerDeviceState.Charging: return "Charging";
        case UPowerDeviceState.Discharging: return "Discharging";
        case UPowerDeviceState.FullyCharged: return "Fully charged";
        case UPowerDeviceState.Empty: return "Empty";
        case UPowerDeviceState.PendingCharge: return "Waiting to charge";
        case UPowerDeviceState.PendingDischarge: return "Waiting to discharge";
        default: return "Unknown";
        }
    }

    visible: false
    implicitWidth: Theme.popupWidth
    implicitHeight: contentLoader.item
        ? contentLoader.item.implicitHeight + Theme.popupPadding * 2 : 100
    color: "transparent"

    anchor {
        item: root.anchorItem
        edges: Edges.Bottom | Edges.Right
        gravity: Edges.Bottom | Edges.Left
        margins.top: 4
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.popupBackground

        Loader {
            id: contentLoader
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Theme.popupPadding
            }
            sourceComponent: root.page === "clock" ? clockPage
                : root.page === "audio" ? audioPage
                : root.page === "network" ? networkPage
                : batteryPage
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: Theme.activeLineWidth
            color: Theme.accent
        }
    }

    Component {
        id: clockPage

        Item {
            id: clockContent
            property date now: root.clock.date
            property int year: now.getFullYear()
            property int month: now.getMonth()
            property int firstDay: new Date(year, month, 1).getDay()
            property int days: new Date(year, month + 1, 0).getDate()

            implicitWidth: Theme.popupContentWidth
            implicitHeight: 310

            PopupHeader {
                width: parent.width
                text: Qt.formatDateTime(parent.now, "dddd, MMMM d")
            }

            Text {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: 40
                }
                text: Qt.formatDateTime(parent.now, "h:mm:ss AP")
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontClock
            }

            Row {
                anchors {
                    left: parent.left
                    top: parent.top
                    topMargin: 86
                }
                spacing: 4

                Repeater {
                    model: ["S", "M", "T", "W", "T", "F", "S"]
                    Text {
                        required property string modelData
                        width: 37
                        text: modelData
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        horizontalAlignment: Text.AlignHCenter
                        font.bold: true
                    }
                }
            }

            Grid {
                anchors {
                    left: parent.left
                    top: parent.top
                    topMargin: 112
                }
                columns: 7
                spacing: 4

                Repeater {
                    model: 42

                    Rectangle {
                        required property int index
                        property int day: index - clockContent.firstDay + 1
                        property bool today: day === clockContent.now.getDate()

                        width: 37
                        height: 29
                        radius: 0
                        color: today ? Theme.primary : "transparent"

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }
                            height: Theme.activeLineWidth
                            visible: parent.today
                            color: Theme.accent
                        }

                        Text {
                            anchors.centerIn: parent
                            text: parent.day > 0 && parent.day <= clockContent.days
                                ? parent.day : ""
                            color: Theme.foreground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                        }
                    }
                }
            }
        }
    }

    Component {
        id: audioPage

        Column {
            width: Theme.popupContentWidth
            spacing: 12

            PopupHeader {
                width: parent.width
                text: "Audio"
            }

            PopupSlider {
                width: parent.width
                label: "Output"
                value: root.sink && root.sink.audio ? root.sink.audio.volume : 0
                muted: root.sink && root.sink.audio ? root.sink.audio.muted : false
                onValueRequested: value => {
                    if (root.sink && root.sink.audio)
                        root.sink.audio.volume = value;
                }
                onMuteRequested: {
                    if (root.sink && root.sink.audio)
                        root.sink.audio.muted = !root.sink.audio.muted;
                }
            }

            PopupSlider {
                width: parent.width
                label: "Microphone"
                value: root.source && root.source.audio ? root.source.audio.volume : 0
                muted: root.source && root.source.audio ? root.source.audio.muted : false
                onValueRequested: value => {
                    if (root.source && root.source.audio)
                        root.source.audio.volume = value;
                }
                onMuteRequested: {
                    if (root.source && root.source.audio)
                        root.source.audio.muted = !root.source.audio.muted;
                }
            }
        }
    }

    Component {
        id: networkPage

        Column {
            width: Theme.popupContentWidth
            spacing: 10

            PopupHeader {
                width: parent.width
                text: "Network"
            }

            Text {
                text: "Connected to " + root.hardware.connection
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
            }

            Column {
                id: networks
                width: parent.width
                spacing: 5

                Repeater {
                    model: root.hardware.wifiNetworks

                    Rectangle {
                        required property var modelData
                        width: networks.width
                        height: 29
                        radius: 0
                        color: modelData.active ? Theme.primary : Theme.background

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }
                            height: Theme.activeLineWidth
                            visible: parent.modelData.active
                            color: Theme.accent
                        }

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: 9
                                verticalCenter: parent.verticalCenter
                            }
                            width: parent.width - 70
                            elide: Text.ElideRight
                            text: modelData.ssid
                            color: Theme.foreground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                        }

                        Text {
                            anchors {
                                right: parent.right
                                rightMargin: 9
                                verticalCenter: parent.verticalCenter
                            }
                            text: modelData.signal + "%"
                            color: Theme.foreground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 30
                radius: 0
                color: Theme.primary

                Text {
                    anchors.centerIn: parent
                    text: "Open network settings"
                    color: Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["nm-connection-editor"])
                }
            }
        }
    }

    Component {
        id: batteryPage

        Column {
            width: Theme.popupContentWidth
            spacing: 12

            PopupHeader {
                width: parent.width
                text: "Battery"
            }

            Text {
                text: Math.round(root.battery.percentage * 100) + "%  "
                    + root.batteryState()
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontDisplay
            }

            Rectangle {
                width: parent.width
                height: 8
                radius: 0
                color: Theme.track

                Rectangle {
                    width: parent.width * root.battery.percentage
                    height: parent.height
                    radius: 0
                    color: root.battery.percentage <= 0.15 ? Theme.urgent : Theme.primary
                }
            }

            Text {
                text: UPower.onBattery
                    ? "Remaining: " + root.duration(root.battery.timeToEmpty)
                    : "Until full: " + root.duration(root.battery.timeToFull)
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
            }

            Text {
                text: "Rate: " + Math.abs(root.battery.changeRate).toFixed(1) + " W"
                    + (root.battery.healthSupported
                        ? "    Health: " + Math.round(root.battery.healthPercentage * 100) + "%"
                        : "")
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
            }
        }
    }
}
