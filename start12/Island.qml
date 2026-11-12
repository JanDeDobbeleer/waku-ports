pragma ComponentBehavior: Bound

import QtQuick

// A rounded translucent group on the taskbar.
Rectangle {
    height: Style.islandHeight
    radius: Style.islandRadius
    color: Style.island
    border.color: Style.islandBorder
    border.width: 1
}
