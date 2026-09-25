import QtQuick
import Quickshell.Widgets

Rectangle {
    id: root

    property color blockColor: Theme.primary
    property color textColor: Theme.foreground
    property bool interactive: false
    property string text: ""
    property string fontFamily: Theme.iconFontFamily
    property string secondaryIcon: ""
    property string secondaryText: ""
    signal clicked(var mouse)
    signal doubleClicked(var mouse)
    signal wheel(var wheel)

    implicitWidth: content.implicitWidth + Theme.contentPadding * 2
    implicitHeight: Theme.blockHeight
    color: blockColor

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 7

        Text {
            text: root.text
            color: root.textColor
            font.family: root.fontFamily
            font.pixelSize: Theme.fontSize
        }

        IconImage {
            width: 18
            height: 18
            anchors.verticalCenter: parent.verticalCenter
            visible: root.secondaryIcon !== ""
            source: root.secondaryIcon
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.secondaryText !== ""
            text: root.secondaryText
            color: root.textColor
            font.family: root.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => root.clicked(mouse)
        onDoubleClicked: mouse => root.doubleClicked(mouse)
        onWheel: wheel => root.wheel(wheel)
    }
}
