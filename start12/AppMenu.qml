pragma ComponentBehavior: Bound

import QtQuick
import waku.services as S

// The right-click menu of an app: pin or unpin it, run it as administrator, show its folder.
Rectangle {
    id: root

    property S.DesktopEntry entry: null
    signal done

    width: 220
    height: col.implicitHeight + 8
    radius: 8
    color: "#fa1b273b"
    border.color: Style.menuBorder
    border.width: 1

    component Item_: Rectangle {
        id: item
        property string label: ""
        signal triggered
        width: root.width - 8
        height: 32
        radius: 4
        color: m.containsMouse ? Style.hover : "transparent"
        Text {
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            text: item.label
            color: Style.text
            font.family: Style.font
            font.pixelSize: Style.fontSize
        }
        MouseArea {
            id: m
            anchors.fill: parent
            hoverEnabled: true
            onClicked: item.triggered()
        }
    }

    Column {
        id: col
        x: 4
        y: 4

        Item_ {
            label: root.entry && Pins.has(root.entry.id) ? "Unpin from Start" : "Pin to Start"
            onTriggered: {
                Pins.toggle(root.entry.id);
                root.done();
            }
        }
        Item_ {
            label: "Run as administrator"
            onTriggered: {
                S.AppsService.launchAsAdmin(root.entry.id);
                root.done();
            }
        }
        Item_ {
            label: "Open file location"
            onTriggered: {
                S.AppsService.openLocation(root.entry.id);
                root.done();
            }
        }
    }
}
