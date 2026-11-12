import "Migrations.js" as Migrations
import QtQuick 6.10

QtObject {
  id: root

  // Migrate TaskbarGrouped widgets to Workspace with showApplications: true
  function migrate(adapter: var, logger: var, rawJson: var): bool {
    return Migrations.migrate28(adapter, logger, rawJson);
  }
}
