import QtQuick
import waku.services as S

// The virtual desktops as numbered buttons: the current one lit, desktops with windows marked by a dot.
// A click goes to that desktop. Shows the first monitor's desktops.
Row {
    id: root

    readonly property var monitors: S.Workspaces.monitors || []
    readonly property var desktops: monitors.length > 0 ? (monitors[0].workspaces || []) : []

    spacing: 2

    Repeater {
        model: root.desktops.length

        Rectangle {
            id: cell
            required property int index
            readonly property var desktop: root.desktops[index]
            readonly property bool current: !!(desktop && (desktop.active || desktop.focused))
            readonly property bool occupied: !!(desktop && desktop.hasWindows)

            width: 30
            height: 40
            radius: 6
            color: current ? Style.hover : mouse.containsMouse ? Style.hover : "transparent"

            Text {
                anchors.centerIn: parent
                text: cell.index + 1
                color: cell.current ? Style.text : Style.dim
                font.family: Style.font
                font.pixelSize: Style.fontSize
                font.bold: cell.current
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 4
                width: cell.current ? 14 : 4
                height: 3
                radius: 1.5
                visible: cell.current || cell.occupied
                color: cell.current ? Style.accent : Style.faint
            }
            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: S.Workspaces.focus(0, String(cell.index))
            }
        }
    }
}
