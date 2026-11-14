pragma ComponentBehavior: Bound

import QtQuick

// A row of the right-hand column: a glyph and a label. `clicked` runs the action.
Rectangle {
    id: root

    property string glyph: ""
    property string label: ""
    signal clicked

    height: 48
    radius: 6
    color: mouse.pressed ? Style.pressed : mouse.containsMouse ? Style.hover : "transparent"

    Glyph {
        x: 20
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        text: root.glyph
        size: 20
    }
    Text {
        x: 58
        width: parent.width - 70
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        elide: Text.ElideRight
        color: Style.text
        font.family: Style.font
        font.pixelSize: Style.fontSize
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
