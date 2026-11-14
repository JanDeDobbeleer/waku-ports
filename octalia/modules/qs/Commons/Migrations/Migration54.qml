import "Migrations.js" as Migrations
import QtQuick 6.10

QtObject {
  id: root

  // Add numpad Enter as a second default keybind for keyEnter
  function migrate(adapter: var, logger: var, rawJson: var): bool {
    return Migrations.migrate54(adapter, logger, rawJson);
  }
}
