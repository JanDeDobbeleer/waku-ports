import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import wabar as W
import wabar.services as S
import qs.services
import qs.utils
import Caelestia.Services
import Caelestia.Config
import qs.modules.launcher.services

// TEST ONLY. Opens and closes the bar flyouts without a cursor, so a capture run (no input allowed)
// can check them: `wabarc --config-home <home> call bar popout network`. It sets the same state the
// hover handler sets (Wrapper.currentName, hasCurrent, currentCenter). Remove once a person has
// checked the hover path on a real desktop.
Scope {
    id: scope

    property var savedFg: 0

    function search_(): var {
        return ShellState.componentsFor(Screens.screens[0])?.find("launcherSearch");
    }

    // The list the search drives: the wallpaper PathView or the app/action ListView.
    function list_(): var {
        const c = ShellState.componentsFor(Screens.screens[0]);
        const s = scope.search_();
        if (!c || !s)
            return null;
        const wall = s.text.startsWith(`${GlobalConfig.launcher.actionPrefix}wallpaper `);
        return c.find(wall ? "launcherWallpaperList" : "launcherAppList");
    }

    // The Visual (the item with `kind` and `ready`) below `o`, at most 6 levels down.
    function visualIn_(o: var, depth: int): var {
        if (o.kind !== undefined && o.ready !== undefined)
            return o;
        if (depth > 6)
            return null;
        for (let i = 0; i < o.children.length; i++) {
            const r = scope.visualIn_(o.children[i], depth + 1);
            if (r)
                return r;
        }
        return null;
    }

    function rows_(): var {
        const l = scope.list_();
        return l?.model?.values ?? [];
    }

    function name_(v: var): string {
        return v ? (v.relativePath ?? v.name ?? String(v)) : "null";
    }

    IpcHandler {
        function popout(name: string): string {
            const c = ShellState.componentsFor(Screens.screens[0]);
            if (!c?.bar)
                return "no bar";
            return c.bar.openPopoutNamed(name) ? "ok" : `no entry named ${name}`;
        }

        function popoutClose(): void {
            const c = ShellState.componentsFor(Screens.screens[0]);
            if (c?.panels)
                c.panels.popouts.hasCurrent = false;
        }

        // name, hasCurrent, then the flyout rectangle in physical screen pixels: x y w h.
        function popoutState(): string {
            const screen = Screens.screens[0];
            const c = ShellState.componentsFor(screen);
            const p = c?.panels?.popouts;
            if (!p)
                return "none";
            const pt = p.mapToItem(null, 0, 0);
            const r = screen.devicePixelRatio;
            const f = v => Math.round(v * r);
            return `${p.currentName} ${p.hasCurrent} ${f(pt.x)} ${f(pt.y)} ${f(p.width)} ${f(p.height)}`;
        }

        // One line per known device: connected, wabar type, resolved Material icon. No names.
        function btDevices(): string {
            return Bluetooth.devices.values.map(d => `${d.connected} ${d.row?.type} ${Icons.getBluetoothIcon(d.icon)}`).join("; ");
        }

        // TEST ONLY: `n` fake tray items replace the real ones (0 restores them). Clicks on them only
        // record themselves; see trayState.
        function fakeTray(n: int): string {
            TrayItems.debugFake = n;
            return `fake tray items: ${n}`;
        }

        // "<items> <shown in the strip> <strip height> <last action>"
        function trayState(): string {
            const t = ShellState.componentsFor(Screens.screens[0])?.bar?.entryItem("tray");
            return `${TrayItems.count} ${t ? t.shown : "no strip"} ${t ? t.height : 0} [${TrayItems.lastAction}]`;
        }

        // Calls the click handler of fake item `i` with `button` (left, middle, right).
        function trayClick(i: int, button: string): string {
            const it = TrayItems.debugFake > 0 ? TrayItems.items[i] : null;
            if (!it)
                return "none";
            if (button === "left")
                it.activate();
            else if (button === "middle")
                it.secondaryActivate();
            else
                it.display(null, 0, 0);
            return TrayItems.lastAction;
        }

        function entries(): string {
            return ShellState.componentsFor(Screens.screens[0])?.bar?.debugEntries() ?? "none";
        }

        // Runs the click handler of the workspace dot `n` (1-based), but only when `n` is the
        // focused workspace, which makes it a no-op. Returns what the handler did.
        function clickWorkspace(n: int): string {
            const w = ShellState.componentsFor(Screens.screens[0])?.bar?.entryItem("workspaces");
            if (!w)
                return "no workspaces";
            if (Hypr.activeWsId !== n)
                return "refused: not the focused workspace";
            return w.clickWorkspace(n);
        }

        // Runs the click handler of the clock: toggles the dashboard (first tab). Returns what it did.
        function clickClock(): string {
            const b = ShellState.componentsFor(Screens.screens[0])?.bar;
            return b ? b.clickClock() : "no bar";
        }

        // "<dashboard> <tab> <yyyy-mm>" of the first screen's state.
        function dashState(): string {
            const s = ShellState.forScreen(Screens.screens[0]);
            return `${s.dashboard} ${s.dashboardTab} ${s.dashboardDate.getFullYear()}-${s.dashboardDate.getMonth() + 1}`;
        }

        // Runs the click handler of apps-list icon `i` (0-based), but only when it is the focused
        // window, which makes it a no-op. Returns what the handler did.
        function clickApp(i: int): string {
            const l = ShellState.componentsFor(Screens.screens[0])?.bar?.entryItem("activeWindow");
            if (!l)
                return "no apps list";
            const g = l.shown[i];
            if (!g || g.windows.length !== 1 || g.windows[0].address !== l.focusedAddress)
                return "refused: not a single focused window";
            return l.clickApp(i);
        }

        // Same handler as a click on a row of the group flyout, for window `i` of the group of
        // executable `exe`, but only when it is already the focused window (a no-op).
        function activateGroupWindow(exe: string, i: int): string {
            const g = Hypr.appGroups.find(x => x.key === exe);
            if (!g?.windows[i])
                return "none";
            if (g.windows[i].address !== Hypr.focusedHwnd)
                return "refused: not the focused window";
            return Hypr.activateGroupWindow(exe, i);
        }

        // Same handler as a click on a group icon (cycle), refused unless the group has one window
        // that is already focused, which is a no-op.
        function activateApp(i: int): string {
            return clickApp(i);
        }

        // One line per group: executable, window count, workspaces of its windows (roman numerals),
        // the windows' hwnds in brackets and a "*" on the group with the focused window.
        function appGroups(): string {
            return Hypr.appGroups.map(g => `${g.exe} ${g.windows.length} ${g.windows.map(t => Hypr.workspaceLabel(t)).join("/")} [${g.windows.map(t => t.srcHwnd ?? t.address).join(",")}]${g.windows.some(t => t.address === Hypr.focusedHwnd) ? " *" : ""}`).join("; ");
        }

        // The open group flyout, per card: "hwnd available sourceWidth sourceHeight x,y,w,h" (the
        // thumbnail rectangle in logical window coordinates). Empty when no group flyout is open.
        function thumbState(): string {
            try {
                const p = ShellState.componentsFor(Screens.screens[0])?.panels?.popouts;
                const g = p?.current ?? p?.content?.item?.currentPopout?.item ?? p?.content?.item?.current;
                return g && typeof g.thumbState === "function" ? g.thumbState() : `no group flyout (${p?.currentName} ${p?.hasCurrent} current=${g} type=${typeof g?.thumbState})`;
            } catch (e) {
                return "error " + e;
            }
        }

        // TEST ONLY: fake extra windows for the first application, to try the group badge.
        function fakeCopies(n: int): string {
            Hypr.debugCopies = n;
            return "fake windows: " + n;
        }

        // The dots of the workspaces entry (ids) and the active one, plus the last komorebic
        // command (a dry run in tests).
        function dots(): string {
            const w = ShellState.componentsFor(Screens.screens[0])?.bar?.entryItem("workspaces");
            return w ? w.debugDots() + " last=[" + Hypr.lastCommand + "]" : "no workspaces";
        }

        // The layout button's wheel (`previous`) or click (`next`) handler. Always a dry run: the
        // command is logged and returned, never sent to komorebi.
        function layoutDry(direction: string): string {
            const b = ShellState.componentsFor(Screens.screens[0])?.bar?.entryItem("layout");
            return b ? b.cycle(direction, true) + " last=[" + Hypr.lastCommand + "]" : "no layout button";
        }

        // The layout button's click handler, the one a real click runs. Refused unless
        // CAELESTIA_DRYRUN=1, so a test never sends `cycle-layout`.
        function clickLayout(): string {
            const b = ShellState.componentsFor(Screens.screens[0])?.bar?.entryItem("layout");
            if (!b)
                return "no layout button";
            if (!Paths.dryRun)
                return "refused: not a dry run";
            return b.click() + " last=[" + Hypr.lastCommand + "]";
        }

        // The layout button: glyph, active workspace, layout (shown and from komorebi), visibility.
        function layoutButton(): string {
            const b = ShellState.componentsFor(Screens.screens[0])?.bar?.entryItem("layout");
            return b ? b.debugState() : "no layout button";
        }

        // count of windows, icons shown, cell size, focused index, then per icon: "wsId:focused".
        function apps(): string {
            try {
                const l = ShellState.componentsFor(Screens.screens[0])?.bar?.entryItem("activeWindow");
                if (!l)
                    return "no apps list";
                const marks = l.shown.map(g => g.windows.map(t => String(t.wsId)).join("+") + (g.windows.some(t => t.address === l.focusedAddress) ? "*" : ""));
                return [l.count, l.shown.length, l.cell, l.focusedIndex(), "fg=" + l.focusedAddress, "avail=" + Hypr.taskbarAvailable, "win=" + Hypr.barWindow, "model=" + Hypr.taskbarCount, "rows=" + Object.keys(Hypr.taskbarRows).length, "wc=" + (typeof S.WindowControl !== "undefined"), marks.join(",")].join(" ");
            } catch (e) {
                return "error " + e;
            }
        }

        // TEST ONLY. The drawers window: active (QWindow::active), the item with active focus, the
        // keyboardFocus property (0 none, 1 exclusive, 2 on demand), the real foreground HWND, the
        // launcher/session flags and the input mask grab flag.
        function winState(): string {
            const c = ShellState.componentsFor(Screens.screens[0]);
            const w = c?.rootWindow;
            if (!w)
                return "no window";
            const bw = w.backingWindow;
            const s = ShellState.forScreen(Screens.screens[0]);
            return `active=${bw.active} visible=${bw.visible} focusItem=${bw.activeFocusItem} keyboardFocus=${w.keyboardFocus} fg=${S.WindowControl.foreground()} launcher=${s.launcher} session=${s.session} lightDismiss=${c.panels ? "yes" : "no"}`;
        }

        // TEST ONLY. Remembers the foreground window, and gives it back. A test that activates the
        // shell window uses these so the owner's focus returns.
        function saveFg(): string {
            scope.savedFg = S.WindowControl.foreground();
            return String(scope.savedFg);
        }

        function restoreFg(): string {
            return String(S.WindowControl.activate(scope.savedFg)) + " fg=" + S.WindowControl.foreground();
        }

        target: "bar"
    }

    // TEST ONLY. `wabarc --config-home <home> call launcher action <name>` runs the handler of the
    // launcher row with that name (Light, Dark, Random, Lock, Sleep, Shutdown, ...), the same code a
    // click runs. Run it with CAELESTIA_DRYRUN=1: the actions then only log.
    IpcHandler {
        function action(name: string): string {
            return Actions.invoke(name);
        }

        // Rows the `>` list shows, comma separated.
        function actions(): string {
            const names = [];
            for (let i = 0; i < Actions.list.length; i++)
                names.push(Actions.list[i].name);
            return names.join(", ");
        }

        // A press at (x, y) of the drawers window, through the same handler a mouse press runs.
        function pressAt(x: int, y: int): string {
            const w = ShellState.componentsFor(Screens.screens[0])?.interactionWrapper;
            return w ? String(w.dismissOnPress(x, y)) : "no window";
        }

        // Opens or closes the launcher the way the shortcut does (the screen state flag).
        function open(): string {
            ShellState.forScreen(Screens.screens[0]).launcher = true;
            return "ok";
        }

        function close(): string {
            ShellState.forScreen(Screens.screens[0]).launcher = false;
            return "ok";
        }

        // Types `text` into the search field (replacing what is there).
        function search(text: string): string {
            const s = scope.search_();
            if (!s)
                return "no search field (open the launcher first)";
            s.text = text;
            return "ok";
        }

        // Names of the rows the list holds, one per line, with the current one marked "*".
        function list(): string {
            const l = scope.list_();
            if (!l)
                return "no list";
            return scope.rows_().map((v, i) => `${i === l.currentIndex ? "*" : " "}${i} ${scope.name_(v)}`).join("
");
        }

        // How many of the wallpaper items the list shows have their picture loaded: "ready=R shown=S
        // items=N". A timing probe for the thumbnails; reads only.
        function walls(): string {
            const l = scope.list_();
            if (!l)
                return "no list";
            let ready = 0, shown = 0, items = 0;
            for (let i = 0; i < l.count; i++) {
                const item = l.itemAtIndex(i);
                if (!item)
                    continue;
                items++;
                if (item.opacity < 0.01)
                    continue;
                shown++;
                const v = scope.visualIn_(item, 0);
                const done = v ? v.ready === true : false;
                if (done)
                    ready++;
            }
            return `ready=${ready} shown=${shown} items=${items}`;
        }

        // Selects row `i` and runs the handler that Enter runs (SearchBar.accepted).
        function select(i: int): string {
            const l = scope.list_();
            const s = scope.search_();
            if (!l || !s)
                return "no list";
            if (!scope.search_().text.startsWith(GlobalConfig.launcher.actionPrefix))
                return "refused: only the > lists (an app row would start the app)";
            if (i < 0 || i >= scope.rows_().length)
                return `no row ${i}`;
            l.currentIndex = i;
            s.accepted();
            return `ok ${scope.name_(scope.rows_()[i])}`;
        }

        // Runs the click handler of row `i`'s delegate (the StateLayer onClicked of the item).
        function click(i: int): string {
            const l = scope.list_();
            if (!l)
                return "no list";
            if (!scope.search_().text.startsWith(GlobalConfig.launcher.actionPrefix))
                return "refused: only the > lists (an app row would start the app)";
            const item = l.itemAtIndex(i);
            if (!item)
                return `row ${i} has no item`;
            let layer = null;
            for (let k = 0; k < item.children.length; k++)
                if (item.children[k].objectName === "rowClick")
                    layer = item.children[k];
            if (!layer)
                return `row ${i} has no click target`;
            layer.clicked(null);
            return "ok";
        }

        // The colour choice, the last session action, then the launcher: open, search text, row
        // count, mode (apps, actions or wallpapers) and the current index.
        function state(): string {
            const s = scope.search_();
            const l = scope.list_();
            const open = ShellState.forScreen(Screens.screens[0]).launcher;
            const mode = !s ? "-" : s.text.startsWith(`${GlobalConfig.launcher.actionPrefix}wallpaper `) ? "wallpapers" : s.text.startsWith(GlobalConfig.launcher.actionPrefix) ? "actions" : "apps";
            return `scheme=${Colours.scheme} seed=${Colours.seed} variant=${Colours.flavour} light=${Colours.currentLight} wallpaper=${WallpaperService.actualCurrent.slice(WallpaperService.actualCurrent.lastIndexOf("/") + 1)} session=${SessionManager.lastLogged} | open=${open} search=[${s?.text ?? ""}] rows=${l ? scope.rows_().length : -1} count=${l?.count ?? -1} mode=${mode} index=${l?.currentIndex ?? -1} shown=${l?.pathItemCount ?? l?.count ?? -1} walls=${WallpaperService.list.length} dir=${Paths.wallsdir}`;
        }

        target: "launcher"
    }

    // TEST ONLY. Times the pictures of the wallpaper picker without the launcher: loads the first
    // `count` wallpapers into plain Images set up like the picker's (`full`: the file at the item's
    // size; `thumb`: image://thumb) and reports when each became ready. `wabarc call thumbprobe
    // start thumb 7`, then `result` until all are ready.
    property var probes: []

    Component {
        id: probeComp

        Image {
            property double t0: Date.now()
            property double ms: -1

            asynchronous: true
            cache: false
            onStatusChanged: {
                if (status === Image.Ready || status === Image.Error)
                    ms = status === Image.Ready ? Date.now() - t0 : -2;
            }
        }
    }

    IpcHandler {
        function start(mode: string, count: int): string {
            for (const o of scope.probes)
                o.destroy();
            const next = [];
            const list = WallpaperService.list;
            for (let i = 0; i < count && i < list.length; i++) {
                const path = list[i].path;
                next.push(probeComp.createObject(scope, mode === "thumb" ? {
                    source: W.Thumbnails.url(path, 640)
                } : {
                    source: "file:///" + path,
                    sourceSize: Qt.size(280, 158)
                }));
            }
            scope.probes = next;
            return `started ${next.length}`;
        }

        function result(): string {
            const ms = scope.probes.map(o => o.ms);
            const ok = ms.filter(m => m >= 0);
            return `n=${ms.length} ready=${ok.length} error=${ms.filter(m => m === -2).length} first=${ok.length ? Math.min(...ok) : -1} last=${ok.length ? Math.max(...ok) : -1}`;
        }

        target: "thumbprobe"
    }
}
