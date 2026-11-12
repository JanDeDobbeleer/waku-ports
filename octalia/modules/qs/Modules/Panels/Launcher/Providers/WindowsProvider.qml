import QtQuick 6.10
import qs.Commons
import qs.Services.Compositor
import "WindowsProviderUtils.js" as WindowsProviderUtils

Item {
  id: root

  property string name: I18n.tr("common.windows")
  property var launcher: null
  property bool handleSearch: Settings.data.appLauncher.enableWindowsSearch
  property string supportedLayouts: "list"
  property string iconMode: Settings.data.appLauncher.iconMode

  function init(): void {
    Logger.d("WindowsProvider", "Initialized");
  }

  // Check if this provider handles the command
  function handleCommand(searchText: string): bool {
    return searchText.startsWith(">win");
  }

  // Return available commands when user types ">"
  function commands(): var {
    return [
          {
            "name": ">win",
            "description": I18n.tr("launcher.providers.windows-search-description"),
            "icon": iconMode === "tabler" ? "app-window" : "preferences-system-windows",
            "isTablerIcon": true,
            "isImage": false,
            "onActivate": function () {
              WindowsProviderUtils.setSearchText(launcher, ">win ");
            }
          }
        ];
  }

  function getResults(query: string): var {
    var appEntry, entry, i, iconName, j, score, searchTerm, win;
    if (!query)
      return [];

    var trimmed = query.trim();

    // Handle command mode: ">win" or ">win <search>"
    var isCommandMode = trimmed.startsWith(">win");
    if (isCommandMode) {
      // Extract search term after ">win "
      searchTerm = trimmed.substring(4).trim();
      // In command mode, show all windows if no search term
      if (searchTerm.length === 0) {
        return getAllWindows();
      }
      trimmed = searchTerm;
    } else {
      // Regular search mode - require at least 2 chars
      if (trimmed.length < 2)
        return [];
    }

    var items = [];

    // Collect all windows from CompositorService
    for (i = 0; i < WindowsProviderUtils.windowCount(CompositorService); i++) {
      win = WindowsProviderUtils.windowAt(CompositorService, i);
      items.push({
                   "id": win.id,
                   "title": win.title || "",
                   "appId": win.appId || "",
                   "workspaceId": win.workspaceId,
                   "isFocused": win.isFocused,
                   "searchText": (win.title + " " + win.appId).toLowerCase()
                 });
    }

    // Fuzzy search on title and appId
    var results = FuzzySort.go(trimmed, items, {
                                 "keys": ["title", "appId"],
                                 "limit": 10
                               });

    // Map to launcher items
    var launcherItems = [];
    for (j = 0; j < results.length; j++) {
      entry = results[j].obj;
      score = results[j].score;

      // Get icon name from DesktopEntry if available, otherwise use appId
      iconName = entry.appId;
      appEntry = WindowsProviderUtils.iconForApp(ThemeIcons, entry.appId);
      if (appEntry) {
        iconName = appEntry;
      }

      launcherItems.push({
                           "name": entry.title || entry.appId,
                           "description": entry.appId,
                           "icon": iconName || "application-x-executable",
                           "isTablerIcon": false,
                           "badgeIcon": "app-window",
                           "_score": score,
                           "provider": root,
                           "windowId": entry.id,
                           "onActivate": createActivateHandler(entry)
                         });
    }

    return launcherItems;
  }

  function getAllWindows(): var {
    var appEntry, i, iconName, win;
    var launcherItems = [];

    for (i = 0; i < WindowsProviderUtils.windowCount(CompositorService); i++) {
      win = WindowsProviderUtils.windowAt(CompositorService, i);

      iconName = win.appId;
      appEntry = WindowsProviderUtils.iconForApp(ThemeIcons, win.appId);
      if (appEntry) {
        iconName = appEntry;
      }

      launcherItems.push({
                           "name": win.title || win.appId,
                           "description": win.appId,
                           "icon": iconName || "application-x-executable",
                           "isTablerIcon": false,
                           "badgeIcon": "app-window",
                           "_score": 0,
                           "provider": root,
                           "windowId": win.id,
                           "onActivate": createActivateHandler({
                                                                 "id": win.id
                                                               })
                         });
    }

    return launcherItems;
  }

  function createActivateHandler(windowEntry: var): var {
    return function () {
      if (launcher)
        launcher.close();

      Qt.callLater(() => {
        var i, win;
                     // Find the actual window object to pass to focusWindow
                     for (i = 0; i < WindowsProviderUtils.windowCount(CompositorService); i++) {
                       win = WindowsProviderUtils.windowAt(CompositorService, i);
                       if (win.id === windowEntry.id) {
                         CompositorService.focusWindow(win);
                         break;
                       }
                     }
                   });
    };
  }
}
