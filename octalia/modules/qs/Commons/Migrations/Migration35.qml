import "Migrations.js" as Migrations
import QtQuick 6.10

QtObject {
  id: root

  // Migrate bar.transparent to bar.backgroundOpacity + bar.useSeparateOpacity
  function migrate(adapter: var, logger: var, rawJson: var): bool {
    return Migrations.migrate35(adapter, logger, rawJson);
  }
}
