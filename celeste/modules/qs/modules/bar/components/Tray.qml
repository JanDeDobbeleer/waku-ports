pragma ComponentBehavior: Bound

import QtQuick
import Celeste.Config
import qs.components
import qs.services

// Port: one tray button under the status icons, tinted like them, with the number of tray items as
// a badge. Hover or click opens the flyout (popouts/TrayFlyout) that lists every icon. Zero
// height, and hidden, when there are no tray items.
StyledRect {
    id: root

    readonly property bool active: TrayItems.count > 0
    property color colour: Colours.palette.m3secondary

    // Port: a click opens the flyout (handled in Bar.qml).
    signal clicked

    clip: false
    visible: active

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: active ? icon.implicitHeight + padding * 2 : 0

    readonly property int padding: Config.bar.tray.background ? Tokens.padding.medium : Tokens.padding.extraSmall

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.tray.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent
        text: "widgets"
        color: root.colour
        fill: 1
    }

    StyledText {
        visible: root.active
        anchors.horizontalCenter: icon.right
        anchors.verticalCenter: icon.top
        text: TrayItems.count > 99 ? "99+" : `${TrayItems.count}`
        color: root.colour
        font: Tokens.font.body.small
    }
}
