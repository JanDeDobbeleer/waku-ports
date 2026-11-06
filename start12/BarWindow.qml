import QtQuick
import waku
import waku.widgets

// The Start12 taskbar: three islands on a transparent strip along the bottom edge, as in Start11.
// Left: the virtual desktops and the tiler layout. Middle: the Start button, your pinned and running
// apps, and the Downloads toolbar. Right: the notification area, volume, the clock and notifications.
// Only the islands take clicks; the strip between them passes them to the windows below.
PanelWindow {
    id: bar

    required property var startMenu

    name: "taskbar"
    anchors {
        bottom: true
        left: true
        right: true
    }
    implicitHeight: Style.barHeight
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: Style.barHeight
    color: "transparent"

    mask: Region {
        Region { item: leftIsland }
        Region { item: mainIsland }
        Region { item: trayIsland }
    }

    Island {
        id: leftIsland
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Style.islandGap
        width: leftRow.implicitWidth + 12

        Row {
            id: leftRow
            anchors.centerIn: parent
            spacing: 6

            DesktopSwitcher {
                anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle {
                visible: layout.visible
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 24
                color: Style.islandBorder
            }
            LayoutSwitcher {
                id: layout
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Island {
        id: mainIsland
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Style.islandGap
        width: mainRow.implicitWidth + 16

        Row {
            id: mainRow
            anchors.centerIn: parent
            spacing: 6

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                height: 40
                radius: 6
                color: logoMouse.pressed ? Style.pressed : logoMouse.containsMouse || bar.startMenu.visible ? Style.hover : "transparent"

                WindowsLogo {
                    anchors.centerIn: parent
                    size: 22
                }
                MouseArea {
                    id: logoMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: bar.startMenu.toggle()
                }
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 24
                color: Style.islandBorder
            }
            Taskbar {
                id: apps
                anchors.verticalCenter: parent.verticalCenter
                iconSize: 24
                grouping: true
                indicator: true
                buttonHeight: 40
                buttonPadding: 8
                activePadding: 8
                buttonRadius: 6
            }
            DownloadsToolbar {
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Island {
        id: trayIsland
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Style.islandGap
        width: trayRow.implicitWidth + 20

        Row {
            id: trayRow
            anchors.centerIn: parent
            spacing: 8

            Tray {
                anchors.verticalCenter: parent.verticalCenter
                iconSize: 16
                unpinnedInPopup: true
            }
            Volume {
                anchors.verticalCenter: parent.verticalCenter
            }
            ClockText {
                anchors.verticalCenter: parent.verticalCenter
            }
            Notifications {
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
