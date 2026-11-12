import QtQuick 6.10
import qs.Commons
import qs.Services.Keyboard
import "EmojiProviderUtils.js" as EmojiProviderUtils

Item {
  id: root

  // Provider metadata
  property string name: I18n.tr("launcher.providers.emoji")
  property var launcher: null
  property string iconMode: Settings.data.appLauncher.iconMode
  property bool handleSearch: false
  property string supportedLayouts: "grid" // Only grid layout for emoji
  property int preferredGridColumns: 7 // More columns for compact emoji display
  property real preferredGridCellRatio: 1.15 // Slightly taller than wide to accommodate label
  property bool supportsAutoPaste: true // Emoji can be auto-pasted
  property bool ignoreDensity: false // Emoji should scale with launcher density

  property string selectedCategory: "recent"
  property bool showsCategories: true // Default to showing categories

  // Empty state message for category view
  readonly property string emptyBrowsingMessage: selectedCategory === "recent" ? I18n.tr("launcher.providers.emoji-no-recent") : ""

  property var categoryIcons: ({
                                 "all": "apps",
                                 "recent": "clock",
                                 "people": "user",
                                 "animals": "paw",
                                 "nature": "leaf",
                                 "food": "apple",
                                 "activity": "run",
                                 "travel": "plane",
                                 "objects": "home",
                                 "symbols": "star",
                                 "flags": "flag"
                               })

  property var categories: ["all", "recent", "people", "animals", "nature", "food", "activity", "travel", "objects", "symbols", "flags"]

  function getCategoryName(category: string): string {
    const names = {
      "all": I18n.tr("launcher.categories.all"),
      "recent": I18n.tr("launcher.categories.emoji-recent"),
      "people": I18n.tr("launcher.categories.emoji-people"),
      "animals": I18n.tr("launcher.categories.emoji-animals"),
      "nature": I18n.tr("launcher.categories.emoji-nature"),
      "food": I18n.tr("launcher.categories.emoji-food"),
      "activity": I18n.tr("launcher.categories.emoji-activity"),
      "travel": I18n.tr("launcher.categories.emoji-travel"),
      "objects": I18n.tr("launcher.categories.emoji-objects"),
      "symbols": I18n.tr("launcher.categories.emoji-symbols"),
      "flags": I18n.tr("launcher.categories.emoji-flags")
    };
    return names[category] || category;
  }

  // Force update results when emoji service loads
  Connections {
    target: EmojiService
    function onLoadedChanged() {
      if (EmojiService.loaded && root.launcher) {
        root.launcher.updateResults();
      }
    }
  }

  // Initialize provider
  function init() {
    Logger.d("EmojiProvider", "Initialized");
  }

  function selectCategory(category: string): void {
    selectedCategory = category;
    if (launcher) {
      launcher.updateResults();
    }
  }

  function onOpened() {
    // Always reset to "recent" category when opening
    selectedCategory = "recent";
  }

  // Check if this provider handles the command
  function handleCommand(searchText: string): bool {
    return searchText.startsWith(">emoji");
  }

  // Return available commands when user types ">"
  function commands(): var {
    return [
          {
            "name": ">emoji",
            "description": I18n.tr("launcher.providers.emoji-search-description"),
            "icon": iconMode === "tabler" ? "mood-smile" : "face-smile",
            "isTablerIcon": true,
            "isImage": false,
            "onActivate": function () {
              launcher.setSearchText(">emoji ");
            }
          }
        ];
  }

  // Get search results
  function getResults(searchText: string): var {
    if (!searchText.startsWith(">emoji")) {
      return [];
    }

    if (!EmojiService.loaded) {
      return [
            {
              "name": I18n.tr("launcher.providers.emoji-loading"),
              "description": I18n.tr("launcher.providers.emoji-loading-description"),
              "icon": iconMode === "tabler" ? "refresh" : "view-refresh",
              "isTablerIcon": true,
              "isImage": false,
              "onActivate": function () {}
            }
          ];
    }

    var query = searchText.slice(6).trim();
    var emojis = [];

    if (query !== "" || selectedCategory === "all") {
      emojis = EmojiService.search(query);
    } else {
      emojis = EmojiService.getEmojisByCategory(selectedCategory);
    }
    return EmojiProviderUtils.formatEntries(emojis, root, EmojiService, launcher);
  }

}
