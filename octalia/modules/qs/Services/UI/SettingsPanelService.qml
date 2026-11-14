pragma Singleton

import "SettingsPanelServiceUtils.js" as SettingsPanelUtils

import QtQuick 6.10
import Quickshell
import qs.Commons
import qs.Services.UI

Singleton {
  id: root

  // Track if the settings window is open
  property bool isWindowOpen: false

  // Reference to the window (set by SettingsPanelWindow)
  property var settingsWindow: null

  // Requested tab when opening
  property int requestedTab: 0

  // Requested subtab when opening (-1 means no specific subtab)
  property int requestedSubTab: -1

  // Requested entry for search navigation
  property var requestedEntry: null

  signal windowOpened
  signal windowClosed

  function openToEntry(entry: var, screen: var): void {
    SettingsPanelUtils.openToEntry(root, Settings, PanelService, Logger, entry, screen);
  }

  // Unified function to open settings to a specific tab and subtab
  // Respects user's settingsPanelMode setting (window vs panel)
  // For panel mode, screen parameter is required
  function openToTab(tab: var, subTab: var, screen: var): void {
    SettingsPanelUtils.openToTab(root, Settings, PanelService, Logger, tab, subTab, screen);
  }

  function openWindow(tab: var): void {
    SettingsPanelUtils.openWindow(root, Settings, PanelService, Logger, tab);
  }

  function closeWindow(): void {
    SettingsPanelUtils.closeWindow(root, Settings, PanelService, Logger);
  }

  function toggleWindow(tab: var): void {
    SettingsPanelUtils.toggleWindow(root, Settings, PanelService, Logger, tab);
  }

  // Unified toggle: opens to tab/subtab if closed, closes if open
  // Respects settingsPanelMode setting
  function toggle(tab: var, subTab: var, screen: var): void {
    SettingsPanelUtils.toggle(root, Settings, PanelService, Logger, tab, subTab, screen);
  }

  // Unified close for both modes
  function close(screen: var): void {
    SettingsPanelUtils.close(root, Settings, PanelService, Logger, screen);
  }
}
