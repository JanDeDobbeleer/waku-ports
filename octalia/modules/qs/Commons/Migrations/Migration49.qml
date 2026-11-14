import "Migrations.js" as Migrations
import QtQuick 6.10
import qs.Commons
import qs.compat

QtObject {
  id: root

  // Remove old launcher_app_usage.json (usage tracking moved to ShellState)
  function migrate(adapter: var, logger: var, rawJson: var): bool {
    return Migrations.migrate49(adapter, logger, rawJson, Settings, Os);
  }
}
