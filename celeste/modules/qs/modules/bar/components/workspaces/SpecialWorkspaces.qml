pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Celeste
import Celeste.Components
import Celeste.Config
import qs.components
import qs.components.effects
import qs.services

Item {
    id: root

    required final property HyprMonitor monitor

    readonly final property int activeSpecialId: monitor?.specialId ?? 0
    readonly final property var wsIds: Hypr.specialIds(monitor, !Config.bar.workspaces.perMonitor)
    readonly final property int activeIdx: wsIds.indexOf(activeSpecialId)
    readonly final property real maxViewY: Math.max(0, view.contentHeight - height)

    readonly final property Workspace activeWs: {
        CUtils.dependency(view.itemsDirty);
        return view.itemAtIndex(activeIdx) as Workspace;
    }

    function ensureVisible(animate: bool): void {
        if (!activeWs)
            return;

        const top = activeWs.layoutY;
        const bottom = top + activeWs.preferredHeight;

        let target = view.y;
        if (top < -target)
            target = -top;
        else if (bottom > -target + height)
            target = -(bottom - height);

        target = CUtils.clamp(target, -maxViewY, 0);
        if (target !== view.y) {
            if (animate) {
                const type = viewYAnim.type;
                viewYAnim.type = Anim.DefaultSpatial;
                view.y = target;
                viewYAnim.type = type;
            } else {
                viewYBehavior.enabled = false;
                view.y = target;
                viewYBehavior.enabled = true;
            }
        }
    }

    onActiveWsChanged: ensureVisible(true)
    onHeightChanged: ensureVisible(false)
    Component.onCompleted: ensureVisible(false)
    onMaxViewYChanged: ensureVisible(true)

    layer.enabled: true
    layer.effect: Mask {
        maskSource: mask
    }

    Connections {
        function onLayoutYChanged(): void {
            root.ensureVisible(true);
        }

        function onPreferredHeightChanged(): void {
            root.ensureVisible(true);
        }

        target: root.activeWs
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: Tokens.rounding.full

            gradient: Gradient {
                orientation: Gradient.Vertical

                GradientStop {
                    position: 0
                    color: Qt.rgba(0, 0, 0, 0)
                }
                GradientStop {
                    position: 0.2
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 0.8
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(0, 0, 0, 0)
                }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            radius: Tokens.rounding.full
            implicitHeight: parent.height / 2
            opacity: view.y < -Tokens.padding.extraSmall ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right

            radius: Tokens.rounding.full
            implicitHeight: parent.height / 2
            opacity: view.y > -root.maxViewY + Tokens.padding.extraSmall ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    LazyListView {
        id: view

        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: contentHeight

        spacing: Tokens.spacing.small
        removeDuration: Tokens.anim.durations.expressiveDefaultEffects

        onContentHeightChanged: root.ensureVisible(true)

        model: ScriptModel {
            values: root.wsIds
        }

        delegate: Workspace {
            activeWsId: root.activeSpecialId
            ws: modelData
            monitor: root.monitor
            offMonitorColour: Colours.palette.m3outline
            displayType: Config.bar.workspaces.specialDisplayType
            showWindows: Config.bar.workspaces.showWindowsOnSpecialWorkspaces
            iconRules: GlobalConfig.bar.workspaces.specialWorkspaceIcons
        }

        Behavior on y {
            id: viewYBehavior

            Anim {
                id: viewYAnim

                type: Anim.FastEffects
            }
        }
    }

    Loader {
        asynchronous: true
        anchors.left: view.left
        anchors.right: view.right
        active: Config.bar.workspaces.activeIndicator

        sourceComponent: ActiveIndicator {
            activeWs: root.activeWs
            mask: view
            color: Colours.palette.m3tertiary
            contentColour: Colours.palette.m3onTertiary
        }
    }

    MouseArea {
        final property real startY
        final property real startViewY
        final property bool dragging

        anchors.fill: parent

        onPressed: event => {
            startY = event.y;
            startViewY = view.y;
            dragging = false;
        }

        onPositionChanged: event => {
            if (!dragging && Math.abs(event.y - startY) > drag.threshold)
                dragging = true;

            if (dragging)
                view.y = CUtils.clamp(startViewY + (event.y - startY), -root.maxViewY, 0);
        }

        onClicked: event => {
            if (dragging)
                return;

            const ws = view.itemAt(event.x, event.y - view.y) as Workspace;
            if (ws) {
                const match = Hypr.workspaceById(ws.ws);
                if (match)
                    Hypr.toggleSpecial(Hypr.trimWsName(match.name));
            } else {
                Hypr.toggleSpecial("special");
            }
        }
    }
}
