import QtQuick
import Quickshell
import Quickshell.Bluetooth
import waku as W
import waku.services as S
import qs.services
import qs.utils
import Celeste.Config
import Celeste.Services
import qs.modules.launcher.services
import "DebugHelpers.js" as DH

// TEST ONLY. Opens and closes the bar flyouts without a cursor, so a capture run (no input allowed)
// can check them: `wakuc --config-home <home> call bar popout network`. It sets the same state the
// hover handler sets (Wrapper.currentName, hasCurrent, currentCenter). Remove once a person has
// checked the hover path on a real desktop. The logic is in DebugHelpers.js, which gets the
// singletons it uses through `env`.
Scope {
    id: scope

    final property var savedFg: 0
    // TEST ONLY: the probe images of the thumbprobe handler.
    final property var probes: []
    readonly final property var env: ({
            scope: scope,
            probeComp: probeComp,
            ShellState: ShellState,
            Screens: Screens,
            Hypr: Hypr,
            Paths: Paths,
            TrayItems: TrayItems,
            UtilitiesActions: UtilitiesActions,
            Bluetooth: Bluetooth,
            Icons: Icons,
            Actions: Actions,
            GlobalConfig: GlobalConfig,
            Colours: Colours,
            WallpaperService: WallpaperService,
            SessionManager: SessionManager,
            WindowControl: S.WindowControl,
            Thumbnails: W.Thumbnails
        })

    IpcHandler {
        function popout(name: string): string {
            return DH.popout(scope.env, name);
        }

        function popoutClose(): void {
            DH.popoutClose(scope.env);
        }

        // name, hasCurrent, then the flyout rectangle in physical screen pixels: x y w h.
        function popoutState(): string {
            return DH.popoutState(scope.env);
        }

        // One line per known device: connected, waku type, resolved Material icon. No names.
        function btDevices(): string {
            return DH.btDevices(scope.env);
        }

        // TEST ONLY: `n` fake tray items replace the real ones (0 restores them). Clicks on them only
        // record themselves; see trayState.
        function fakeTray(n: int): string {
            TrayItems.debugFake = n;
            return `fake tray items: ${n}`;
        }

        // "<items> <button visible> <button height> <last action>"
        function trayState(): string {
            return DH.trayState(scope.env);
        }

        // Calls the click handler of fake item `i` with `button` (left, middle, right).
        function trayClick(i: int, button: string): string {
            return DH.trayClick(scope.env, i, button);
        }

        function entries(): string {
            return DH.entries(scope.env);
        }

        // Runs the click handler of the workspace dot `n` (1-based), but only when `n` is the
        // focused workspace, which makes it a no-op. Returns what the handler did.
        function clickWorkspace(n: int): string {
            return DH.clickWorkspace(scope.env, n);
        }

        // Runs the click handler of the clock: toggles the dashboard (first tab). Returns what it did.
        function clickClock(): string {
            return DH.clickClock(scope.env);
        }

        // "<dashboard> <tab> <yyyy-mm>" of the first screen's state.
        function dashState(): string {
            return DH.dashState(scope.env);
        }

        // Opens the dashboard on tab `i` (0-based), as a click on that tab does. -1 closes it.
        function dashTab(i: int): string {
            return DH.dashTab(scope.env, i);
        }

        // The dashboard panel rectangle in physical screen pixels: x y w h.
        function dashRect(): string {
            return DH.dashRect(scope.env);
        }

        // The Utilities tab: buttons shown, buttons known, whether the existence check ran, the
        // missing probe files, then "id=target" per shown button.
        function utilitiesTab(): string {
            return DH.utilitiesTab(scope.env);
        }

        // Runs Utilities tab action `id` through the click path. Refused unless CELESTE_DRYRUN=1, so
        // a test never opens a window. Returns the target and the logged line.
        function utilitiesAction(id: string): string {
            return DH.utilitiesAction(scope.env, id);
        }

        // Runs the click handler of apps-list icon `i` (0-based), but only when it is the focused
        // window, which makes it a no-op. Returns what the handler did.
        function clickApp(i: int): string {
            return DH.clickApp(scope.env, i);
        }

        // Same handler as a click on a row of the group flyout, for window `i` of the group of
        // executable `exe`, but only when it is already the focused window (a no-op).
        function activateGroupWindow(exe: string, i: int): string {
            return DH.activateGroupWindow(scope.env, exe, i);
        }

        // Same handler as a click on a group icon (cycle), refused unless the group has one window
        // that is already focused, which is a no-op.
        function activateApp(i: int): string {
            return DH.clickApp(scope.env, i);
        }

        // One line per group: executable, window count, workspaces of its windows (roman numerals),
        // the windows' hwnds in brackets ("(min)" after a minimized one) and a "*" on the group
        // with the focused window.
        function appGroups(): string {
            return DH.appGroups(scope.env);
        }

        function appProgress(): string {
            return DH.appProgress(scope.env);
        }

        // TEST ONLY. What a click on apps-list icon `i` would do, without doing it (the dry path
        // of Hypr.activateToplevel on the window clickGroup would pick).
        function clickAppDry(i: int): string {
            return DH.clickAppDry(scope.env, i);
        }

        // The open group flyout, per card: "hwnd available sourceWidth sourceHeight x,y,w,h" (the
        // thumbnail rectangle in logical window coordinates). Empty when no group flyout is open.
        function thumbState(): string {
            return DH.thumbState(scope.env);
        }

        // TEST ONLY: fake extra windows for the first application, to try the group badge.
        function fakeCopies(n: int): string {
            Hypr.debugCopies = n;
            return "fake windows: " + n;
        }

        // The dots of the workspaces entry (ids) and the active one.
        function dots(): string {
            return DH.dots(scope.env);
        }

        // The layout button's wheel (`previous`) or click (`next`) handler. Always a dry run: the
        // step is logged and returned, never made.
        function layoutDry(direction: string): string {
            return DH.layoutDry(scope.env, direction);
        }

        // The layout button's click handler, the one a real click runs. Refused unless
        // CELESTE_DRYRUN=1, so a test never changes the layout.
        function clickLayout(): string {
            return DH.clickLayout(scope.env);
        }

        // The layout button: glyph, layout and visibility.
        function layoutButton(): string {
            return DH.layoutButton(scope.env);
        }

        // count of windows, icons shown, cell size, focused index, then per icon: "wsId:focused".
        function apps(): string {
            return DH.apps(scope.env);
        }

        // TEST ONLY. The drawers window: active (QWindow::active), the item with active focus, the
        // keyboardFocus property (0 none, 1 exclusive, 2 on demand), the real foreground HWND, the
        // launcher/session flags and the input mask grab flag.
        function winState(): string {
            return DH.winState(scope.env);
        }

        // TEST ONLY. Remembers the foreground window, and gives it back. A test that activates the
        // shell window uses these so the owner's focus returns.
        function saveFg(): string {
            return DH.saveFg(scope.env);
        }

        function restoreFg(): string {
            return DH.restoreFg(scope.env);
        }

        target: "bar"
    }

    // TEST ONLY. `wakuc --config-home <home> call launcher action <name>` runs the handler of the
    // launcher row with that name (Light, Dark, Random, Lock, Sleep, Shutdown, ...), the same code a
    // click runs. Run it with CELESTE_DRYRUN=1: the actions then only log.
    IpcHandler {
        function action(name: string): string {
            return Actions.invoke(name);
        }

        // Rows the `>` list shows, comma separated.
        function actions(): string {
            return DH.actions(scope.env);
        }

        // A press at (x, y) of the drawers window, through the same handler a mouse press runs.
        function pressAt(x: int, y: int): string {
            return DH.pressAt(scope.env, x, y);
        }

        // Opens or closes the launcher the way the shortcut does (the screen state flag).
        function open(): string {
            return DH.setLauncher(scope.env, true);
        }

        function close(): string {
            return DH.setLauncher(scope.env, false);
        }

        // Types `text` into the search field (replacing what is there).
        function search(text: string): string {
            return DH.search(scope.env, text);
        }

        // Names of the rows the list holds, one per line, with the current one marked "*".
        function list(): string {
            return DH.list(scope.env);
        }

        // How many of the wallpaper items the list shows have their picture loaded: "ready=R shown=S
        // items=N". A timing probe for the thumbnails; reads only.
        function walls(): string {
            return DH.walls(scope.env);
        }

        // Selects row `i` and runs the handler that Enter runs (SearchBar.accepted).
        function select(i: int): string {
            return DH.select(scope.env, i);
        }

        // Runs the click handler of row `i`'s delegate (the StateLayer onClicked of the item).
        function click(i: int): string {
            return DH.click(scope.env, i);
        }

        // The colour choice, the last session action, then the launcher: open, search text, row
        // count, mode (apps, actions or wallpapers) and the current index.
        function state(): string {
            return DH.launcherState(scope.env);
        }

        target: "launcher"
    }

    // TEST ONLY. Times the pictures of the wallpaper picker without the launcher: loads the first
    // `count` wallpapers into plain Images set up like the picker's (`full`: the file at the item's
    // size; `thumb`: image://thumb) and reports when each became ready. `wakuc call thumbprobe
    // start thumb 7`, then `result` until all are ready.
    Component {
        id: probeComp

        Image {
            final property double t0: Date.now()
            final property double ms: -1

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
            return DH.probeStart(scope.env, mode, count);
        }

        function result(): string {
            return DH.probeResult(scope.env);
        }

        target: "thumbprobe"
    }

    // TEST ONLY. The colour state, for a capture run without input: `wakuc --config-home <home>
    // call colours dump` prints the mode, whether the preview palette is shown and a few roles;
    // `mode light` switches the palette only (never the Windows theme); `step <i>` moves the open
    // launcher list to row i as the arrow keys do, without accepting it.
    IpcHandler {
        function dump(): string {
            return DH.coloursDump(scope.env);
        }

        function mode(m: string): string {
            Colours.applyMode(m);
            return "ok";
        }

        function step(i: int): string {
            return DH.step(scope.env, i);
        }

        target: "colours"
    }
}