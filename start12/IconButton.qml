pragma ComponentBehavior: Bound

import QtQuick

// A square button that shows one glyph and runs `clicked`.
Rectangle {
    id: root
    property string glyph: ""
    property int size: 32
    property int glyphSize: 16
    property string tip: ""
    signal clicked

    implicitWidth: size
    implicitHeight: size
    radius: 6
    color: mouse.pressed ? Style.pressed : mouse.containsMouse ? Style.hover : "transparent"

    Glyph {
        anchors.centerIn: parent
        text: root.glyph
        size: root.glyphSize
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
