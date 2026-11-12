.pragma library

function buildGroups(compositor, onlySameOutput, screenName) {
  const order = [];
  const byKey = {};
  const activeIds = Array.from(compositor.getActiveWorkspaces()).map(function (ws) { return ws.id; });
  const total = compositor.windows.count || 0;
  for (let i = 0; i < total; i++) {
    const w = compositor.windows.get(i);
    if (!w || !w.appId)
      continue;
    if (onlySameOutput && w.output !== screenName)
      continue;
    const key = String(w.appId).toLowerCase();
    let g = byKey[key];
    if (!g) {
      g = { key: key, appId: w.appId, windows: [], focused: false, onActiveWs: false };
      byKey[key] = g;
      order.push(g);
    }
    g.windows.push(w);
    if (w.isFocused)
      g.focused = true;
    if (activeIds.includes(w.workspaceId))
      g.onActiveWs = true;
  }
  return order;
}

function focusGroup(compositor, g) {
  if (!g || g.windows.length === 0)
    return;
  let target = g.windows[0];
  const fi = g.windows.findIndex(function (w) { return w.isFocused; });
  if (fi >= 0)
    target = g.windows[(fi + 1) % g.windows.length];
  compositor.focusWindow(target);
}

function windowCount(group) {
  return group.windows.length;
}
