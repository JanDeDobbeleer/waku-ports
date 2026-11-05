import QtQuick

// One drive: its letter, a bar of the space used, and the space free.
Item {
    id: root

    property string letter: ""
    property real used: 0          // 0..1
    property string freeText: ""
    property color color: Style.accent

    implicitHeight: 22

    Text {
        id: name
        anchors.verticalCenter: parent.verticalCenter
        text: root.letter
        color: Style.text
        font.family: Style.font
        font.pixelSize: Style.fontSize
        font.bold: true
    }
    Rectangle {
        x: 34
        width: parent.width - 34 - 92
        height: 8
        radius: 4
        anchors.verticalCenter: parent.verticalCenter
        color: "#26ffffff"

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.used))
            height: parent.height
            radius: 4
            color: root.color
        }
    }
    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.freeText
        color: Style.dim
        font.family: Style.font
        font.pixelSize: Style.smallSize
    }
}
