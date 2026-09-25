import QtQuick

Rectangle {
    id: root

    property string text: ""

    implicitHeight: 32
    color: "#0288d1"

    Text {
        anchors {
            left: parent.left
            leftMargin: 10
            verticalCenter: parent.verticalCenter
        }
        text: root.text
        color: "#ffffff"
        font.family: "SF Pro Display, Helvetica, Arial, sans-serif"
        font.pixelSize: 18
        font.bold: true
    }
}
