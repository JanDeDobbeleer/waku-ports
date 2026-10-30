pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Port: the tray strip under the status icons. Shows up to Config.bar.tray.maxShown icons and a
// "+n" badge for the rest; the flyout (popouts/TrayFlyout) lists them all. Zero height, and
// hidden, when there are no icons.
StyledRect {
    id: root

    readonly property alias layout: layout
    readonly property bool active: TrayItems.count > 0
    readonly property int shown: Math.min(TrayItems.count, Math.max(1, Config.bar.tray.maxShown))
    readonly property int extra: TrayItems.count - shown

    readonly property int padding: Config.bar.tray.background ? Tokens.padding.medium : Tokens.padding.extraSmall

    clip: true
    visible: active

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: active ? layout.implicitHeight + padding * 2 : 0

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.tray.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    Column {
        id: layout

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.padding
        spacing: Tokens.spacing.small

        Repeater {
            model: TrayItems.items.slice(0, root.shown)

            TrayItem {}
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.extra > 0
            text: `+${root.extra}`
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
        }
    }
}
