import QtQuick
import Quickshell

// An app in a list: a small icon and its name. Left click starts it; right click opens the app menu.
Rectangle {
    id: root

    required property var entry
    property bool highlighted: false
    signal activated
    signal contextRequested(var point)

    height: 40
    radius: 6
    color: mouse.containsMouse || highlighted ? Style.hover : "transparent"

    Image {
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: 24
        smooth: true
        mipmap: true
        source: root.entry ? Quickshell.iconPath(root.entry.icon, true) : ""
    }
    Text {
        x: 50
        width: parent.width - 62
        anchors.verticalCenter: parent.verticalCenter
        text: root.entry ? root.entry.name : ""
        elide: Text.ElideRight
        color: Style.text
        font.family: Style.font
        font.pixelSize: Style.fontSize
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.contextRequested(root.mapToItem(null, mouse.x, mouse.y));
            else
                root.activated();
        }
    }
}
