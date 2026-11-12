pragma Singleton

import "UpdateServiceUtils.js" as UpdateServiceUtils

import QtQuick 6.10
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.compat

Singleton {
  id: root

  // Version properties
  readonly property string baseVersion: "4.7.8"
  readonly property bool isDevelopment: true
  readonly property string developmentSuffix: "-git"
  readonly property string currentVersion: `v${!isDevelopment ? baseVersion : baseVersion + developmentSuffix}`

  // Telemetry was introduced in this version - users upgrading from earlier need to see the wizard
  readonly property string telemetryIntroVersion: "4.0.2"

  // URLs
  readonly property string discordUrl: "https://discord.noctalia.dev"
  readonly property string feedbackUrl: Quickshell.env("OCTALIA_CHANGELOG_FEEDBACK_URL") || ""
  readonly property string upgradeLogBaseUrl: Quickshell.env("OCTALIA_UPGRADELOG_URL") || "https://api.noctalia.dev/upgradelog"

  // Changelog properties
  property bool initialized: false
  property bool changelogPending: false
  property string changelogFromVersion: ""
  property string changelogToVersion: ""
  property string previousVersion: ""
  property string changelogCurrentVersion: ""
  property string releaseContent: ""
  property string lastShownVersion: ""
  property bool popupScheduled: false
  property string fetchError: ""
  property string changelogLastSeenVersion: ""
  property bool changelogStateLoaded: false
  property bool pendingShowRequest: false
  property bool pendingTelemetryWizardCheck: false

  // Fix for FileView race condition
  property bool saveInProgress: false
  property bool pendingSave: false
  property int saveDebounceTimer: 0

  Connections {
    target: PanelService
    function onPopupMenuWindowRegistered(screen: var) {
      UpdateServiceUtils.onPopupMenuWindowRegistered(screen, root);
    }
  }

  signal popupQueued(string fromVersion, string toVersion)
  signal telemetryWizardNeeded

  function init() {
    if (initialized)
      return;

    initialized = true;
    Logger.i("UpdateService", "Version:", root.currentVersion);

    // Load changelog state from ShellState
    Qt.callLater(() => {
                   if (typeof ShellState !== 'undefined' && ShellState.isLoaded) {
                     loadChangelogState();
                   }
                 });
  }

  Connections {
    target: typeof ShellState !== 'undefined' ? ShellState : null
    function onIsLoadedChanged() {
      if (ShellState.isLoaded) {
        root.loadChangelogState();
      }
    }
  }

  // Debounce timer to prevent rapid successive saves
  Timer {
    id: saveDebouncer
    interval: 300
    repeat: false
    onTriggered: root.executeSave()
  }

  function handleChangelogRequest() {
    const fromVersion = changelogFromVersion || "";
    const toVersion = changelogToVersion || "";

    if (Settings.shouldOpenSetupWizard) {
      // If you'll see the setup wizard then you don't need to see the changelog
      markChangelogSeen(toVersion);
      return;
    }

    if (!toVersion)
      return;

    if (popupScheduled && changelogCurrentVersion === toVersion)
      return;

    if (!popupScheduled && lastShownVersion === toVersion)
      return;

    previousVersion = fromVersion;
    changelogCurrentVersion = toVersion;

    // Fetch the upgrade log from the server
    fetchUpgradeLog(fromVersion, toVersion);

    popupScheduled = true;
    root.popupQueued(previousVersion, changelogCurrentVersion);

    clearChangelogRequest();
  }

  function fetchUpgradeLog(fromVersion: var, toVersion: var): void {
    // Normalize and ensure "v" prefix for consistent URL format
    let from = ensureVersionPrefix(fromVersion || changelogLastSeenVersion || "3.0.0");
    let to = ensureVersionPrefix(toVersion);

    // Strip -git suffix
    from = from.replace(root.developmentSuffix, "");
    to = to.replace(root.developmentSuffix, "");

    // 'from' always needs to be before 'to' (use semantic comparison)
    if (compareVersions(from, to) >= 0) {
      from = "v3.0.0";
    }

    const url = `${upgradeLogBaseUrl}/${from}/${to}`;
    Logger.i("UpdateService", "Fetching upgrade log:", url);
    const request = new XMLHttpRequest();
    UpdateServiceUtils.observeUpgradeRequest(request, XMLHttpRequest.DONE, toVersion, root, Logger, I18n);
    request.open("GET", url);
    request.send();
  }

  function normalizeVersion(version: var): string {
    if (!version)
      return "";
    return version.startsWith("v") ? version.substring(1) : version;
  }

  function ensureVersionPrefix(version: var): string {
    if (!version)
      return "";
    return version.startsWith("v") ? version : "v" + version;
  }

  function parseVersionParts(version: var): var {
    return UpdateServiceUtils.parseVersionParts(version, root);
  }

  function compareVersions(a: var, b: var): int {
    return UpdateServiceUtils.compareVersions(a, b, root);
  }

  // Check if user is upgrading from a version before telemetry was introduced
  function shouldShowTelemetryWizard(): bool {
    if (!changelogStateLoaded)
      return false;
    if (Settings.isFreshInstall)
      return false;
    if (Settings.shouldOpenSetupWizard)
      return false;

    // No previous version recorded but settings exist - assume upgrading from old version
    // (e.g., user deleted shell-state.json but has existing settings)
    if (!changelogLastSeenVersion || changelogLastSeenVersion === "")
      return true;

    // Check if last seen version is before telemetry introduction
    return compareVersions(changelogLastSeenVersion, telemetryIntroVersion) < 0;
  }

  // Called by shell.qml to check for telemetry wizard after init
  // If state isn't loaded yet, sets a pending flag and emits telemetryWizardNeeded later
  function checkTelemetryWizardOrChangelog() {
    Logger.d("UpdateService", "checkTelemetryWizardOrChangelog called, stateLoaded:", changelogStateLoaded);
    if (!changelogStateLoaded) {
      // State not loaded yet, set pending flags
      Logger.d("UpdateService", "State not loaded yet, setting pending flags");
      pendingTelemetryWizardCheck = true;
      pendingShowRequest = true;
      return;
    }

    // State is already loaded, check immediately
    const needsTelemetryWizard = shouldShowTelemetryWizard();
    Logger.d("UpdateService", "shouldShowTelemetryWizard:", needsTelemetryWizard, "lastSeenVersion:", changelogLastSeenVersion);
    if (needsTelemetryWizard) {
      Logger.i("UpdateService", "Emitting telemetryWizardNeeded signal");
      root.telemetryWizardNeeded();
    } else {
      showLatestChangelog();
    }
  }

  function openWhenReady(): void {
    UpdateServiceUtils.openWhenReady(root, Quickshell, PanelService, Logger);
  }

  function openDiscord() {
    if (!discordUrl)
      return;
    Os.open(discordUrl);
  }

  function openFeedbackForm() {
    if (!feedbackUrl)
      return;
    Os.open(feedbackUrl);
  }

  function showLatestChangelog() {
    if (!currentVersion)
      return;

    if (!changelogStateLoaded) {
      pendingShowRequest = true;
      return;
    }

    // Normalize versions for comparison (strip -git, ensure v prefix)
    const lastSeen = ensureVersionPrefix(changelogLastSeenVersion.replace(developmentSuffix, ""));
    const target = ensureVersionPrefix(currentVersion.replace(developmentSuffix, ""));

    if (lastSeen === target)
      return;

    if (!Settings.data.general.showChangelogOnStartup) {
      // user has opted out of seeing changelogs, mark as seen
      markChangelogSeen(target);
      return;
    }

    changelogFromVersion = lastSeen;
    changelogToVersion = target;
    changelogPending = true;
    handleChangelogRequest();
  }

  // Manual changelog viewing (e.g., from Settings > About > View Changelog)
  // Shows all changes since v3.0.0, unlike showLatestChangelog() which uses lastSeenVersion
  property var viewChangelogTargetScreen: null

  function viewChangelog(screen: var): void {
    if (!currentVersion)
      return;

    const target = ensureVersionPrefix(currentVersion.replace(developmentSuffix, ""));
    const fromVersion = "v3.8.2";

    previousVersion = fromVersion;
    changelogCurrentVersion = target;
    viewChangelogTargetScreen = screen || null;
    popupScheduled = true;
    fetchUpgradeLog(fromVersion, target);
  }

  function clearChangelogRequest() {
    changelogPending = false;
    changelogFromVersion = "";
    changelogToVersion = "";
  }

  function markChangelogSeen(version: var): void {
    if (!version)
      return;
    changelogLastSeenVersion = version;
    debouncedSaveChangelogState();
  }

  function loadChangelogState() {
    UpdateServiceUtils.loadChangelogState(root, ShellState, Logger);
    changelogStateLoaded = true;

    // Handle pending telemetry wizard check first
    if (pendingTelemetryWizardCheck) {
      pendingTelemetryWizardCheck = false;
      if (shouldShowTelemetryWizard()) {
        root.telemetryWizardNeeded();
      } else if (pendingShowRequest) {
        pendingShowRequest = false;
        Qt.callLater(root.showLatestChangelog);
      }
      return;
    }

    if (pendingShowRequest) {
      pendingShowRequest = false;
      Qt.callLater(root.showLatestChangelog);
    }
  }

  function debouncedSaveChangelogState() {
    // Queue a save and restart the debounce timer
    pendingSave = true;
    saveDebouncer.restart();
  }

  function executeSave() {
    if (!pendingSave)
      return;

    // Prevent concurrent saves
    if (saveInProgress) {
      // Retry after a short delay
      saveDebouncer.start();
      return;
    }

    pendingSave = false;
    saveInProgress = true;

    UpdateServiceUtils.executeSave(root, ShellState, Logger);
  }

  function _scheduleExecuteSave(): void {
    Qt.callLater(executeSave);
  }

  function saveChangelogState() {
    // Immediate save (backward compatibility)
    debouncedSaveChangelogState();
  }
}
