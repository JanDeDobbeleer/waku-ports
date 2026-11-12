.pragma library

function deleteKey(object, key) { delete object[key]; }

function performSave(Settings, Os, root, Logger) {
  try {
    Os.mkdirp(Settings.cacheDir);
    root.scheduleStateWrite();
  } catch (error) {
    Logger.e("ShellState", "Failed to save state:", error);
  }
}

function writeAdapter(stateFileView, Logger) {
  try {
    stateFileView.writeAdapter();
    Logger.d("ShellState", "Saved state file");
  } catch (writeError) {
    Logger.e("ShellState", "Failed to write state file:", writeError);
  }
}

function setSettingsSidebarExpanded(root, expanded) {
    let uiState = root.getUiState();
    uiState.settingsSidebarExpanded = expanded;
    root.setUiState(uiState);
}

function getSettingsSidebarExpanded(root) {
    return root.getUiState().settingsSidebarExpanded !== false; // default to true
}

function getTelemetryInstanceId(root) {
    return root.getTelemetryState().instanceId || "";
}

function setTelemetryInstanceId(root, instanceId) {
    let state = root.getTelemetryState();
    state.instanceId = instanceId;
    root.setTelemetryState(state);
}

function buildStateSnapshot(QtObj2JS, Settings, ShellState, NotificationService, PowerProfileService, BarService, PanelService, WallpaperService, DesktopWidgetRegistry, Logger) {
    try {
      const settingsData = QtObj2JS.qtObjectToPlainObject(Settings.data);
      const shellStateData = ShellState?.data ? QtObj2JS.qtObjectToPlainObject(ShellState.data) || {} : {};

      return {
        settings: settingsData,
        state: {
          doNotDisturb: NotificationService.doNotDisturb,
          octaliaPerformanceMode: PowerProfileService.octaliaPerformanceMode,
          barVisible: BarService.isVisible,
          openedPanel: PanelService.openedPanel?.objectName || "",
          lockScreenActive: PanelService.lockScreen?.active || false,
          wallpapers: WallpaperService.getWallpapersEffectiveMap(),
          desktopWidgetsEditMode: DesktopWidgetRegistry.editMode || false,
          // -------------
          display: shellStateData.display || {},
          notificationsState: shellStateData.notificationsState || {},
          changelogState: shellStateData.changelogState || {},
          colorSchemesList: shellStateData.colorSchemesList || {},
          ui: shellStateData.ui || {}
        }
      };
    } catch (error) {
      Logger.e("Settings", "Failed to build state snapshot:", error);
      return null;
    }
}
