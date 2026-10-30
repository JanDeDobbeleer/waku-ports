pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
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
//
// wabar gap: `Workspaces` gives a window count per workspace, not the windows. With komorebi the
// windows of each workspace come from a read-only `komorebic state` (hwnd lists per monitor and
// workspace, in the same order as `Workspaces`), joined by hwnd with the ungrouped TaskbarModel
// rows (key `w:<hwnd>`: title, executable, icon). A window the taskbar does not list (tool
// windows, overlays) is not shown. With GlazeWM, or before the first state, a workspace has no
// windows.
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

    // Relative step on the focused monitor, clamped to its first and last workspace.
    function stepWorkspace(delta: int): void {
        const mon = focusedMonitor;
        const current = mon?.activeWorkspace;
        if (!current)
            return;
        runFocus(mon, current.id - 1 + delta);
    }

    // `ws` is a workspace id (its 1-based position on the monitor) or its name.
    function focusWorkspace(ws: var): void {
        const mon = focusedMonitor;
        if (!mon)
            return;
        const target = workspaceList.values.find(w => w.monitor === mon && (w.id === Number(ws) || w.name === String(ws)));
        if (target)
            runFocus(mon, target.id - 1);
    }

    // The only command this shell sends to komorebi: `komorebic focus-workspace <index>`, an
    // index (0-based) of an existing workspace on the focused monitor. Anything else is dropped.
    function runFocus(mon: var, index: int): void {
        if (!komorebi || mon !== focusedMonitor || !Number.isInteger(index))
            return;
        const count = workspaceList.values.filter(w => w.monitor === mon).length;
        if (index < 0 || index >= count)
            return;
        focusProc.pending = ["komorebic", "focus-workspace", String(index)];
        if (!focusProc.running)
            focusProc.start();
    }

    // The window the bar's running-apps list points at, for the hover popout (null: show the
    // focused one).
    property var hoverToplevel: null

    // Brings a toplevel from `toplevels` to the front and returns what it did, for the test IPC:
    // "focused" (already the foreground window: nothing happens, a taskbar click would minimise
    // it), "activate" (hwnd raised through the engine's TaskbarModel), "switch+activate" (its
    // workspace is focused first with `komorebic focus-workspace`, then the hwnd is raised after
    // komorebi has uncloaked it), "eager-focus" (the taskbar has no row for it: `komorebic
    // eager-focus <exe>`), or "none".
    function activateToplevel(t: var): string {
        if (!t || !t.address)
            return "none";
        if (focusedHwnd === t.address)
            return "focused";
        const exe = t.lastIpcObject?.class ?? "";
        if (komorebi && t.monId === focusedMonitor?.id && !t.wsActive) {
            pendingActivate = {
                hwnd: t.address,
                exe: exe
            };
            runFocus(focusedMonitor, t.wsId - 1);
            activateTimer.restart();
            return "switch+activate";
        }
        return activateHwnd(t.address, exe);
    }

    function activateHwnd(hwnd: string, exe: string): string {
        const row = taskbarRows[hwnd];
        if (row !== undefined) {
            taskbar.activate(row);
            return "activate";
        }
        // The only other command besides focus-workspace: focus a window by its executable name.
        if (komorebi && /^[A-Za-z0-9_.\- ]+$/.test(exe)) {
            focusProc.pending = ["komorebic", "eager-focus", exe.toLowerCase().endsWith(".exe") ? exe : exe + ".exe"];
            if (!focusProc.running)
                focusProc.start();
            return "eager-focus";
        }
        return "none";
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

    // Executable name without ".exe", lower case: what a desktop entry or an icon rule matches.
    function appName(exe: string): string {
        return (exe ?? "").replace(/\.exe$/i, "").toLowerCase();
    }

    // `image://appicon/...` of the installed app that `name` matches, or "" when none does.
    function appIconUrl(name: string): string {
        // The exe name first, then without a vendor prefix ("ms-teams") and without separators.
        for (const n of [name, name.replace(/^ms-/, ""), name.replace(/[-_. ]/g, "")]) {
            const icon = n ? DesktopEntries.heuristicLookup(n)?.icon : "";
            const url = icon ? String(Quickshell.iconPath(icon, true)) : "";
            if (url)
                return url;
        }
        return "";
    }

    // Toplevel items of workspace `wsIdx` on monitor `monIdx`, in komorebi's order.
    function windowsOf(monIdx: int, wsIdx: int, wsActive: bool): var {
        const out = [];
        for (const h of wsWindows[monIdx + ":" + wsIdx] ?? []) {
            // The taskbar row adds the icon; komorebi's own title and exe stand in without it
            // (the model has no window to attach to here, so it can stay empty).
            const row = taskbarWindows[h.hwnd] ?? ({
                    title: h.title,
                    exe: h.exe,
                    iconUrl: ""
                });
            const name = appName(h.exe || row.exe);
            // The window's own icon when the taskbar lists it, else the desktop entry's icon.
            const icon = row.iconUrl || appIconUrl(name);
            out.push({
                title: row.title,
                address: String(h.hwnd),
                // Plain values: the object is copied into a `var` list, so a link set later is lost.
                wsId: wsIdx + 1,
                monId: monIdx,
                wsActive: wsActive,
                workspace: null,
                wayland: null,
                iconUrl: row.iconUrl,
                icon: icon,
                lastIpcObject: {
                    address: String(h.hwnd),
                    class: name,
                    initialClass: name,
                    title: row.title,
                    initialTitle: row.title,
                    windowClass: h.windowClass,
                    mapped: true,
                    hidden: false,
                    fullscreen: 0,
                    floating: h.floating,
                    tags: []
                }
            });
        }
        return out;
    }

    // Reads the JSON of `komorebic state` into { "<monitor>:<workspace>": [{hwnd, exe, ...}] }.
    function parseState(text: string): void {
        let state;
        try {
            state = JSON.parse(text);
        } catch (e) {
            return;
        }
        const list = o => Array.isArray(o) ? o : (o?.elements ?? []);
        const one = (w, floating) => ({
                hwnd: w.hwnd,
                exe: w.exe ?? "",
                title: w.title ?? "",
                windowClass: w.class ?? "",
                floating: floating
            });
        const map = {};
        list(state?.monitors).forEach((mon, mi) => list(mon.workspaces).forEach((ws, wi) => {
            const out = [];
            for (const c of list(ws.containers))
                for (const w of list(c.windows))
                    out.push(one(w, false));
            for (const w of list(ws.monocle_container?.windows))
                out.push(one(w, false));
            if (ws.maximized_window)
                out.push(one(ws.maximized_window, false));
            for (const w of list(ws.floating_windows))
                out.push(one(w, true));
            map[mi + ":" + wi] = out;
        }));
        // komorebi's focused window: focused monitor, workspace, container, window.
        let focusedHwnd = "";
        try {
            const mons = state?.monitors;
            const monObj = list(mons)[mons?.focused ?? 0];
            const wsList = monObj?.workspaces;
            const wsObj = list(wsList)[wsList?.focused ?? 0];
            const conts = wsObj?.containers;
            const c = list(conts)[conts?.focused ?? 0];
            const wins = c?.windows;
            const w = list(wins)[wins?.focused ?? 0];
            if (w?.hwnd)
                focusedHwnd = String(w.hwnd);
        } catch (e) {
        }
        komorebiFocused = focusedHwnd;
        wsWindows = map;
        rebuild();
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
            // The index, not the object: indexOf() on a fresh list of QObject wrappers gave -1,
            // so `komorebic state` windows (keyed by monitor index) were never found.
            let wmi = wabarMons.findIndex(m => m.name === screen.name);
            if (wmi < 0 && wabarMons.length === screens.length)
                wmi = i;
            const wm = wmi >= 0 ? wabarMons[wmi] : null;
            const mon = monComp.createObject(root, {
                name: screen.name,
                id: i,
                handle: wm?.handle ?? 0
            });
            mons.push(mon);
            const list = wm?.workspaces ?? [];
            for (let j = 0; j < list.length; j++) {
                const src = list[j];
                const windows = windowsOf(wmi, j, src.active);
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
                        windows: windows.length
                    }
                });
                wss.push(ws);
                for (const w of windows)
                    w.workspace = ws;
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
        const all = [];
        for (const w of workspaceList.values)
            for (const t of w.toplevels.values)
                all.push(t);
        toplevelList.values = all;
        for (const o of oldMons)
            o.destroy();
        for (const o of oldWs)
            o.destroy();
    }

    Component.onCompleted: rebuild()

    Connections {
        function onChanged(): void {
            root.rebuild();
            stateTimer.restart();
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

        // The windows of all workspaces that komorebi and the taskbar both know.
        property var values: []
    }

    // Foreground window from the taskbar rows.
    property var foreground: null
    // hwnd -> { title, exe, iconUrl } for every taskbar row, and the komorebi windows per workspace.
    property var taskbarWindows: ({})
    property var wsWindows: ({})
    // hwnd -> row of the ungrouped TaskbarModel, for `taskbar.activate(row)`.
    property var taskbarRows: ({})
    property var pendingActivate: null
    property string komorebiFocused: ""
    // The window with focus: the foreground taskbar row when the engine lists it, else the one
    // komorebi has focused.
    readonly property string focusedHwnd: foreground?.address || komorebiFocused
    // Set by the bar: a window for the taskbar model (see the model below).
    property var barWindow: null
    readonly property int taskbarCount: taskbar.count
    readonly property bool taskbarAvailable: S.TaskbarService.available

    readonly property bool komorebi: S.Workspaces.provider === "komorebi"

    onKomorebiChanged: stateTimer.restart()

    // Read only: `komorebic state` prints the state and changes nothing.
    Timer {
        id: stateTimer

        interval: 150
        onTriggered: {
            if (!root.komorebi) {
                root.wsWindows = {};
                root.rebuild();
            } else if (statePoll.running) {
                stateTimer.restart();
            } else {
                statePoll.running = true;
            }
        }
    }

    Process {
        id: statePoll

        command: ["komorebic", "state"]
        stdout: StdioCollector {
            onStreamFinished: root.parseState(text)
        }
    }

    // Waits for komorebi to uncloak the windows of the workspace just focused, then raises one.
    Timer {
        id: activateTimer

        interval: 350
        onTriggered: {
            const p = root.pendingActivate;
            root.pendingActivate = null;
            if (p)
                root.activateHwnd(p.hwnd, p.exe);
        }
    }

    // Runs the allowed komorebic commands (focus-workspace from runFocus, eager-focus from
    // activateHwnd); a request made while it runs waits and
    // replaces any earlier waiting one.
    Process {
        id: focusProc

        property var pending: []

        function start(): void {
            command = pending;
            pending = [];
            running = true;
        }

        onRunningChanged: {
            if (!running && pending.length > 0)
                start();
        }
    }

    S.TaskbarModel {
        id: taskbar

        grouping: false
        // The engine starts its window tracker only for a model that has a bar window; the apps
        // list hands it its own (see AppsList). showOnlyVisible stays false: komorebi cloaks the
        // windows of the other workspaces and they must stay in the list.
        window: root.barWindow
    }

    Instantiator {
        id: rows

        function update(): void {
            const known = {};
            const idx = {};
            for (let i = 0; i < count; i++) {
                const o = objectAt(i);
                if (o && o.key.startsWith("w:"))
                    idx[o.key.slice(2)] = i;
                if (o && o.key.startsWith("w:"))
                    known[o.key.slice(2)] = {
                        title: o.title,
                        exe: o.exe,
                        iconUrl: o.iconUrl
                    };
            }
            root.taskbarWindows = known;
            root.taskbarRows = idx;
            stateTimer.restart();
            for (let i = 0; i < count; i++) {
                const o = objectAt(i);
                if (o && o.active) {
                    root.foreground = {
                        title: o.title,
                        workspace: null,
                        wayland: null,
                        address: o.key.startsWith("w:") ? o.key.slice(2) : "",
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
            required property string key
            required property string iconUrl
            required property string uniqueId
            readonly property string exe: uniqueId.split(/[\\/!]/).pop().replace(/\.exe$/i, "")

            onActiveChanged: rows.update()
            onTitleChanged: rows.update()
            onIconUrlChanged: rows.update()
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
