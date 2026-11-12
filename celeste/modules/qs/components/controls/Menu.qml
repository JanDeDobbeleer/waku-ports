pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Celeste
import Celeste.Config
import qs.components
import qs.components.effects
import qs.services
import "MenuHelpers.js" as MenuHelpers

MouseArea {
    id: root

    enum Side {
        Top,
        Bottom,
        Left,
        Right
    }

    required final property Item attachTo
    final property int attachSideX: Menu.Right
    final property int attachSideY: Menu.Bottom
    final property int thisSideX: Menu.Right
    final property int thisSideY: Menu.Top
    final property real marginX
    final property real marginY

    final property list<MenuItem> items
    final property MenuItem active: items[0] ?? null
    final property bool expanded

    // Port: untyped. A MenuItem-typed argument cannot take a component derived from MenuItem
    // (the drive menu's DiskItem); the call fails and the handler never runs.
    signal itemSelected(var item)

    // Port: the `as ContentWindow` cast is null here, so the menu ended up on the window's root item
    // instead of the interaction wrapper. Its items' hover then took the hover from the wrapper,
    // which read it as the mouse leaving and closed the dashboard. Duck-typed lookup instead.
    parent: {
        return MenuHelpers.parentItem(QsWindow.window);
    }
    anchors.fill: parent

    enabled: expanded
    // Port: no hover here. This item covers the whole drawer window, and a hover-enabled child
    // takes the hover away from Interactions, which then thinks the mouse left and closes the
    // dashboard before a menu item can be clicked.
    hoverEnabled: false
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    onClicked: expanded = false

    opacity: expanded ? 1 : 0
    layer.enabled: opacity < 1

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    TransformWatcher {
        id: watcher

        a: root.parent
        b: root.attachTo
    }

    Elevation {
        id: menu

        x: {
            CUtils.dependency(watcher.transform); // mapToItem is not reactive so this forces updates
            return MenuHelpers.positionX(root.attachTo, root.parent, root.attachSideX, root.thisSideX, Menu.Left, Menu.Right, width, root.marginX);
        }
        y: {
            CUtils.dependency(watcher.transform); // mapToItem is not reactive so this forces updates
            return MenuHelpers.positionY(root.attachTo, root.parent, root.attachSideY, root.thisSideY, Menu.Top, Menu.Bottom, height, root.marginY);
        }

        radius: Tokens.rounding.large
        level: 2

        implicitWidth: Math.max(200, column.implicitWidth + column.anchors.margins * 2)
        implicitHeight: column.implicitHeight + column.anchors.margins * 2

        transform: Scale {
            yScale: root.expanded ? 1 : 0.1
            origin.y: root.thisSideY === Menu.Bottom ? menu.height : 0

            Behavior on yScale {
                Anim {}
            }
        }

        MouseArea {
            anchors.fill: parent
            onWheel: e => e.accepted = true
        }

        StyledRect {
            anchors.fill: parent
            radius: parent.radius
            color: Colours.palette.m3surfaceContainerLow

            ColumnLayout {
                id: column

                anchors.fill: parent
                anchors.margins: Tokens.padding.extraSmall
                spacing: 0

                Repeater {
                    id: repeater

                    model: root.items

                    StyledRect {
                        id: menuItem

                        required final property int index
                        required final property MenuItem modelData
                        readonly final property bool active: modelData === root?.active

                        Layout.fillWidth: true
                        implicitWidth: menuOptionRow.implicitWidth + Tokens.padding.medium * 2
                        implicitHeight: menuOptionRow.implicitHeight + Tokens.padding.medium * 2

                        radius: active ? Tokens.rounding.medium : Tokens.rounding.extraSmall
                        topLeftRadius: index === 0 ? Tokens.rounding.medium : radius
                        topRightRadius: index === 0 ? Tokens.rounding.medium : radius
                        bottomLeftRadius: index === repeater?.count - 1 ? Tokens.rounding.medium : radius
                        bottomRightRadius: index === repeater?.count - 1 ? Tokens.rounding.medium : radius

                        color: Qt.alpha(Colours.palette.m3tertiaryContainer, active ? 1 : 0)

                        Behavior on radius {
                            Anim {}
                        }

                        StateLayer {
                            topLeftRadius: parent.topLeftRadius
                            topRightRadius: parent.topRightRadius
                            bottomLeftRadius: parent.bottomLeftRadius
                            bottomRightRadius: parent.bottomRightRadius

                            color: menuItem.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                            disabled: !root.expanded
                            onClicked: {
                                root.itemSelected(menuItem.modelData);
                                root.active = menuItem.modelData;
                                MenuHelpers.click(menuItem.modelData);
                                root.expanded = false;
                            }
                        }

                        RowLayout {
                            id: menuOptionRow

                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                Layout.alignment: Qt.AlignVCenter
                                text: menuItem.modelData?.icon ?? ""
                                color: menuItem.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.fillWidth: true
                                text: menuItem.modelData?.text ?? ""
                                color: menuItem.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                            }

                            Loader {
                                asynchronous: true
                                Layout.alignment: Qt.AlignVCenter
                                active: menuItem.modelData?.trailingIcon.length > 0
                                visible: active

                                sourceComponent: MaterialIcon {
                                    text: menuItem.modelData.trailingIcon
                                    color: menuItem.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
