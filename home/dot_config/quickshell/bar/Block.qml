import QtQuick

Rectangle {
    id: root

    property color blockColor: "#0288d1"
    property color textColor: "#ffffff"
    property bool interactive: false
    property string text: ""
    signal clicked(var mouse)
    signal wheel(var wheel)

    implicitWidth: label.implicitWidth + 20
    implicitHeight: 32
    color: blockColor

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.textColor
        font.family: "SF Pro Display, Font Awesome 6 Free"
        font.pixelSize: 18
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.wheel(wheel)
    }
}
