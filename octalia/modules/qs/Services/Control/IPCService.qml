pragma Singleton

import "IPCServiceUtils.js" as IPCUtils

import QtQuick 6.10
import Quickshell

import qs.Commons
import qs.Modules.Panels.Settings
import qs.Services.Compositor
import qs.Services.Hardware
import qs.Services.Location
import qs.Services.Media
import qs.Services.Networking
import qs.Services.Power
import qs.Services.System
import qs.Services.Theming
import qs.Services.UI

Singleton {
  id: root

  // Screen detector, set via init()
  property var screenDetector: null

  function init(detector: var): void {
    root.screenDetector = detector;
    Logger.i("IPCService", "Service started");
  }

  // Helper for index-based notification lookups in IPC
  function _getNotificationByIndex(index: string, funcName: string): var {
    var idx = index === "" ? 0 : parseInt(index);
    if (isNaN(idx)) {
      Logger.w("IPC", "Argument to ipc call '" + funcName + "' must be a number");
      return null;
    }
    if (idx < 0 || idx >= IPCUtils.modelCount(NotificationService.popupModel)) {
      Logger.w("IPC", "Notification index out of range: " + idx);
      return null;
    }
    return IPCUtils.modelGet(NotificationService.popupModel, idx);
  }

  IpcHandler {
    target: "bar"
    function toggle() {
      BarService.toggleVisibility();
    }
    function hideBar() {
      BarService.hide();
    }
    function showBar() {
      BarService.show();
    }
    function peek() {
      BarService.peek();
    }
    function setDisplayMode(mode: string, screen: string) {
      if (mode === "always_visible" || mode === "non_exclusive" || mode === "auto_hide") {
        if (!screen || screen === "all") {
          Settings.data.bar.displayMode = mode;
        } else {
          Settings.setScreenOverride(screen, "displayMode", mode);
        }
      }
    }
    function setPosition(position: string, screen: string) {
      var valid = position === "top" || position === "bottom" || position === "left" || position === "right";
      if (!valid) {
        Logger.w("IPC", "Invalid bar position: " + position + ". Valid: top, bottom, left, right");
        return;
      }
      if (!screen || screen === "all") {
        Settings.data.bar.position = position;
      } else {
        Settings.setScreenOverride(screen, "position", position);
      }
    }
  }

  // Settings IPC helpers (outside IpcHandler to avoid QVariant IPC warnings)
  readonly property var _settingsTabMap: ({
                                            "about": SettingsPanel.Tab.About,
                                            "audio": SettingsPanel.Tab.Audio,
                                            "bar": SettingsPanel.Tab.Bar,
                                            "colorscheme": SettingsPanel.Tab.ColorScheme,
                                            "lockscreen": SettingsPanel.Tab.LockScreen,
                                            "controlcenter": SettingsPanel.Tab.ControlCenter,
                                            "desktopwidgets": SettingsPanel.Tab.DesktopWidgets,
                                            "osd": SettingsPanel.Tab.OSD,
                                            "display": SettingsPanel.Tab.Display,
                                            "dock": SettingsPanel.Tab.Dock,
                                            "general": SettingsPanel.Tab.General,
                                            "hooks": SettingsPanel.Tab.Hooks,
                                            "launcher": SettingsPanel.Tab.Launcher,
                                            "location": SettingsPanel.Tab.Location,
                                            "connections": SettingsPanel.Tab.Connections,
                                            "notifications": SettingsPanel.Tab.Notifications,
                                            "sessionmenu": SettingsPanel.Tab.SessionMenu,
                                            "system": SettingsPanel.Tab.System,
                                            "systemmonitor": SettingsPanel.Tab.System,
                                            "userinterface": SettingsPanel.Tab.UserInterface,
                                            "wallpaper": SettingsPanel.Tab.Wallpaper,
                                            "idle": SettingsPanel.Tab.Idle
                                          })

  function _parseSettingsTabArg(tabArg: var): var {
    var parts = tabArg.split("/");
    var tabId = _resolveSettingsTab(parts[0]);
    var subTabId = parts.length > 1 ? parseInt(parts[1]) : -1;
    return {
      "tab": tabId,
      "subTab": isNaN(subTabId) ? -1 : subTabId
    };
  }

  function _resolveSettingsTab(tabName: var): var {
    if (!tabName)
      return SettingsPanel.Tab.General;
    var key = tabName.toLowerCase().replace(/[-_]/g, "");
    if (key in _settingsTabMap)
      return _settingsTabMap[key];
    Logger.w("IPC", "Unknown settings tab: " + tabName);
    return SettingsPanel.Tab.General;
  }

  function _settingsToggle(tabId: var, subTabId: var): void {
    root.screenDetector.withCurrentScreen(function (screen: var): void {
                                            SettingsPanelService.toggle(tabId, subTabId, screen);
                                          });
  }

  function _settingsOpen(tabId: var, subTabId: var): void {
    root.screenDetector.withCurrentScreen(function (screen: var): void {
                                            SettingsPanelService.openToTab(tabId, subTabId, screen);
                                          });
  }

  IpcHandler {
    target: "settings"

    function toggle() {
      root._settingsToggle(SettingsPanel.Tab.General, -1);
    }

    function toggleTab(tab: string) {
      var parsed = root._parseSettingsTabArg(tab);
      IPCUtils.toggleSettings(root, parsed);
    }

    function open() {
      root._settingsOpen(SettingsPanel.Tab.General, -1);
    }

    function openTab(tab: string) {
      var parsed = root._parseSettingsTabArg(tab);
      IPCUtils.openSettings(root, parsed);
    }
  }

  IpcHandler {
    target: "calendar"
    function toggle() {
      root.screenDetector.withCurrentScreen(function (screen: var): void {
                                              var clockPanel = PanelService.getPanel("clockPanel", screen);
                                              IPCUtils.invokePanel(clockPanel, "toggle", [null, "Clock"]);
                                            });
    }
  }

  IpcHandler {
    target: "notifications"
    function toggleHistory() {
      // Will attempt to open the panel next to the bar button if any.
      root.screenDetector.withCurrentScreen(function (screen: var): void {
                                              var notificationHistoryPanel = PanelService.getPanel("notificationHistoryPanel", screen);
                                              notificationHistoryPanel.toggle(null, "NotificationHistory");
                                            });
    }
    function toggleDND() {
      NotificationService.doNotDisturb = !NotificationService.doNotDisturb;
    }
    function enableDND() {
      NotificationService.doNotDisturb = true;
    }
    function disableDND() {
      NotificationService.doNotDisturb = false;
    }
    function clear() {
      NotificationService.clearHistory();
    }

    function dismissOldest() {
      NotificationService.dismissOldestPopup();
    }

    function removeOldestHistory() {
      NotificationService.removeOldestHistory();
    }

    function dismissAll() {
      NotificationService.dismissAllPopups();
    }

    function getHistory(): string {
      return JSON.stringify(NotificationService.getHistorySnapshot(), null, 2);
    }

    function removeFromHistory(id: string): bool {
      return NotificationService.removeFromHistory(id);
    }

    function invokeDefault(index: string): bool {
      var notif = root._getNotificationByIndex(index, "notifications invokeDefault");
      if (!notif)
        return false;
      return IPCUtils.invokeDefault(notif, NotificationService);
    }

    function invokeDefaultAndDismiss(index: string): bool {
      var notif = root._getNotificationByIndex(index, "notifications invokeDefaultAndDismiss");
      if (!notif)
        return false;
      return IPCUtils.invokeDefaultAndDismiss(notif, NotificationService);
    }

    function invokeAction(id: string, actionId: string): bool {
      if (!id || !actionId) {
        Logger.w("IPC", "Both 'id' and 'actionId' are required for 'notifications invokeAction'");
        return false;
      }
      return NotificationService.invokeAction(id, actionId);
    }

    function getActions(index: string): string {
      var notif = root._getNotificationByIndex(index, "notifications getActions");
      if (!notif)
        return "[]";
      return IPCUtils.notificationActions(notif);
    }
  }

  IpcHandler {
    target: "toast"

    function send(json: string) {
      IPCUtils.sendToast(json, ToastService, Logger);
    }

    function dismiss() {
      ToastService.dismissToast();
    }
  }

  // Idle Inhibitor / Keep Awake
  IpcHandler {
    target: "idleInhibitor"
    function toggle() {
      IdleInhibitorService.manualToggle();
    }
    function enable() {
      IdleInhibitorService.addManualInhibitor(null);
    }
    function disable() {
      IdleInhibitorService.removeManualInhibitor();
    }
    function enableFor(seconds: string) {
      var secs = parseInt(seconds);
      if (isNaN(secs) || secs <= 0) {
        Logger.w("IPC", "Argument to 'idleInhibitor enableFor' must be a positive number");
        return;
      }
      IdleInhibitorService.addManualInhibitor(secs);
    }
  }

  // Port: same key as celeste's launcher. waku registers it; remove the line to bind
  // `wakuc shortcut launcher` elsewhere.
  GlobalShortcut {
    name: "launcher"
    description: "Toggle launcher"
    keys: "alt+space"
    onPressed: root.toggleLauncher()
  }

  function toggleLauncher() {
      root.screenDetector.withCurrentScreen(function (screen: var): void {
                                              var searchText = PanelService.getLauncherSearchText(screen);
                                              var isInAppMode = !searchText.startsWith(">");
                                              if (!PanelService.isLauncherOpen(screen)) {
                                                // Closed -> open in app mode
                                                PanelService.openLauncherWithSearch(screen, "");
                                              } else if (isInAppMode) {
                                                // Already in app mode -> close
                                                PanelService.closeLauncher(screen);
                                              } else {
                                                // In another mode -> switch to app mode
                                                PanelService.setLauncherSearchText(screen, "");
                                              }
                                            }, Settings.data.appLauncher.overviewLayer);
    }

  IpcHandler {
    target: "launcher"
    function toggle() {
      root.toggleLauncher();
    }
    function clipboard() {
      root.screenDetector.withCurrentScreen(function (screen: var): void {
                                              var searchText = PanelService.getLauncherSearchText(screen);
                                              var isInClipMode = searchText.startsWith(">clip");
                                              if (!PanelService.isLauncherOpen(screen)) {
                                                // Closed -> open in clipboard mode
                                                PanelService.openLauncherWithSearch(screen, ">clip ");
                                              } else if (isInClipMode) {
                                                // Already in clipboard mode -> close
                                                PanelService.closeLauncher(screen);
                                              } else {
                                                // In another mode -> switch to clipboard mode
                                                PanelService.setLauncherSearchText(screen, ">clip ");
                                              }
                                            }, Settings.data.appLauncher.overviewLayer);
    }
    function command() {
      root.screenDetector.withCurrentScreen(function (screen: var): void {
                                              var searchText = PanelService.getLauncherSearchText(screen);
                                              var isInCmdMode = searchText.startsWith(">cmd");
                                              if (!PanelService.isLauncherOpen(screen)) {
                                                PanelService.openLauncherWithSearch(screen, ">cmd ");
                                              } else if (isInCmdMode) {
                                                PanelService.closeLauncher(screen);
                                              } else {
                                                PanelService.setLauncherSearchText(screen, ">cmd ");
                                              }
                                            }, Settings.data.appLauncher.overviewLayer);
    }
    function emoji() {
      root.screenDetector.withCurrentScreen(function (screen: var): void {
                                              var searchText = PanelService.getLauncherSearchText(screen);
                                              var isInEmojiMode = searchText.startsWith(">emoji");
                                              if (!PanelService.isLauncherOpen(screen)) {
                                                // Closed -> open in emoji mode
                                                PanelService.openLauncherWithSearch(screen, ">emoji ");
                                              } else if (isInEmojiMode) {
                                                // Already in emoji mode -> close
                                                PanelService.closeLauncher(screen);
                                              } else {
                                                // In another mode -> switch to emoji mode
                                                PanelService.setLauncherSearchText(screen, ">emoji ");
                                              }
                                            }, Settings.data.appLauncher.overviewLayer);
    }
    function windows() {
      root.screenDetector.withCurrentScreen(function (screen: var): void {
                                              var searchText = PanelService.getLauncherSearchText(screen);
                                              var isInWindowsMode = searchText.startsWith(">win");
                                              if (!PanelService.isLauncherOpen(screen)) {
                                                PanelService.openLauncherWithSearch(screen, ">win ");
                                              } else if (isInWindowsMode) {
                                                PanelService.closeLauncher(screen);
                                              } else {
                                                PanelService.setLauncherSearchText(screen, ">win ");
                                              }
                                            }, Settings.data.appLauncher.overviewLayer);
    }
    function settings() {
      root.screenDetector.withCurrentScreen(function (screen: var): void {
                                              var searchText = PanelService.getLauncherSearchText(screen);
                                              var isInSettingsMode = searchText.startsWith(">settings");
                                              if (!PanelService.isLauncherOpen(screen)) {
                                                PanelService.openLauncherWithSearch(screen, ">settings ");
                                              } else if (isInSettingsMode) {
                                                PanelService.closeLauncher(screen);
                                              } else {
                                                PanelService.setLauncherSearchText(screen, ">settings ");
                                              }
                                            }, Settings.data.appLauncher.overviewLayer);
    }
  }

  IpcHandler {
    target: "lockScreen"

    // New preferred method - lock the screen
    function lock() {
      // Only lock if not already locked (prevents the red screen issue)
      if (!IPCUtils.lockScreenActive(PanelService.lockScreen)) {
        CompositorService.lock();
      }
    }
  }

  IpcHandler {
    target: "brightness"
    function increase() {
      BrightnessService.increaseBrightness();
    }
    function decrease() {
      BrightnessService.decreaseBrightness();
    }
    function set(value: string) {
      var val = parseFloat(value);
      if (isNaN(val))
        return;

      // Normalize logic: heuristic handling of 0-100 vs 0-1
      if (val > 1.0)
        val = val / 100.0;

      // Clamp
      val = Math.max(0.0, Math.min(1.0, val));

      BrightnessService.setBrightness(val);
    }
  }

  IpcHandler {
    target: "monitors"
    function on() {
      CompositorService.turnOnMonitors();
    }
    function off() {
      CompositorService.turnOffMonitors();
    }
  }

  IpcHandler {
    target: "darkMode"
    function toggle() {
      Settings.data.colorSchemes.darkMode = !Settings.data.colorSchemes.darkMode;
    }
    function setDark() {
      Settings.data.colorSchemes.darkMode = true;
    }
    function setLight() {
      Settings.data.colorSchemes.darkMode = false;
    }
  }

  IpcHandler {
    target: "nightLight"
    function toggle() {
      if (!ProgramCheckerService.wlsunsetAvailable) {
        Logger.w("IPC", "wlsunset not available, cannot toggle night light");
        return;
      }

      if (Settings.data.nightLight.forced) {
        Settings.data.nightLight.forced = false;
      } else {
        if (Settings.data.nightLight.enabled) {
          Settings.data.nightLight.enabled = false;
        } else {
          Settings.data.nightLight.forced = true;
          Settings.data.nightLight.enabled = true;
        }
      }
    }
  }

  IpcHandler {
    target: "colorScheme"
    function set(schemeName: string) {
      ColorSchemeService.setPredefinedScheme(schemeName);
    }
    function setGenerationMethod(method: string) {
      var valid = IPCUtils.isValidScheme(TemplateProcessor.schemeTypes, method);

      if (valid) {
        Settings.data.colorSchemes.generationMethod = method;
      } else {
        Logger.w("IPC", "Invalid generation method received: " + method);
      }
    }
  }

  IpcHandler {
    target: "volume"
    function increase() {
      AudioService.increaseVolume();
    }
    function decrease() {
      AudioService.decreaseVolume();
    }
    function muteOutput() {
      AudioService.setOutputMuted(!AudioService.muted);
    }
    function increaseInput() {
      AudioService.increaseInputVolume();
    }
    function decreaseInput() {
      AudioService.decreaseInputVolume();
    }
    function muteInput() {
      AudioService.setInputMuted(!AudioService.inputMuted);
    }
    function togglePanel() {
      root.screenDetector.withCurrentScreen(function (screen: var): void {
                                              var panel = PanelService.getPanel("audioPanel", screen);
                                              IPCUtils.invokePanel(panel, "toggle", [null, "Volume"]);
                                            });
    }
    function openPanel() {
      root.screenDetector.withCurrentScreen(function (screen: var): void {
                                              var panel = PanelService.getPanel("audioPanel", screen);
                                              IPCUtils.invokePanel(panel, "open", [null, "Volume"]);
                                            });
    }
    function closePanel() {
      root.screenDetector.withCurrentScreen(function (screen: var): void {
                                              var panel = PanelService.getPanel("audioPanel", screen);
                                              IPCUtils.invokePanel(panel, "close", [null, "Volume"]);
                                            });
    }
  }

  IpcHandler {
    target: "sessionMenu"
    function toggle() {
      root.screenDetector.withCurrentScreen(function (screen: var): void {
                                              var sessionMenuPanel = PanelService.getPanel("sessionMenuPanel", screen);
                                              // Session Menu is never open near the bar
                                              IPCUtils.invokePanel(sessionMenuPanel, "toggle", []);
                                            });
    }

    function lock() {
      if (!IPCUtils.lockScreenActive(PanelService.lockScreen)) {
        CompositorService.lock();
      }
    }

    function lockAndSuspend() {
      // Only lock and suspend if not already locked
      if (!IPCUtils.lockScreenActive(PanelService.lockScreen)) {
        CompositorService.lockAndSuspend();
      }
    }
  }

  IpcHandler {
    target: "controlCenter"
    function toggle() {
      root.screenDetector.withCurrentScreen(function (screen: var): void {
                                              var controlCenterPanel = PanelService.getPanel("controlCenterPanel", screen);
                                              if (Settings.data.controlCenter.position === "close_to_bar_button") {
                                                // Will attempt to open the panel next to the bar button if any.
                                                IPCUtils.invokePanel(controlCenterPanel, "toggle", [null, "ControlCenter"]);
                                              } else {
                                                IPCUtils.invokePanel(controlCenterPanel, "toggle", []);
                                              }
                                            });
    }
  }

  IpcHandler {
    target: "dock"
    function toggle() {
      Settings.data.dock.enabled = !Settings.data.dock.enabled;
    }
  }

  // Wallpaper IPC: trigger a new random wallpaper
  IpcHandler {
    target: "wallpaper"
    function toggle() {
      if (Settings.data.wallpaper.enabled) {
        root.screenDetector.withCurrentScreen(function (screen: var): void {
                                                var wallpaperPanel = PanelService.getPanel("wallpaperPanel", screen);
                                                IPCUtils.invokePanel(wallpaperPanel, "toggle", []);
                                              });
      }
    }

    function random(screen: string) {
      if (Settings.data.wallpaper.enabled) {
        if (!screen || screen === "all" || screen.trim().length === 0) {
          screen = undefined;
        }
        WallpaperService.setRandomWallpaper(screen);
      }
    }

    function get(screen: string): string {
      var found;
      if (screen === "all" || screen === "") {
        if (Quickshell.screens.length > 1) {
          return JSON.stringify(WallpaperService.getWallpapersEffectiveMap());
        }
        return WallpaperService.getWallpaper(Quickshell.screens[0].name) ?? "";
      } else {
        found = IPCUtils.findScreen(Quickshell.screens, screen);
        if (!found) {
          Logger.w("IPC", "wallpaper get: unknown screen: " + screen);
          return "";
        }
        return WallpaperService.getWallpaper(screen) ?? "";
      }
    }

    function set(path: string, screen: string) {
      if (screen === "all" || screen === "") {
        screen = undefined;
      }
      WallpaperService.changeWallpaper(path, screen);
    }

    function refresh() {
      WallpaperService.refreshWallpapersList();
    }

    function toggleAutomation() {
      Settings.data.wallpaper.automationEnabled = !Settings.data.wallpaper.automationEnabled;
    }
    function disableAutomation() {
      Settings.data.wallpaper.automationEnabled = false;
    }
    function enableAutomation() {
      Settings.data.wallpaper.automationEnabled = true;
    }
  }

  IpcHandler {
    target: "wifi"
    function toggle() {
      NetworkService.setWifiEnabled(!NetworkService.wifiEnabled);
    }
    function enable() {
      NetworkService.setWifiEnabled(true);
    }
    function disable() {
      NetworkService.setWifiEnabled(false);
    }
  }

  IpcHandler {
    target: "network"
    function togglePanel() {
      root.screenDetector.withCurrentScreen(function (screen: var): void {
                                              var networkPanel = PanelService.getPanel("networkPanel", screen);
                                              IPCUtils.invokePanel(networkPanel, "toggle", [null, "Network"]);
                                            });
    }
  }

  IpcHandler {
    target: "bluetooth"
    function toggle() {
      BluetoothService.setBluetoothEnabled(!BluetoothService.enabled);
    }
    function enable() {
      BluetoothService.setBluetoothEnabled(true);
    }
    function disable() {
      BluetoothService.setBluetoothEnabled(false);
    }
    function togglePanel() {
      root.screenDetector.withCurrentScreen(function (screen: var): void {
                                              var bluetoothPanel = PanelService.getPanel("bluetoothPanel", screen);
                                              IPCUtils.invokePanel(bluetoothPanel, "toggle", [null, "Bluetooth"]);
                                            });
    }
    function toggleAutoConnect() {
      Settings.data.network.bluetoothAutoConnect = !Settings.data.network.bluetoothAutoConnect;
    }
    function enableAutoConnect() {
      Settings.data.network.bluetoothAutoConnect = true;
    }
    function disableAutoConnect() {
      Settings.data.network.bluetoothAutoConnect = false;
    }
  }

  IpcHandler {
    target: "airplaneMode"
    function toggle() {
      NetworkService.setAirplaneMode(!NetworkService.airplaneModeEnabled);
    }
    function enable() {
      NetworkService.setAirplaneMode(true);
    }
    function disable() {
      NetworkService.setAirplaneMode(false);
    }
  }

  IpcHandler {
    target: "battery"
    function togglePanel() {
      root.screenDetector.withCurrentScreen(function (screen: var): void {
                                              var batteryPanel = PanelService.getPanel("batteryPanel", screen);
                                              IPCUtils.invokePanel(batteryPanel, "toggle", [null, "Battery"]);
                                            });
    }
  }

  IpcHandler {
    target: "powerProfile"
    function cycle() {
      PowerProfileService.cycleProfile();
    }

    function cycleReverse() {
      PowerProfileService.cycleProfileReverse();
    }

    function set(mode: string) {
      switch (mode) {
      case "performance":
        PowerProfileService.setProfile(2);
        break;
      case "balanced":
        PowerProfileService.setProfile(1);
        break;
      case "powersaver":
        PowerProfileService.setProfile(0);
        break;
      }
    }

    function toggleOctaliaPerformance() {
      PowerProfileService.toggleOctaliaPerformance();
    }

    function enableOctaliaPerformance() {
      PowerProfileService.setOctaliaPerformance(true);
    }

    function disableOctaliaPerformance() {
      PowerProfileService.setOctaliaPerformance(false);
    }
  }

  IpcHandler {
    target: "media"

    function toggle() {
      root.screenDetector.withCurrentScreen(function (screen: var): void {
                                              var panel = PanelService.getPanel("mediaPlayerPanel", screen);
                                              IPCUtils.invokePanel(panel, "toggle", [null, "MediaMini"]);
                                            });
    }

    function playPause() {
      MediaService.playPause();
    }

    function play() {
      MediaService.play();
    }

    function stop() {
      MediaService.stop();
    }

    function pause() {
      MediaService.pause();
    }

    function next() {
      MediaService.next();
    }

    function previous() {
      MediaService.previous();
    }

    function seekRelative(offset: string) {
      var offsetVal = parseFloat(offset);
      if (Number.isNaN(offsetVal)) {
        Logger.w("Media", "Argument to ipc call 'media seekRelative' must be a number");
        return;
      }
      MediaService.seekRelative(offsetVal);
    }

    function seekByRatio(position: string) {
      var positionVal = parseFloat(position);
      if (Number.isNaN(positionVal)) {
        Logger.w("Media", "Argument to ipc call 'media seekByRatio' must be a number");
        return;
      }
      MediaService.seekByRatio(positionVal);
    }
  }

  IpcHandler {
    target: "state"

    // Returns all settings and shell state as JSON
    function all(): string {
      return IPCUtils.stateAsJson(ShellState, Logger);
    }
  }

  IpcHandler {
    target: "desktopWidgets"
    function toggle() {
      Settings.data.desktopWidgets.enabled = !Settings.data.desktopWidgets.enabled;
    }
    function disable() {
      Settings.data.desktopWidgets.enabled = false;
    }
    function enable() {
      Settings.data.desktopWidgets.enabled = true;
    }
    function edit() {
      DesktopWidgetRegistry.editMode = !DesktopWidgetRegistry.editMode;
    }
  }

  IpcHandler {
    target: "location"
    function get(): string {
      return Settings.data.location.name;
    }
    function set(name: string) {
      Settings.data.location.name = name;
      LocationService.update();
    }
  }

  IpcHandler {
    target: "systemMonitor"
    function toggle() {
      root.screenDetector.withCurrentScreen(function (screen: var): void {
                                              var panel = PanelService.getPanel("systemStatsPanel", screen);
                                              IPCUtils.invokePanel(panel, "toggle", [null, "SystemMonitor"]);
                                            });
    }
  }
}
