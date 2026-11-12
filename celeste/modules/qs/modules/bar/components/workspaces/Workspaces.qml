pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Celeste
import Celeste.Components
import Celeste.Config
import qs.components
import qs.services
import "WorkspacesData.js" as WD

ClipRect {
    id: root

    required final property ShellScreen screen
    required final property bool fullscreen

    readonly final property HyprMonitor monitor: Hypr.monitorFor(screen)
    readonly final property bool onSpecial: monitor?.specialName !== ""
    readonly final property int activeWsId: monitor?.activeWorkspace?.id ?? 1
    readonly final property int activeWsIdx: workspaceIndex(activeWsId)
    // Port: the desktops that exist plus one dot that creates the next.
    readonly final property int existing: WD.workspaceCount(Hypr.workspaces.values, monitor)
    readonly final property int shown: Math.min(20, existing + 1)

    readonly final property bool dynamic: Config.bar.workspaces.dynamic

    // Port, dynamic: every occupied workspace, the active one and the first empty one after the
    // last of those (a slot to move to an empty desktop), in workspace order.
    readonly final property var dynamicIds: WD.dynamicIds(Hypr.workspaces.values, monitor, activeWsId)

    // Port: the dots' ids, replaced only when the set of dots changes. A recomputation that gives
    // the same ids (a window title changed, a state refresh) hands the dot model nothing new.
    final property list<int> wsIds
    onWsIdsRawChanged: {
        if (!WD.sameIds(wsIds, wsIdsRaw))
            wsIds = wsIdsRaw;
    }
    Component.onCompleted: wsIds = wsIdsRaw

    readonly final property var wsIdsRaw: {
        if (dynamic)
            return dynamicIds;
        if (Config.bar.workspaces.showUnoccupied)
            return WD.range(shown);
        return WD.shownIds(Hypr.workspaces.values, monitor, activeWsId, !Config.bar.workspaces.perMonitor, shown);
    }

    readonly final property var workspaces: {
        CUtils.dependency(workspacesItem.itemsDirty);
        return dotItems();
    }

    function dotItems(): var {
        const out = [];
        for (let i = 0; i < wsIds.length; i++)
            out.push(workspacesItem.itemAtIndex(workspaceIndex(wsIds[i])));
        return out;
    }
    // Only relevant for when showUnoccupied is true
    readonly final property int groupOffset: {
        if (dynamic || !Config.bar.workspaces.showUnoccupied)
            return 0;
        return Math.floor((activeWsId - 1) / shown) * shown;
    }

    final property real blur: onSpecial ? 1 : 0

    // Port: no `as Workspace` cast. On waku a cast to a type of the same module came back null
    // (like the Loader casts in the hover path), so the click never found a workspace.
    function clickWorkspaceAt(x: real, y: real): string {
        return clickWorkspace(WD.itemWs(workspacesItem.itemAt(x, y)));
    }

    // Right click on a dot closes that desktop (Windows virtual desktops only).
    function removeWorkspaceAt(x: real, y: real): string {
        const ws = WD.itemWs(workspacesItem.itemAt(x, y));
        if (!ws)
            return "none";
        Hypr.removeWorkspace(ws);
        return "remove";
    }

    // The click handler of the dots (the test IPC calls it too). Returns what happened.
    function clickWorkspace(ws: int): string {
        if (!ws)
            return "none";
        if (Hypr.activeWsId === ws) {
            Hypr.toggleSpecial("special");
            return "focused";
        }
        Hypr.focusWorkspace(ws);
        return "focus";
    }

    // The ids of the dots and the active one, for the test IPC.
    function debugDots(): string {
        return "dots=" + wsIds.join(",") + " active=" + activeWsId;
    }

    function workspaceIndex(id: int): int {
        if (dynamic || !Config.bar.workspaces.showUnoccupied)
            return wsIds.indexOf(id);

        let index = id - 1;
        while (index < 0)
            index += shown;
        return index % shown;
    }

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: workspacesItem.layoutHeight + workspacesItem.anchors.margins * 2

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    Item {
        anchors.fill: parent
        scale: root.onSpecial ? 0.8 : 1
        opacity: root.onSpecial ? 0.5 : 1
        visible: !root.fullscreen

        layer.enabled: root.blur > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.blur
            blurMax: 32
        }

        Loader {
            asynchronous: true
            opacity: Config.bar.workspaces.occupiedBg ? 1 : 0
            active: opacity > 0

            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall

            sourceComponent: OccupiedBg {
                workspaces: root.workspaces
                wsSpacing: workspacesItem.spacing
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        LazyListView {
            id: workspacesItem

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.extraSmall
            implicitHeight: contentHeight

            spacing: Tokens.spacing.extraSmall
            removeDuration: Tokens.anim.durations.expressiveDefaultEffects

            model: ScriptModel {
                values: WD.toArray(root.wsIds)
            }

            delegate: Workspace {
                activeWsId: root.activeWsId
                ws: !root.dynamic && Config.bar.workspaces.showUnoccupied ? root.groupOffset + index + 1 : modelData
                monitor: root.monitor

                displayType: Config.bar.workspaces.displayType
                showWindows: false // Port: windows are listed in AppsList, not in the pills
                iconRules: GlobalConfig.bar.workspaces.workspaceIcons
                activeLabel: Config.bar.workspaces.activeLabel
                occupiedLabel: Config.bar.workspaces.occupiedLabel
                label: Config.bar.workspaces.label
            }
        }

        Loader {
            asynchronous: true
            opacity: !root.dynamic && Config.bar.workspaces.showUnoccupied ? 0 : 1
            active: opacity > 0

            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall

            sourceComponent: GapMarkers {
                workspaces: root.workspaces
                wsSpacing: workspacesItem.spacing
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Loader {
            asynchronous: true
            anchors.left: workspacesItem.left
            anchors.right: workspacesItem.right
            active: Config.bar.workspaces.activeIndicator

            sourceComponent: ActiveIndicator {
                activeWs: {
                    CUtils.dependency(workspacesItem.itemsDirty);
                    return workspacesItem.itemAtIndex(root.activeWsIdx) as Workspace;
                }
                mask: workspacesItem
            }
        }

        MouseArea {
            anchors.fill: workspacesItem
            acceptedButtons: Hypr.canRemoveWorkspace ? Qt.LeftButton | Qt.RightButton : Qt.LeftButton
            onClicked: event => {
                if (event.button === Qt.RightButton)
                    root.removeWorkspaceAt(event.x, event.y);
                else
                    root.clickWorkspaceAt(event.x, event.y);
            }
        }

        Behavior on scale {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: specialWs

        anchors.fill: parent

        asynchronous: true
        active: opacity > 0
        opacity: root.onSpecial ? 1 : 0

        sourceComponent: Item {
            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: Qt.alpha(Colours.palette.m3scrim, Colours.light ? 0 : 0.2)
            }

            SpecialWorkspaces {
                anchors.fill: parent
                anchors.margins: Tokens.padding.extraSmall
                monitor: root.monitor

                scale: root.onSpecial ? 1 : 0.5

                Behavior on scale {
                    Anim {}
                }
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Behavior on blur {
        Anim {
            type: Anim.StandardSmall
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }
}
