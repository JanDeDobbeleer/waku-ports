pragma Singleton

import "PanelServiceUtils.js" as PanelUtils

import QtQuick 6.10
import Quickshell
import qs.Commons
import qs.Services.Compositor
import "../../Modules/Bar/Extras/TrayMenuHelpers.js" as TrayMenuHelpers

Singleton {
  id: root

  // A ref. to the lockScreen, so it's accessible from anywhere.
  property var lockScreen: null

  // Panels
  property var registeredPanels: ({})
  property var openedPanel: null
  property var closingPanel: null
  property bool closedImmediately: false

  // Overlay launcher state (separate from normal panels)
  property bool overlayLauncherOpen: false
  property var overlayLauncherScreen: null
  property var overlayLauncherCore: null  // Reference to LauncherCore when overlay is active
  // Brief window after panel opens where Exclusive keyboard is allowed on Hyprland
  // This allows text inputs to receive focus, then switches to OnDemand for click-to-close
  property bool isInitializingKeyboard: false

  // Global state for keybind recording components to block global shortcuts
  property bool isKeybindRecording: false

  signal willOpen
  signal didClose

  // Background slot assignments for dynamic panel background rendering
  // Slot 0: currently opening/open panel, Slot 1: closing panel
  property var backgroundSlotAssignments: [null, null]
  signal slotAssignmentChanged(int slotIndex, var panel)

  function assignToSlot(slotIndex: var, panel: var): void {
    var newAssignments;
    if (backgroundSlotAssignments[slotIndex] !== panel) {
      newAssignments = backgroundSlotAssignments.slice();
      newAssignments[slotIndex] = panel;
      backgroundSlotAssignments = newAssignments;
      slotAssignmentChanged(slotIndex, panel);
    }
  }

  // Popup menu windows (one per screen) - used for both tray menus and context menus
  property var popupMenuWindows: ({})
  signal popupMenuWindowRegistered(var screen)

  // Register this panel (called after panel is loaded)
  function registerPanel(panel: var): void {
    PanelUtils.registerPanel(panel, root, Logger);
  }

  // Register popup menu window for a screen
  function registerPopupMenuWindow(screen: var, window: var): void {
    PanelUtils.registerPopupMenuWindow(screen, window, root, Logger);
  }

  // Unregister popup menu window for a screen (called on destruction)
  function unregisterPopupMenuWindow(screen: var): void {
    PanelUtils.unregisterPopupMenuWindow(screen, root, Logger);
  }

  // Get popup menu window for a screen
  function getPopupMenuWindow(screen: var): var {
    return PanelUtils.getPopupMenuWindow(screen, root);
  }

  // Show a context menu with proper handling for all compositors
  // Optional targetItem: if provided, menu will be horizontally centered on this item instead of anchorItem
  function showContextMenu(contextMenu: var, anchorItem: var, screen: var, targetItem: var): void {
    if (!contextMenu || !anchorItem)
      return;

    // Close any previously opened context menu first
    closeContextMenu(screen);

    var popupMenuWindow = getPopupMenuWindow(screen);
    if (popupMenuWindow) {
      popupMenuWindow.showContextMenu(contextMenu);
      contextMenu.openAtItem(anchorItem, screen, targetItem);
    }
  }

  // Close any open context menu or popup menu window
  function closeContextMenu(screen: var): void {
    PanelUtils.closeContextMenu(screen, root);
  }

  // Show a tray menu with proper handling for all compositors
  // Returns true if menu was shown successfully
  function showTrayMenu(screen: var, trayItem: var, trayMenu: var, anchorItem: var, menuX: var, menuY: var, widgetSection: var, widgetIndex: var): bool {
    return PanelUtils.showTrayMenu(screen, trayItem, trayMenu, anchorItem, menuX, menuY, widgetSection, widgetIndex, root, TrayMenuHelpers);
  }

  // Close tray menu
  function closeTrayMenu(screen: var): void {
    var popupMenuWindow = getPopupMenuWindow(screen);
    if (popupMenuWindow) {
      // This closes both the window and calls hideMenu on the tray menu
      popupMenuWindow.close();
    }
  }

  // Find a fallback screen, prioritizing 0x0 position (primary)
  function findFallbackScreen(): ShellScreen {
    return PanelUtils.findFallbackScreen(root, Quickshell);
  }

  // Returns a panel (loads it on-demand if not yet loaded)
  // By default, if panel not found on screen, tries other screens (favoring 0x0)
  // Pass fallback=false to disable this behavior
  function getPanel(name: var, screen: var): var {
    return PanelUtils.getPanel(name, screen, undefined, root, Logger);
  }

  function getPanelWithFallback(name: var, screen: var, fallback: var): var {
    return PanelUtils.getPanel(name, screen, fallback, root, Logger);
  }

  function invokePanel(panel: var, method: string, args: var): void {
    PanelUtils.invokePanel(panel, method, args);
  }

  function setPanelProperties(panel: var, properties: var): void {
    PanelUtils.setPanelProperties(panel, properties);
  }

  function isPanelVisible(panel: var): bool {
    return PanelUtils.isPanelVisible(panel);
  }

  function openSettingsPanel(panel: var, tab: int): void {
    PanelUtils.openSettingsPanel(panel, tab);
  }

  // Check if a panel exists
  function hasPanel(name: var): bool {
    return name in registeredPanels;
  }

  // Check if panels can be shown on a given screen (has bar enabled or allowPanelsOnScreenWithoutBar)
  function canShowPanelsOnScreen(screen: var): var {
    return PanelUtils.canShowPanelsOnScreen(screen, root, Settings);
  }

  // Find a screen that can show panels
  function findScreenForPanels(): ShellScreen {
    return PanelUtils.findScreenForPanels(root, Quickshell);
  }

  // Timer to switch from Exclusive to OnDemand keyboard focus on Hyprland
  Timer {
    id: keyboardInitTimer
    interval: 100
    repeat: false
    onTriggered: {
      root.isInitializingKeyboard = false;
    }
  }

  // Helper to keep only one panel open at any time
  function willOpenPanel(panel: var): void {
    PanelUtils.willOpenPanel(panel, root, keyboardInitTimer);
  }

  // Open launcher panel (handles both normal and overlay mode)
  function openLauncher(screen: var): void {
    var panel;
    if (Settings.data.appLauncher.overviewLayer) {
      // Close any regular panel first
      if (openedPanel) {
        closingPanel = openedPanel;
        assignToSlot(1, closingPanel);
        openedPanel.close();
        openedPanel = null;
      }
      // Open overlay launcher
      overlayLauncherOpen = true;
      overlayLauncherScreen = screen;
      willOpen();
    } else {
      // Normal mode - use the SmartPanel
      panel = getPanel("launcherPanel", screen);
      if (panel)
        panel.open();
    }
  }

  // Toggle launcher panel
  function toggleLauncher(screen: var): void {
    var panel;
    if (Settings.data.appLauncher.overviewLayer) {
      if (overlayLauncherOpen && overlayLauncherScreen === screen) {
        closeOverlayLauncher();
      } else {
        openLauncher(screen);
      }
    } else {
      panel = getPanel("launcherPanel", screen);
      if (panel)
        panel.toggle();
    }
  }

  // Close overlay launcher
  function closeOverlayLauncher() {
    if (overlayLauncherOpen) {
      overlayLauncherOpen = false;
      overlayLauncherScreen = null;
      didClose();
    }
  }

  // Close overlay launcher immediately (for app launches)
  function closeOverlayLauncherImmediately() {
    if (overlayLauncherOpen) {
      closedImmediately = true;
      overlayLauncherOpen = false;
      overlayLauncherScreen = null;
      didClose();
    }
  }

  // ==================== Unified Launcher API ====================
  // These methods work for both normal (SmartPanel) and overlay modes

  function isLauncherOpen(screen: var): var {
    var panel;
    if (Settings.data.appLauncher.overviewLayer) {
      return overlayLauncherOpen && overlayLauncherScreen === screen;
    } else {
      panel = getPanel("launcherPanel", screen);
      return PanelUtils.isPanelOpen(panel);
    }
  }

  function getLauncherSearchText(screen: var): var {
    return PanelUtils.getLauncherSearchText(screen, root, Settings);
  }

  function setLauncherSearchText(screen: var, text: var): void {
    var panel;
    if (Settings.data.appLauncher.overviewLayer) {
      if (overlayLauncherCore)
        overlayLauncherCore.setSearchText(text);
    } else {
      panel = getPanel("launcherPanel", screen);
      if (panel)
        panel.setSearchText(text);
    }
  }

  function openLauncherWithSearch(screen: var, searchText: var): void {
    var panel;
    if (Settings.data.appLauncher.overviewLayer) {
      openLauncher(screen);
      // Set search text after core is ready
      Qt.callLater(() => {
                     if (overlayLauncherCore)
                     overlayLauncherCore.setSearchText(searchText);
                   });
    } else {
      panel = getPanel("launcherPanel", screen);
      if (panel) {
        panel.open();
        panel.setSearchText(searchText);
      }
    }
  }

  function closeLauncher(screen: var): void {
    var panel;
    if (Settings.data.appLauncher.overviewLayer) {
      closeOverlayLauncher();
    } else {
      panel = getPanel("launcherPanel", screen);
      if (panel)
        panel.close();
    }
  }

  // Close any open panel (for general use)
  function closePanel() {
    PanelUtils.closePanel(root);
  }

  function closedPanel(panel: var): void {
    if (openedPanel && openedPanel === panel) {
      openedPanel = null;
      assignToSlot(0, null);
    }

    if (closingPanel && closingPanel === panel) {
      closingPanel = null;
      assignToSlot(1, null);
    }

    // Reset keyboard init state
    isInitializingKeyboard = false;
    keyboardInitTimer.stop();

    // emit signal
    didClose();
  }

  // Close panels when compositor overview opens (if setting is enabled)
  Connections {
    target: CompositorService
    enabled: Settings.data.bar.hideOnOverview

    function onOverviewActiveChanged() {
      if (CompositorService.overviewActive && root.openedPanel) {
        root.openedPanel.close();
      }
    }
  }
}
