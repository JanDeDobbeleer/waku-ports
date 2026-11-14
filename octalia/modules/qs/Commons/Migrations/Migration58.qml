import "Migrations.js" as Migrations
import QtQuick 6.10

QtObject {
  function migrate(adapter: var, logger: var, rawJson: var): bool {
    return Migrations.migrate58(adapter, logger, rawJson);
  }
}
