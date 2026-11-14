.pragma library

function loadDisplayScalesFromState(root, ShellState, Logger) {
    try {
      const cached = ShellState.getDisplay();
      if (cached && Object.keys(cached).length > 0) {
        root.displayScales = cached;
        root.displayScalesLoaded = true;
        Logger.d("CompositorService", "Loaded display scales from ShellState");
      } else {
        // Migration is now handled in Settings.qml
        root.displayScalesLoaded = true;
      }
    } catch (error) {
      Logger.e("CompositorService", "Failed to load display scales:", error);
      root.displayScalesLoaded = true;
    }
}

function setupBackendConnections(root) {
    if (!root.backend)
      return;

    // Connect backend signals to facade signals
    root.backend.workspaceChanged.connect(() => {
                                       // Sync workspaces when they change
                                       root.syncWorkspaces();
                                       // Forward the signal
                                       root.workspaceChanged();
                                     });

    root.backend.activeWindowChanged.connect(() => {
                                          // Only sync focus state, not entire window list
                                          root.syncFocusedWindow();
                                          // Forward the signal
                                          root.activeWindowChanged();
                                        });

    root.backend.windowListChanged.connect(() => {
                                        root.syncWindows();
                                      });

    // Property bindings - use automatic property change signal
    root.backend.focusedWindowIndexChanged.connect(() => {
                                                root.focusedWindowIndex = root.backend.focusedWindowIndex;
                                              });

    // Overview state (Niri-specific)
    if (root.backend.overviewActiveChanged) {
      root.backend.overviewActiveChanged.connect(() => {
                                              root.overviewActive = root.backend.overviewActive;
                                            });
    }

    // Initial sync
    root.syncWorkspaces();
    root.syncWindows();
    root.focusedWindowIndex = root.backend.focusedWindowIndex;
    if (root.backend.overviewActive !== undefined) {
      root.overviewActive = root.backend.overviewActive;
    }
    if (root.backend.globalWorkspaces !== undefined) {
      root.globalWorkspaces = root.backend.globalWorkspaces;
    }
}

function syncWorkspaces(root) {
    var i;
    root.workspaces.clear();
    const ws = root.backend.workspaces;
    for (i = 0; i < ws.count; i++) {
      root.workspaces.append(ws.get(i));
    }
    // Emit signal to notify listeners that workspace list has been updated
    root.workspacesChanged();
}

function syncWindows(root) {
    var i;
    root.windows.clear();
    const ws = root.backend.windows;
    for (i = 0; i < ws.length; i++) {
      root.windows.append(ws[i]);
    }
    // Emit signal to notify listeners that window list has been updated
    root.windowListChanged();
}

function syncFocusedWindow(root) {
    var i;
    const newIndex = root.backend.focusedWindowIndex;

    // Update isFocused flags by syncing from backend
    for (i = 0; i < root.windows.count && i < root.backend.windows.length; i++) {
      const backendFocused = root.backend.windows[i].isFocused;
      if (root.windows.get(i).isFocused !== backendFocused) {
        root.windows.setProperty(i, "isFocused", backendFocused);
      }
    }

    root.focusedWindowIndex = newIndex;
}

function updateDisplayScales(root, Logger) {
    if (!root.backend || !root.backend.queryDisplayScales) {
      Logger.w("CompositorService", "Backend does not support display scale queries");
      return;
    }

    root.backend.queryDisplayScales();
}

function saveDisplayScalesToCache(root, ShellState, Logger) {
    try {
      ShellState.setDisplay(root.displayScales);
      Logger.d("CompositorService", "Saved display scales to ShellState");
    } catch (error) {
      Logger.e("CompositorService", "Failed to save display scales:", error);
    }
}

function getFocusedScreen(root) {
    if (root.backend && root.backend.getFocusedScreen) {
      return root.backend.getFocusedScreen();
    }
    return null;
}

function switchToWorkspace(workspace, root, Logger) {
    if (root.backend && root.backend.switchToWorkspace) {
      root.backend.switchToWorkspace(workspace);
    } else {
      Logger.w("Compositor", "No backend available for workspace switching");
    }
}

function scrollWorkspaceContent(direction, root) {
    if (root.backend && root.backend.scrollWorkspaceContent) {
      root.backend.scrollWorkspaceContent(direction);
    }
}

function focusWindow(window, root, Logger) {
    if (root.backend && root.backend.focusWindow) {
      root.backend.focusWindow(window);
    } else {
      Logger.w("Compositor", "No backend available for window focus");
    }
}

function closeWindow(window, root, Logger) {
    if (root.backend && root.backend.closeWindow) {
      root.backend.closeWindow(window);
    } else {
      Logger.w("Compositor", "No backend available for window closing");
    }
}

function spawn(command, root, Logger, Quickshell) {
    // Ensure command is a proper JS array (QML lists can behave unexpectedly in some contexts)
    const cmdArray = Array.isArray(command) ? command : (command && typeof command === "object" && command.length !== undefined) ? Array.from(command) : [command];

    Logger.d("CompositorService", `Spawning: ${cmdArray.join(" ")}`);
    if (root.backend && root.backend.spawn) {
      root.backend.spawn(cmdArray);
    } else {
      try {
        Quickshell.execDetached(cmdArray);
      } catch (e) {
        Logger.e("CompositorService", "Failed to execute detached:", e);
      }
    }
}

function getCustomCommand(action, root, Settings) {
    const powerOptions = Settings.data.sessionMenu.powerOptions || [];
    for (let i = 0; i < powerOptions.length; i++) {
      const option = powerOptions[i];
      if (option.action === action && option.enabled && option.command && option.command.trim() !== "") {
        return option.command.trim();
      }
    }
    return "";
}

function turnOffMonitors(root, Logger, Quickshell) {
    Logger.i("Compositor", "Turn off monitors requested");
    if (root.backend && root.backend.turnOffMonitors) {
      root.backend.turnOffMonitors();
    } else {
      // Windows: broadcast WM_SYSCOMMAND / SC_MONITORPOWER (0xF170) = 2 (power off). Any mouse or
      // key input turns the displays back on, so turnOnMonitors() has nothing to do.
      // The script is user32 SendMessage(HWND_BROADCAST, 0x0112, 0xF170, 2), UTF-16LE base64.
      Quickshell.execDetached(["powershell.exe", "-NoProfile", "-NonInteractive", "-WindowStyle", "Hidden", "-EncodedCommand", "QQBkAGQALQBUAHkAcABlACAALQBOAGEAbQBlACAAVwAgAC0ATgBhAG0AZQBzAHAAYQBjAGUAIABOACAALQBNAGUAbQBiAGUAcgBEAGUAZgBpAG4AaQB0AGkAbwBuACAAJwBbAEQAbABsAEkAbQBwAG8AcgB0ACgAIgB1AHMAZQByADMAMgAuAGQAbABsACIAKQBdACAAcAB1AGIAbABpAGMAIABzAHQAYQB0AGkAYwAgAGUAeAB0AGUAcgBuACAASQBuAHQAUAB0AHIAIABTAGUAbgBkAE0AZQBzAHMAYQBnAGUAKABJAG4AdABQAHQAcgAgAGgALAAgAGkAbgB0ACAAbQAsACAASQBuAHQAUAB0AHIAIAB3ACwAIABJAG4AdABQAHQAcgAgAGwAKQA7ACcAOwAgAFsAdgBvAGkAZABdAFsATgAuAFcAXQA6ADoAUwBlAG4AZABNAGUAcwBzAGEAZwBlACgAWwBJAG4AdABQAHQAcgBdADAAeABGAEYARgBGACwAIAAwAHgAMAAxADEAMgAsACAAWwBJAG4AdABQAHQAcgBdADAAeABGADEANwAwACwAIABbAEkAbgB0AFAAdAByAF0AMgApAA=="]);
    }
}

function turnOnMonitors(root, Logger) {
    Logger.i("Compositor", "Turn on monitors requested");
    if (root.backend && root.backend.turnOnMonitors) {
      root.backend.turnOnMonitors();
    } else {
      Logger.w("Compositor", "No backend available for turnOnMonitors");
    }
}

function cycleKeyboardLayout(root) {
    if (root.backend && root.backend.cycleKeyboardLayout) {
      root.backend.cycleKeyboardLayout();
    }
}

function setScrollCommand(item) {
  item.msgCommand = "scrollmsg";
}

function getFocusedWindowTitle(root) {
  var title;
  if (root.focusedWindowIndex >= 0 && root.focusedWindowIndex < root.windows.count) {
    title = root.windows.get(root.focusedWindowIndex).title;
    if (title !== undefined)
      title = title.replace(/(\r\n|\n|\r)/g, "");
    return title || "";
  }
  return "";
}

function getFocusedWindow(root) {
  if (root.focusedWindowIndex >= 0 && root.focusedWindowIndex < root.windows.count)
    return root.windows.get(root.focusedWindowIndex);
  return null;
}

function getCurrentWorkspace(root) {
  for (var i = 0; i < root.workspaces.count; i++) {
    var ws = root.workspaces.get(i);
    if (ws.isFocused)
      return ws;
  }
  return null;
}

function getWindowsForWorkspace(root, workspaceId) {
  var windows = [];
  for (var i = 0; i < root.windows.count; i++) {
    var window = root.windows.get(i);
    if (window.workspaceId === workspaceId) {
      windows.push({ id: window.id, title: window.title, appId: window.appId,
                     isFocused: window.isFocused, workspaceId: window.workspaceId, handle: window.handle });
    }
  }
  return windows;
}

function getActiveWorkspaces(root) {
  var active = [];
  for (var i = 0; i < root.workspaces.count; i++) {
    var ws = root.workspaces.get(i);
    if (ws.isActive)
      active.push(ws);
  }
  return active;
}
