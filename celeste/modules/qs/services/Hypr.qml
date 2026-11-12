pragma Singleton

import QtQuick
import Quickshell
import Celeste.Config
import Celeste.I18n
import waku.services as S
import qs.compat

// Celeste's Hyprland service over waku. The objects it hands out (`monitors.values`,
// `workspaces.values`, `activeToplevel`, ...) keep the shape of Quickshell's Hyprland types but are
// plain QtObjects built here, so a module that declares `required property HyprlandMonitor` must
// declare `var` instead.
//
// Sources: the Windows virtual desktops through `Workspaces` (ids are the desktop's position,
// `Hypr.activeWsId` counts from 1), the foreground window and the window rows through
// `TaskbarModel`, and the lock keys and keyboard layout through `DesktopState`. Tiling is waku's
// own (`S.Tiling`), not this service's concern.
//
// The engine lists the windows of each desktop (hwnd numbers). They are joined by hwnd with the
// ungrouped taskbar rows (key `w:<hwnd>`); a window without a row is skipped, the rows give title,
// executable, icon and minimized, and the rows' order (first appeared) is the window order. There
// is one engine entry (handle 0) for every screen, so a window is listed once per screen
// workspace but once in `toplevels`.
Singleton {
    id: root

    readonly property bool hasWm: S.Workspaces.connected
    readonly property bool usingLua: false

    readonly property var monitors: monitorList
    readonly property var workspaces: workspaceList
    readonly property var toplevels: toplevelList

    // waku gap: only the foreground window is known. It has a title and an executable name, no
    // class, address or workspace.
    readonly property var activeToplevel: foreground
    readonly property var focusedWorkspace: workspaceList.values.find(w => w.focused) ?? null
    readonly property var focusedMonitor: monitorList.values.find(m => m.focused) ?? monitorList.values[0] ?? null
    readonly property int activeWsId: focusedWorkspace?.id ?? 1

    // waku gap: no keyboard device model. The lock keys and the layout come from DesktopState.
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

    // `ws` is a desktop id (its 1-based position). A dot past the last desktop creates it.
    function focusWorkspace(ws: var): void {
        const n = Number(ws);
        if (Number.isInteger(n) && n >= 1)
            S.Workspaces.focus(0, String(n - 1));
    }

    // Windows virtual desktops: closes desktop `ws` (1-based, like focusWorkspace) the way Task
    // View's close button does, without switching to it. The spare "add" dot (a number past the
    // last desktop) never closes anything.
    function removeWorkspace(ws: var): void {
        if (!canRemoveWorkspace)
            return;
        const n = Number(ws);
        if (Number.isInteger(n) && n >= 1 && n <= S.VirtualDesktops.desktops.length)
            S.Workspaces.remove(0, String(n - 1));
    }

    // Shows the existing desktop `index` (0-based). A step never creates a desktop; only a click on
    // a dot does (focusWorkspace). Anything else is dropped.
    function runFocus(mon: var, index: int): void {
        if (Number.isInteger(index) && index >= 0 && index < S.VirtualDesktops.desktops.length)
            S.Workspaces.focus(0, String(index));
    }

    // The window the bar's running-apps list points at, for the hover popout (null: show the
    // focused one).
    property var hoverToplevel: null

    // Brings a toplevel from `toplevels` to the front and returns what it did, for the test IPC:
    // "focused" (already the focused window: nothing happens, a taskbar click would minimise it),
    // "switch+activate" (its virtual desktop is shown first, then, after the switch, the window is
    // raised), "window-control" (raised through the engine's `WindowControl`), "activate" (raised
    // through a TaskbarModel row) or "none". The highlight moves at once (`optimisticHwnd`) and
    // settles on the foreground window.
    // A minimized window is restored by both raise paths (WindowControl and the taskbar row), never
    // minimized again: it is never the focused window. With `dry` nothing happens; the result
    // says what would (test IPC).
    // Whether raising `t` first needs a switch to its desktop (the monitor does not matter:
    // desktops belong to none).
    function switchesFirst(t: var): bool {
        return !t.wsActive;
    }

    function activateToplevel(t: var, dry = false): string {
        if (!t || !t.address)
            return "none";
        if (focusedHwnd === t.address)
            return "focused";
        if (dry) {
            if (switchesFirst(t))
                return "switch+activate";
            return activateHwnd(t.address, t.lastIpcObject?.class ?? "", true);
        }
        optimisticHwnd = String(t.address);
        optimisticAt = Date.now();
        optimisticTimer.restart();
        const exe = t.lastIpcObject?.class ?? "";
        let result;
        if (switchesFirst(t)) {
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
        return result;
    }

    function activateHwnd(hwnd: string, exe: string, dry = false): string {
        // The engine's WindowControl (absent on an older engine).
        if (typeof S.WindowControl !== "undefined" && S.WindowControl) {
            if (dry)
                return "window-control";
            if (S.WindowControl.activate(Number(hwnd)))
                return "window-control";
        }
        const row = taskbarRows[hwnd];
        if (row !== undefined) {
            if (!dry)
                taskbar.activate(row);
            return "activate";
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

    // waku gap: no special workspaces.
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
        return !ipc?.class || !ipc.mapped || (ipc.tags ?? []).some(t => ignoredTags.includes(t));
    }

    function reloadDynamicConfs(): void {
    }

    // Executable name without ".exe", lower case: what a desktop entry or an icon rule matches.
    function appName(exe: string): string {
        return (exe ?? "").replace(/\.exe$/i, "").toLowerCase();
    }

    // The application a taskbar row belongs to, from the engine's pin id (`uniqueId`): "aumid:<id>"
    // for a packaged app, "explorer:<folder>" for a File Explorer window, "path:<exe>[|args]" for
    // the rest. Windows of one application share one identity, so the apps list groups them:
    //   aumid:Microsoft.WindowsTerminal_8wekyb3d8bbwe!App  ->  microsoft.windowsterminal
    //   explorer:C:\Windows                                 ->  explorer
    //   path:C:\Program Files\Spotify\Spotify.exe           ->  spotify
    // The last path segment alone is wrong: every packaged app ends in "!App", and an Explorer
    // window's would be its folder name.
    function appIdentity(uniqueId: string): string {
        const id = uniqueId ?? "";
        if (id.startsWith("explorer:"))
            return "explorer";
        if (id.startsWith("aumid:"))
            return id.slice(6).split("!")[0].split("_")[0].toLowerCase();
        const path = (id.startsWith("path:") ? id.slice(5) : id).split("|")[0];
        return path.split(/[\\/]/).pop().replace(/\.exe$/i, "").toLowerCase();
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

    // The windows of a virtual desktop as entries for windowsOf: the engine's hwnds
    // that the taskbar lists, in the taskbar rows' order (the engine's order is by hwnd). The row
    // says whether the window is minimized; a window without a row is skipped.
    function desktopWindows(hwnds: var): var {
        const out = [];
        for (const hwnd of hwnds ?? []) {
            const row = taskbarWindows[hwnd];
            if (!row)
                continue;
            out.push({
                hwnd: hwnd,
                exe: row.exe || "",
                title: row.title,
                windowClass: "",
                floating: false,
                minimized: !!row.minimized,
                order: taskbarRows[hwnd] ?? 0
            });
        }
        out.sort((a, b) => a.order - b.order);
        return out;
    }

    // Toplevel items of desktop `wsIdx` on monitor `monIdx`: the desktop's windows (`desktopHwnds`,
    // see desktopWindows).
    function windowsOf(monIdx: int, wsIdx: int, wsActive: bool, desktopHwnds = []): var {
        const out = [];
        const ignoredTags = GlobalConfig.bar.workspaces.ignoredTags;
        for (const h of desktopWindows(desktopHwnds)) {
            // The taskbar row adds the icon; the entry's own title and exe stand in without it
            // (the model has no window to attach to here, so it can stay empty).
            const row = taskbarWindows[h.hwnd] ?? ({
                    title: h.title,
                    exe: h.exe,
                    iconUrl: ""
                });
            const name = appName(h.exe || row.exe);
            // The window's own icon when the taskbar lists it, else the desktop entry's icon.
            const icon = row.iconUrl || appIconUrl(name);
            const t = {
                title: row.title,
                address: String(h.hwnd),
                // Plain values: the object is copied into a `var` list, so a link set later is lost.
                wsId: wsIdx + 1,
                monId: monIdx,
                wsActive: wsActive,
                minimized: !!h.minimized,
                progressState: row.progressState ?? "none",
                progress: row.progress ?? 0,
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
                    minimized: !!h.minimized,
                    fullscreen: 0,
                    floating: h.floating,
                    tags: []
                }
            };
            if (h.minimized && isToplevelIgnored(t, ignoredTags))
                continue;
            out.push(t);
        }
        return out;
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

    // Brings monitors, workspaces and windows up to date with the engine's desktops and the
    // screens. Objects are kept by identity: a property is set
    // only when it differs, an object is created or destroyed only for a real addition or removal,
    // and a list is assigned only when its members changed.
    function rebuild(): void {
        const wakuMons = S.Workspaces.monitors;
        const screens = Quickshell.screens;

        // 1. Plan: plain data only, so the signature can tell whether anything changed.
        const plan = [];
        for (let i = 0; i < screens.length; i++) {
            const screen = screens[i];
            // The index, not the object: indexOf() on a fresh list of QObject wrappers gave -1.
            let wmi = wakuMons.findIndex(m => m.name === screen.name);
            if (wmi < 0 && wakuMons.length === screens.length)
                wmi = i;
            // Virtual desktops belong to no monitor: the engine has one entry with handle 0 and
            // no name, which every screen shows.
            if (wmi < 0)
                wmi = wakuMons.findIndex(m => m.handle === 0);
            const wm = wmi >= 0 ? wakuMons[wmi] : null;
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
                    windows: windowsOf(wmi, j, !!src.active, src.windows)
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
            // One entry per window: virtual desktops show the same windows on every screen.
            const all = [];
            const seen = {};
            for (const w of wss)
                for (const t of w.toplevels.values) {
                    if (seen[t.address])
                        continue;
                    seen[t.address] = true;
                    all.push(t);
                }
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
                    iconUrl: by[k][0].iconUrl,
                    progressState: groupProgress(by[k]).state,
                    progress: groupProgress(by[k]).value
                }));
    }

    function groupProgress(windows: var): var {
        const priority = { error: 0, paused: 1, normal: 2, indeterminate: 3, none: 4 };
        let state = "none";
        let value = 0;
        for (const t of windows) {
            const next = t.progressState ?? "none";
            const p = priority[next] ?? 4;
            const v = t.progress ?? 0;
            if (p < priority[state] || (p === priority[state] && v < value)) {
                state = next;
                value = v;
            }
        }
        return { state: state, value: value };
    }

    Component.onCompleted: {
        rebuild();
    }

    Connections {
        function onChanged(): void {
            // The engine emits `changed` for events that leave the workspaces as they were.
            const sig = JSON.stringify([S.Workspaces.provider, S.Workspaces.connected, S.Workspaces.monitors]);
            if (sig === root.engineSig)
                return;
            root.engineSig = sig;
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

        // The windows of all desktops that the taskbar lists, minimized ones included
        // (`minimized: true`).
        property var values: []
    }

    // Foreground window from the taskbar rows.
    property var foreground: null
    // hwnd -> { title, exe, iconUrl } for every taskbar row.
    property var taskbarWindows: ({})
    // hwnd -> row of the ungrouped TaskbarModel, for `taskbar.activate(row)`.
    property var taskbarRows: ({})
    property var pendingActivate: null
    // The window with focus: the foreground taskbar row. `optimisticHwnd` leads for a moment after
    // a click, so the highlight moves at once.
    readonly property string focusedHwnd: optimisticHwnd || foreground?.address || ""
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

    // The workspaces are Windows virtual desktops.
    readonly property bool virtualDesktops: S.Workspaces.provider === "windows"
    // The engine can close a desktop (the shell interface is open and more than one exists).
    readonly property bool canRemoveWorkspace: virtualDesktops && S.Workspaces.canRemove

    property string engineSig: ""
    property string knownSig: ""
    property string knownKeys: ""
    property string rowsSig: ""
    property string foregroundSig: ""
    // Waits for the switch to finish, then raises the window.
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

    S.TaskbarModel {
        id: taskbar

        // The model has no service of its own: without this it never has a row.
        service: S.TaskbarService
        grouping: false
        // The engine starts its window tracker only for a model that has a bar window; the apps
        // list hands it its own (see AppsList). showOnlyVisible stays false: the windows of the
        // other desktops are cloaked and they must stay in the list.
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
                        iconUrl: o.iconUrl,
                        minimized: o.minimized,
                        progressState: o.progressState,
                        progress: o.progress
                    };
            }
            const knownSig = JSON.stringify(known);
            if (knownSig !== root.knownSig) {
                const keys = Object.keys(known).sort().join(",");
                root.knownSig = knownSig;
                root.taskbarWindows = known;
                // A window that came or went: look at the desktops now instead of at the next poll.
                if (keys !== root.knownKeys) {
                    root.knownKeys = keys;
                    S.VirtualDesktops.refresh();
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
            required property var model
            required property string title
            required property bool active
            required property bool minimized
            required property string key
            required property string iconUrl
            required property string uniqueId
            readonly property string exe: root.appIdentity(uniqueId)
            readonly property string progressState: model.progressState ?? "none"
            readonly property real progress: model.progress ?? 0

            onActiveChanged: rows.update()
            onMinimizedChanged: rows.update()
            onTitleChanged: rows.update()
            onIconUrlChanged: rows.update()
            onProgressStateChanged: rows.update()
            onProgressChanged: rows.update()
        }
        onObjectAdded: update()
        onObjectRemoved: update()
    }

    QtObject {
        id: extras

        // waku gap: nothing to configure. These keep upstream's call sites working.
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
