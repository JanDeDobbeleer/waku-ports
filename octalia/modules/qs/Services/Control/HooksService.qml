pragma Singleton

import "HooksServiceUtils.js" as HooksServiceUtils

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Power
import qs.Services.Theming
import qs.Services.UI

Singleton {
  id: root

  // Hook connections for automatic script execution
  Connections {
    target: Settings.data.colorSchemes
    function onDarkModeChanged() {
      root.executeDarkModeHook(Settings.data.colorSchemes.darkMode);
    }
  }

  // Pending wallpaper hook when waiting for color generation
  property var pendingWallpaperHook: null

  Connections {
    target: WallpaperService
    function onWallpaperChanged(screenName: string, path: string): void {
      var effectiveMonitor;
      // Check if we need to wait for color generation
      if (Settings.data.colorSchemes.useWallpaperColors) {
        effectiveMonitor = Settings.data.colorSchemes.monitorForColors;
        if (effectiveMonitor === "" || effectiveMonitor === undefined) {
          effectiveMonitor = Screen.name;
        }

        if (screenName === effectiveMonitor) {
          // Store pending hook and wait for colors to be generated
          root.pendingWallpaperHook = {
            path: path,
            screenName: screenName
          };
          return;
        }
      }
      // No color generation, execute immediately
      root.executeWallpaperHook(path, screenName);
    }
  }

  Connections {
    target: TemplateProcessor
    function onColorsGenerated() {
      // Execute pending wallpaper hook after colors are ready
      if (root.pendingWallpaperHook) {
        const hook = root.pendingWallpaperHook;
        root.pendingWallpaperHook = null;
        HooksServiceUtils.executePendingWallpaperHook(root, hook);
      }
      root.executeColorGenerationHook();
    }
  }

  // Track lock screen state for unlock hook
  property bool wasLocked: false

  Connections {
    target: PanelService
    function onLockScreenChanged() {
      if (PanelService.lockScreen) {
        lockScreenActiveConnection.target = PanelService.lockScreen;
      }
    }
  }

  Connections {
    id: lockScreenActiveConnection
    target: PanelService.lockScreen
    function onActiveChanged() {
      // Detect lock: was unlocked, now locked
      if (!root.wasLocked && HooksServiceUtils.lockScreenActive(PanelService.lockScreen)) {
        root.executeLockHook();
      }
      // Detect unlock: was locked, now not locked
      if (root.wasLocked && !HooksServiceUtils.lockScreenActive(PanelService.lockScreen)) {
        root.executeUnlockHook();
      }
      root.wasLocked = HooksServiceUtils.lockScreenActive(PanelService.lockScreen);
    }
  }

  // Track performance mode state for hooks
  property bool wasPerformanceModeEnabled: false

  Connections {
    target: PowerProfileService
    function onOctaliaPerformanceModeChanged() {
      const isEnabled = PowerProfileService.octaliaPerformanceMode;

      // Detect enabled: was disabled, now enabled
      if (!root.wasPerformanceModeEnabled && isEnabled) {
        root.executePerformanceModeEnabledHook();
      }
      // Detect disabled: was enabled, now disabled
      if (root.wasPerformanceModeEnabled && !isEnabled) {
        root.executePerformanceModeDisabledHook();
      }
      root.wasPerformanceModeEnabled = isEnabled;
    }
  }

  // Execute wallpaper change hook
  function executeWallpaperHook(wallpaperPath: var, screenName: var): void {
    HooksServiceUtils.executeWallpaperHook(wallpaperPath, screenName, Settings, Quickshell, Logger);
  }

  // Execute dark mode change hook
  function executeDarkModeHook(isDarkMode: var): void {
    HooksServiceUtils.executeDarkModeHook(isDarkMode, Settings, Quickshell, Logger);
  }

  // Execute screen lock hook
  function executeLockHook(): void {
    HooksServiceUtils.executeLockHook(Settings, Quickshell, Logger);
  }

  // Execute screen unlock hook
  function executeUnlockHook(): void {
    HooksServiceUtils.executeUnlockHook(Settings, Quickshell, Logger);
  }

  // Execute performance mode enabled hook
  function executePerformanceModeEnabledHook(): void {
    HooksServiceUtils.executePerformanceModeEnabledHook(Settings, Quickshell, Logger);
  }

  // Execute performance mode disabled hook
  function executePerformanceModeDisabledHook(): void {
    HooksServiceUtils.executePerformanceModeDisabledHook(Settings, Quickshell, Logger);
  }

  // Execute color generation hook
  function executeColorGenerationHook(): void {
    HooksServiceUtils.executeColorGenerationHook(Settings, Quickshell, Logger);
  }

  // Blocking power hook infrastructure
  property var pendingPowerCallback: null

  Process {
    id: powerHookProcess
    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0) {
        Logger.w("HooksService", `Power hook failed with exit code ${exitCode}`);
      }

      if (root.pendingPowerCallback !== null) {
        const callback = root.pendingPowerCallback;
        root.pendingPowerCallback = null;
        HooksServiceUtils.call(callback);
      }
    }
  }

  function runPowerHook(script: var, callback: var): void {
    pendingPowerCallback = callback;
    powerHookProcess.command = ["cmd", "/c", script];
    powerHookProcess.running = true;
  }

  function executeSessionHook(action: var, callback: var): void {
    HooksServiceUtils.executeSessionHook(root, Settings, Logger, action, callback);
  }

  // Execute startup hook
  function executeStartupHook(): void {
    HooksServiceUtils.executeStartupHook(Settings, Quickshell, Logger);
  }

  // Initialize the service
  function init() {
    Logger.i("HooksService", "Service started");
    // Initialize lock screen state tracking
    Qt.callLater(() => {
                   if (PanelService.lockScreen) {
                     wasLocked = HooksServiceUtils.lockScreenActive(PanelService.lockScreen);
                     lockScreenActiveConnection.target = PanelService.lockScreen;
                   }
                   // Initialize performance mode state tracking
                   wasPerformanceModeEnabled = PowerProfileService.octaliaPerformanceMode;
                   // Execute startup hook
                   executeStartupHook();
                 });
  }
}
