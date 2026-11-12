import "WakuServiceUtils.js" as WakuServiceUtils

import QtQuick 6.10
import Quickshell
import Quickshell.Wayland
import waku.services as S
import qs.Commons

// Compositor backend for waku: the Windows virtual desktops through the engine's `Workspaces`,
// windows through `ToplevelManager`. Same contract as the Wayland backends this replaces.
//
// A window belongs to the desktop whose `windows` lists its handle. A window no desktop lists is
// reported on the focused desktop of the first monitor.
Item {
  id: root

  property ListModel workspaces: ListModel {}
  property var windows: []
  property int focusedWindowIndex: -1
  // Virtual desktops belong to no monitor (the engine reports one entry without a name), so every
  // bar shows all of them.
  property bool globalWorkspaces: true

  signal workspaceChanged
  signal activeWindowChanged
  signal windowListChanged
  signal displayScalesChanged

  function initialize() {
    syncWorkspaces();
    syncWindows();
    Logger.i("WakuService", "Service started (" + (S.Workspaces.provider || "no virtual desktops") + ")");
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
  function screenNameFor(monitorName: var): string {
    return WakuServiceUtils.screenNameFor(monitorName, Quickshell.screens);
  }

  function syncWorkspaces(): void {
    WakuServiceUtils.syncWorkspaces(root, S.Workspaces);
  }

  function focusedWorkspaceId(): var {
    return WakuServiceUtils.focusedWorkspaceId(workspaces);
  }

  function syncWindows(): void {
    WakuServiceUtils.syncWindows(root, S.Workspaces, ToplevelManager);
  }

  function focusWindow(window: var): void {
    WakuServiceUtils.focusWindow(window);
  }

  function closeWindow(window: var): void {
    WakuServiceUtils.closeWindow(window);
  }

  function switchToWorkspace(workspace: var): void {
    if (!workspace)
      return;
    S.Workspaces.focus(0, String(WakuServiceUtils.workspaceOid(workspace)));
  }

  function cycleKeyboardLayout() {
    Logger.w("WakuService", "Keyboard layout cycling not supported");
  }

  function queryDisplayScales() {
  }

  function getFocusedScreen(): var {
    return null;
  }
}
