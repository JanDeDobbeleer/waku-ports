pragma ComponentBehavior: Bound

import "components"
import "components/workspaces"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
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

    function checkPopout(y: real): void {
        const ch = childAt(width / 2, y);

        if (ch?.entryId !== "tray")
            closeTray();

        if (!ch) {
            popouts.hasCurrent = false;
            return;
        }

        const id = ch.entryId;
        const top = ch.y;

        if (id === "statusIcons" && Config.bar.popouts.statusIcons) {
            const items = ch.item.items;
            const icon = items.childAt(items.width / 2, mapToItem(items, 0, y).y);
            if (icon) {
                popouts.currentName = icon.name;
                popouts.currentCenter = Qt.binding(() => icon.mapToItem(root, 0, icon.implicitHeight / 2).y);
                popouts.hasCurrent = true;
            }
        } else if (id === "tray" && Config.bar.popouts.tray) {
            const tray = ch.item;
            if (!Config.bar.tray.compact || (tray.expanded && !tray.expandIcon.contains(mapToItem(tray.expandIcon, tray.implicitWidth / 2, y)))) {
                // Port: no tray menu popout (the menu is null on Windows).
                popouts.hasCurrent = false;
            } else {
                popouts.hasCurrent = false;
                tray.expanded = true;
            }
        } else if (id === "activeWindow" && Config.bar.popouts.activeWindow && Config.bar.activeWindow.showOnHover) {
            // Port: the popout shows the window under the cursor (see AppsList).
            const app = ch.item.appAt(ch.item.mapFromItem(root, 0, y).y);
            if (app) {
                Hypr.hoverToplevel = app.modelData;
                popouts.currentName = id.toLowerCase();
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
            if (ch.entryId === "statusIcons") {
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
        if (ch?.entryId === "workspaces" && Config.bar.scrollActions.workspaces) {
            // Workspace scroll
            const mon = Hypr.monitorFor(screen);
            const specialWs = mon?.lastIpcObject.specialWorkspace.name;
            if (specialWs?.length > 0)
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.workspace.toggle_special("${specialWs.slice(8)}")` : `togglespecialworkspace ${specialWs.slice(8)}`);
            else if (angleDelta.y < 0 || mon.activeWorkspace?.id > 1)
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ workspace = "r${angleDelta.y > 0 ? "-" : "+"}1" })` : `workspace r${angleDelta.y > 0 ? "-" : "+"}1`);
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
                    Tray {
                        objectName: "taskbarTray"
                    }
                }
            }
            DelegateChoice {
                roleValue: "clock"
                delegate: EntryWrapper {
                    Clock {
                        objectName: "taskbarClock"
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
