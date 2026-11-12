.pragma library

function openToEntry(root, Settings, PanelService, Logger, entry, screen) {
    var settingsPanel;
    if (Settings.data.ui.settingsPanelMode === "window") {
      root.requestedEntry = entry;
      if (root.settingsWindow) {
        root.settingsWindow.visible = true;
        root.isWindowOpen = true;
        root.windowOpened();
        root.settingsWindow.navigateToEntry(entry);
      }
    } else {
      if (!screen) {
        Logger.w("SettingsPanelService", "Screen parameter required for panel mode");
        return;
      }
      settingsPanel = PanelService.getPanel("settingsPanel", screen);
      if (settingsPanel) {
        settingsPanel.requestedEntry = entry;
        settingsPanel.open();
      }
    }
}

function openToTab(root, Settings, PanelService, Logger, tab, subTab, screen) {
    var settingsPanel;
    const tabId = tab !== undefined ? tab : 0;
    const subTabId = subTab !== undefined ? subTab : -1;

    if (Settings.data.ui.settingsPanelMode === "window") {
      root.requestedTab = tabId;
      root.requestedSubTab = subTabId;
      if (root.settingsWindow) {
        root.settingsWindow.visible = true;
        root.isWindowOpen = true;
        root.windowOpened();
        root.settingsWindow.navigateTo(tabId, subTabId);
      }
    } else {
      if (!screen) {
        Logger.w("SettingsPanelService", "Screen parameter required for panel mode");
        return;
      }
      settingsPanel = PanelService.getPanel("settingsPanel", screen);
      if (settingsPanel) {
        settingsPanel.openToTab(tabId, subTabId);
      }
    }
}

function openWindow(root, Settings, PanelService, Logger, tab) {
    root.requestedTab = tab !== undefined ? tab : 0;
    root.requestedSubTab = -1;
    if (root.settingsWindow) {
      root.settingsWindow.visible = true;
      root.isWindowOpen = true;
      root.windowOpened();
      root.settingsWindow.navigateTo(root.requestedTab, -1);
    }
}

function closeWindow(root, Settings, PanelService, Logger) {
    if (root.settingsWindow) {
      root.settingsWindow.visible = false;
      root.isWindowOpen = false;
      root.windowClosed();
    }
}

function toggleWindow(root, Settings, PanelService, Logger, tab) {
    if (root.isWindowOpen) {
      root.closeWindow();
    } else {
      root.openWindow(tab);
    }
}

function toggle(root, Settings, PanelService, Logger, tab, subTab, screen) {
    var settingsPanel;
    const tabId = tab !== undefined ? tab : 0;
    const subTabId = subTab !== undefined ? subTab : -1;

    if (Settings.data.ui.settingsPanelMode === "window") {
      if (root.isWindowOpen) {
        root.closeWindow();
      } else {
        root.openToTab(tabId, subTabId);
      }
    } else {
      if (!screen) {
        Logger.w("SettingsPanelService", "Screen parameter required for panel mode");
        return;
      }
      settingsPanel = PanelService.getPanel("settingsPanel", screen);
      if (settingsPanel?.isPanelOpen) {
        settingsPanel.close();
      } else {
        settingsPanel?.openToTab(tabId, subTabId);
      }
    }
}

function close(root, Settings, PanelService, Logger, screen) {
    var settingsPanel;
    if (Settings.data.ui.settingsPanelMode === "window") {
      root.closeWindow();
    } else {
      if (!screen)
        return;
      settingsPanel = PanelService.getPanel("settingsPanel", screen);
      settingsPanel?.close();
    }
}
