pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "AppRowHelpers.js" as AppRowHelpers

// An app in a list: a small icon and its name. Left click starts it; right click opens the app menu.
Rectangle {
    id: root

    required property var entry
    property bool highlighted: false
    signal activated
    signal contextRequested(point: point)

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
        source: Quickshell.iconPath(AppRowHelpers.stringField(root.entry, "icon"), true)
    }
    Text {
        x: 50
        width: parent.width - 62
        anchors.verticalCenter: parent.verticalCenter
        text: AppRowHelpers.stringField(root.entry, "name")
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
