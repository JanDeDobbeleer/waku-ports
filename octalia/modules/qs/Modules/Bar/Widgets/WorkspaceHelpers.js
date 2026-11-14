.pragma library

function getSelectedWindow(windows, selectedWindowId) {
  if (!selectedWindowId)
    return null;
  for (var i = 0; i < windows.count; i++) {
    var win = windows.get(i);
    if (win && (win.id == selectedWindowId || win.address == selectedWindowId))
      return win;
  }
  return null;
}

function count(model) { return model.count; }
function get(model, index) { return model.get(index); }

function focusedIndex(model) {
  for (var i = 0; i < model.count; i++) {
    if (model.get(i).isFocused === true)
      return i;
  }
  return -1;
}

function normalizeAppId(appId) {
  if (!appId || typeof appId !== "string")
    return "";
  return appId.toLowerCase().trim();
}

function isAppPinned(pinnedApps, appId) {
  if (!appId)
    return false;
  const normalizedId = normalizeAppId(appId);
  return pinnedApps.some(function (pinnedId) { return normalizeAppId(pinnedId) === normalizedId; });
}

function toggleAppPin(pinnedApps, appId) {
  const normalizedId = normalizeAppId(appId);
  pinnedApps = pinnedApps.slice();
  const existingIndex = pinnedApps.findIndex(function (pinnedId) { return normalizeAppId(pinnedId) === normalizedId; });
  if (existingIndex >= 0)
    pinnedApps.splice(existingIndex, 1);
  else
    pinnedApps.push(appId);
  return pinnedApps;
}

function reconcile(model, targetList) {
  var i = 0;
  while (i < model.count || i < targetList.length) {
    if (i < model.count && i < targetList.length) {
      var existing = model.get(i);
      var target = targetList[i];
      if (existing.id === target.id) {
        model.set(i, target);
        i++;
      } else {
        model.remove(i);
      }
    } else if (i < model.count) {
      model.remove(i);
    } else {
      model.append(targetList[i]);
      i++;
    }
  }
}

function appendDesktopActions(items, entry) {
  if (entry != null && entry.actions) {
    entry.actions.forEach(function (action) {
      items.push({ label: action.name, action: "desktop-action-" + action.name, icon: "chevron-right", desktopAction: action });
    });
  }
}

function runDesktopAction(item, quickshell) {
  if (item && item.desktopAction) {
    if (item.desktopAction.command && item.desktopAction.command.length > 0)
      quickshell.execDetached(item.desktopAction.command);
    else if (item.desktopAction.execute)
      item.desktopAction.execute();
  }
}

function workspaceList(compositor, screen, followFocusedScreen, hideUnoccupied) {
  var targetList = [];
  var focusedOutput = null;
  if (followFocusedScreen) {
    for (var i = 0; i < compositor.workspaces.count; i++) {
      const ws = compositor.workspaces.get(i);
      if (ws.isFocused)
        focusedOutput = ws.output.toLowerCase();
    }
  }
  if (screen !== null) {
    const screenName = screen.name.toLowerCase();
    for (i = 0; i < compositor.workspaces.count; i++) {
      const ws = compositor.workspaces.get(i);
      const matchesScreen = compositor.globalWorkspaces || (followFocusedScreen && ws.output.toLowerCase() == focusedOutput) || (!followFocusedScreen && ws.output.toLowerCase() == screenName);
      if (!matchesScreen || (hideUnoccupied && !ws.isOccupied && !ws.isFocused))
        continue;
      var workspaceData = {
        id: ws.id, idx: ws.idx, name: ws.name, output: ws.output,
        isFocused: ws.isFocused, isActive: ws.isActive, isUrgent: ws.isUrgent, isOccupied: ws.isOccupied
      };
      if (ws.handle !== null && ws.handle !== undefined)
        workspaceData.handle = ws.handle;
      targetList.push(workspaceData);
    }
  }
  return targetList;
}
