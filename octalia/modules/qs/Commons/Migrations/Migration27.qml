import "Migrations.js" as Migrations
import QtQuick 6.10

QtObject {
  id: root

  // Migrate from version < 27 to version 27
  // Converts settingsPanelAttachToBar boolean to settingsPanelMode string
  function migrate(adapter: var, logger: var, rawJson: var): bool {
    return Migrations.migrate27(adapter, logger, rawJson);
  }
}
