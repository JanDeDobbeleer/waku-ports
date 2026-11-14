import "Migrations.js" as Migrations
import QtQuick 6.10

QtObject {
  id: root

  function migrate(adapter: var, logger: var, rawJson: var): bool {
    return Migrations.migrate43(adapter, logger, rawJson);
  }
}
