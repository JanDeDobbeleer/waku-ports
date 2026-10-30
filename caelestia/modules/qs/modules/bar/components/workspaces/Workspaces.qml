pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Caelestia
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services

ClipRect {
    id: root

    required property ShellScreen screen
    required property bool fullscreen

    readonly property var monitor: Hypr.monitorFor(screen)
    readonly property bool onSpecial: monitor?.lastIpcObject.specialWorkspace?.name !== ""
    readonly property int activeWsId: monitor.activeWorkspace?.id ?? 1
    readonly property int activeWsIdx: workspaceIndex(activeWsId)
    // Port: komorebi workspaces are real, so show all of them when there are more than `shown`.
    readonly property int shown: Math.max(1, Config.bar.workspaces.shown, Hypr.workspaces.values.filter(w => w.monitor === monitor).length)

    readonly property bool dynamic: Config.bar.workspaces.dynamic

    // Port, dynamic: every occupied workspace, the active one and the first empty one after the
    // last of those (a slot to move to an empty desktop), in workspace order.
    readonly property var dynamicIds: {
        const mine = Hypr.workspaces.values.filter(w => w.monitor === monitor);
        const ignoredTags = GlobalConfig.bar.workspaces.ignoredTags;
        const used = w => w.id === activeWsId || w.toplevels.values.some(t => !Hypr.isToplevelIgnored(t, ignoredTags));
        const ids = mine.filter(used).map(w => w.id);
        const last = ids.length > 0 ? Math.max(...ids) : 0;
        const spare = mine.find(w => w.id > last);
        if (spare)
            ids.push(spare.id);
        return ids;
    }

    // Port: the dots' ids, replaced only when the set of dots changes. A recomputation that gives
    // the same ids (a window title changed, a state refresh) hands the dot model nothing new.
    property var wsIds: []
    onWsIdsRawChanged: {
        if (wsIds.join(",") !== wsIdsRaw.join(","))
            wsIds = wsIdsRaw;
    }
    Component.onCompleted: wsIds = wsIdsRaw

    readonly property var wsIdsRaw: {
        if (dynamic)
            return dynamicIds;
        if (Config.bar.workspaces.showUnoccupied)
            return Array.from({
                length: shown
            }, (_, i) => i + 1);

        const allMonitors = !Config.bar.workspaces.perMonitor;
        const ignoredTags = GlobalConfig.bar.workspaces.ignoredTags;
        const workspaces = Hypr.workspaces.values.filter(w => w.id > 0 && (allMonitors || w.monitor === root.monitor) && (w.id === activeWsId || w.toplevels.values.some(t => !Hypr.isToplevelIgnored(t, ignoredTags))));
        const currentIdx = workspaces.findIndex(w => w.id === activeWsId);
        if (currentIdx < 0)
            return [];

        const end = CUtils.clamp(currentIdx + 1, Math.min(shown, workspaces.length), workspaces.length);
        const start = Math.max(0, end - shown);

        return workspaces.slice(start, end).map(w => w.id);
    }

    readonly property var workspaces: {
        CUtils.dependency(workspaces.itemsDirty);
        return wsIds.map(id => workspaces.itemAtIndex(workspaceIndex(id)));
    }

    // Only relevant for when showUnoccupied is true
    readonly property int groupOffset: {
        if (dynamic || !Config.bar.workspaces.showUnoccupied)
            return 0;
        return Math.floor((activeWsId - 1) / shown) * shown;
    }

    property real blur: onSpecial ? 1 : 0

    // Port: no `as Workspace` cast. On wabar a cast to a type of the same module came back null
    // (like the Loader casts in the hover path), so the click never found a workspace.
    function clickWorkspaceAt(x: real, y: real): string {
        if (layoutAt(workspaces.mapToItem(root, x, y).y))
            return cycleLayout("next");
        return clickWorkspace(workspaces.itemAt(x, y)?.ws ?? 0);
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

    // The layout glyph under the active dot, when `y` (local to this item) is over it.
    function layoutAt(y: real): var {
        const w = workspaces.itemAtIndex(activeWsIdx);
        if (!w || !w.hasLayout)
            return null;
        const p = w.mapToItem(root, 0, w.layoutTop);
        return y >= p.y && y <= p.y + w.layoutHeight ? w : null;
    }

    // Vertical centre of the layout glyph, local to this item.
    function layoutCentre(): real {
        const w = workspaces.itemAtIndex(activeWsIdx);
        return w ? w.mapToItem(root, 0, w.layoutTop + w.layoutHeight / 2).y : 0;
    }

    // Test and click handler of the layout switcher: `next` or `previous`. `dry` logs the command
    // and does not run it.
    function cycleLayout(direction: string, dry = false): string {
        const w = workspaces.itemAtIndex(activeWsIdx);
        if (!w || !w.hasLayout)
            return "none";
        return Hypr.cycleLayout(direction, dry) ? "cycle-layout " + direction : "none";
    }

    // The ids of the dots and the layout under the active one, for the test IPC.
    function debugDots(): string {
        const w = workspaces.itemAtIndex(activeWsIdx);
        return "dots=" + wsIds.join(",") + " active=" + activeWsId + " layout=" + (w?.layoutName ?? "") + " glyph=" + (w?.layoutGlyph ?? "");
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
    implicitHeight: workspaces.layoutHeight + workspaces.anchors.margins * 2

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
                wsSpacing: workspaces.spacing
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        LazyListView {
            id: workspaces

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.extraSmall
            implicitHeight: contentHeight

            spacing: Tokens.spacing.extraSmall
            removeDuration: Tokens.anim.durations.expressiveDefaultEffects

            model: ScriptModel {
                values: root.wsIds
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
                wsSpacing: workspaces.spacing
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Loader {
            asynchronous: true
            anchors.left: workspaces.left
            anchors.right: workspaces.right
            active: Config.bar.workspaces.activeIndicator

            sourceComponent: ActiveIndicator {
                activeWs: {
                    CUtils.dependency(workspaces.itemsDirty);
                    return workspaces.itemAtIndex(root.activeWsIdx) as Workspace;
                }
                mask: workspaces
            }
        }

        MouseArea {
            anchors.fill: workspaces
            onClicked: event => root.clickWorkspaceAt(event.x, event.y)
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

                scale: 0.5
                Component.onCompleted: scale = Qt.binding(() => root.onSpecial ? 1 : 0.5)

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
