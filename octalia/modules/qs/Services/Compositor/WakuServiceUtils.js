.pragma library

function screenNameFor(monitorName, screens) {
    const want = String(monitorName || "").toLowerCase();
    for (const s of screens) {
      const n = String(s.name);
      if (n.toLowerCase() === want || n.toLowerCase().endsWith("\\" + want))
        return n;
    }
    return String(monitorName || "");
}

function syncWorkspaces(root, workspaceSource) {
    root.workspaces.clear();
    const mons = workspaceSource.monitors || [];
    for (let m = 0; m < mons.length; m++) {
      const list = mons[m].workspaces || [];
      for (let w = 0; w < list.length; w++) {
        const ws = list[w];
        root.workspaces.append({
                            "id": mons[m].name + ":" + ws.id,
                            "idx": w + 1,
                            "name": ws.label || String(w + 1),
                            "output": root.screenNameFor(mons[m].name),
                            "isFocused": !!ws.focused,
                            "isActive": !!ws.active,
                            "isUrgent": false,
                            "isOccupied": !!ws.hasWindows,
                            "oid": ws.id
                          });
      }
    }
    root.syncWindows();
    root.workspaceChanged();
}

function syncWindows(root, workspaceSource, ToplevelManager) {
    const out = [];
    const wsId = root.focusedWorkspaceId();
    const output = root.workspaces.count > 0 ? root.workspaces.get(0).output : "";
    // hwnd -> {workspace id, monitor name} for the windows the desktops list.
    const placed = {};
    for (const mon of (workspaceSource.monitors || [])) {
      for (const ws of (mon.workspaces || [])) {
        for (const hwnd of (ws.windows || []))
          placed[String(hwnd)] = {
            "workspaceId": mon.name + ":" + ws.id,
            "output": root.screenNameFor(mon.name)
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
    root.windows = out;
    root.focusedWindowIndex = focused;
    root.windowListChanged();
}

function focusWindow(window) {
    if (window && window.toplevel)
      window.toplevel.activate();
}

function closeWindow(window) {
    if (window && window.toplevel)
      window.toplevel.close();
}

function workspaceOid(workspace) {
  return workspace.oid;
}

function focusedWorkspaceId(workspaces) {
    for (let i = 0; i < workspaces.count; i++) {
      if (workspaces.get(i).isFocused)
        return workspaces.get(i).id;
    }
    return workspaces.count > 0 ? workspaces.get(0).id : "1";
}
