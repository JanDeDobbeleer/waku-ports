import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import qs.services
import qs.utils

// TEST ONLY. Opens and closes the bar flyouts without a cursor, so a capture run (no input allowed)
// can check them: `wabarc --config-home <home> call bar popout network`. It sets the same state the
// hover handler sets (Wrapper.currentName, hasCurrent, currentCenter). Remove once a person has
// checked the hover path on a real desktop.
Scope {
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

        // Runs the click handler of apps-list icon `i` (0-based), but only when it is the focused
        // window, which makes it a no-op. Returns what the handler did.
        function clickApp(i: int): string {
            const l = ShellState.componentsFor(Screens.screens[0])?.bar?.entryItem("activeWindow");
            if (!l)
                return "no apps list";
            if (l.shown[i]?.address !== l.focusedAddress)
                return "refused: not the focused window";
            return l.clickApp(i);
        }

        // count of windows, icons shown, cell size, focused index, then per icon: "wsId:focused".
        function apps(): string {
            try {
                const l = ShellState.componentsFor(Screens.screens[0])?.bar?.entryItem("activeWindow");
                if (!l)
                    return "no apps list";
                const marks = l.shown.map(t => String(t.wsId) + (t.address === l.focusedAddress ? "*" : ""));
                return [l.count, l.shown.length, l.cell, l.focusedIndex(), "fg=" + l.focusedAddress, "avail=" + Hypr.taskbarAvailable, "win=" + Hypr.barWindow, "model=" + Hypr.taskbarCount, "rows=" + Object.keys(Hypr.taskbarRows).length, "addr=" + l.shown.map(t => t.address).join("/"), marks.join(",")].join(" ");
            } catch (e) {
                return "error " + e;
            }
        }

        target: "bar"
    }
}
