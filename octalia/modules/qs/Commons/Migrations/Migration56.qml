import "Migrations.js" as Migrations
import QtQuick 6.10
import Quickshell
import qs.Commons

QtObject {
  id: root

  function migrate(adapter: var, logger: var, rawJson: var): bool {
    return Migrations.migrate56(adapter, logger, rawJson, Settings, Quickshell);
  }
}
