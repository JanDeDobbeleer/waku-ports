.pragma library

function registerPanel(panel, root, Logger) {
    root.registeredPanels[panel.objectName] = panel;
    Logger.d("PanelService", "Registered panel:", panel.objectName);
}

function registerPopupMenuWindow(screen, window, root, Logger) {
    if (!screen || !window)
      return;
    var key = screen.name;
    root.popupMenuWindows[key] = window;
    Logger.d("PanelService", "Registered popup menu window for screen:", key);
    root.popupMenuWindowRegistered(screen);
}

function unregisterPopupMenuWindow(screen, root, Logger) {
    if (!screen)
      return;
    var key = screen.name;
    delete root.popupMenuWindows[key];
    Logger.d("PanelService", "Unregistered popup menu window for screen:", key);
}

function getPopupMenuWindow(screen, root) {
    if (!screen)
      return null;
    return root.popupMenuWindows[screen.name] || null;
}

function closeContextMenu(screen, root) {
    var popupMenuWindow = root.getPopupMenuWindow(screen);
    if (popupMenuWindow && popupMenuWindow.visible) {
      popupMenuWindow.close();
    }
}

function showTrayMenu(screen, trayItem, trayMenu, anchorItem, menuX, menuY, widgetSection, widgetIndex, root, TrayMenuHelpers) {
    if (!trayItem || !trayMenu || !anchorItem)
      return false;

    // Close any previously opened menu first
    root.closeContextMenu(screen);

    TrayMenuHelpers.setMenuScreen(trayMenu, screen);
    trayMenu.trayItem = trayItem;
    trayMenu.widgetSection = widgetSection;
    trayMenu.widgetIndex = widgetIndex;

    var popupMenuWindow = root.getPopupMenuWindow(screen);
    if (popupMenuWindow) {
      popupMenuWindow.open();
      trayMenu.showAt(anchorItem, menuX, menuY);
    } else {
      return false;
    }
    return true;
}

function findFallbackScreen(root, Quickshell) {
    let primaryCandidate = null;
    let firstScreen = null;

    for (let i = 0; i < Quickshell.screens.length; i++) {
      const s = Quickshell.screens[i];
      if (s.x === 0 && s.y === 0) {
        primaryCandidate = s;
      }
      if (!firstScreen) {
        firstScreen = s;
      }
    }

    return primaryCandidate || firstScreen || null;
}

function getPanel(name, screen, fallback, root, Logger) {
    if (fallback === undefined) fallback = true;
    var key;
    var fallbackKey, fallbackScreen;
    if (!screen) {
      Logger.d("PanelService", "missing screen for getPanel:", name);
      // If no screen specified, return the first matching panel
      for (key in root.registeredPanels) {
        if (key.startsWith(name + "-")) {
          return root.registeredPanels[key];
        }
      }
      return null;
    }

    var panelKey = `${name}-${screen.name}`;

    // Check if panel is already loaded
    if (root.registeredPanels[panelKey]) {
      return root.registeredPanels[panelKey];
    }

    // If fallback enabled, try to find panel on another screen
    if (fallback) {
      // First try the primary screen (0x0)
      fallbackScreen = root.findFallbackScreen();
      if (fallbackScreen && fallbackScreen.name !== screen.name) {
        fallbackKey = `${name}-${fallbackScreen.name}`;
        if (root.registeredPanels[fallbackKey]) {
          Logger.d("PanelService", "Panel fallback from", screen.name, "to", fallbackScreen.name);
          return root.registeredPanels[fallbackKey];
        }
      }

      // Try any other screen
      for (key in root.registeredPanels) {
        if (key.startsWith(name + "-")) {
          Logger.d("PanelService", "Panel fallback to first available:", key);
          return root.registeredPanels[key];
        }
      }
    }

    Logger.w("PanelService", "Panel not found:", panelKey);
    return null;
}

function canShowPanelsOnScreen(screen, root, Settings) {
    const name = screen?.name || "";
    const monitors = Settings.data.bar.monitors || [];
    const allowPanelsOnScreenWithoutBar = Settings.data.general.allowPanelsOnScreenWithoutBar;
    return allowPanelsOnScreenWithoutBar || monitors.length === 0 || monitors.includes(name);
}

function findScreenForPanels(root, Quickshell) {
    for (let i = 0; i < Quickshell.screens.length; i++) {
      if (root.canShowPanelsOnScreen(Quickshell.screens[i])) {
        return Quickshell.screens[i];
      }
    }
    return null;
}

function willOpenPanel(panel, root, keyboardInitTimer) {
    // Close overlay launcher if open
    if (root.overlayLauncherOpen) {
      root.overlayLauncherOpen = false;
      root.overlayLauncherScreen = null;
    }

    if (root.openedPanel && root.openedPanel !== panel) {
      // Move current panel to closing slot before closing it
      root.closingPanel = root.openedPanel;
      root.assignToSlot(1, root.closingPanel);
      root.openedPanel.close();
    }

    // Assign new panel to open slot
    root.openedPanel = panel;
    root.assignToSlot(0, panel);

    // Start keyboard initialization period (for Hyprland workaround)
    if (panel && panel.exclusiveKeyboard) {
      root.isInitializingKeyboard = true;
      keyboardInitTimer.restart();
    }

    // emit signal
    root.willOpen();
}

function getLauncherSearchText(screen, root, Settings) {
    var panel;
    if (Settings.data.appLauncher.overviewLayer) {
      return root.overlayLauncherCore ? root.overlayLauncherCore.searchText : "";
    } else {
      panel = root.getPanel("launcherPanel", screen);
      return panel ? panel.searchText : "";
    }
}

function closePanel(root) {
    if (root.overlayLauncherOpen) {
      root.closeOverlayLauncher();
    } else if (root.openedPanel && root.openedPanel.close) {
      root.openedPanel.close();
    }
}

function invokePanel(panel, method, args) {
  if (panel !== null && panel !== undefined)
    panel[method](...args);
}

function openSettingsPanel(panel, tab) {
  panel.requestedTab = tab;
  panel.open();
}

function isPanelOpen(panel) { return panel ? panel.isPanelOpen : false; }

function isPanelVisible(panel) { return !!panel && !!panel.visible; }

// Writes each key of properties onto the panel, for panels whose type is only known at runtime.
function setPanelProperties(panel, properties) {
  if (!panel)
    return;
  for (const key in properties)
    panel[key] = properties[key];
}
