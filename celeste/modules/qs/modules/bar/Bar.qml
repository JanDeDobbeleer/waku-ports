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

ColumnLayout {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property bool fullscreen
    readonly property int vPadding: Tokens.padding.large

    function closeTray(): void {
        if (!Config.bar.tray.compact)
            return;

        for (let i = 0; i < repeater.count; i++) {
            const tray = repeater.itemAt(i)?.item;
            if (tray && tray.expanded !== undefined)
                tray.expanded = false;
        }
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
        return !ch || !ch.item;
    }

    function checkPopout(y: real): void {
        const ch = childAt(width / 2, y);

        if (ch?.entryId !== "tray")
            closeTray();

        // Port: leaving the clock closes its popout, and so does leaving the layout button.
        if (ch?.entryId !== "clock" && popouts.currentName === "clock")
            popouts.hasCurrent = false;
        if (ch?.entryId !== "layout" && popouts.currentName === "layout")
            popouts.hasCurrent = false;
        if (ch?.entryId !== "tray" && popouts.currentName === "tray")
            popouts.hasCurrent = false;

        if (!ch) {
            popouts.hasCurrent = false;
            return;
        }

        const id = ch.entryId;
        const top = ch.y;

        if (id === "clock") {
            // Port: hovering the clock opens the calendar, unless the dashboard is open.
            if (screenState.dashboard) {
                if (popouts.currentName === "clock")
                    popouts.hasCurrent = false;
            } else {
                popouts.currentName = "clock";
                popouts.currentCenter = ch.mapToItem(root, 0, ch.height / 2).y;
                popouts.hasCurrent = true;
            }
        } else if (id === "layout") {
            // Port: hovering the layout button opens its hint.
            if (ch.item.active) {
                popouts.currentName = "layout";
                popouts.currentCenter = ch.mapToItem(root, 0, ch.height / 2).y;
                popouts.hasCurrent = true;
            }
        } else if (id === "statusIcons" && Config.bar.popouts.statusIcons) {
            const items = ch.item.items;
            const icon = items.childAt(items.width / 2, mapToItem(items, 0, y).y);
            if (icon) {
                popouts.currentName = icon.name;
                popouts.currentCenter = Qt.binding(() => icon.mapToItem(root, 0, icon.implicitHeight / 2).y);
                popouts.hasCurrent = true;
            }
        } else if (id === "tray" && Config.bar.popouts.tray) {
            // Port: hovering the tray button opens the flyout with every icon.
            if (ch.visible && ch.item.active) {
                popouts.currentName = "tray";
                popouts.currentCenter = ch.mapToItem(root, 0, ch.height / 2).y;
                popouts.hasCurrent = true;
            }
        } else if (id === "activeWindow" && Config.bar.popouts.activeWindow && Config.bar.activeWindow.showOnHover) {
            // Port: the popout shows the window under the cursor (see AppsList), or the windows of
            // an application with several (the "appgroup" popout).
            const app = ch.item.appAt(ch.item.mapFromItem(root, 0, y).y);
            if (app) {
                const group = app.modelData;
                // Port: one window or several, the flyout shows preview cards.
                Hypr.hoverGroupKey = group.key;
                popouts.currentName = "appgroup";
                popouts.currentCenter = app.mapToItem(root, 0, app.height / 2).y;
                popouts.hasCurrent = true;
            } else {
                popouts.hasCurrent = false;
            }
        }
    }

    // Port, test only (DebugIpc): sets the state checkPopout sets when the cursor is over the entry
    // named `name` ("network", "bluetooth", "battery", "audio", "kblayout", "lockstatus",
    // "activewindow"). Returns false when no such entry is in the bar.
    function debugEntries(): string {
        const out = [];
        for (let i = 0; i < repeater.count; i++) {
            const ch = repeater.itemAt(i);
            let extra = "";
            if (ch?.entryId === "statusIcons")
                extra = "[" + Array.from({length: ch.item.items.children.length}, (_, j) => ch.item.items.children[j].name).join(",") + "]";
            out.push(`${ch?.entryId}${extra}`);
        }
        return out.join(" ");
    }

    function openPopoutNamed(name: string): bool {
        for (let i = 0; i < repeater.count; i++) {
            const ch = repeater.itemAt(i);
            if (!ch)
                continue;
            if (ch.entryId === "clock" && name === "clock") {
                popouts.currentName = name;
                popouts.currentCenter = ch.mapToItem(root, 0, ch.height / 2).y;
                popouts.hasCurrent = true;
                return true;
            } else if (ch.entryId === "tray" && name === "tray") {
                if (!ch.visible || !ch.item.active)
                    return false;
                popouts.currentName = name;
                popouts.currentCenter = ch.mapToItem(root, 0, ch.height / 2).y;
                popouts.hasCurrent = true;
                return true;
            } else if (ch.entryId === "layout" && name === "layout") {
                popouts.currentName = name;
                popouts.currentCenter = ch.mapToItem(root, 0, ch.height / 2).y;
                popouts.hasCurrent = true;
                return true;
            } else if (ch.entryId === "activeWindow" && name.toLowerCase().startsWith("appgroup:")) {
                // "appGroup:<exe>": the flyout of that application's group.
                const key = name.slice("appgroup:".length);
                const app = ch.item.appForKey(key);
                if (!app)
                    return false;
                Hypr.hoverGroupKey = key;
                popouts.currentName = "appgroup";
                popouts.currentCenter = app.mapToItem(root, 0, app.height / 2).y;
                popouts.hasCurrent = true;
                return true;
            } else if (ch.entryId === "statusIcons") {
                const items = ch.item.items;
                for (let j = 0; j < items.children.length; j++) {
                    const icon = items.children[j];
                    if (icon.name === name) {
                        popouts.currentName = icon.name;
                        popouts.currentCenter = Qt.binding(() => icon.mapToItem(root, 0, icon.implicitHeight / 2).y);
                        popouts.hasCurrent = true;
                        return true;
                    }
                }
            } else if (ch.entryId === "activeWindow" && name === "activewindow") {
                Hypr.hoverToplevel = null;
                popouts.currentName = name;
                popouts.currentCenter = ch.item.mapToItem(root, 0, ch.item.implicitHeight / 2).y;
                popouts.hasCurrent = true;
                return true;
            }
        }
        return false;
    }

    // Port, test only (DebugIpc): the item of the entry with this id, or null.
    function entryItem(id: string): var {
        for (let i = 0; i < repeater.count; i++) {
            const ch = repeater.itemAt(i);
            if (ch?.entryId === id)
                return ch.item;
        }
        return null;
    }

    function handleWheel(y: real, angleDelta: point): void {
        const ch = childAt(width / 2, y);
        if (ch?.entryId === "layout") {
            // Port: the wheel over the layout button cycles the layout (wheel up: previous).
            ch.item.cycle(angleDelta.y > 0 ? "previous" : "next");
        } else if (ch?.entryId === "workspaces" && Config.bar.scrollActions.workspaces) {
            // Workspace scroll
            const mon = Hypr.monitorFor(screen);
            const specialWs = mon?.lastIpcObject.specialWorkspace.name;
            if (specialWs?.length > 0)
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.workspace.toggle_special("${specialWs.slice(8)}")` : `togglespecialworkspace ${specialWs.slice(8)}`);
            else if (ch.item?.wsIds?.length > 0) {
                // Port: step through the dots that are shown, and wrap at both ends. The
                // dynamic dots hide empty desktops, so a step over all of them would leave the
                // dots unchanged.
                const ids = ch.item.wsIds;
                const at = Math.max(0, ids.indexOf(mon?.activeWorkspace?.id));
                const next = ids[(at + (angleDelta.y > 0 ? -1 : 1) + ids.length) % ids.length];
                Hypr.dispatch(`workspace ${next}`);
            }
        } else if (y < screen.height / 2 && Config.bar.scrollActions.volume) {
            // Volume scroll on top half
            if (angleDelta.y > 0)
                Audio.incrementVolume();
            else if (angleDelta.y < 0)
                Audio.decrementVolume();
        } else if (Config.bar.scrollActions.brightness) {
            // Brightness scroll on bottom half
            const monitor = Brightness.getMonitorForScreen(screen);
            if (angleDelta.y > 0)
                monitor.setBrightness(monitor.brightness + GlobalConfig.services.brightnessIncrement);
            else if (angleDelta.y < 0)
                monitor.setBrightness(monitor.brightness - GlobalConfig.services.brightnessIncrement);
        }
    }

    spacing: Tokens.spacing.medium

    Repeater {
        id: repeater

        model: ScriptModel {
            values: Config.bar.entries.values.filter(e => e.enabled)
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
                        objectName: "taskbarWorkspaces"
                        screen: root.screen
                        fullscreen: root.fullscreen
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
                    }
                }
            }
            DelegateChoice {
                roleValue: "activeWindow"
                delegate: EntryWrapper {
                    AppsList {
                        objectName: "taskbarAppsList"
                        bar: root
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
                        objectName: "taskbarStatusIcons"
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
        required property var modelData
        required property int index
        default property Item item
        readonly property string entryId: modelData.id

        Layout.topMargin: index === 0 ? root.vPadding : 0
        Layout.bottomMargin: index === repeater.count - 1 ? root.vPadding : 0
        Layout.alignment: Qt.AlignHCenter

        implicitWidth: item?.implicitWidth ?? 0
        implicitHeight: item?.implicitHeight ?? 0

        children: item
    }
}
