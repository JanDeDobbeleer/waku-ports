pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import waku.services as S

// A pinned app: its icon over its name. Left click starts it; right click opens the app menu.
Rectangle {
    id: root

    required property S.DesktopEntry entry
    signal activated
    signal contextRequested(point: point)

    width: 84
    height: 88
    radius: 6
    color: mouse.containsMouse ? Style.hover : "transparent"

    Image {
        id: icon
        anchors.horizontalCenter: parent.horizontalCenter
        y: 10
        width: 32
        height: 32
        smooth: true
        mipmap: true
        source: root.entry ? Quickshell.iconPath(root.entry.icon, true) : ""
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: icon.bottom
        anchors.topMargin: 6
        width: parent.width - 8
        text: root.entry ? root.entry.name : ""
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
        color: Style.text
        font.family: Style.font
        font.pixelSize: 11
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
