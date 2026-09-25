import QtQuick

Item {
    id: root

    property string label: ""
    property real value: 0
    property bool muted: false
    signal valueRequested(real value)
    signal muteRequested()

    implicitWidth: 280
    implicitHeight: 58

    Text {
        anchors.left: parent.left
        text: root.label
        color: "#ffffff"
        font.family: "SF Pro Display, Helvetica, Arial, sans-serif"
        font.pixelSize: 15
    }

    Rectangle {
        anchors {
            right: parent.right
            top: parent.top
        }
        width: 58
        height: 24
        radius: 0
        color: root.muted ? "#e91e63" : "#0288d1"

        Text {
            anchors.centerIn: parent
            text: root.muted ? "MUTED" : Math.round(root.value * 100) + "%"
            color: "#ffffff"
            font.pixelSize: 11
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.muteRequested()
        }
    }

    Rectangle {
        id: track
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 8
        radius: 0
        color: "#40000000"

        Rectangle {
            width: Math.min(parent.width, parent.width * root.value / 1.5)
            height: parent.height
            radius: 0
            color: root.muted ? "#e91e63" : "#0288d1"
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            function updateValue(mouse) {
                root.valueRequested(Math.max(0,
                    Math.min(1.5, mouse.x / width * 1.5)));
            }

            onPressed: mouse => updateValue(mouse)
            onPositionChanged: mouse => {
                if (pressed)
                    updateValue(mouse);
            }
        }
    }
}
