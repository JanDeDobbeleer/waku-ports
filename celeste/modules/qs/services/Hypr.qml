pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Celeste.I18n
import waku.services as S
import qs.compat
import "HyprData.js" as H

// Celeste's Hyprland service over waku. The objects it hands out (`monitors.values`,
// `workspaces.values`, `activeToplevel`, ...) keep the shape of Quickshell's Hyprland types but are
// plain QtObjects (HyprMonitor, HyprWorkspace, HyprToplevel, HyprGroup) built here, so a module
// that declares `required property HyprlandMonitor` must declare `HyprMonitor` instead.
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
// workspace but once in `toplevels`. The plain-data work is in HyprData.js.
Singleton {
    id: root

    readonly final property bool hasWm: S.Workspaces.connected
    readonly final property bool usingLua: false

    readonly final property HyprList monitors: monitorList
    readonly final property HyprList workspaces: workspaceList
    readonly final property HyprList toplevels: toplevelList

    // waku gap: only the foreground window is known. It has a title and an executable name, no
    // class, address or workspace.
    readonly final property HyprToplevel activeToplevel: foreground
    readonly final property HyprWorkspace focusedWorkspace: H.focusedWorkspace(workspaceList.values)
    readonly final property HyprMonitor focusedMonitor: H.focusedMonitor(monitorList.values)
    readonly final property int activeWsId: focusedWorkspace?.id ?? 1

    // waku gap: no keyboard device model. The lock keys and the layout come from DesktopState.
    readonly final property bool capsLock: S.DesktopState.capsLock
    readonly final property bool numLock: S.DesktopState.numLock
    readonly final property string defaultKbLayout: S.DesktopState.keyboardLayout || "??"
    readonly final property string kbLayoutFull: S.DesktopState.keyboardLayout || Tr.trCtx("Unknown", "keyboard layout")
    readonly final property string kbLayout: S.DesktopState.keyboardLayout || "??"
    readonly final property var keyboard: null

    readonly property alias extras: extras
    readonly property alias options: extras.options
    readonly property alias devices: extras.devices

    final property string lastSpecialWorkspace: ""

    signal configReloaded

    // Understands `workspace N`, `workspace r+1` and `workspace r-1`; everything else is ignored.
    function dispatch(request: string): void {
        const arg = H.parseDispatch(request);
        if (arg === "")
            return;
        if (arg === "r+1")
            stepWorkspace(1);
        else if (arg === "r-1")
            stepWorkspace(-1);
        else
            focusWorkspace(Number(arg));
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
    function focusWorkspace(ws: real): void {
        if (Number.isInteger(ws) && ws >= 1)
            S.Workspaces.focus(0, String(ws - 1));
    }

    // Windows virtual desktops: closes desktop `ws` (1-based, like focusWorkspace) the way Task
    // View's close button does, without switching to it. The spare "add" dot (a number past the
    // last desktop) never closes anything.
    function removeWorkspace(ws: real): void {
        if (!canRemoveWorkspace)
            return;
        if (Number.isInteger(ws) && ws >= 1 && ws <= S.VirtualDesktops.desktops.length)
            S.Workspaces.remove(0, String(ws - 1));
    }

    // Shows the existing desktop `index` (0-based). A step never creates a desktop; only a click on
    // a dot does (focusWorkspace). Anything else is dropped.
    function runFocus(mon: HyprMonitor, index: int): void {
        if (Number.isInteger(index) && index >= 0 && index < S.VirtualDesktops.desktops.length)
            S.Workspaces.focus(0, String(index));
    }

    // The window the bar's running-apps list points at, for the hover popout (null: show the
    // focused one).
    final property HyprToplevel hoverToplevel: null

    // Brings a toplevel from `toplevels` to the front and returns what it did, for the test IPC:
    // "focused" (already the focused window: nothing happens, a taskbar click would minimise it),
    // "switch+activate" (its virtual desktop is shown first, then, after the switch, the window is
    // raised), "window-control" (raised through the engine's `WindowControl`), "activate" (raised
    // through a TaskbarModel row) or "none". The highlight moves at once (`optimisticHwnd`) and
    // settles on the foreground window.
    // A minimized window is restored by both raise paths (WindowControl and the taskbar row), never
    // minimized again: it is never the focused window. `previewActivate` says what would happen
    // without doing it (test IPC).
    // Whether raising `t` first needs a switch to its desktop (the monitor does not matter:
    // desktops belong to none).
    function switchesFirst(t: HyprToplevel): bool {
        return !t.wsActive;
    }

    function activateToplevel(t: HyprToplevel): string {
        if (!t || !t.address)
            return "none";
        if (focusedHwnd === t.address)
            return "focused";
        optimisticHwnd = String(t.address);
        optimisticAt = Date.now();
        optimisticTimer.restart();
        if (switchesFirst(t)) {
            pendingActivate = {
                hwnd: t.address,
                exe: t.appClass
            };
            runFocus(focusedMonitor, t.wsId - 1);
            activateTimer.restart();
            return "switch+activate";
        }
        return activateHwnd(t.address);
    }

    function previewActivate(t: HyprToplevel): string {
        if (!t || !t.address)
            return "none";
        if (focusedHwnd === t.address)
            return "focused";
        if (switchesFirst(t))
            return "switch+activate";
        if (H.hasWindowControl(S.WindowControl))
            return "window-control";
        return H.rowIndex(taskbarRows, t.address) >= 0 ? "activate" : "none";
    }

    function activateHwnd(hwnd: string): string {
        // The engine's WindowControl (absent on an older engine).
        if (H.activateWindow(S.WindowControl, hwnd))
            return "window-control";
        const row = H.rowIndex(taskbarRows, hwnd);
        if (row >= 0) {
            taskbar.activate(row);
            return "activate";
        }
        return "none";
    }

    // What a click on a group icon activates: the next window of the group when one of them has
    // focus, else the one that had focus last (or the first).
    function clickTarget(g: HyprGroup): HyprToplevel {
        return H.clickTarget(g, focusedHwnd, groupLastFocused);
    }

    // Returns what activateToplevel did.
    function clickGroup(g: HyprGroup): string {
        const target = clickTarget(g);
        return target ? activateToplevel(target) : "none";
    }

    function groupWindow(g: HyprGroup, i: int): HyprToplevel {
        return H.windowAt(g, i);
    }

    function groupCount(g: HyprGroup): int {
        return H.groupSize(g);
    }

    function groupByKey(key: string): HyprGroup {
        return H.groupByKey(appGroups, key);
    }

    // Window `i` of group `key`, activated like a click on a single icon.
    function activateGroupWindow(key: string, i: int): string {
        const t = H.windowAt(groupByKey(key), i);
        return t ? activateToplevel(t) : "none";
    }

    // The workspace name (a roman numeral) of the workspace a toplevel is on.
    function workspaceLabel(t: HyprToplevel): string {
        return H.workspaceLabel(workspaceList.values, t);
    }

    function toplevelCount(ws: int): int {
        return H.toplevelsOf(H.workspaceById(workspaceList.values, ws, focusedMonitor)).length;
    }

    function specialIds(mon: HyprMonitor, allMonitors: bool): var {
        return H.specialIds(workspaceList.values, mon, allMonitors);
    }

    function workspaceById(id: int): HyprWorkspace {
        return H.workspaceById(workspaceList.values, id, null);
    }

    // waku gap: no special workspaces.
    function toggleSpecial(name: string): void {
    }

    function cycleSpecialWorkspace(direction: string): void {
    }

    function monitorNames(): list<string> {
        return H.names(monitorList.values);
    }

    function monitorFor(screen: ShellScreen): HyprMonitor {
        return H.monitorFor(monitorList.values, screen?.name);
    }

    function trimWsName(name: string): string {
        return name.startsWith("special:") ? name.slice("special:".length) : name;
    }

    function toplevelsForWs(ws: int, ignoredTags: var): var {
        return H.toplevelsOf(H.workspaceById(workspaceList.values, ws, focusedMonitor));
    }

    function isToplevelIgnored(toplevel: HyprToplevel, ignoredTags: var): bool {
        return !toplevel?.appClass;
    }

    function specialFullscreen(mon: HyprMonitor): bool {
        return H.isFullscreenOn(H.workspaceByName(workspaceList.values, mon?.specialName ?? ""));
    }

    function windowCount(ws: HyprWorkspace): int {
        return H.toplevelsOf(ws).length;
    }

    function hasFullscreen(ws: HyprWorkspace): bool {
        return H.isFullscreenOn(ws);
    }

    function reloadDynamicConfs(): void {
    }

    // Executable name without ".exe", lower case: what a desktop entry or an icon rule matches.
    function appName(exe: string): string {
        return H.appName(exe);
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
        return H.appIdentity(uniqueId);
    }

    // `image://appicon/...` of the installed app that `name` matches, or "" when none does.
    function appIconUrl(name: string): string {
        return H.appIconUrl(root, name);
    }

    function iconUrlFor(name: string): string {
        const icon = DesktopEntries.heuristicLookup(name)?.icon;
        return icon ? String(Quickshell.iconPath(icon, true)) : "";
    }

    function makeMonitor(name: string, id: int, handle: real): HyprMonitor {
        return monComp.createObject(root, {
            name: name,
            id: id,
            handle: handle
        }) as HyprMonitor;
    }

    function makeWorkspace(key: string, monitor: HyprMonitor): HyprWorkspace {
        return wsComp.createObject(root, {
            key: key,
            monitor: monitor
        }) as HyprWorkspace;
    }

    function makeToplevel(props: var): HyprToplevel {
        return tlComp.createObject(root, props) as HyprToplevel;
    }

    function makeGroup(props: var): HyprGroup {
        return grpComp.createObject(root, props) as HyprGroup;
    }

    function refreshDesktops(): void {
        S.VirtualDesktops.refresh();
    }

    // Brings monitors, workspaces and windows up to date with the engine's desktops and the
    // screens. Objects are kept by identity: a property is set only when it differs, an object is
    // created or destroyed only for a real addition or removal, and a list is assigned only when
    // its members changed. An identical input does nothing, so a delegate bound to an object never
    // sees it replaced.
    function rebuild(): void {
        H.rebuild(root, S.Workspaces.monitors, Quickshell.screens);
    }

    // What the last rebuild was made from.
    final property string rebuildSig: ""
    // The monitor and workspace objects by key: screen name, and screen name + engine workspace id.
    final property var monObjs: ({})
    final property var wsObjs: ({})
    // key -> signature of the windows last given to that workspace.
    final property var wsWinSigs: ({})

    // The apps list groups windows by application: the executable name (`appClass`), else the
    // window class, else the window itself. `groupOrder` keeps first-seen order, so the icons do
    // not move when the focus changes.
    final property var appGroups: []
    final property var groupOrder: []
    // The group the hover popout lists.
    final property string hoverGroupKey: ""

    // TEST ONLY (DebugIpc): adds this many fake windows to the first application, to try the group
    // badge and flyout when no application has several windows. They are never focusable.
    final property int debugCopies: 0
    final property var lastAll: []
    final property var fakeObjs: []

    onDebugCopiesChanged: H.updateGroups(root, lastAll)

    Component.onCompleted: {
        rebuild();
    }

    Connections {
        function onChanged(): void {
            // The engine emits `changed` for events that leave the workspaces as they were.
            const workspaces = S.Workspaces;
            if (!workspaces)
                return;
            const sig = H.engineSignature(workspaces);
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

    HyprList {
        id: monitorList
    }

    HyprList {
        id: workspaceList
    }

    HyprList {
        id: toplevelList
    }

    // Foreground window from the taskbar rows.
    final property HyprToplevel foreground: null
    // hwnd -> { title, exe, iconUrl } for every taskbar row.
    final property var taskbarWindows: ({})
    // hwnd -> index in the ungrouped TaskbarModel, for `taskbar.activate(row)`.
    final property var taskbarRows: ({})
    final property var pendingActivate: null
    // The window with focus: the foreground taskbar row. `optimisticHwnd` leads for a moment after
    // a click, so the highlight moves at once.
    readonly final property string focusedHwnd: optimisticHwnd || foreground?.address || ""
    final property string optimisticHwnd: ""
    final property real optimisticAt: 0
    // key (the app's executable) -> hwnd of the group's window that had focus last.
    final property var groupLastFocused: ({})
    onFocusedHwndChanged: H.noteFocus(root)
    // Set by the bar: a window for the taskbar model (see the model below).
    final property var barWindow: null
    readonly final property int taskbarCount: taskbar.count
    readonly final property bool taskbarAvailable: S.TaskbarService.available

    // The workspaces are Windows virtual desktops.
    readonly final property bool virtualDesktops: S.Workspaces.provider === "windows"
    // The engine can close a desktop (the shell interface is open and more than one exists).
    readonly final property bool canRemoveWorkspace: virtualDesktops && S.Workspaces.canRemove

    final property string engineSig: ""
    final property string knownSig: ""
    final property string knownKeys: ""
    final property string rowsSig: ""
    final property string foregroundSig: ""
    // Waits for the switch to finish, then raises the window.
    Timer {
        id: activateTimer

        interval: 350
        onTriggered: root.activatePending()
    }

    function updateRows(): void {
        H.updateRows(root, rows);
    }

    function activatePending(): void {
        const hwnd = H.pendingHwnd(pendingActivate);
        pendingActivate = null;
        if (hwnd !== "")
            activateHwnd(hwnd);
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
            H.updateRows(root, rows);
        }

        model: taskbar
        delegate: QtObject {
            required final property var model
            required final property string title
            required final property bool active
            required final property bool minimized
            required final property string key
            required final property string iconUrl
            required final property string uniqueId
            readonly final property string exe: root.appIdentity(uniqueId)
            readonly final property string progressState: H.roleValue(model, "progressState", "none")
            readonly final property real progress: H.roleValue(model, "progress", 0)

            onActiveChanged: root.updateRows()
            onMinimizedChanged: root.updateRows()
            onTitleChanged: root.updateRows()
            onIconUrlChanged: root.updateRows()
            onProgressStateChanged: root.updateRows()
            onProgressChanged: root.updateRows()
        }
        onObjectAdded: update()
        onObjectRemoved: update()
    }

    QtObject {
        id: extras

        // waku gap: nothing to configure. These keep upstream's call sites working.
        final property var options: ({})
        final property var devices: ({
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

        HyprMonitor {}
    }

    Component {
        id: wsComp

        HyprWorkspace {}
    }

    Component {
        id: tlComp

        HyprToplevel {}
    }

    Component {
        id: grpComp

        HyprGroup {}
    }
}
