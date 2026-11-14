import "Migrations.js" as Migrations
import QtQuick 6.10

QtObject {
  id: root

  // Migrate keybinds from single strings to arrays of strings
  function migrate(adapter: var, logger: var, rawJson: var): bool {
    return Migrations.migrate50(adapter, logger, rawJson);
  }
}
