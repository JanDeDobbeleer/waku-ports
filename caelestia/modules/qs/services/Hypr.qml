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

    // `komorebic focus-workspace <index>`, an index (0-based) of an existing workspace on the
    // focused monitor. Anything else is dropped.
    function runFocus(mon: var, index: int): void {
        if (!komorebi || mon !== focusedMonitor || !Number.isInteger(index))
            return;
        const count = workspaceList.values.filter(w => w.monitor === mon).length;
        if (index < 0 || index >= count)
            return;
        sendKomorebic(["focus-workspace", String(index)]);
    }

    // The window the bar's running-apps list points at, for the hover popout (null: show the
    // focused one).
    property var hoverToplevel: null

    // Brings a toplevel from `toplevels` to the front and returns what it did, for the test IPC:
    // "focused" (already the focused window: nothing happens, a taskbar click would minimise it),
    // "switch+activate" (its workspace is focused first with `komorebic focus-workspace`, then,
    // after komorebi has uncloaked it, the window is raised), "window-control" (raised through the
    // engine's `WindowControl`), "activate" (raised through a TaskbarModel row), "eager-focus"
    // (`komorebic eager-focus <exe>`: the last resort, it may pick another window of that exe) or
    // "none". The highlight moves at once (`optimisticHwnd`) and settles on komorebi's state.
    function activateToplevel(t: var): string {
        if (!t || !t.address)
            return "none";
        if (focusedHwnd === t.address)
            return "focused";
        optimisticHwnd = String(t.address);
        optimisticAt = Date.now();
        optimisticTimer.restart();
        const exe = t.lastIpcObject?.class ?? "";
        let result;
        if (komorebi && t.monId === focusedMonitor?.id && !t.wsActive) {
            pendingActivate = {
                hwnd: t.address,
                exe: exe
            };
            runFocus(focusedMonitor, t.wsId - 1);
            activateTimer.restart();
            result = "switch+activate";
        } else {
            result = activateHwnd(t.address, exe);
        }
        settleTimer.restart();
        return result;
    }

    function activateHwnd(hwnd: string, exe: string): string {
        // The engine's WindowControl (absent on an older engine).
        if (typeof S.WindowControl !== "undefined" && S.WindowControl) {
            if (S.WindowControl.activate(Number(hwnd)))
                return "window-control";
        }
        const row = taskbarRows[hwnd];
        if (row !== undefined) {
            taskbar.activate(row);
            return "activate";
        }
        // Focus a window by its executable name.
        if (komorebi && /^[A-Za-z0-9_.\- ]+$/.test(exe)) {
            sendKomorebic(["eager-focus", exe.toLowerCase().endsWith(".exe") ? exe : exe + ".exe"]);
            return "eager-focus";
        }
        return "none";
    }

    // What a click on a group icon activates: the next window of the group when one of them has
    // focus, else the one that had focus last (or the first). Returns what activateToplevel did.
    function clickGroup(g: var): string {
        const ws = g?.windows ?? [];
        if (ws.length === 0)
            return "none";
        const fi = ws.findIndex(t => t.address === focusedHwnd);
        let target;
        if (fi >= 0)
            target = ws.length > 1 ? ws[(fi + 1) % ws.length] : ws[0];
        else
            target = ws.find(t => t.address === groupLastFocused[g.key]) ?? ws[0];
        return activateToplevel(target);
    }

    // Window `i` of group `key`, activated like a click on a single icon.
    function activateGroupWindow(key: string, i: int): string {
        const g = appGroups.find(x => x.key === key);
        return g?.windows[i] ? activateToplevel(g.windows[i]) : "none";
    }

    // The workspace name (a roman numeral) of the workspace a toplevel is on.
    function workspaceLabel(t: var): string {
        const w = workspaceList.values.find(x => x.monitor?.id === t?.monId && x.id === t?.wsId);
        return w?.name ?? String(t?.wsId ?? "");
    }

    // The only komorebic commands this shell sends: focus-workspace, eager-focus, cycle-layout and
    // change-layout. With `dry` the command is logged and not run (tests). A refresh of the state
    // follows.
    readonly property var allowedCommands: ["focus-workspace", "eager-focus", "cycle-layout", "change-layout"]
    readonly property var layoutNames: ["BSP", "Columns", "Rows", "VerticalStack", "HorizontalStack", "UltrawideVerticalStack", "Grid", "RightMainVerticalStack"]
    property string lastCommand: ""

    function sendKomorebic(args: var, dry = false): bool {
        if (!komorebi || !allowedCommands.includes(args[0]))
            return false;
        if (args[0] === "change-layout" && !layoutNames.includes(args[1]))
            return false;
        if (args[0] === "cycle-layout" && args[1] !== "next" && args[1] !== "previous")
            return false;
        lastCommand = "komorebic " + args.join(" ");
        settleTimer.restart();
        if (dry) {
            console.log("dry run: " + lastCommand);
            return true;
        }
        focusProc.pending = ["komorebic"].concat(args);
        if (!focusProc.running)
            focusProc.start();
        return true;
    }

    // Cycles the layout of the focused workspace (`next` or `previous`).
    function cycleLayout(direction: string, dry = false): bool {
        return sendKomorebic(["cycle-layout", direction], dry);
    }

    function setLayout(name: string, dry = false): bool {
        return sendKomorebic(["change-layout", name], dry);
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
        const layouts = {};
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
            // `layout` is { "Default": "BSP" }, { "Custom": [...] } or a bare name.
            const l = ws.layout;
            layouts[mi + ":" + wi] = typeof l === "string" ? l : (l?.Default ?? (l?.Custom ? "Custom" : ""));
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
        // komorebi's answer replaces the guess, unless the guess is too fresh to be in the state.
        if (optimisticHwnd && Date.now() - optimisticAt > 300) {
            optimisticHwnd = "";
            optimisticTimer.stop();
        }
        const stateSig = JSON.stringify([layouts, map]);
        if (stateSig === lastStateSig)
            return;
        lastStateSig = stateSig;
        wsLayouts = layouts;
        wsWindows = map;
        rebuild();
    }

    // What the last rebuild was made from. An identical input does nothing: the objects below are
    // kept, so a delegate bound to one never sees it replaced.
    property string rebuildSig: ""
    // The Mon and Ws objects by key: screen name, and screen name + engine workspace id.
    property var monObjs: ({})
    property var wsObjs: ({})
    // key -> signature of the windows last given to that workspace.
    property var wsWinSigs: ({})

    function sameList(a: var, b: var): bool {
        if (a.length !== b.length)
            return false;
        for (let i = 0; i < a.length; i++)
            if (a[i] !== b[i])
                return false;
        return true;
    }

    // Brings monitors, workspaces and windows up to date with the engine's workspaces, the
    // `komorebic state` windows and the screens. Objects are kept by identity: a property is set
    // only when it differs, an object is created or destroyed only for a real addition or removal,
    // and a list is assigned only when its members changed.
    function rebuild(): void {
        const wabarMons = S.Workspaces.monitors;
        const screens = Quickshell.screens;

        // 1. Plan: plain data only, so the signature can tell whether anything changed.
        const plan = [];
        for (let i = 0; i < screens.length; i++) {
            const screen = screens[i];
            // The index, not the object: indexOf() on a fresh list of QObject wrappers gave -1,
            // so `komorebic state` windows (keyed by monitor index) were never found.
            let wmi = wabarMons.findIndex(m => m.name === screen.name);
            if (wmi < 0 && wabarMons.length === screens.length)
                wmi = i;
            const wm = wmi >= 0 ? wabarMons[wmi] : null;
            const wsPlan = [];
            const list = wm?.workspaces ?? [];
            for (let j = 0; j < list.length; j++) {
                const src = list[j];
                wsPlan.push({
                    key: screen.name + "|" + src.id,
                    srcId: String(src.id),
                    index: j,
                    label: src.label || String(j + 1),
                    active: !!src.active,
                    focused: !!src.focused,
                    layout: wsLayouts[wmi + ":" + j] ?? "",
                    windows: windowsOf(wmi, j, !!src.active)
                });
            }
            plan.push({
                name: screen.name,
                id: i,
                handle: wm?.handle ?? 0,
                workspaces: wsPlan
            });
        }
        const sig = JSON.stringify(plan);
        if (sig === rebuildSig)
            return;
        rebuildSig = sig;

        // 2. Apply, in place.
        const mons = [];
        const wss = [];
        const newMonObjs = {};
        const newWsObjs = {};
        const newWinSigs = {};
        let focusedMon = null;
        let windowsChanged = false;
        let created = 0;

        for (const mp of plan) {
            let mon = monObjs[mp.name];
            if (!mon) {
                mon = monComp.createObject(root, {
                    name: mp.name,
                    id: mp.id,
                    handle: mp.handle
                });
                created++;
            } else {
                if (mon.id !== mp.id)
                    mon.id = mp.id;
                if (mon.handle !== mp.handle)
                    mon.handle = mp.handle;
            }
            newMonObjs[mp.name] = mon;
            mons.push(mon);
            let activeWs = null;
            for (const wp of mp.workspaces) {
                const winSig = JSON.stringify(wp.windows);
                let ws = wsObjs[wp.key];
                const isNew = !ws;
                if (isNew) {
                    ws = wsComp.createObject(root, {
                        key: wp.srcId,
                        monitor: mon
                    });
                    created++;
                }
                if (ws.id !== wp.index + 1)
                    ws.id = wp.index + 1;
                if (ws.layoutName !== wp.layout)
                    ws.layoutName = wp.layout;
                if (ws.name !== wp.label)
                    ws.name = wp.label;
                if (ws.monitor !== mon)
                    ws.monitor = mon;
                if (ws.active !== wp.active)
                    ws.active = wp.active;
                if (ws.focused !== wp.focused)
                    ws.focused = wp.focused;
                if (isNew || wsWinSigs[wp.key] !== winSig) {
                    windowsChanged = true;
                    ws.toplevels = {
                        values: wp.windows
                    };
                    ws.lastIpcObject = {
                        windows: wp.windows.length
                    };
                    for (const w of wp.windows)
                        w.workspace = ws;
                }
                newWinSigs[wp.key] = winSig;
                newWsObjs[wp.key] = ws;
                wss.push(ws);
                if (wp.active)
                    activeWs = ws;
                if (wp.focused)
                    focusedMon = mon;
            }
            if (activeWs && mon.activeWorkspace !== activeWs)
                mon.activeWorkspace = activeWs;
        }
        if (!focusedMon && mons.length > 0)
            focusedMon = mons[0];
        for (const m of mons)
            if (m.focused !== (m === focusedMon))
                m.focused = m === focusedMon;

        // Objects that are gone, for the destroy below.
        const oldObjs = [];
        for (const k of Object.keys(monObjs))
            if (!newMonObjs[k])
                oldObjs.push(monObjs[k]);
        for (const k of Object.keys(wsObjs))
            if (!newWsObjs[k])
                oldObjs.push(wsObjs[k]);
        if (oldObjs.length > 0)
            windowsChanged = true;
        monObjs = newMonObjs;
        wsObjs = newWsObjs;
        wsWinSigs = newWinSigs;

        // 3. Publish. A list that did not change is not assigned, so nothing downstream re-evaluates.
        if (!sameList(monitorList.values, mons))
            monitorList.values = mons;
        if (!sameList(workspaceList.values, wss))
            workspaceList.values = wss;
        if (windowsChanged) {
            const all = [];
            for (const w of wss)
                for (const t of w.toplevels.values)
                    all.push(t);
            toplevelList.values = all;
            updateGroups(all);
        }
        for (const o of oldObjs)
            o.destroy();
    }

    // The apps list groups windows by application: the executable name (`lastIpcObject.class`),
    // else the window class, else the window itself. `groupOrder` keeps first-seen order, so the
    // icons do not move when the focus changes.
    property var appGroups: []
    property var groupOrder: []
    // The group the hover popout lists.
    property string hoverGroupKey: ""

    function groupKey(t: var): string {
        return t.lastIpcObject?.class || t.lastIpcObject?.windowClass || t.address;
    }

    // TEST ONLY (DebugIpc): adds this many fake windows to the first application, to try the group
    // badge and flyout when no application has several windows. They are never focusable.
    property int debugCopies: 0
    property var lastAll: []

    onDebugCopiesChanged: updateGroups(lastAll)

    function updateGroups(real: var): void {
        lastAll = real;
        const all = real.slice();
        for (let i = 0; i < debugCopies && real.length > 0; i++)
            all.push(Object.assign({}, real[0], {
                address: "fake" + i,
                srcHwnd: real[0].address,
                title: "Fake window " + (i + 1),
                wsId: ((real[0].wsId + i) % 7) + 1
            }));
        const by = {};
        for (const t of all) {
            if (!t.address)
                continue;
            const k = groupKey(t);
            if (!by[k])
                by[k] = [];
            by[k].push(t);
        }
        const order = groupOrder.filter(k => by[k]);
        for (const k of Object.keys(by))
            if (!order.includes(k))
                order.push(k);
        groupOrder = order;
        appGroups = order.map(k => ({
                    key: k,
                    exe: k,
                    windows: by[k],
                    icon: by[k][0].icon,
                    iconUrl: by[k][0].iconUrl
                }));
    }

    Component.onCompleted: rebuild()

    Connections {
        function onChanged(): void {
            // The engine emits `changed` for events that leave the workspaces as they were.
            const sig = JSON.stringify([S.Workspaces.provider, S.Workspaces.connected, S.Workspaces.monitors]);
            if (sig === root.engineSig)
                return;
            root.engineSig = sig;
            root.rebuild();
            root.queue();
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
    // "<monitor>:<workspace>" -> komorebi layout name.
    property var wsLayouts: ({})
    // hwnd -> row of the ungrouped TaskbarModel, for `taskbar.activate(row)`.
    property var taskbarRows: ({})
    property var pendingActivate: null
    property string komorebiFocused: ""
    // The window with focus: the foreground taskbar row when the engine lists it, else the one
    // komorebi has focused.
    // `optimisticHwnd` leads for a moment after a click, so the highlight moves at once.
    readonly property string focusedHwnd: optimisticHwnd || foreground?.address || komorebiFocused
    property string optimisticHwnd: ""
    property real optimisticAt: 0
    // key (the app's executable) -> hwnd of the group's window that had focus last.
    property var groupLastFocused: ({})
    onFocusedHwndChanged: {
        const t = toplevelList.values.find(x => x.address === focusedHwnd);
        if (t) {
            const k = groupKey(t);
            if (groupLastFocused[k] !== t.address)
                groupLastFocused[k] = t.address;
        }
    }
    // Set by the bar: a window for the taskbar model (see the model below).
    property var barWindow: null
    readonly property int taskbarCount: taskbar.count
    readonly property bool taskbarAvailable: S.TaskbarService.available

    readonly property bool komorebi: S.Workspaces.provider === "komorebi"

    property string lastStateSig: ""
    property string engineSig: ""
    property string knownSig: ""
    property string knownKeys: ""
    property string rowsSig: ""
    property string foregroundSig: ""
    function queue(): void {
        if (!stateTimer.running)
            stateTimer.start();
    }
    onKomorebiChanged: queue()

    // komorebi events that change no workspace (a layout set by a hotkey) do not show in the
    // engine's data, so the state is read now and then anyway. An unchanged answer does nothing.
    Timer {
        interval: 10000
        repeat: true
        running: root.komorebi
        onTriggered: root.queue()
    }

    // Read only: `komorebic state` prints the state and changes nothing.
    Timer {
        id: stateTimer

        interval: 150
        onTriggered: {
            if (!root.komorebi) {
                root.lastStateSig = "";
                root.wsWindows = {};
                root.wsLayouts = {};
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

    // The optimistic highlight lasts 1.5 s at most.
    Timer {
        id: optimisticTimer

        interval: 1500
        onTriggered: root.optimisticHwnd = ""
    }

    // Refreshes the state a moment after a command or an activation, so the highlight settles on
    // what komorebi reports.
    Timer {
        id: settleTimer

        interval: 400
        onTriggered: root.queue()
    }

    // Runs the allowed komorebic commands (see sendKomorebic); a request made while it runs waits
    // and replaces any earlier waiting one.
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

        // The model has no service of its own: without this it never has a row.
        service: S.TaskbarService
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
            const knownSig = JSON.stringify(known);
            if (knownSig !== root.knownSig) {
                const keys = Object.keys(known).sort().join(",");
                root.knownSig = knownSig;
                root.taskbarWindows = known;
                // A title or an icon needs no new state, only a new join. A window that came or
                // went does.
                if (keys !== root.knownKeys) {
                    root.knownKeys = keys;
                    root.queue();
                }
                root.rebuild();
            }
            const idxSig = JSON.stringify(idx);
            if (idxSig !== root.rowsSig) {
                root.rowsSig = idxSig;
                root.taskbarRows = idx;
            }
            for (let i = 0; i < count; i++) {
                const o = objectAt(i);
                if (o && o.active) {
                    const fgSig = o.key + "|" + o.title + "|" + o.exe;
                    if (fgSig === root.foregroundSig && root.foreground)
                        return;
                    root.foregroundSig = fgSig;
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
            root.foregroundSig = "";
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
        property string layoutName
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
