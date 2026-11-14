import "Migrations.js" as Migrations
import QtQuick 6.10

QtObject {
  /**
  * Migration 45: Migrate 'floating' bar setting to 'barType'
  */
  function migrate(adapter: var, logger: var, rawJson: var): bool {
    return Migrations.migrate45(adapter, logger, rawJson);
  }
}
