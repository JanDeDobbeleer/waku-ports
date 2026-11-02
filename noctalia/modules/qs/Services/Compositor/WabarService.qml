import QtQuick
import Quickshell
import Quickshell.Wayland
import wabar.services as S
import qs.Commons

// Compositor backend for wabar: komorebi or GlazeWM through the engine's `Workspaces`, windows
// through `ToplevelManager`. Same contract as the Wayland backends this replaces.
//
// A window belongs to the workspace whose `windows` (komorebi) lists its handle. With GlazeWM, or
// for a window komorebi does not list, it is reported on the focused workspace of the first monitor.
Item {
  id: root

  property ListModel workspaces: ListModel {}
  property var windows: []
  property int focusedWindowIndex: -1
  property bool globalWorkspaces: false

  signal workspaceChanged
  signal activeWindowChanged
  signal windowListChanged
  signal displayScalesChanged

  function initialize() {
    syncWorkspaces();
    syncWindows();
    Logger.i("WabarService", "Service started (" + (S.Workspaces.provider || "no tiling window manager") + ")");
  }

  Connections {
    target: S.Workspaces
    function onMonitorsChanged() {
      Qt.callLater(root.syncWorkspaces);
    }
  }

  Connections {
    target: ToplevelManager.toplevels
    function onValuesChanged() {
      Qt.callLater(root.syncWindows);
    }
  }

  Connections {
    target: ToplevelManager
    function onActiveToplevelChanged() {
      Qt.callLater(root.syncWindows);
      root.activeWindowChanged();
    }
  }

  // The engine names a monitor "DISPLAY1"; Quickshell screens are "\\.\DISPLAY1". The bar matches
  // a workspace to its screen by name, so report the screen's own name.
  function screenNameFor(monitorName) {
    const want = String(monitorName || "").toLowerCase();
    for (const s of Quickshell.screens) {
      const n = String(s.name);
      if (n.toLowerCase() === want || n.toLowerCase().endsWith("\\" + want))
        return n;
    }
    return String(monitorName || "");
  }

  function syncWorkspaces() {
    workspaces.clear();
    const mons = S.Workspaces.monitors || [];
    for (let m = 0; m < mons.length; m++) {
      const list = mons[m].workspaces || [];
      for (let w = 0; w < list.length; w++) {
        const ws = list[w];
        workspaces.append({
                            "id": mons[m].name + ":" + ws.id,
                            "idx": w + 1,
                            "name": ws.label || String(w + 1),
                            "output": screenNameFor(mons[m].name),
                            "isFocused": !!ws.focused,
                            "isActive": !!ws.active,
                            "isUrgent": false,
                            "isOccupied": !!ws.hasWindows,
                            "oid": ws.id
                          });
      }
    }
    syncWindows();
    workspaceChanged();
  }

  function focusedWorkspaceId() {
    for (let i = 0; i < workspaces.count; i++) {
      if (workspaces.get(i).isFocused)
        return workspaces.get(i).id;
    }
    return workspaces.count > 0 ? workspaces.get(0).id : "1";
  }

  function syncWindows() {
    const out = [];
    const wsId = focusedWorkspaceId();
    const output = workspaces.count > 0 ? workspaces.get(0).output : "";
    // hwnd -> {workspace id, monitor name} for the windows komorebi lists.
    const placed = {};
    for (const mon of (S.Workspaces.monitors || [])) {
      for (const ws of (mon.workspaces || [])) {
        for (const hwnd of (ws.windows || []))
          placed[String(hwnd)] = {
            "workspaceId": mon.name + ":" + ws.id,
            "output": screenNameFor(mon.name)
          };
      }
    }
    let focused = -1;
    const tls = ToplevelManager.toplevels.values || [];
    for (let i = 0; i < tls.length; i++) {
      const t = tls[i];
      if (t.activated)
        focused = i;
      const at = placed[String(t.hwnd)];
      out.push({
                 "id": t.hwnd,
                 "appId": t.appId,
                 "title": t.title,
                 "output": at ? at.output : output,
                 "workspaceId": at ? at.workspaceId : wsId,
                 "isFocused": t.activated,
                 "toplevel": t
               });
    }
    windows = out;
    focusedWindowIndex = focused;
    windowListChanged();
  }

  function focusWindow(window) {
    if (window && window.toplevel)
      window.toplevel.activate();
  }

  function closeWindow(window) {
    if (window && window.toplevel)
      window.toplevel.close();
  }

  function switchToWorkspace(workspace) {
    if (!workspace)
      return;
    Quickshell.execDetached(["komorebic", "focus-workspace", String((workspace.idx ?? 1) - 1)]);
  }

  function cycleKeyboardLayout() {
    Logger.w("WabarService", "Keyboard layout cycling not supported");
  }

  function queryDisplayScales() {
  }

  function getFocusedScreen() {
    return null;
  }
}
