.pragma library

function loadChangelogState(root, ShellState, Logger) {
    try {
      const changelog = ShellState.getChangelogState();
      root.changelogLastSeenVersion = changelog.lastSeenVersion || "";

      // Migration is now handled in Settings.qml
      Logger.d("UpdateService", "Loaded changelog state from ShellState");
    } catch (error) {
      Logger.e("UpdateService", "Failed to load changelog state:", error);
    }
}

function executeSave(root, ShellState, Logger) {
    try {
      ShellState.setChangelogState({
                                     lastSeenVersion: root.changelogLastSeenVersion || ""
                                   });
      Logger.d("UpdateService", "Saved changelog state to ShellState");
      root.saveInProgress = false;

      // Check if another save was queued while we were saving
      if (root.pendingSave) {
        root._scheduleExecuteSave();
      }
    } catch (error) {
      Logger.e("UpdateService", "Failed to save changelog state:", error);
      root.saveInProgress = false;
    }
}

function parseVersionParts(version, root) {
    const clean = root.normalizeVersion(version);
    if (!clean)
      return [];
    return clean.split(/[^0-9]+/).filter(part => part.length > 0).map(part => parseInt(part));
}

function openWhenReady(root, Quickshell, PanelService, Logger) {
    if (!root.popupScheduled)
      return;

    if (!Quickshell.screens || Quickshell.screens.length === 0) {
      return;
    }

    let targetScreen = root.viewChangelogTargetScreen;

    if (targetScreen) {
      // Explicit screen requested - validate it
      if (!PanelService.canShowPanelsOnScreen(targetScreen)) {
        Logger.w("UpdateService", "Changelog cannot be shown on screen without bar:", targetScreen.name);
        root.popupScheduled = false;
        root.viewChangelogTargetScreen = null;
        return;
      }
    } else {
      // No explicit screen - find one that can show panels
      targetScreen = PanelService.findScreenForPanels();
      if (!targetScreen) {
        Logger.w("UpdateService", "No screen available to show changelog");
        root.popupScheduled = false;
        return;
      }
    }

    const panel = PanelService.getPanel("changelogPanel", targetScreen);
    if (!panel) {
      // Panel not found yet. Wait for popupMenuWindowRegistered signal.
      // This avoids the memory leak (#1306).
      Logger.d("UpdateService", "Waiting for changelogPanel on screen:", targetScreen.name);
      return;
    }

    panel.open();
    root.popupScheduled = false;
    root.lastShownVersion = root.changelogCurrentVersion;
    root.viewChangelogTargetScreen = null;
}

function observeUpgradeRequest(request, done, toVersion, root, Logger, I18n) {
    request.onreadystatechange = function () {
      if (request.readyState === done) {
        Logger.d("UpdateService", "Request completed with status:", request.status);
        Logger.d("UpdateService", "Response text length:", request.responseText ? request.responseText.length : 0);

        if (request.status >= 200 && request.status < 300) {
          root.releaseContent = request.responseText || "";
          Logger.d("UpdateService", "Successfully fetched upgrade log");
          root.fetchError = "";
          root.openWhenReady();
        } else {
          Logger.w("UpdateService", "Failed to fetch upgrade log, status:", request.status);
          root.releaseContent = "";

          if (request.status === 404) {
            // Changelog not available for this version range - skip silently
            Logger.w("UpdateService", "Changelog not found, skipping display");
            root.fetchError = "";
            root.popupScheduled = false;
            root.markChangelogSeen(toVersion);
          } else {
            // Network error or server issue - show error to user
            root.fetchError = I18n.tr("changelog.error.fetch-failed");
            root.openWhenReady();
          }
        }
      }
    };
}

function onPopupMenuWindowRegistered(screen, root) {
      if (root.popupScheduled) {
        if (!root.viewChangelogTargetScreen || root.viewChangelogTargetScreen.name === screen.name) {
          root.openWhenReady();
        }
      }
}

function compareVersions(a, b, root) {
    var i;
    if (a === b)
      return 0;
    const partsA = root.parseVersionParts(a);
    const partsB = root.parseVersionParts(b);
    const length = Math.max(partsA.length, partsB.length);
    for (i = 0; i < length; i++) {
      const valA = partsA[i] || 0;
      const valB = partsB[i] || 0;
      if (valA > valB)
        return 1;
      if (valA < valB)
        return -1;
    }
    return 0;
}
