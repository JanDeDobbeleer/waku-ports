import "Migrations.js" as Migrations
import QtQuick 6.10
import Quickshell
import qs.Commons
import qs.compat

QtObject {
  id: root

  function migrate(adapter: var, logger: var, rawJson: var): bool {
    return Migrations.migrate44(adapter, logger, rawJson, Settings, Os, Quickshell);
  }
}
