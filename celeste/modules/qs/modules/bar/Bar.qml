pragma ComponentBehavior: Bound

import "components"
import "components/workspaces"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Celeste.Config
import qs.components
import qs.services
import qs.modules.bar.popouts as BarPopouts
import "BarHelpers.js" as BH

ColumnLayout {
    id: root

    required final property ShellScreen screen
    required final property ScreenState screenState
    required final property BarPopouts.Wrapper popouts
    required final property bool fullscreen
    readonly final property int vPadding: Tokens.padding.large

    // The entries' items, set by their delegates.
    property Tray trayItem: null
    property LayoutButton layoutItem: null
    property StatusIcons statusItem: null
    property AppsList appsItem: null
    property Workspaces workspacesItem: null

    function closeTray(): void {
        if (!Config.bar.tray.compact)
            return;

        if (trayItem)
            trayItem.expanded = false;
    }

    // Port: the click on the clock opens the dashboard on its first tab and closes the clock
    // popout; with the dashboard open it closes it. Returns what happened (test IPC too).
    function clickClock(): string {
        popouts.hasCurrent = false;
        if (screenState.dashboard) {
            screenState.dashboard = false;
            return "dashboard closed";
        }
        screenState.dashboardTab = 0;
        screenState.dashboard = true;
        return "dashboard opened";
    }

    // Port: true when (x, y) in bar coordinates is not over any entry (a gap or a spacer), so a click
    // there can open the dashboard. Entries are as wide as their item and centred.
    function emptyAt(x: real, y: real): bool {
        const ch = childAt(x, y);
        return !ch || !BH.hasItem(ch);
    }

    function showPopout(name: string, ch: Item): void {
        popouts.currentName = name;
        popouts.currentCenter = ch.mapToItem(root, 0, ch.height / 2).y;
        popouts.hasCurrent = true;
    }

    function checkPopout(y: real): void {
        const ch = childAt(width / 2, y);
        const id = BH.entryId(ch);

        if (id !== "tray")
            closeTray();

        // Port: leaving the clock closes its popout, and so does leaving the layout button.
        if (id !== "clock" && popouts.currentName === "clock")
            popouts.hasCurrent = false;
        if (id !== "layout" && popouts.currentName === "layout")
            popouts.hasCurrent = false;
        if (id !== "tray" && popouts.currentName === "tray")
            popouts.hasCurrent = false;

        if (!ch) {
            popouts.hasCurrent = false;
            return;
        }

        if (id === "clock") {
            // Port: hovering the clock opens the calendar, unless the dashboard is open.
            if (screenState.dashboard) {
                if (popouts.currentName === "clock")
                    popouts.hasCurrent = false;
            } else {
                showPopout("clock", ch);
            }
        } else if (id === "layout") {
            // Port: hovering the layout button opens its hint.
            if (layoutItem?.active)
                showPopout("layout", ch);
        } else if (id === "statusIcons" && Config.bar.popouts.statusIcons) {
            const items = statusItem.items;
            const icon = items.childAt(items.width / 2, mapToItem(items, 0, y).y);
            if (icon) {
                popouts.currentName = BH.iconName(icon);
                popouts.currentCenter = Qt.binding(() => icon.mapToItem(root, 0, icon.implicitHeight / 2).y);
                popouts.hasCurrent = true;
            }
        } else if (id === "tray" && Config.bar.popouts.tray) {
            // Port: hovering the tray button opens the flyout with every icon.
            if (ch.visible && trayItem?.active)
                showPopout("tray", ch);
        } else if (id === "activeWindow" && Config.bar.popouts.activeWindow && Config.bar.activeWindow.showOnHover) {
            // Port: the popout shows the window under the cursor (see AppsList), or the windows of
            // an application with several (the "appgroup" popout).
            const app = appsItem.appAt(appsItem.mapFromItem(root, 0, y).y);
            if (app) {
                // Port: one window or several, the flyout shows preview cards.
                Hypr.hoverGroupKey = BH.groupKey(app);
                popouts.currentName = "appgroup";
                popouts.currentCenter = app.mapToItem(root, 0, app.height / 2).y;
                popouts.hasCurrent = true;
            } else {
                popouts.hasCurrent = false;
            }
        }
    }

    // Port, test only (DebugIpc): the entry ids, with the names of the status icons.
    function debugEntries(): string {
        const out = [];
        for (let i = 0; i < repeater.count; i++) {
            const id = BH.entryId(repeater.itemAt(i));
            out.push(id === "statusIcons" ? id + "[" + BH.childNames(statusItem.items).join(",") + "]" : id);
        }
        return out.join(" ");
    }

    // Port, test only (DebugIpc): sets the state checkPopout sets when the cursor is over the entry
    // named `name` ("network", "bluetooth", "battery", "audio", "kblayout", "lockstatus",
    // "activewindow"). Returns false when no such entry is in the bar.
    function openPopoutNamed(name: string): bool {
        for (let i = 0; i < repeater.count; i++) {
            const ch = repeater.itemAt(i);
            if (!ch)
                continue;
            const id = BH.entryId(ch);
            if (id === "clock" && name === "clock") {
                showPopout(name, ch);
                return true;
            } else if (id === "tray" && name === "tray") {
                if (!ch.visible || !trayItem?.active)
                    return false;
                showPopout(name, ch);
                return true;
            } else if (id === "layout" && name === "layout") {
                showPopout(name, ch);
                return true;
            } else if (id === "activeWindow" && name.toLowerCase().startsWith("appgroup:")) {
                // "appGroup:<exe>": the flyout of that application's group.
                const key = name.slice("appgroup:".length);
                const app = appsItem.appForKey(key);
                if (!app)
                    return false;
                Hypr.hoverGroupKey = key;
                popouts.currentName = "appgroup";
                popouts.currentCenter = app.mapToItem(root, 0, app.height / 2).y;
                popouts.hasCurrent = true;
                return true;
            } else if (id === "statusIcons") {
                const items = statusItem.items;
                for (let j = 0; j < items.children.length; j++) {
                    const icon = items.children[j];
                    if (BH.iconName(icon) === name) {
                        popouts.currentName = name;
                        popouts.currentCenter = Qt.binding(() => icon.mapToItem(root, 0, icon.implicitHeight / 2).y);
                        popouts.hasCurrent = true;
                        return true;
                    }
                }
            } else if (id === "activeWindow" && name === "activewindow") {
                Hypr.hoverToplevel = null;
                popouts.currentName = name;
                popouts.currentCenter = appsItem.mapToItem(root, 0, appsItem.implicitHeight / 2).y;
                popouts.hasCurrent = true;
                return true;
            }
        }
        return false;
    }

    // Port, test only (DebugIpc): the item of the entry with this id, or null.
    function entryItem(id: string): Item {
        for (let i = 0; i < repeater.count; i++) {
            const ch = repeater.itemAt(i);
            if (BH.entryId(ch) === id)
                return BH.itemOf(ch);
        }
        return null;
    }

    function handleWheel(y: real, angleDelta: point): void {
        const ch = childAt(width / 2, y);
        const id = BH.entryId(ch);
        if (id === "layout") {
            // Port: the wheel over the layout button cycles the layout (wheel up: previous).
            layoutItem.cycle(angleDelta.y > 0 ? "previous" : "next", Paths.dryRun);
        } else if (id === "workspaces" && Config.bar.scrollActions.workspaces) {
            // Workspace scroll
            const mon = Hypr.monitorFor(screen);
            const specialWs = mon?.specialName ?? "";
            if (specialWs.length > 0)
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.workspace.toggle_special("${specialWs.slice(8)}")` : `togglespecialworkspace ${specialWs.slice(8)}`);
            else if (workspacesItem && workspacesItem.wsIds.length > 0) {
                // Port: step through the dots that are shown, and wrap at both ends. The
                // dynamic dots hide empty desktops, so a step over all of them would leave the
                // dots unchanged.
                const ids = workspacesItem.wsIds;
                const at = Math.max(0, ids.indexOf(mon?.activeWorkspace?.id ?? 0));
                const next = ids[(at + (angleDelta.y > 0 ? -1 : 1) + ids.length) % ids.length];
                Hypr.dispatch(`workspace ${next}`);
            }
        } else if (y < screen.height / 2 && Config.bar.scrollActions.volume) {
            // Volume scroll on top half
            if (angleDelta.y > 0)
                Audio.incrementVolume(0);
            else if (angleDelta.y < 0)
                Audio.decrementVolume(0);
        } else if (Config.bar.scrollActions.brightness) {
            // Brightness scroll on bottom half
            if (angleDelta.y > 0)
                Brightness.adjustForScreen(screen, GlobalConfig.services.brightnessIncrement);
            else if (angleDelta.y < 0)
                Brightness.adjustForScreen(screen, -GlobalConfig.services.brightnessIncrement);
        }
    }
    spacing: Tokens.spacing.medium

    Repeater {
        id: repeater

        model: ScriptModel {
            values: BH.enabledEntries(Config.bar.entries.values)
        }

        DelegateChooser {
            role: "id"

            DelegateChoice {
                roleValue: "spacer"
                delegate: EntryWrapper {
                    Layout.fillHeight: true
                }
            }
            DelegateChoice {
                roleValue: "logo"
                delegate: EntryWrapper {
                    OsIcon {
                        objectName: "taskbarLogo"
                        screenState: root.screenState
                    }
                }
            }
            DelegateChoice {
                roleValue: "workspaces"
                delegate: EntryWrapper {
                    Workspaces {
                        id: workspacesEntry
                        objectName: "taskbarWorkspaces"
                        screen: root.screen
                        fullscreen: root.fullscreen
                        Component.onCompleted: root.workspacesItem = workspacesEntry
                    }
                }
            }
            DelegateChoice {
                roleValue: "layout"
                delegate: EntryWrapper {
                    visible: btn.active

                    LayoutButton {
                        id: btn

                        objectName: "taskbarLayoutButton"
                        Component.onCompleted: root.layoutItem = btn
                    }
                }
            }
            DelegateChoice {
                roleValue: "activeWindow"
                delegate: EntryWrapper {
                    AppsList {
                        id: appsEntry
                        objectName: "taskbarAppsList"
                        bar: root
                        Component.onCompleted: root.appsItem = appsEntry
                    }
                }
            }
            DelegateChoice {
                roleValue: "tray"
                delegate: EntryWrapper {
                    visible: trayStrip.active

                    Tray {
                        id: trayStrip

                        objectName: "taskbarTray"
                        onClicked: root.openPopoutNamed("tray")
                        Component.onCompleted: root.trayItem = trayStrip
                    }
                }
            }
            DelegateChoice {
                roleValue: "clock"
                delegate: EntryWrapper {
                    Clock {
                        objectName: "taskbarClock"
                        onClicked: root.clickClock()
                    }
                }
            }
            DelegateChoice {
                roleValue: "statusIcons"
                delegate: EntryWrapper {
                    StatusIcons {
                        id: statusEntry
                        objectName: "taskbarStatusIcons"
                        Component.onCompleted: root.statusItem = statusEntry
                    }
                }
            }
            DelegateChoice {
                roleValue: "power"
                delegate: EntryWrapper {
                    Power {
                        objectName: "taskbarPowerButton"
                        screenState: root.screenState
                    }
                }
            }
        }
    }

    component EntryWrapper: Item {
        required final property var modelData
        required final property int index
        default final property Item item
        readonly final property string entryId: BH.field(modelData, "id")

        Layout.topMargin: index === 0 ? root.vPadding : 0
        Layout.bottomMargin: index === repeater.count - 1 ? root.vPadding : 0
        Layout.alignment: Qt.AlignHCenter

        implicitWidth: item?.implicitWidth ?? 0
        implicitHeight: item?.implicitHeight ?? 0

        children: item
    }
}
