pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import waku.services as S
import qs.compat

// Caelestia's Hyprland service over waku. The objects it hands out (`monitors.values`,
// `workspaces.values`, `activeToplevel`, ...) keep the shape of Quickshell's Hyprland types but are
// plain QtObjects built here, so a module that declares `required property HyprlandMonitor` must
// declare `var` instead.
//
// Sources: komorebi or GlazeWM through `Workspaces` (ids are the workspace's position on its
// monitor, `Hypr.activeWsId` counts from 1), the foreground window through `TaskbarModel`, and
// the lock keys and keyboard layout through `DesktopState`. With no tiling window manager running
// `workspaces.values` is empty and `hasWm` is false, so a bar can show a "no WM" pill.
//
// waku gap: `Workspaces` gives a window count per workspace, not the windows. With komorebi the
// windows of each workspace come from a read-only `komorebic state` (hwnd lists per monitor and
// workspace, in the same order as `Workspaces`), joined by hwnd with the ungrouped TaskbarModel
// rows (key `w:<hwnd>`: title, executable, icon). A window the taskbar does not list (tool
// windows, overlays) is not shown. With GlazeWM, or before the first state, a workspace has no
// windows.
//
// With the Windows virtual desktops (no tiling manager: `Workspaces.provider` is "windows") the
// engine lists the windows of each desktop (hwnd numbers). They are joined by hwnd with the same
// taskbar rows; a window without a row is skipped, the rows give title, executable, icon and
// minimized, and the rows' order (first appeared) is the window order. There is one engine entry
// (handle 0) for every screen, so a window is listed once per screen workspace but once in
// `toplevels`.
//
// Minimized windows: komorebi drops a window from its workspace when it is minimized and adds it
// back to the focused workspace when it is restored, so `komorebic state` never lists one. The
// taskbar rows still do (`minimized` true). Such a row becomes a toplevel with `minimized: true` on
// the workspace komorebi last had it on, else on the focused one (see minimizedVerdict for the
// filter).
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

    // `ws` is a workspace id (its 1-based position on the monitor) or its name.
    function focusWorkspace(ws: var): void {
        // Windows virtual desktops: a dot past the last desktop creates it.
        if (S.Workspaces.provider === "windows") {
            const n = Number(ws);
            if (Number.isInteger(n) && n >= 1)
                S.Workspaces.focus(0, String(n - 1));
            return;
        }
        const mon = focusedMonitor;
        if (!mon)
            return;
        const target = workspaceList.values.find(w => w.monitor === mon && (w.id === Number(ws) || w.name === String(ws)));
        if (target)
            runFocus(mon, target.id - 1);
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

    // `komorebic focus-workspace <index>`, an index (0-based) of an existing workspace on the
    // focused monitor. Anything else is dropped.
    function runFocus(mon: var, index: int): void {
        // Windows virtual desktops (no tiling manager running): the engine switches the desktop.
        if (S.Workspaces.provider === "windows") {
            // A step never creates a desktop; only a click on a dot does (focusWorkspace).
            if (Number.isInteger(index) && index >= 0 && index < S.VirtualDesktops.desktops.length)
                S.Workspaces.focus(0, String(index));
            return;
        }
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
    // "switch+activate" (its workspace is focused first with `komorebic focus-workspace`, or its
    // virtual desktop is shown, then, after the switch, the window is raised), "window-control" (raised through the
    // engine's `WindowControl`), "activate" (raised through a TaskbarModel row), "eager-focus"
    // (`komorebic eager-focus <exe>`: the last resort, it may pick another window of that exe) or
    // "none". The highlight moves at once (`optimisticHwnd`) and settles on komorebi's state.
    // A minimized window is restored by both raise paths (WindowControl and the taskbar row), never
    // minimized again: it is never the focused window. With `dry` nothing happens; the result
    // says what would (test IPC).
    // Whether raising `t` first needs a switch to its workspace: komorebi (a workspace on the
    // focused monitor that is not shown) or a virtual desktop that is not shown (the monitor does
    // not matter: desktops belong to none).
    function switchesFirst(t: var): bool {
        if (virtualDesktops)
            return !t.wsActive;
        return komorebi && t.monId === focusedMonitor?.id && !t.wsActive;
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
        settleTimer.restart();
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
        // Focus a window by its executable name.
        if (komorebi && /^[A-Za-z0-9_.\- ]+$/.test(exe)) {
            if (!dry)
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

    // waku gap: komorebi and GlazeWM have no special workspaces.
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

    // Why a taskbar row is not a minimized toplevel, or "" when it is one. `row` is a taskbar row
    // ({ title, exe, minimized }); the engine has already dropped tool windows, owned windows,
    // hidden and empty-title windows, immersive shell windows and ghost UWP frames from the rows.
    // `managed`: the hwnds komorebi lists; `seen`: hwnd -> what komorebi last said about it;
    // `rules`: komorebi's ignore_identifiers; `restored`: hwnd -> when it was restored (a window
    // restored a moment ago stays until komorebi lists it again, so its icon does not jump).
    function minimizedVerdict(hwnd: string, row: var, managed: var, seen: var, rules: var, restored: var, now: real): string {
        if (!row)
            return "no taskbar row";
        // A cloaked window (another workspace) is not minimized: komorebi lists it.
        if (!row.minimized && !(now - (restored?.[hwnd] ?? 0) < 1500))
            return "not minimized";
        if (managed?.[hwnd])
            return "komorebi lists it";
        if (!(row.title ?? "").trim())
            return "empty title";
        const name = appName(seen?.[hwnd]?.exe || row.exe || "");
        if (!name)
            return "no executable";
        if (name === "waku" || name === "wakuc")
            return "the bar";
        // A window komorebi managed before is not one it ignores.
        if (!seen?.[hwnd] && komorebiIgnores(name + ".exe", row.title, rules))
            return "komorebi ignores it";
        return "";
    }

    // Whether one of komorebi's ignore rules matches a window by executable and title. Rules on the
    // class or the path cannot be checked (the taskbar rows have neither) and do not match.
    function komorebiIgnores(exe: string, title: string, rules: var): bool {
        const one = r => {
            const id = String(r?.id ?? "");
            const s = r?.matching_strategy ?? "Legacy";
            let v;
            if (r?.kind === "Exe")
                v = exe.toLowerCase();
            else if (r?.kind === "Title")
                v = title;
            else
                return false;
            const i = r.kind === "Exe" ? id.toLowerCase() : id;
            switch (s) {
            case "Legacy":
                return r.kind === "Exe" ? v === i : (v.startsWith(i) || v.endsWith(i));
            case "Equals":
                return v === i;
            case "StartsWith":
                return v.startsWith(i);
            case "EndsWith":
                return v.endsWith(i);
            case "Contains":
                return v.includes(i);
            case "DoesNotEqual":
                return v !== i;
            case "DoesNotStartWith":
                return !v.startsWith(i);
            case "DoesNotEndWith":
                return !v.endsWith(i);
            case "DoesNotContain":
                return !v.includes(i);
            case "Regex":
                try {
                    return new RegExp(id).test(r.kind === "Exe" ? exe : title);
                } catch (e) {
                    return false;
                }
            default:
                return false;
            }
        };
        for (const r of rules ?? []) {
            if (Array.isArray(r) ? (r.length > 0 && r.every(one)) : one(r))
                return true;
        }
        return false;
    }

    // The minimized windows per "<monitor>:<workspace>", as komorebi-like entries for windowsOf.
    // Empty without komorebi or before its first state.
    function minimizedByWs(): var {
        const out = {};
        if (!komorebi || lastStateSig === "")
            return out;
        const mons = S.Workspaces.monitors;
        let active = "";
        for (let mi = 0; mi < mons.length && !active; mi++) {
            const wi = (mons[mi].workspaces ?? []).findIndex(w => w.focused);
            if (wi >= 0)
                active = mi + ":" + wi;
        }
        if (!active && mons.length > 0) {
            const wi = (mons[0].workspaces ?? []).findIndex(w => w.active);
            if (wi >= 0)
                active = "0:" + wi;
        }
        const now = Date.now();
        for (const hwnd of Object.keys(taskbarWindows)) {
            const row = taskbarWindows[hwnd];
            if (minimizedVerdict(hwnd, row, managedHwnds, seenHwnds, ignoreRules, restoredAt, now) !== "")
                continue;
            const s = seenHwnds[hwnd];
            const known = s && s.mi < mons.length && s.wi < (mons[s.mi].workspaces ?? []).length;
            const slot = known ? s.mi + ":" + s.wi : active;
            if (!slot)
                continue;
            if (!out[slot])
                out[slot] = [];
            out[slot].push({
                hwnd: Number(hwnd),
                exe: s?.exe || row.exe || "",
                title: row.title,
                windowClass: s?.windowClass ?? "",
                floating: s?.floating ?? false,
                minimized: true
            });
        }
        return out;
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

    // The windows of a virtual desktop as komorebi-like entries for windowsOf: the engine's hwnds
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

    // Toplevel items of workspace `wsIdx` on monitor `monIdx`, in komorebi's order, then the
    // minimized windows placed there (`minimized`: from minimizedByWs). On virtual desktops: the
    // desktop's windows (`desktopHwnds`, see desktopWindows).
    function windowsOf(monIdx: int, wsIdx: int, wsActive: bool, minimized = ({}), desktopHwnds = []): var {
        const out = [];
        const key = monIdx + ":" + wsIdx;
        const ignoredTags = GlobalConfig.bar.workspaces.ignoredTags;
        const source = virtualDesktops ? desktopWindows(desktopHwnds) : (wsWindows[key] ?? []).concat(minimized[key] ?? []);
        for (const h of source) {
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
            const t = {
                title: row.title,
                address: String(h.hwnd),
                // Plain values: the object is copied into a `var` list, so a link set later is lost.
                wsId: wsIdx + 1,
                monId: monIdx,
                wsActive: wsActive,
                minimized: !!h.minimized,
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
        const managed = {};
        // What komorebi said about each window last, kept while the taskbar lists the window, so a
        // minimized one (dropped from the state) goes back to its own workspace.
        const seen = {};
        const live = Object.keys(taskbarWindows).length > 0;
        for (const k of Object.keys(seenHwnds))
            if (!live || taskbarWindows[k])
                seen[k] = seenHwnds[k];
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
            for (const w of out) {
                managed[String(w.hwnd)] = true;
                seen[String(w.hwnd)] = {
                    mi: mi,
                    wi: wi,
                    exe: w.exe,
                    windowClass: w.windowClass,
                    floating: w.floating
                };
            }
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
        seenHwnds = seen;
        const stateSig = JSON.stringify([layouts, map]);
        if (stateSig === lastStateSig)
            return;
        lastStateSig = stateSig;
        managedHwnds = managed;
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
        const wakuMons = S.Workspaces.monitors;
        const screens = Quickshell.screens;

        // 1. Plan: plain data only, so the signature can tell whether anything changed.
        const plan = [];
        const minimized = minimizedByWs();
        for (let i = 0; i < screens.length; i++) {
            const screen = screens[i];
            // The index, not the object: indexOf() on a fresh list of QObject wrappers gave -1,
            // so `komorebic state` windows (keyed by monitor index) were never found.
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
                    layout: wsLayouts[wmi + ":" + j] ?? "",
                    windows: windowsOf(wmi, j, !!src.active, minimized, src.windows)
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
                    iconUrl: by[k][0].iconUrl
                }));
    }

    Component.onCompleted: {
        rebuild();
        if (komorebi)
            rulesPoll.running = true;
    }

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

        // The windows of all workspaces that komorebi and the taskbar both know, plus the
        // minimized windows the taskbar lists (`minimized: true`).
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
    // The hwnds the last komorebi state lists, hwnd -> what komorebi said about a window last
    // ({ mi, wi, exe, windowClass, floating }), komorebi's ignore rules (`komorebic global-state`)
    // and hwnd -> when a minimized window was restored. See minimizedVerdict.
    property var managedHwnds: ({})
    property var seenHwnds: ({})
    property var ignoreRules: []
    property var restoredAt: ({})
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
    // The workspaces are Windows virtual desktops (no tiling manager runs).
    readonly property bool virtualDesktops: S.Workspaces.provider === "windows"
    // The engine can close a desktop (the shell interface is open and more than one exists).
    readonly property bool canRemoveWorkspace: virtualDesktops && S.Workspaces.canRemove

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
    onKomorebiChanged: {
        queue();
        if (komorebi && !rulesPoll.running)
            rulesPoll.running = true;
    }

    // Read only: `komorebic global-state` prints the configuration komorebi runs with; only the
    // ignore rules are taken, once per komorebi connection.
    Process {
        id: rulesPoll

        command: ["komorebic", "global-state"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const rules = JSON.parse(text)?.ignore_identifiers;
                    root.ignoreRules = Array.isArray(rules) ? rules : [];
                } catch (e) {
                    root.ignoreRules = [];
                }
                root.rebuild();
            }
        }
    }

    // A restored window stays in the list for a moment (see minimizedVerdict); then the list is
    // rebuilt from what komorebi says.
    Timer {
        id: restoreTimer

        interval: 1600
        onTriggered: root.rebuild()
    }

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
                        iconUrl: o.iconUrl,
                        minimized: o.minimized
                    };
            }
            const knownSig = JSON.stringify(known);
            if (knownSig !== root.knownSig) {
                const keys = Object.keys(known).sort().join(",");
                // A window that was minimized and is not any more: restored a moment ago.
                const now = Date.now();
                let restored = false;
                let flipped = false;
                const restoredAt = {};
                for (const h of Object.keys(root.restoredAt))
                    if (known[h] && now - root.restoredAt[h] < 1500)
                        restoredAt[h] = root.restoredAt[h];
                for (const h of Object.keys(known)) {
                    const was = root.taskbarWindows[h];
                    if (was && !!was.minimized !== !!known[h].minimized)
                        flipped = true;
                    if (was?.minimized && !known[h].minimized) {
                        restoredAt[h] = now;
                        restored = true;
                    }
                }
                root.restoredAt = restoredAt;
                if (restored)
                    restoreTimer.restart();
                // komorebi drops a window on minimize and adds it on restore: read its state.
                if (flipped)
                    root.queue();
                root.knownSig = knownSig;
                root.taskbarWindows = known;
                // A title or an icon needs no new state, only a new join. A window that came or
                // went does.
                if (keys !== root.knownKeys) {
                    root.knownKeys = keys;
                    root.queue();
                    // Look at the desktops now instead of at the next poll (500 ms).
                    if (root.virtualDesktops)
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
            required property string title
            required property bool active
            required property bool minimized
            required property string key
            required property string iconUrl
            required property string uniqueId
            readonly property string exe: uniqueId.split(/[\\/!]/).pop().replace(/\.exe$/i, "")

            onActiveChanged: rows.update()
            onMinimizedChanged: rows.update()
            onTitleChanged: rows.update()
            onIconUrlChanged: rows.update()
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
