pragma Singleton

import "CompositorServiceUtils.js" as CompositorServiceUtils

import QtQuick 6.10
import Quickshell
import waku.services as S
import qs.Commons
import qs.Services.Control

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
        root.loadDisplayScalesFromState();
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
        if (root.isScroll) {
          CompositorServiceUtils.setScrollCommand(item);
        }
        root.backend = item;
        root.setupBackendConnections();
        root.backend.initialize();
      }
    }
  }

  // Load display scales from ShellState
  function loadDisplayScalesFromState(): void {
    CompositorServiceUtils.loadDisplayScalesFromState(root, ShellState, Logger);
  }

  // waku backend component
  Component {
    id: wakuComponent
    WakuService {
      id: wakuBackend
    }
  }

  function setupBackendConnections(): void {
    CompositorServiceUtils.setupBackendConnections(root);
  }

  function syncWorkspaces(): void {
    CompositorServiceUtils.syncWorkspaces(root);
  }

  function syncWindows(): void {
    CompositorServiceUtils.syncWindows(root);
  }

  // Sync only the focused window state, not the entire window list
  function syncFocusedWindow(): void {
    CompositorServiceUtils.syncFocusedWindow(root);
  }

  // Update display scales from backend
  function updateDisplayScales(): void {
    CompositorServiceUtils.updateDisplayScales(root, Logger);
  }

  // Called by backend when display scales are ready
  function onDisplayScalesUpdated(scales: var): void {
    displayScales = scales;
    saveDisplayScalesToCache();
    Logger.d("CompositorService", "Display scales updated");
  }

  // Save display scales to cache
  function saveDisplayScalesToCache(): void {
    CompositorServiceUtils.saveDisplayScalesToCache(root, ShellState, Logger);
  }

  // Public function to get scale for a specific display
  function getDisplayScale(displayName: var): var {
    if (!displayName || !displayScales[displayName]) {
      return 1.0;
    }
    return displayScales[displayName].scale || 1.0;
  }

  // Public function to get all display info for a specific display
  function getDisplayInfo(displayName: var): var {
    if (!displayName || !displayScales[displayName]) {
      return null;
    }
    return displayScales[displayName];
  }

  // Get focused window
  function getFocusedWindow(): var {
    return CompositorServiceUtils.getFocusedWindow(root);
  }

  // Get focused screen from compositor
  function getFocusedScreen(): var {
    return CompositorServiceUtils.getFocusedScreen(root);
  }

  // Get focused window title
  function getFocusedWindowTitle(): string {
    return CompositorServiceUtils.getFocusedWindowTitle(root);
  }

  // Get clean app name from appId
  // Extracts the last segment from reverse domain notation (e.g., "org.kde.dolphin" -> "Dolphin")
  // Falls back to title if appId is empty
  function getCleanAppName(appId: var, fallbackTitle: var): string {
    var name = (appId || "").split(".").pop() || fallbackTitle || "Unknown";
    return name.charAt(0).toUpperCase() + name.slice(1);
  }

  function getWindowsForWorkspace(workspaceId: var): var {
    return CompositorServiceUtils.getWindowsForWorkspace(root, workspaceId);
  }

  // Generic workspace switching
  function switchToWorkspace(workspace: var): void {
    CompositorServiceUtils.switchToWorkspace(workspace, root, Logger);
  }

  // Scrollable workspace content (Niri)
  function scrollWorkspaceContent(direction: var): void {
    CompositorServiceUtils.scrollWorkspaceContent(direction, root);
  }

  // Get current workspace
  function getCurrentWorkspace(): var {
    return CompositorServiceUtils.getCurrentWorkspace(root);
  }

  // Get active workspaces
  function getActiveWorkspaces(): var {
    return CompositorServiceUtils.getActiveWorkspaces(root);
  }

  // Set focused window
  function focusWindow(window: var): void {
    CompositorServiceUtils.focusWindow(window, root, Logger);
  }

  // Close window
  function closeWindow(window: var): void {
    CompositorServiceUtils.closeWindow(window, root, Logger);
  }

  // Spawn command
  function spawn(command: var): void {
    CompositorServiceUtils.spawn(command, root, Logger, Quickshell);
  }

  // Session management helper for custom commands
  function getCustomCommand(action: var): var {
    return CompositorServiceUtils.getCustomCommand(action, root, Settings);
  }

  function executeSessionAction(action: var, defaultCommand: var): bool {
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
  function windowsSession(id: var): void {
    if (!S.ControlCenter.requestAction(id))
      S.ControlCenter.requestAction(id);
  }

  // Session management
  function logout() {
    Logger.i("Compositor", "Logout requested");
    if (executeSessionAction("logout", undefined))
      return;

    windowsSession("signOut");
  }

  function shutdown() {
    Logger.i("Compositor", "Shutdown requested");
    if (executeSessionAction("shutdown", undefined))
      return;

    HooksService.executeSessionHook("shutdown", () => {
                                      root.windowsSession("shutdown");
                                    });
  }

  function reboot() {
    Logger.i("Compositor", "Reboot requested");
    if (executeSessionAction("reboot", undefined))
      return;

    HooksService.executeSessionHook("reboot", () => {
                                      root.windowsSession("restart");
                                    });
  }

  function userspaceReboot() {
    Logger.i("Compositor", "Userspace reboot requested");
    if (executeSessionAction("userspaceReboot", undefined))
      return;

    HooksService.executeSessionHook("userspaceReboot", () => {
                                      root.windowsSession("restart");
                                    });
  }

  function rebootToUefi() {
    Logger.i("Compositor", "Reboot to UEFI firmware requested requested");
    if (executeSessionAction("rebootToUefi", undefined))
      return;

    HooksService.executeSessionHook("rebootToUefi", () => {
                                      Quickshell.execDetached(["shutdown", "/r", "/fw", "/t", "0"]);
                                    });
  }

  function turnOffMonitors() {
    CompositorServiceUtils.turnOffMonitors(root, Logger, Quickshell);
  }

  function turnOnMonitors() {
    CompositorServiceUtils.turnOnMonitors(root, Logger);
  }

  function suspend() {
    Logger.i("Compositor", "Suspend requested");
    if (executeSessionAction("suspend", undefined))
      return;

    windowsSession("sleep");
  }

  function lock() {
    Logger.i("Compositor", "LockScreen requested");
    if (executeSessionAction("lock", undefined))
      return;

    windowsSession("lock");
  }

  function hibernate() {
    Logger.i("Compositor", "Hibernate requested");
    if (executeSessionAction("hibernate", undefined))
      return;

    windowsSession("hibernate");
  }

  function cycleKeyboardLayout() {
    CompositorServiceUtils.cycleKeyboardLayout(root);
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
      root.suspend();
    }
  }
}
