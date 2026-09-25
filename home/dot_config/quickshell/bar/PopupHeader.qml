import QtQuick

Rectangle {
    id: root

    property string text: ""

    implicitHeight: Theme.blockHeight
    color: Theme.primary

    Text {
        anchors {
            left: parent.left
            leftMargin: Theme.contentPadding
            verticalCenter: parent.verticalCenter
        }
        text: root.text
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
    }
}
