import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
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

        // One line per group: executable, window count, workspaces of its windows (roman numerals)
        // and a "*" on the group with the focused window.
        function appGroups(): string {
            return Hypr.appGroups.map(g => `${g.exe} ${g.windows.length} ${g.windows.map(t => Hypr.workspaceLabel(t)).join("/")}${g.windows.some(t => t.address === Hypr.focusedHwnd) ? " *" : ""}`).join("; ");
        }

        // TEST ONLY: fake extra windows for the first application, to try the group badge.
        function fakeCopies(n: int): string {
            Hypr.debugCopies = n;
            return "fake windows: " + n;
        }

        // The dots of the workspaces entry (ids), the active one and the layout name and glyph
        // under it, plus the last komorebic command (a dry run in tests).
        function dots(): string {
            const w = ShellState.componentsFor(Screens.screens[0])?.bar?.entryItem("workspaces");
            return w ? w.debugDots() + " last=[" + Hypr.lastCommand + "]" : "no workspaces";
        }

        // The layout switcher's click (`next`) or wheel (`previous`) handler. Always a dry run:
        // the command is logged and returned, never sent to komorebi.
        function layoutDry(direction: string): string {
            const w = ShellState.componentsFor(Screens.screens[0])?.bar?.entryItem("workspaces");
            return w ? w.cycleLayout(direction, true) + " last=[" + Hypr.lastCommand + "]" : "no workspaces";
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
            return `scheme=${Colours.scheme} seed=${Colours.seed} variant=${Colours.flavour} light=${Colours.currentLight} wallpaper=${WallpaperService.actualCurrent.slice(WallpaperService.actualCurrent.lastIndexOf("/") + 1)} session=${SessionManager.lastLogged} | open=${open} search=[${s?.text ?? ""}] rows=${l ? scope.rows_().length : -1} count=${l?.count ?? -1} mode=${mode} index=${l?.currentIndex ?? -1} walls=${WallpaperService.list.length} dir=${Paths.wallsdir}`;
        }

        target: "launcher"
    }
}
