import QtQuick
import waku
import waku.widgets

// The Start12 taskbar: three islands on a transparent strip along the bottom edge. Left: the Start
// button and the Downloads toolbar. Middle: your pinned and running apps. Right: the notification
// area, volume, the clock and notifications. Only the islands take clicks; the strip between them
// passes them to the windows below.
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
        Region { item: startIsland }
        Region { item: appsIsland }
        Region { item: trayIsland }
    }

    Island {
        id: startIsland
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Style.islandGap
        width: startRow.implicitWidth + 12

        Row {
            id: startRow
            anchors.centerIn: parent
            spacing: 6

            Rectangle {
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
            DownloadsToolbar {
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Island {
        id: appsIsland
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Style.islandGap
        width: Math.max(56, apps.implicitWidth + 16)

        Taskbar {
            id: apps
            anchors.centerIn: parent
            iconSize: 24
            grouping: true
            indicator: true
            buttonHeight: 40
            buttonPadding: 8
            activePadding: 8
            buttonRadius: 6
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
