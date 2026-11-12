import "Migrations.js" as Migrations
import QtQuick 6.10

QtObject {
  id: root

  // Add default keybinds (1-6) to session menu power options if none are defined
  function migrate(adapter: var, logger: var, rawJson: var): bool {
    return Migrations.migrate53(adapter, logger, rawJson);
  }
}
