pragma ComponentBehavior: Bound

import "components"
import "components/workspaces"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Celeste.Config
import qs.components
import qs.services
import qs.utils
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
        BH.showPopout(root, popouts, name, ch);
    }

    function checkPopout(y: real): void {
        BH.checkPopout(root, y, Hypr, Config, Qt);
    }

    // Port, test only (DebugIpc): the entry ids, with the names of the status icons.
    function debugEntries(): string {
        return BH.debugEntries(repeater, statusItem);
    }

    // Port, test only (DebugIpc): sets the state checkPopout sets when the cursor is over the entry
    // named `name` ("network", "bluetooth", "battery", "audio", "kblayout", "lockstatus",
    // "activewindow"). Returns false when no such entry is in the bar.
    function openPopoutNamed(name: string): bool {
        return BH.openPopoutNamed(root, name, repeater, statusItem, appsItem, Hypr, Qt);
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
        BH.handleWheel(root, y, angleDelta, Hypr, Paths, Config, Audio, Brightness, GlobalConfig);
    }
    spacing: Tokens.spacing.medium

    Repeater {
        id: repeater

        model: ScriptModel {
            values: BH.enabledEntries(Config.bar.entries)
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

        implicitWidth: BH.implicitWidth(item)
        implicitHeight: BH.implicitHeight(item)

        children: item
    }
}
