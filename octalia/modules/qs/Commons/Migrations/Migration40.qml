import "Migrations.js" as Migrations
import QtQuick 6.10

QtObject {
  id: root

  // List of all template IDs that existed as booleans in the old format
  readonly property var templateIds: ["gtk", "qt", "kcolorscheme", "alacritty", "kitty", "ghostty", "foot", "wezterm", "fuzzel", "discord", "pywalfox", "vicinae", "walker", "code", "spicetify", "telegram", "cava", "yazi", "emacs", "niri", "hyprland", "mango", "zed", "helix", "zenBrowser"]

  function migrate(adapter: var, logger: var, rawJson: var): bool {
    return Migrations.migrate40(adapter, logger, rawJson, templateIds);
  }
}
