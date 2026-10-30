pragma Singleton

import QtQuick
import Quickshell
import Caelestia.I18n
import wabar.services as S
import qs.compat

// Caelestia's Hyprland service over wabar. The objects it hands out (`monitors.values`,
// `workspaces.values`, `activeToplevel`, ...) keep the shape of Quickshell's Hyprland types but are
// plain QtObjects built here, so a module that declares `required property HyprlandMonitor` must
// declare `var` instead.
//
// Sources: komorebi or GlazeWM through `Workspaces` (ids are the workspace's position on its
// monitor, `Hypr.activeWsId` counts from 1), the foreground window through `TaskbarModel`, and
// the lock keys and keyboard layout through `DesktopState`. With no tiling window manager running
// `workspaces.values` is empty and `hasWm` is false, so a bar can show a "no WM" pill.
Singleton {
    id: root

    readonly property bool hasWm: S.Workspaces.connected
    readonly property bool usingLua: false

    readonly property var monitors: monitorList
    readonly property var workspaces: workspaceList
    readonly property var toplevels: toplevelList

    // wabar gap: only the foreground window is known. It has a title and an executable name, no
    // class, address or workspace.
    readonly property var activeToplevel: foreground
    readonly property var focusedWorkspace: workspaceList.values.find(w => w.focused) ?? null
    readonly property var focusedMonitor: monitorList.values.find(m => m.focused) ?? monitorList.values[0] ?? null
    readonly property int activeWsId: focusedWorkspace?.id ?? 1

    // wabar gap: no keyboard device model. The lock keys and the layout come from DesktopState.
    readonly property bool capsLock: S.DesktopState.capsLock
    readonly property bool numLock: S.DesktopState.numLock
    readonly property string defaultKbLayout: S.DesktopState.keyboardLayout || "??"
    readonly property string kbLayoutFull: S.DesktopState.keyboardLayout || Tr.trCtx("Unknown", "keyboard layout")
    readonly property string kbLayout: S.DesktopState.keyboardLayout || "??"
    readonly property var keyboard: null

    readonly property alias extras: extras
    readonly property alias options: extras.options
    readonly property alias devices: extras.devices

    property string lastSpecialWorkspace: ""

    signal configReloaded

    // Understands `workspace N`, `workspace r+1` and `workspace r-1`; everything else is ignored.
    function dispatch(request: string): void {
        const m = /^workspace\s+(r[+-]1|\d+)$/.exec(request ?? "");
        if (!m)
            return;
        if (m[1] === "r+1")
            stepWorkspace(1);
        else if (m[1] === "r-1")
            stepWorkspace(-1);
        else
            focusWorkspace(Number(m[1]));
    }

    function stepWorkspace(delta: int): void {
        const mon = focusedMonitor;
        if (!mon)
            return;
        if (delta > 0)
            S.Workspaces.focusNext(mon.handle);
        else
            S.Workspaces.focusPrevious(mon.handle);
    }

    function focusWorkspace(ws: var): void {
        const mon = focusedMonitor;
        if (!mon)
            return;
        const target = workspaceList.values.find(w => w.monitor === mon && (w.id === Number(ws) || w.name === String(ws)));
        if (target)
            S.Workspaces.focus(mon.handle, target.key);
    }

    // wabar gap: komorebi and GlazeWM have no special workspaces.
    function toggleSpecial(name: string): void {
    }

    function cycleSpecialWorkspace(direction: string): void {
    }

    function monitorNames(): list<string> {
        return monitorList.values.map(e => e.name);
    }

    function monitorFor(screen: ShellScreen): var {
        return monitorList.values.find(m => m.name === screen?.name) ?? null;
    }

    function trimWsName(name: string): string {
        return name.startsWith("special:") ? name.slice("special:".length) : name;
    }

    function toplevelsForWs(ws: int, ignoredTags = []): var {
        const w = (focusedMonitor ? workspaceList.values.find(x => x.monitor === focusedMonitor && x.id === ws) : null) ?? workspaceList.values.find(x => x.id === ws);
        return w ? w.toplevels.values : [];
    }

    function isToplevelIgnored(toplevel: var, ignoredTags = []): bool {
        const ipc = toplevel?.lastIpcObject;
        return !ipc?.class || !ipc.mapped;
    }

    function reloadDynamicConfs(): void {
    }

    function rebuild(): void {
        const oldMons = monitorList.values;
        const oldWs = workspaceList.values;
        const mons = [];
        const wss = [];
        const wabarMons = S.Workspaces.monitors;
        const screens = Quickshell.screens;
        let focusedMon = null;

        for (let i = 0; i < screens.length; i++) {
            const screen = screens[i];
            const wm = wabarMons.find(m => m.name === screen.name) ?? (wabarMons.length === screens.length ? wabarMons[i] : null);
            const mon = monComp.createObject(root, {
                name: screen.name,
                id: i,
                handle: wm?.handle ?? 0
            });
            mons.push(mon);
            const list = wm?.workspaces ?? [];
            for (let j = 0; j < list.length; j++) {
                const src = list[j];
                const windows = [];
                for (let k = 0; k < (src.windowCount ?? 0); k++)
                    windows.push({
                        title: "",
                        workspace: null,
                        lastIpcObject: {
                            class: "window",
                            mapped: true,
                            fullscreen: 0,
                            tags: []
                        }
                    });
                const ws = wsComp.createObject(root, {
                    id: j + 1,
                    key: String(src.id),
                    name: src.label || String(j + 1),
                    monitor: mon,
                    active: src.active,
                    focused: src.focused,
                    toplevels: {
                        values: windows
                    },
                    lastIpcObject: {
                        windows: src.windowCount ?? 0
                    }
                });
                wss.push(ws);
                if (src.active)
                    mon.activeWorkspace = ws;
                if (src.focused)
                    focusedMon = mon;
            }
        }
        if (focusedMon)
            focusedMon.focused = true;
        else if (mons.length > 0)
            mons[0].focused = true;

        monitorList.values = mons;
        workspaceList.values = wss;
        for (const o of oldMons)
            o.destroy();
        for (const o of oldWs)
            o.destroy();
    }

    Component.onCompleted: rebuild()

    Connections {
        function onChanged(): void {
            root.rebuild();
        }

        target: S.Workspaces
    }

    Connections {
        function onScreensChanged(): void {
            root.rebuild();
        }

        target: Quickshell
    }

    QtObject {
        id: monitorList

        property var values: []
    }

    QtObject {
        id: workspaceList

        property var values: []
    }

    QtObject {
        id: toplevelList

        // wabar gap: the window list is not exposed in Hyprland's shape.
        readonly property var values: []
    }

    // Foreground window from the taskbar rows.
    property var foreground: null

    S.TaskbarModel {
        id: taskbar

        grouping: false
    }

    Instantiator {
        id: rows

        function update(): void {
            for (let i = 0; i < count; i++) {
                const o = objectAt(i);
                if (o && o.active) {
                    root.foreground = {
                        title: o.title,
                        workspace: null,
                        wayland: null,
                        address: "",
                        lastIpcObject: {
                            class: o.exe,
                            mapped: true,
                            fullscreen: 0,
                            tags: []
                        }
                    };
                    return;
                }
            }
            root.foreground = null;
        }

        model: taskbar
        delegate: QtObject {
            required property string title
            required property bool active
            required property string uniqueId
            readonly property string exe: uniqueId.split(/[\\/!]/).pop().replace(/\.exe$/i, "")

            onActiveChanged: rows.update()
            onTitleChanged: rows.update()
        }
        onObjectAdded: update()
        onObjectRemoved: update()
    }

    QtObject {
        id: extras

        // wabar gap: nothing to configure. These keep upstream's call sites working.
        property var options: ({})
        property var devices: ({
                keyboards: [],
                mice: []
            })

        function message(msg: string): void {
        }

        function batchMessage(msgs: var): void {
        }

        function applyOptions(opts: var): void {
        }

        function refreshOptions(): void {
        }

        function refreshDevices(): void {
        }
    }

    Component {
        id: monComp

        Mon {}
    }

    Component {
        id: wsComp

        Ws {}
    }

    component Mon: QtObject {
        property string name
        property int id
        property real handle
        property bool focused
        property var activeWorkspace: null
        property var lastIpcObject: ({
                specialWorkspace: {
                    name: ""
                }
            })
    }

    component Ws: QtObject {
        property int id
        property string key
        property string name
        property var monitor: null
        property bool active
        property bool focused
        property var toplevels: ({
                values: []
            })
        property var lastIpcObject: ({
                windows: 0
            })
    }
}
