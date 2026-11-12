import "Migrations.js" as Migrations
import QtQuick 6.10
import qs.Commons
import qs.compat

QtObject {
  id: root

  // Clear legacy emoji usage cache to adopt new format
  function migrate(adapter: var, logger: var, rawJson: var): bool {
    return Migrations.migrate36(adapter, logger, rawJson, Settings, Os);
  }
}
