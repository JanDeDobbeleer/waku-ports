pragma ComponentBehavior: Bound

import QtQuick 6.10
import Quickshell
import "Backgrounds/BackgroundHelpers.js" as BackgroundHelpers

import qs.Commons
import qs.Modules.MainScreen
import qs.Services.UI

// ------------------------------
// MainScreen for each screen (manages bar + all panels)
// Wrapped in Loader to optimize memory - only loads when screen needs it
Variants {
  model: Quickshell.screens
  delegate: Item {
    id: windowItem
    required property ShellScreen modelData

    property bool shouldBeActive: {
      var monitors;
      if (!modelData || !modelData.name) {
        return false;
      }

      let shouldLoad = true;
      if (!Settings.data.general.allowPanelsOnScreenWithoutBar) {
        // Check if bar is configured for this screen
        monitors = Settings.data.bar.monitors || [];
        shouldLoad = BackgroundHelpers.includesScreen(monitors, modelData?.name);
      }

      if (shouldLoad) {
        Logger.d("AllScreens", "Screen activated: ", modelData?.name);
      }
      return shouldLoad;
    }

    property bool windowLoaded: false

    // Main Screen loader - Bar and panels backgrounds
    Loader {
      id: windowLoader
      active: windowItem.shouldBeActive
      asynchronous: false

      property ShellScreen loaderScreen: windowItem.modelData

      onLoaded: {
        // Signal that window is loaded so exclusion zone can be created
        windowItem.windowLoaded = true;
      }

      sourceComponent: MainScreen {
        screen: windowLoader.loaderScreen
      }
    }

    // BarTriggerZone - thin invisible zone to reveal hidden bar
    // Always loaded when auto-hide is enabled (it's just 1px, no performance impact)
    Loader {
      active: {
        if (!windowItem.windowLoaded || !windowItem.shouldBeActive)
          return false;
        if (!BarService.effectivelyVisible)
          return false;
        if (Settings.getBarDisplayModeForScreen(windowItem.modelData?.name) !== "auto_hide")
          return false;

        // Check if bar is configured for this screen
        var monitors = Settings.data.bar.monitors || [];
        return BackgroundHelpers.includesScreen(monitors, windowItem.modelData?.name);
      }
      asynchronous: false

      sourceComponent: BarTriggerZone {
        screen: windowItem.modelData
      }

      onLoaded: {
        Logger.d("AllScreens", "BarTriggerZone created for", windowItem.modelData?.name);
      }
    }

    // BarExclusionZone - created after MainScreen has fully loaded
    // Note: Exclusion zone should NOT be affected by hideOnOverview setting.
    // When bar is hidden during overview, the exclusion zone should remain to prevent
    // windows from moving into the bar area. Auto-hide is handled by the component
    // itself via ExclusionMode.Ignore/Auto.
    Repeater {
      model: Settings.data.bar.barType === "framed" ? ["top", "bottom", "left", "right"] : [Settings.getBarPositionForScreen(windowItem.modelData?.name)]
      delegate: Loader {
        id: exclusionLoader
        required property var modelData
        active: {
          if (!windowItem.windowLoaded || !windowItem.shouldBeActive)
            return false;

          // Check if bar is configured for this screen
          var monitors = Settings.data.bar.monitors || [];
          return BackgroundHelpers.includesScreen(monitors, windowItem.modelData?.name);
        }
        asynchronous: false

        sourceComponent: BarExclusionZone {
          screen: windowItem.modelData
          edge: exclusionLoader.modelData
        }

        onLoaded: {
          Logger.d("AllScreens", "BarExclusionZone (" + modelData + ") created for", windowItem.modelData?.name);
        }
      }
    }

    // PopupMenuWindow - reusable popup window for both tray menus and context menus
    // Stays alive when bar is hidden to avoid Wayland surface churn crashes.
    // PopupMenuWindow manages its own visibility internally.
    Loader {
      active: {
        // Desktop widgets edit mode needs popup window on ALL screens
        if (DesktopWidgetRegistry.editMode && Settings.data.desktopWidgets.enabled) {
          return true;
        }

        // Normal bar-based condition
        if (!windowItem.windowLoaded || !windowItem.shouldBeActive)
          return false;

        // Check if bar is configured for this screen
        var monitors = Settings.data.bar.monitors || [];
        return BackgroundHelpers.includesScreen(monitors, windowItem.modelData?.name);
      }
      asynchronous: false

      sourceComponent: PopupMenuWindow {
        screen: windowItem.modelData
      }

      onLoaded: {
        Logger.d("AllScreens", "PopupMenuWindow created for", windowItem.modelData?.name);
      }
    }
  }
}
