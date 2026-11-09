pragma Singleton

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import waku.services as S
import qs.Commons
import qs.Services.Control
import qs.Services.UI
import qs.compat

Singleton {
  id: root

  // Compositor detection
  property bool isHyprland: false
  property bool isNiri: false
  property bool isSway: false
  property bool isMango: false
  property bool isLabwc: false
  property bool isExtWorkspace: false
  property bool isScroll: false

  // Generic workspace and window data
  property ListModel workspaces: ListModel {}
  property ListModel windows: ListModel {}
  property int focusedWindowIndex: -1

  // Display scale data
  property var displayScales: ({})
  property bool displayScalesLoaded: false

  // Overview state (Niri-specific, defaults to false for other compositors)
  property bool overviewActive: false

  // Global workspaces flag (workspaces shared across all outputs)
  // True for LabWC (stacking compositor), false for tiling WMs with per-output workspaces
  property bool globalWorkspaces: false

  // Generic events
  signal workspaceChanged
  signal activeWindowChanged
  signal windowListChanged

  // Backend service loader
  property var backend: null

  Component.onCompleted: {
    // Load display scales from ShellState
    Qt.callLater(() => {
                   if (typeof ShellState !== 'undefined' && ShellState.isLoaded) {
                     loadDisplayScalesFromState();
                   }
                 });

    detectCompositor();
  }

  Connections {
    target: typeof ShellState !== 'undefined' ? ShellState : null
    function onIsLoadedChanged() {
      if (ShellState.isLoaded) {
        loadDisplayScalesFromState();
      }
    }
  }

  function detectCompositor() {
    isHyprland = false;
    isNiri = false;
    isSway = false;
    isMango = false;
    isLabwc = false;
    isExtWorkspace = false;
    backendLoader.sourceComponent = wakuComponent;
  }

  Loader {
    id: backendLoader
    onLoaded: {
      if (item) {
        if (isScroll) {
          item.msgCommand = "scrollmsg";
        }
        root.backend = item;
        setupBackendConnections();
        backend.initialize();
      }
    }
  }

  // Load display scales from ShellState
  function loadDisplayScalesFromState() {
    try {
      const cached = ShellState.getDisplay();
      if (cached && Object.keys(cached).length > 0) {
        displayScales = cached;
        displayScalesLoaded = true;
        Logger.d("CompositorService", "Loaded display scales from ShellState");
      } else {
        // Migration is now handled in Settings.qml
        displayScalesLoaded = true;
      }
    } catch (error) {
      Logger.e("CompositorService", "Failed to load display scales:", error);
      displayScalesLoaded = true;
    }
  }

  // waku backend component
  Component {
    id: wakuComponent
    WakuService {
      id: wakuBackend
    }
  }

  function setupBackendConnections() {
    if (!backend)
      return;

    // Connect backend signals to facade signals
    backend.workspaceChanged.connect(() => {
                                       // Sync workspaces when they change
                                       syncWorkspaces();
                                       // Forward the signal
                                       workspaceChanged();
                                     });

    backend.activeWindowChanged.connect(() => {
                                          // Only sync focus state, not entire window list
                                          syncFocusedWindow();
                                          // Forward the signal
                                          activeWindowChanged();
                                        });

    backend.windowListChanged.connect(() => {
                                        syncWindows();
                                      });

    // Property bindings - use automatic property change signal
    backend.focusedWindowIndexChanged.connect(() => {
                                                focusedWindowIndex = backend.focusedWindowIndex;
                                              });

    // Overview state (Niri-specific)
    if (backend.overviewActiveChanged) {
      backend.overviewActiveChanged.connect(() => {
                                              overviewActive = backend.overviewActive;
                                            });
    }

    // Initial sync
    syncWorkspaces();
    syncWindows();
    focusedWindowIndex = backend.focusedWindowIndex;
    if (backend.overviewActive !== undefined) {
      overviewActive = backend.overviewActive;
    }
    if (backend.globalWorkspaces !== undefined) {
      globalWorkspaces = backend.globalWorkspaces;
    }
  }

  function syncWorkspaces() {
    workspaces.clear();
    const ws = backend.workspaces;
    for (var i = 0; i < ws.count; i++) {
      workspaces.append(ws.get(i));
    }
    // Emit signal to notify listeners that workspace list has been updated
    workspacesChanged();
  }

  function syncWindows() {
    windows.clear();
    const ws = backend.windows;
    for (var i = 0; i < ws.length; i++) {
      windows.append(ws[i]);
    }
    // Emit signal to notify listeners that window list has been updated
    windowListChanged();
  }

  // Sync only the focused window state, not the entire window list
  function syncFocusedWindow() {
    const newIndex = backend.focusedWindowIndex;

    // Update isFocused flags by syncing from backend
    for (var i = 0; i < windows.count && i < backend.windows.length; i++) {
      const backendFocused = backend.windows[i].isFocused;
      if (windows.get(i).isFocused !== backendFocused) {
        windows.setProperty(i, "isFocused", backendFocused);
      }
    }

    focusedWindowIndex = newIndex;
  }

  // Update display scales from backend
  function updateDisplayScales() {
    if (!backend || !backend.queryDisplayScales) {
      Logger.w("CompositorService", "Backend does not support display scale queries");
      return;
    }

    backend.queryDisplayScales();
  }

  // Called by backend when display scales are ready
  function onDisplayScalesUpdated(scales) {
    displayScales = scales;
    saveDisplayScalesToCache();
    Logger.d("CompositorService", "Display scales updated");
  }

  // Save display scales to cache
  function saveDisplayScalesToCache() {
    try {
      ShellState.setDisplay(displayScales);
      Logger.d("CompositorService", "Saved display scales to ShellState");
    } catch (error) {
      Logger.e("CompositorService", "Failed to save display scales:", error);
    }
  }

  // Public function to get scale for a specific display
  function getDisplayScale(displayName) {
    if (!displayName || !displayScales[displayName]) {
      return 1.0;
    }
    return displayScales[displayName].scale || 1.0;
  }

  // Public function to get all display info for a specific display
  function getDisplayInfo(displayName) {
    if (!displayName || !displayScales[displayName]) {
      return null;
    }
    return displayScales[displayName];
  }

  // Get focused window
  function getFocusedWindow() {
    if (focusedWindowIndex >= 0 && focusedWindowIndex < windows.count) {
      return windows.get(focusedWindowIndex);
    }
    return null;
  }

  // Get focused screen from compositor
  function getFocusedScreen() {
    if (backend && backend.getFocusedScreen) {
      return backend.getFocusedScreen();
    }
    return null;
  }

  // Get focused window title
  function getFocusedWindowTitle() {
    if (focusedWindowIndex >= 0 && focusedWindowIndex < windows.count) {
      var title = windows.get(focusedWindowIndex).title;
      if (title !== undefined) {
        title = title.replace(/(\r\n|\n|\r)/g, "");
      }
      return title || "";
    }
    return "";
  }

  // Get clean app name from appId
  // Extracts the last segment from reverse domain notation (e.g., "org.kde.dolphin" -> "Dolphin")
  // Falls back to title if appId is empty
  function getCleanAppName(appId, fallbackTitle) {
    var name = (appId || "").split(".").pop() || fallbackTitle || "Unknown";
    return name.charAt(0).toUpperCase() + name.slice(1);
  }

  function getWindowsForWorkspace(workspaceId) {
    var windowsInWs = [];
    for (var i = 0; i < windows.count; i++) {
      var window = windows.get(i);
      if (window.workspaceId === workspaceId) {
        // Snapshot to plain JS object so callers never hold live ListModel
        // proxies that become invalid when syncWindows() clears the model.
        windowsInWs.push({
                           id: window.id,
                           title: window.title,
                           appId: window.appId,
                           isFocused: window.isFocused,
                           workspaceId: window.workspaceId,
                           handle: window.handle
                         });
      }
    }
    return windowsInWs;
  }

  // Generic workspace switching
  function switchToWorkspace(workspace) {
    if (backend && backend.switchToWorkspace) {
      backend.switchToWorkspace(workspace);
    } else {
      Logger.w("Compositor", "No backend available for workspace switching");
    }
  }

  // Scrollable workspace content (Niri)
  function scrollWorkspaceContent(direction) {
    if (backend && backend.scrollWorkspaceContent) {
      backend.scrollWorkspaceContent(direction);
    }
  }

  // Get current workspace
  function getCurrentWorkspace() {
    for (var i = 0; i < workspaces.count; i++) {
      const ws = workspaces.get(i);
      if (ws.isFocused) {
        return ws;
      }
    }
    return null;
  }

  // Get active workspaces
  function getActiveWorkspaces() {
    const activeWorkspaces = [];
    for (var i = 0; i < workspaces.count; i++) {
      const ws = workspaces.get(i);
      if (ws.isActive) {
        activeWorkspaces.push(ws);
      }
    }
    return activeWorkspaces;
  }

  // Set focused window
  function focusWindow(window) {
    if (backend && backend.focusWindow) {
      backend.focusWindow(window);
    } else {
      Logger.w("Compositor", "No backend available for window focus");
    }
  }

  // Close window
  function closeWindow(window) {
    if (backend && backend.closeWindow) {
      backend.closeWindow(window);
    } else {
      Logger.w("Compositor", "No backend available for window closing");
    }
  }

  // Spawn command
  function spawn(command) {
    // Ensure command is a proper JS array (QML lists can behave unexpectedly in some contexts)
    const cmdArray = Array.isArray(command) ? command : (command && typeof command === "object" && command.length !== undefined) ? Array.from(command) : [command];

    Logger.d("CompositorService", `Spawning: ${cmdArray.join(" ")}`);
    if (backend && backend.spawn) {
      backend.spawn(cmdArray);
    } else {
      try {
        Quickshell.execDetached(cmdArray);
      } catch (e) {
        Logger.e("CompositorService", "Failed to execute detached:", e);
      }
    }
  }

  // Session management helper for custom commands
  function getCustomCommand(action) {
    const powerOptions = Settings.data.sessionMenu.powerOptions || [];
    for (let i = 0; i < powerOptions.length; i++) {
      const option = powerOptions[i];
      if (option.action === action && option.enabled && option.command && option.command.trim() !== "") {
        return option.command.trim();
      }
    }
    return "";
  }

  function executeSessionAction(action, defaultCommand) {
    const customCommand = getCustomCommand(action);
    if (customCommand) {
      Logger.i("Compositor", `Executing custom command for action: ${action} Command: ${customCommand}`);
      Quickshell.execDetached(["cmd", "/c", customCommand]);
      return true;
    }
    return false;
  }

  // Session management, through the engine's ControlCenter: lock, sleep, hibernate, signOut, restart and
  // shutdown. The engine asks for a second request of the same id before it runs a dangerous one;
  // Octalia's session menu has its own confirmation, so the request is repeated here.
  function windowsSession(id) {
    if (!S.ControlCenter.requestAction(id))
      S.ControlCenter.requestAction(id);
  }

  // Session management
  function logout() {
    Logger.i("Compositor", "Logout requested");
    if (executeSessionAction("logout"))
      return;

    windowsSession("signOut");
  }

  function shutdown() {
    Logger.i("Compositor", "Shutdown requested");
    if (executeSessionAction("shutdown"))
      return;

    HooksService.executeSessionHook("shutdown", () => {
                                      root.windowsSession("shutdown");
                                    });
  }

  function reboot() {
    Logger.i("Compositor", "Reboot requested");
    if (executeSessionAction("reboot"))
      return;

    HooksService.executeSessionHook("reboot", () => {
                                      root.windowsSession("restart");
                                    });
  }

  function userspaceReboot() {
    Logger.i("Compositor", "Userspace reboot requested");
    if (executeSessionAction("userspaceReboot"))
      return;

    HooksService.executeSessionHook("userspaceReboot", () => {
                                      root.windowsSession("restart");
                                    });
  }

  function rebootToUefi() {
    Logger.i("Compositor", "Reboot to UEFI firmware requested requested");
    if (executeSessionAction("rebootToUefi"))
      return;

    HooksService.executeSessionHook("rebootToUefi", () => {
                                      Quickshell.execDetached(["shutdown", "/r", "/fw", "/t", "0"]);
                                    });
  }

  function turnOffMonitors() {
    Logger.i("Compositor", "Turn off monitors requested");
    if (backend && backend.turnOffMonitors) {
      backend.turnOffMonitors();
    } else {
      // Windows: broadcast WM_SYSCOMMAND / SC_MONITORPOWER (0xF170) = 2 (power off). Any mouse or
      // key input turns the displays back on, so turnOnMonitors() has nothing to do.
      // The script is user32 SendMessage(HWND_BROADCAST, 0x0112, 0xF170, 2), UTF-16LE base64.
      Quickshell.execDetached(["powershell.exe", "-NoProfile", "-NonInteractive", "-WindowStyle", "Hidden", "-EncodedCommand", "QQBkAGQALQBUAHkAcABlACAALQBOAGEAbQBlACAAVwAgAC0ATgBhAG0AZQBzAHAAYQBjAGUAIABOACAALQBNAGUAbQBiAGUAcgBEAGUAZgBpAG4AaQB0AGkAbwBuACAAJwBbAEQAbABsAEkAbQBwAG8AcgB0ACgAIgB1AHMAZQByADMAMgAuAGQAbABsACIAKQBdACAAcAB1AGIAbABpAGMAIABzAHQAYQB0AGkAYwAgAGUAeAB0AGUAcgBuACAASQBuAHQAUAB0AHIAIABTAGUAbgBkAE0AZQBzAHMAYQBnAGUAKABJAG4AdABQAHQAcgAgAGgALAAgAGkAbgB0ACAAbQAsACAASQBuAHQAUAB0AHIAIAB3ACwAIABJAG4AdABQAHQAcgAgAGwAKQA7ACcAOwAgAFsAdgBvAGkAZABdAFsATgAuAFcAXQA6ADoAUwBlAG4AZABNAGUAcwBzAGEAZwBlACgAWwBJAG4AdABQAHQAcgBdADAAeABGAEYARgBGACwAIAAwAHgAMAAxADEAMgAsACAAWwBJAG4AdABQAHQAcgBdADAAeABGADEANwAwACwAIABbAEkAbgB0AFAAdAByAF0AMgApAA=="]);
    }
  }

  function turnOnMonitors() {
    Logger.i("Compositor", "Turn on monitors requested");
    if (backend && backend.turnOnMonitors) {
      backend.turnOnMonitors();
    } else {
      Logger.w("Compositor", "No backend available for turnOnMonitors");
    }
  }

  function suspend() {
    Logger.i("Compositor", "Suspend requested");
    if (executeSessionAction("suspend"))
      return;

    windowsSession("sleep");
  }

  function lock() {
    Logger.i("Compositor", "LockScreen requested");
    if (executeSessionAction("lock"))
      return;

    windowsSession("lock");
  }

  function hibernate() {
    Logger.i("Compositor", "Hibernate requested");
    if (executeSessionAction("hibernate"))
      return;

    windowsSession("hibernate");
  }

  function cycleKeyboardLayout() {
    if (backend && backend.cycleKeyboardLayout) {
      backend.cycleKeyboardLayout();
    }
  }

  // Windows has no Octalia lock screen: lock the workstation through the engine, then sleep.
  function lockAndSuspend() {
    Logger.i("Compositor", "Lock and suspend requested");
    lock();
    lockAndSuspendTimer.restart();
  }

  Timer {
    id: lockAndSuspendTimer
    interval: 1500
    repeat: false
    running: false
    onTriggered: {
      // A custom sleep command is honoured by suspend()
      suspend();
    }
  }
}
