import QtQuick 6.10
import Quickshell
import qs.Commons
import "CommandProviderUtils.js" as CommandProviderUtils

Item {
  property var launcher: null
  property string name: I18n.tr("common.command")
  property string iconMode: Settings.data.appLauncher.iconMode

  function handleCommand(query: string): bool {
    return query.startsWith(">cmd");
  }

  function commands(): var {
    return [
          {
            "name": ">cmd",
            "description": I18n.tr("launcher.providers.command-description"),
            "icon": iconMode === "tabler" ? "terminal" : "utilities-terminal",
            "isTablerIcon": true,
            "isImage": false,
            "onActivate": function () {
              CommandProviderUtils.setSearchText(launcher, ">cmd ");
            }
          }
        ];
  }

  function getResults(query: string): var {
    if (!query.startsWith(">cmd"))
      return [];

    return [CommandProviderUtils.commandResult(query, launcher, Quickshell, Logger, I18n.tr("common.command"), I18n.tr("launcher.providers.command-description"), iconMode === "tabler" ? "terminal" : "utilities-terminal")];
  }
}
