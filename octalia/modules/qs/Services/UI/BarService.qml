pragma Singleton

import "BarServiceUtils.js" as BarServiceUtils

import QtQuick 6.10
import Quickshell
import qs.Commons
import qs.Services.Compositor
import qs.Services.UI
import qs.compat

Singleton {
  id: root

  property bool isVisible: true

  // Computed visibility that factors in compositor overview state
  readonly property bool effectivelyVisible: {
    if (!isVisible) {
      return false;
    }
    if (Settings.data.bar.hideOnOverview && CompositorService.overviewActive) {
      return false;
    }
    return true;
  }

  property var readyBars: ({})

  // Revision counter - increment when widget list structure changes (add/remove/reorder)
  // This triggers Bar.qml to re-sync its ListModels
  property int widgetsRevision: 0

  // Registry to store actual widget instances
  // Key format: "screenName|section|widgetId|index"
  property var widgetInstances: ({})

  signal activeWidgetsChanged
  signal barReadyChanged(string screenName)
  signal barAutoHideStateChanged(string screenName, bool hidden)
  signal barHoverStateChanged(string screenName, bool hovered)

  // Track if a popup menu is open from the bar (prevents auto-hide)
  property bool popupOpen: false

  // Auto-hide state per screen: { screenName: { hovered: bool, hidden: bool } }
  property var screenAutoHideState: ({})

  // Get or create auto-hide state for a screen
  function getOrCreateAutoHideState(screenName: var): var {
    return BarServiceUtils.getOrCreateAutoHideState(root, Settings, screenName);
  }

  // Set hover state for a screen
  function setScreenHovered(screenName: var, hovered: var): void {
    BarServiceUtils.setAutoHideState(root, Settings, screenName, "hovered", hovered);
  }

  // Set hidden state for a screen
  function setScreenHidden(screenName: var, hidden: var): void {
    BarServiceUtils.setAutoHideState(root, Settings, screenName, "hidden", hidden);
  }

  // Check if bar is hidden on a screen
  function isBarHidden(screenName: var): var {
    var state = screenAutoHideState[screenName];
    return state ? state.hidden : false;
  }

  // Check if bar is hovered on a screen
  function isBarHovered(screenName: var): var {
    var state = screenAutoHideState[screenName];
    return state ? state.hovered : false;
  }

  // Toggle bar visibility. In auto-hide mode, toggles the per-screen hidden
  // state without touching isVisible (so hover-to-show still works).
  // For non-auto-hide screens, toggles the global isVisible flag.
  function toggleVisibility() {
    var screenName;
    // Check if any auto-hide screen is currently visible
    var anyAutoHideVisible = false;
    var hasAutoHideScreens = false;
    for (screenName in screenAutoHideState) {
      if (Settings.getBarDisplayModeForScreen(screenName) === "auto_hide") {
        hasAutoHideScreens = true;
        if (!screenAutoHideState[screenName].hidden) {
          anyAutoHideVisible = true;
          break;
        }
      }
    }

    // Toggle auto-hide screens (per-screen hidden state only)
    if (hasAutoHideScreens) {
      for (screenName in screenAutoHideState) {
        if (Settings.getBarDisplayModeForScreen(screenName) === "auto_hide") {
          setScreenHidden(screenName, anyAutoHideVisible);
        }
      }
    }

    // Only toggle global visibility when no auto-hide screens exist,
    // otherwise it would permanently disable hover-to-show
    if (!hasAutoHideScreens) {
      isVisible = !isVisible;
    }
  }

  // Show bar. In auto-hide mode, un-hides on screens with auto-hide enabled.
  // The bar stays visible until the user hovers and moves away.
  function show() {
    var screenName;
    // Show auto-hide screens
    for (screenName in screenAutoHideState) {
      if (Settings.getBarDisplayModeForScreen(screenName) === "auto_hide") {
        setScreenHidden(screenName, false);
      }
    }
    // Set global visibility (affects non-auto-hide screens)
    isVisible = true;
  }

  // Hide bar. In auto-hide mode, sets per-screen hidden state without touching
  // isVisible so hover-to-show still works. For non-auto-hide screens, sets
  // global visibility to false.
  function hide() {
    var screenName;
    var hasAutoHideScreens = false;
    for (screenName in screenAutoHideState) {
      if (Settings.getBarDisplayModeForScreen(screenName) === "auto_hide") {
        setScreenHidden(screenName, true);
        hasAutoHideScreens = true;
      }
    }
    // Only set global visibility off when no auto-hide screens exist,
    // otherwise it would permanently disable hover-to-show
    if (!hasAutoHideScreens) {
      isVisible = false;
    }
  }

  // Temporarily show the bar, then auto-hide after the configured delay.
  // Uses the same pattern as workspace switch: show, then emit unhover
  // to start the hide timer.
  function peek() {
    var screenName;
    for (screenName in screenAutoHideState) {
      if (Settings.getBarDisplayModeForScreen(screenName) === "auto_hide") {
        setScreenHidden(screenName, false);
        if (!isBarHovered(screenName)) {
          barHoverStateChanged(screenName, false);
        }
      }
    }
  }

  Component.onCompleted: {
    Logger.i("BarService", "Service started");
  }

  // Bump widgetsRevision when settings are reloaded from an external file change
  // so Bar.qml re-syncs its widget ListModels with the updated widget configuration
  Connections {
    target: Settings
    function onSettingsReloaded() {
      Logger.d("BarService", "Settings reloaded externally, bumping widgetsRevision");
      root.widgetsRevision++;
    }
  }

  // update bar's hidden state when mode changes
  Connections {
    target: Settings.data.bar
    function onDisplayModeChanged() {
      var displayMode;
      Logger.d("BarService", "Display mode changed to:", Settings.data.bar.displayMode);

      // Only affect screens without displayMode overrides
      for (let screenName in root.screenAutoHideState) {
        if (!Settings.hasScreenOverride(screenName, "displayMode")) {
          displayMode = Settings.getBarDisplayModeForScreen(screenName);
          if (displayMode === "auto_hide") {
            root.setScreenHidden(screenName, true);
          } else {
            if (root.screenAutoHideState[screenName].hidden) {
              root.setScreenHidden(screenName, false);
            }
          }
        }
      }
    }

    function onScreenOverridesChanged() {
      var displayMode;
      Logger.d("BarService", "Screen overrides changed, re-evaluating auto-hide states");

      // Re-evaluate auto-hide state for all screens
      for (let screenName in root.screenAutoHideState) {
        displayMode = Settings.getBarDisplayModeForScreen(screenName);
        if (displayMode === "auto_hide") {
          if (!root.screenAutoHideState[screenName].hidden) {
            root.setScreenHidden(screenName, true);
          }
        } else {
          if (root.screenAutoHideState[screenName].hidden) {
            root.setScreenHidden(screenName, false);
          }
        }
      }
    }
  }

  // Track last workspace ID to detect actual workspace changes
  property var lastWorkspaceId: null

  // Debounce rapid workspace switches to reduce load/unload races (SIGSEGV in QV4)
  property string _pendingWorkspaceScreen: ""

  Timer {
    id: workspaceDebounceTimer
    interval: 80
    repeat: false
    onTriggered: {
      var screen = root._pendingWorkspaceScreen;
      root._pendingWorkspaceScreen = "";
      if (screen) {
        root.setScreenHidden(screen, false);
        if (!root.isBarHovered(screen)) {
          root.barHoverStateChanged(screen, false);
        }
      }
    }
  }

  // Workspace switch handler - directly show bar on the focused workspace screen
  Connections {
    target: CompositorService
    function onWorkspaceChanged() {
      BarServiceUtils.onWorkspaceChanged(root, Settings, CompositorService, Logger, workspaceDebounceTimer);
    }
  }

  // Function for the Bar to call when it's ready
  function registerBar(screenName: var): void {
    if (!readyBars[screenName]) {
      readyBars[screenName] = true;
      Logger.d("BarService", "Bar is ready on screen:", screenName);
      barReadyChanged(screenName);
    }
  }

  // Function for the Dock to check if the bar is ready
  function isBarReady(screenName: var): var {
    return readyBars[screenName] || false;
  }

  // Register a widget instance
  function registerWidget(screenName: var, section: var, widgetId: var, index: var, instance: var): void {
    const key = [screenName, section, widgetId, index].join("|");
    widgetInstances[key] = {
      "key": key,
      "screenName": screenName,
      "section": section,
      "widgetId": widgetId,
      "index": index,
      "instance": instance
    };

    Logger.d("BarService", "Registered widget:", key);
    root.activeWidgetsChanged();
  }

  // Unregister a widget instance
  function unregisterWidget(screenName: var, section: var, widgetId: var, index: var): void {
    const key = [screenName, section, widgetId, index].join("|");
    BarServiceUtils.unregisterWidget(widgetInstances, key);
    Logger.d("BarService", "Unregistered widget:", key);
    root.activeWidgetsChanged();
  }

  // Lookup a specific widget instance (returns the actual QML instance)
  function lookupWidget(widgetId: var, screenName: var): var {
    return BarServiceUtils.lookupWidget(widgetInstances, widgetId, screenName, undefined, undefined);
  }

  function lookupWidgetInSection(widgetId: var, screenName: var, section: var, index: var): var {
    return BarServiceUtils.lookupWidget(widgetInstances, widgetId, screenName, section, index);
  }

  // Get all instances of a widget type
  function getAllWidgetInstances(widgetId: var, screenName: var): var {
    return BarServiceUtils.getAllWidgetInstances(widgetInstances, widgetId, screenName, undefined);
  }

  function getAllWidgetInstancesInSection(widgetId: var, screenName: var, section: var): var {
    return BarServiceUtils.getAllWidgetInstances(widgetInstances, widgetId, screenName, section);
  }

  // Get widget with full metadata
  function getWidgetWithMetadata(widgetId: var, screenName: var, section: var): var {
    return BarServiceUtils.getWidgetWithMetadata(widgetInstances, widgetId, screenName, section);
  }

  // Get all widgets in a specific section
  function getWidgetsBySection(section: var, screenName: var): var {
    return BarServiceUtils.getWidgetsBySection(widgetInstances, section, screenName);
  }

  // Get all registered widgets (for debugging)
  function getAllRegisteredWidgets(): var {
    return BarServiceUtils.getAllRegisteredWidgets(widgetInstances);
  }

  // Check if a widget type exists in a section
  function hasWidget(widgetId: var, section: var, screenName: var): bool {
    return BarServiceUtils.hasWidget(widgetInstances, widgetId, section, screenName);
  }

  // Get pill direction for a widget instance
  function getPillDirection(widgetInstance: var): bool {
    return BarServiceUtils.getPillDirection(widgetInstance, Logger);
  }

  // Helper to close any existing dialogs in a popup menu window
  function closeExistingDialogs(popupMenuWindow: var): void {
    BarServiceUtils.closeExistingDialogs(popupMenuWindow);
  }

  // Open widget settings dialog for a bar widget
  // Parameters:
  //   screen: The screen to show the dialog on
  //   section: Section id ("left", "center", "right")
  //   index: Widget index in section
  //   widgetId: Widget type id (e.g., "Volume")
  //   widgetData: Current widget settings object
  function openWidgetSettings(screen: var, section: var, index: var, widgetId: var, widgetData: var): void {
    // Get the popup menu window to use as parent (avoids clipping issues with bar height)
    var popupMenuWindow = PanelService.getPopupMenuWindow(screen);
    if (!popupMenuWindow) {
      Logger.e("BarService", "No popup menu window found for screen");
      return;
    }

    // Close any existing dialogs first to prevent stacking
    closeExistingDialogs(popupMenuWindow);

    if (PanelService.openedPanel) {
      PanelService.openedPanel.close();
    }

    var component = Qt.createComponent(ShellUrl.dir + "/modules/qs/Modules/Panels/Settings/Bar/BarWidgetSettingsDialog.qml");
    BarServiceUtils.openWidgetSettings(component, popupMenuWindow, screen, section, index, widgetId, widgetData, Settings, Logger, Component.Ready, Component.Error);
  }
}
