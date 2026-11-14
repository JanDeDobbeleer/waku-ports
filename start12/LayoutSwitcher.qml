pragma ComponentBehavior: Bound

import QtQuick
import waku.services as S

// The layout of waku's built-in tiler for the focused desktop. Left click: next layout. Right click:
// previous. Hidden while the tiler is off.
Rectangle {
    id: root

    readonly property var names: ({
            "mainStack": "Main",
            "mainStackTop": "Top",
            "columns": "Columns",
            "rows": "Rows",
            "bsp": "BSP",
            "grid": "Grid",
            "centerMain": "Centred"
        })
    readonly property string layoutName: S.Tiling.currentLayout

    visible: S.Tiling.active && layoutName !== ""
    implicitWidth: visible ? label.implicitWidth + 24 : 0
    implicitHeight: 40
    radius: 6
    color: mouse.containsMouse ? Style.hover : "transparent"

    Text {
        id: label
        anchors.centerIn: parent
        text: root.names[root.layoutName] || root.layoutName
        color: Style.text
        font.family: Style.font
        font.pixelSize: Style.fontSize
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => S.Tiling.cycleLayout(mouse.button === Qt.RightButton ? -1 : 1)
    }
}
