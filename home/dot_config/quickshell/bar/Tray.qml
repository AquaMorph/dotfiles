import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Rectangle {
    id: root

    required property var barWindow

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
                        if (mouse.button === Qt.MiddleButton) {
                            trayItem.modelData.secondaryActivate();
                        } else if (mouse.button === Qt.RightButton || trayItem.modelData.onlyMenu) {
                            const point = mapToItem(root.barWindow.contentItem, 0, height);
                            trayItem.modelData.display(root.barWindow, point.x, point.y);
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
