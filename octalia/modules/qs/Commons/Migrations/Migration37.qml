import "Migrations.js" as Migrations
import QtQuick 6.10

QtObject {
  id: root

  // Rename WiFi widgets/shortcuts to Network
  function migrate(adapter: var, logger: var, rawJson: var): bool {
    return Migrations.migrate37(adapter, logger, rawJson);
  }
}
