import QtQuick

Block {
    id: root

    required property var service

    visible: service.brightness >= 0
    blockColor: Theme.secondary
    interactive: true
    text: "\uf185  " + service.brightness + "%"
    onWheel: wheel => {
        const change = wheel.angleDelta.y > 0 ? "+5%" : "5%-";
        service.setBrightness(change);
    }
}
