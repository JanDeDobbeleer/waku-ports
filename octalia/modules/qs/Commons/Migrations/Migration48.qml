import "Migrations.js" as Migrations
import QtQuick 6.10

QtObject {
  id: root

  // Migrate battery thresholds from notifications to systemMonitor
  function migrate(adapter: var, logger: var, rawJson: var): bool {
    return Migrations.migrate48(adapter, logger, rawJson);
  }
}
