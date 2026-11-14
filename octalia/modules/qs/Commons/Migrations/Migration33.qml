import "Migrations.js" as Migrations
import QtQuick 6.10

QtObject {
  id: root

  // Migrate wallpaper.randomEnabled to wallpaper.wallpaperChangeMode
  function migrate(adapter: var, logger: var, rawJson: var): bool {
    return Migrations.migrate33(adapter, logger, rawJson);
  }
}
