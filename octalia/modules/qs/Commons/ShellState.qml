pragma Singleton

import "ShellStateUtils.js" as ShellStateUtils

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import "../Helpers/QtObj2JS.js" as QtObj2JS
import qs.Services.Power
import qs.Services.System
import qs.Services.UI
import qs.compat

// Centralized shell state management for small cache files
Singleton {
  id: root

  property string stateFile: ""
  property bool isLoaded: false

  // State properties for different services
  readonly property alias data: adapter

  // Signals for state changes
  signal displayStateChanged
  signal notificationsStateChanged
  signal changelogStateChanged
  signal colorSchemesListChanged

  Component.onCompleted: {
    // Setup state file path (needs Settings to be available)
    Qt.callLater(() => {
                   if (typeof Settings !== 'undefined' && Settings.cacheDir) {
                     stateFile = Settings.cacheDir + "shell-state.json";
                     stateFileView.path = stateFile;
                   }
                 });
  }

  // FileView for shell state
  FileView {
    id: stateFileView
    printErrors: false
    watchChanges: false

    adapter: JsonAdapter {
      id: adapter

      // CompositorService: display scales
      property var display: ({})

      // NotificationService: notification state
      property var notificationsState: ({
                                          lastSeenTs: 0
                                        })

      // UpdateService: changelog state
      property var changelogState: ({
                                      lastSeenVersion: ""
                                    })

      // SchemeDownloader: color schemes list
      property var colorSchemesList: ({
                                        schemes: [],
                                        timestamp: 0
                                      })

      // UI state: settings panel, etc.
      property var ui: ({
                          settingsSidebarExpanded: true
                        })

      // Telemetry state
      property var telemetry: ({
                                 instanceId: ""
                               })

      // Launcher app usage counts
      property var launcherUsage: ({})
    }

    onLoaded: {
      root.isLoaded = true;
      Logger.d("ShellState", "Loaded state file");
    }

    onLoadFailed: error => {
      if (error === 2) {
        // File doesn't exist, will be created on first write
        root.isLoaded = true;
        Logger.d("ShellState", "State file doesn't exist, will create on first write");
      } else {
        Logger.e("ShellState", "Failed to load state file:", error);
        root.isLoaded = true;
      }
    }
  }

  // Launcher usage
  function getLauncherUsageCount(key: var): real {
    const m = adapter.launcherUsage;
    if (!m)
      return 0;
    const v = m[key];
    return typeof v === 'number' && isFinite(v) ? v : 0;
  }

  function recordLauncherUsage(key: var): void {
    let counts = Object.assign({}, adapter.launcherUsage || {});
    counts[key] = getLauncherUsageCount(key) + 1;
    adapter.launcherUsage = counts;
    save();
  }

  // Migrate usage from one key to another, merging counts in a single save
  function migrateLauncherUsage(fromKey: var, toKey: var): void {
    let counts = Object.assign({}, adapter.launcherUsage || {});
    const fromCount = typeof counts[fromKey] === 'number' && isFinite(counts[fromKey]) ? counts[fromKey] : 0;
    const toCount = typeof counts[toKey] === 'number' && isFinite(counts[toKey]) ? counts[toKey] : 0;
    counts[toKey] = toCount + fromCount;
    ShellStateUtils.deleteKey(counts, fromKey);
    adapter.launcherUsage = counts;
    save();
  }

  // Debounced save timer
  Timer {
    id: saveTimer
    interval: 500
    onTriggered: root.performSave()
  }

  property bool saveQueued: false

  function save() {
    saveQueued = true;
    saveTimer.restart();
  }

  function performSave() {
    if (!saveQueued || !stateFile) {
      return;
    }

    saveQueued = false;

    ShellStateUtils.performSave(Settings, Os, root, Logger);
  }

  function scheduleStateWrite(): void {
    Qt.callLater(() => { ShellStateUtils.writeAdapter(stateFileView, Logger); });
  }

  // Convenience functions for each service

  // Display state (CompositorService)
  function setDisplay(displayData: var) {
    adapter.display = displayData;
    save();
    displayStateChanged();
  }

  function getDisplay(): var {
    return adapter.display || {};
  }

  // Notifications state (NotificationService)
  function setNotificationsState(stateData: var) {
    adapter.notificationsState = stateData;
    save();
    notificationsStateChanged();
  }

  function getNotificationsState(): var {
    return adapter.notificationsState || {
      lastSeenTs: 0
    };
  }

  // Changelog state (UpdateService)
  function setChangelogState(stateData: var) {
    adapter.changelogState = stateData;
    save();
    changelogStateChanged();
  }

  function getChangelogState(): var {
    return adapter.changelogState || {
      lastSeenVersion: ""
    };
  }

  // Color schemes list (SchemeDownloader)
  function setColorSchemesList(listData: var) {
    adapter.colorSchemesList = listData;
    save();
    colorSchemesListChanged();
  }

  function getColorSchemesList(): var {
    return adapter.colorSchemesList || {
      schemes: [],
      timestamp: 0
    };
  }

  // UI state
  function setUiState(stateData: var) {
    adapter.ui = stateData;
    save();
  }

  function getUiState(): var {
    return adapter.ui || {
      settingsSidebarExpanded: true
    };
  }

  function setSettingsSidebarExpanded(expanded: var): void {
    ShellStateUtils.setSettingsSidebarExpanded(root, expanded);
  }

  function getSettingsSidebarExpanded(): bool {
    return ShellStateUtils.getSettingsSidebarExpanded(root);
  }

  // Telemetry state
  function setTelemetryState(stateData: var) {
    adapter.telemetry = stateData;
    save();
  }

  function getTelemetryState(): var {
    return adapter.telemetry || {
      instanceId: ""
    };
  }

  function getTelemetryInstanceId(): string {
    return ShellStateUtils.getTelemetryInstanceId(root);
  }

  function setTelemetryInstanceId(instanceId: var): void {
    ShellStateUtils.setTelemetryInstanceId(root, instanceId);
  }

  // -----------------------------------------------------
  function buildStateSnapshot(): var {
    return ShellStateUtils.buildStateSnapshot(QtObj2JS, Settings, ShellState, NotificationService, PowerProfileService, BarService, PanelService, WallpaperService, DesktopWidgetRegistry, Logger);
  }
}
