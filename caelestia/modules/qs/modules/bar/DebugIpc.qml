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

        // "<items> <button visible> <button height> <last action>"
        function trayState(): string {
            const t = ShellState.componentsFor(Screens.screens[0])?.bar?.entryItem("tray");
            return `${TrayItems.count} ${t ? t.active : "no button"} ${t ? t.height : 0} [${TrayItems.lastAction}]`;
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

        // Opens the dashboard on tab `i` (0-based), as a click on that tab does. -1 closes it.
        function dashTab(i: int): string {
            const s = ShellState.forScreen(Screens.screens[0]);
            if (i < 0) {
                s.dashboard = false;
                return "closed";
            }
            s.dashboardTab = i;
            s.dashboard = true;
            return `dashboard tab ${i}`;
        }

        // The dashboard panel rectangle in physical screen pixels: x y w h.
        function dashRect(): string {
            const screen = Screens.screens[0];
            const d = ShellState.componentsFor(screen)?.panels?.dashboard;
            if (!d)
                return "none";
            const pt = d.mapToItem(null, 0, 0);
            const f = v => Math.round(v * screen.devicePixelRatio);
            return `${f(pt.x)} ${f(pt.y)} ${f(d.width)} ${f(d.height)}`;
        }

        // The Utilities tab: buttons shown, buttons known, whether the existence check ran, the
        // missing probe files, then "id=target" per shown button.
        function utilitiesTab(): string {
            const shown = UtilitiesActions.actions;
            return `${shown.length} of ${UtilitiesActions.all.length} probed=${UtilitiesActions.probed} missing=[${Object.keys(UtilitiesActions.missing).join(",")}] ${shown.map(a => `${a.id}=${a.target}`).join(" ")}`;
        }

        // Runs Utilities tab action `id` through the click path. Refused unless CAELESTIA_DRYRUN=1, so
        // a test never opens a window. Returns the target and the logged line.
        function utilitiesAction(id: string): string {
            if (!Paths.dryRun)
                return "refused: not a dry run";
            const target = UtilitiesActions.launch(id);
            return target ? `${target} [${UtilitiesActions.lastLogged}]` : `no action ${id}`;
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
        // the windows' hwnds in brackets ("(min)" after a minimized one) and a "*" on the group
        // with the focused window.
        function appGroups(): string {
            return Hypr.appGroups.map(g => `${g.exe} ${g.windows.length} ${g.windows.map(t => Hypr.workspaceLabel(t)).join("/")} [${g.windows.map(t => (t.srcHwnd ?? t.address) + (t.minimized ? "(min)" : "")).join(",")}]${g.windows.some(t => t.address === Hypr.focusedHwnd) ? " *" : ""}`).join("; ");
        }

        // TEST ONLY. Per minimized taskbar row: hwnd, executable and why it is (or is not) a
        // minimized toplevel ("ok" when it is). No titles. Then the number of ignore rules read.
        function minimizedState(): string {
            const now = Date.now();
            const out = [];
            for (const h of Object.keys(Hypr.taskbarWindows)) {
                const row = Hypr.taskbarWindows[h];
                if (!row.minimized)
                    continue;
                const v = Hypr.minimizedVerdict(h, row, Hypr.managedHwnds, Hypr.seenHwnds, Hypr.ignoreRules, Hypr.restoredAt, now);
                const s = Hypr.seenHwnds[h];
                out.push(`${h} ${row.exe} ${v || "ok"} seen=${s ? s.mi + ":" + s.wi : "-"}`);
            }
            return `${out.join("; ") || "no minimized rows"} | rules=${Hypr.ignoreRules.length}`;
        }

        // TEST ONLY. What a click on apps-list icon `i` would do, without doing it (the dry path
        // of Hypr.activateToplevel on the window clickGroup would pick).
        function clickAppDry(i: int): string {
            const l = ShellState.componentsFor(Screens.screens[0])?.bar?.entryItem("activeWindow");
            const g = l?.shown[i];
            if (!g)
                return "none";
            const ws = g.windows;
            const fi = ws.findIndex(t => t.address === Hypr.focusedHwnd);
            const t = fi >= 0 ? ws[(fi + 1) % ws.length] : (ws.find(x => x.address === Hypr.groupLastFocused[g.key]) ?? ws[0]);
            return `${g.exe} ${t.address}${t.minimized ? "(min)" : ""} -> ${Hypr.activateToplevel(t, true)}`;
        }

        // TEST ONLY. Runs Hypr.minimizedVerdict over fake taskbar rows and checks each answer.
        // Returns "PASS n/n" or the cases that failed.
        function minimizedFilterTest(): string {
            const rules = [
                {
                    kind: "Exe",
                    id: "1Password.exe",
                    matching_strategy: "Equals"
                },
                {
                    kind: "Title",
                    id: "Picture-in-Picture",
                    matching_strategy: "Legacy"
                },
                [
                    {
                        kind: "Class",
                        id: "SomeClass",
                        matching_strategy: "Equals"
                    },
                    {
                        kind: "Title",
                        id: "Composite",
                        matching_strategy: "Contains"
                    }
                ],
                [
                    {
                        kind: "Exe",
                        id: "tool.exe",
                        matching_strategy: "Equals"
                    },
                    {
                        kind: "Title",
                        id: "Main",
                        matching_strategy: "DoesNotContain"
                    }
                ]
            ];
            const managed = {
                "300": true
            };
            const seen = {
                "300": {
                    mi: 0,
                    wi: 0,
                    exe: "Code.exe"
                },
                "700": {
                    mi: 0,
                    wi: 1,
                    exe: "Spotify.exe"
                },
                "800": {
                    mi: 0,
                    wi: 2,
                    exe: "1Password.exe"
                }
            };
            const restored = {
                "1300": Date.now() - 200,
                "1400": Date.now() - 5000
            };
            const r = (title, exe, minimized) => ({
                    title: title,
                    exe: exe,
                    minimized: minimized
                });
            const cases = [
                ["100", r("Visible", "notepad", false), "not minimized"],
                ["200", r("Cloaked on workspace III", "Code", false), "not minimized"],
                ["300", r("Minimized but listed", "Code", true), "komorebi lists it"],
                ["400", r("   ", "notepad", true), "empty title"],
                ["500", r("bar", "wabar", true), "the bar"],
                ["600", r("Vault", "1Password", true), "komorebi ignores it"],
                ["650", r("Picture-in-Picture", "firefox", true), "komorebi ignores it"],
                ["700", r("Spotify Premium", "Spotify", true), ""],
                ["800", r("Vault", "1Password", true), ""],
                ["900", r("Untitled - Notepad", "notepad", true), ""],
                ["1000", r("Composite title", "app", true), ""],
                ["1100", r("Helper", "tool", true), "komorebi ignores it"],
                ["1150", r("Main window", "tool", true), ""],
                ["1200", r("No exe", "", true), "no executable"],
                ["1300", r("Just restored", "notepad", false), ""],
                ["1400", r("Restored long ago", "notepad", false), "not minimized"],
                ["1500", null, "no taskbar row"]
            ];
            const fails = [];
            const now = Date.now();
            for (const [h, row, want] of cases) {
                const got = Hypr.minimizedVerdict(h, row, managed, seen, rules, restored, now);
                if (got !== want)
                    fails.push(`${h}: want [${want}] got [${got}]`);
            }
            // Tags: a toplevel with an ignored tag is ignored, one without is not.
            const tl = tags => ({
                    lastIpcObject: {
                        class: "x",
                        mapped: true,
                        tags: tags
                    }
                });
            if (!Hypr.isToplevelIgnored(tl(["hide_in_bar"]), ["hide_in_bar"]))
                fails.push("tag hide_in_bar not ignored");
            if (Hypr.isToplevelIgnored(tl([]), ["hide_in_bar"]))
                fails.push("untagged toplevel ignored");
            const n = cases.length + 2;
            return fails.length === 0 ? `PASS ${n}/${n}` : `FAIL ${fails.length}/${n}: ${fails.join("; ")}`;
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

        // TEST ONLY. komorebi's cached work area against the OS work area, one line per komorebi
        // monitor ("name id komorebi=l,t,r,b os=l,t,r,b state", physical pixels), then whether a
        // refresh would run, the hidden window, the last verdict and the age of the last refresh.
        // It shows the last reading and starts a fresh read-only one (a dry pass: it never
        // refreshes); call it again a second later for the fresh numbers.
        function komorebiAreas(): string {
            const rows = Hypr.workAreaRows(Hypr.komorebiMonitors, Hypr.osMonitors, Hypr.areaTolerance);
            const started = Hypr.areaPass(true);
            const lines = rows.map(r => `${r.name} id=${r.id} komorebi=${r.komorebi} os=${r.os} ${r.state}`);
            const screens = Quickshell.screens.map(s => `${s.name} ${s.x},${s.y} ${s.width}x${s.height}@${s.devicePixelRatio}`).join(", ");
            const age = Hypr.lastAreaRefresh > 0 ? Math.round((Date.now() - Hypr.lastAreaRefresh) / 1000) + "s" : "never";
            return `${lines.join("; ") || "no komorebi monitors read yet"} | refresh=${Hypr.areaNeedsRefresh(rows) ? "would run" : "no"} hidden=${Hypr.komorebiHiddenHwnd} verdict=[${Hypr.lastAreaVerdict}] lastRefresh=${age} dryRun=${Hypr.dryRun} fresh=${started} screens=[${screens}]`;
        }

        // TEST ONLY. The refresh, always as a dry run: it logs and returns the message it would
        // send, never sends it.
        function komorebiRefresh(): string {
            return Hypr.refreshKomorebi(true);
        }

        // TEST ONLY. Skews the OS work area by `px` on the left and starts a settle cycle, so the
        // automatic path finds a difference. Refused unless CAELESTIA_DRYRUN=1: the refresh it
        // reaches is then only logged.
        function komorebiCycle(px: int): string {
            if (!Paths.dryRun)
                return "refused: not a dry run";
            Hypr.debugAreaSkew = px;
            Hypr.startAreaCycle();
            return `cycle started, skew ${px}`;
        }

        // TEST ONLY. Runs Hypr.workAreaRows over fake monitors and checks each state and the
        // refresh decision. Returns "PASS n/n" or the cases that failed.
        function komorebiAreasTest(): string {
            const km = (name, id, l, t, w, h) => ({
                    name: name,
                    id: id,
                    work: {
                        left: l,
                        top: t,
                        right: w,
                        bottom: h
                    }
                });
            const om = (name, id, l, t, r, b) => ({
                    name: name,
                    id: id,
                    work: [l, t, r, b]
                });
            const cases = [
                ["in sync", [km("DISPLAY1", 1, 63, 0, 2817, 1920)], [om("DISPLAY1", 1, 63, 0, 2880, 1920)], ["ok"], false],
                ["full monitor cached", [km("DISPLAY1", 1, 0, 0, 2880, 1920)], [om("DISPLAY1", 1, 63, 0, 2880, 1920)], ["differs"], true],
                ["within tolerance", [km("DISPLAY1", 1, 60, 0, 2820, 1920)], [om("DISPLAY1", 1, 63, 0, 2880, 1920)], ["ok"], false],
                ["old scale cached", [km("DISPLAY1", 1, 47, 0, 1873, 1280)], [om("DISPLAY1", 1, 63, 0, 2880, 1920)], ["differs"], true],
                ["stale handle", [km("DISPLAY1", 9, 0, 0, 2880, 1920)], [om("DISPLAY1", 1, 63, 0, 2880, 1920)], ["stale"], false],
                ["stale handle in sync", [km("DISPLAY1", 9, 63, 0, 2817, 1920)], [om("DISPLAY1", 1, 63, 0, 2880, 1920)], ["ok"], false],
                ["monitor gone", [km("DISPLAY2", 2, 0, 0, 1920, 1080)], [om("DISPLAY1", 1, 63, 0, 2880, 1920)], ["unknown"], false],
                ["second monitor off", [km("DISPLAY1", 1, 63, 0, 2817, 1920), km("DISPLAY2", 2, 2880, 0, 1920, 1080)], [om("DISPLAY1", 1, 63, 0, 2880, 1920), om("DISPLAY2", 2, 2943, 0, 4800, 1080)], ["ok", "differs"], true],
                ["no OS reading", [km("DISPLAY1", 1, 63, 0, 2817, 1920)], [], ["unknown"], false]
            ];
            const fails = [];
            for (const [label, k, o, want, refresh] of cases) {
                const rows = Hypr.workAreaRows(k, o, 4);
                const got = rows.map(r => r.state);
                if (JSON.stringify(got) !== JSON.stringify(want))
                    fails.push(`${label}: want [${want}] got [${got}]`);
                if (Hypr.areaNeedsRefresh(rows) !== refresh)
                    fails.push(`${label}: refresh want ${refresh}`);
            }
            const n = cases.length;
            return fails.length === 0 ? `PASS ${n}/${n}` : `FAIL ${fails.length}/${n}: ${fails.join("; ")}`;
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
                // "m" after a workspace id: that window is minimized.
                const marks = l.shown.map(g => g.windows.map(t => String(t.wsId) + (t.minimized ? "m" : "")).join("+") + (g.windows.some(t => t.address === l.focusedAddress) ? "*" : ""));
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
    // TEST ONLY. The colour state, for a capture run without input: `wabarc --config-home <home>
    // call colours dump` prints the mode, whether the preview palette is shown and a few roles;
    // `mode light` switches the palette only (never the Windows theme); `step <i>` moves the open
    // launcher list to row i as the arrow keys do, without accepting it.
    IpcHandler {
        function dump(): string {
            const p = Colours.palette;
            return `currentLight=${Colours.currentLight} showPreview=${Colours.showPreview} lock=${WallpaperService.previewColourLock} wall=${WallpaperService.actualCurrent} surface=${p.m3surface} primary=${p.m3primary} background=${p.m3background} current.surface=${Colours.current.m3surface} preview.surface=${Colours.preview.m3surface} t.surface=${Colours.tPalette.m3surface}`;
        }

        function mode(m: string): string {
            Colours.applyMode(m);
            return "ok";
        }

        function step(i: int): string {
            const l = scope.list_();
            if (!l)
                return "no list";
            l.currentIndex = i;
            return `ok ${i}`;
        }

        target: "colours"
    }
}