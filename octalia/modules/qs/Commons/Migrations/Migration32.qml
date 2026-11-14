import "Migrations.js" as Migrations
import QtQuick 6.10

QtObject {
  id: root

  // Migrate systemMonitor.enableNvidiaGpu to systemMonitor.enableDgpuMonitoring
  function migrate(adapter: var, logger: var, rawJson: var): bool {
    return Migrations.migrate32(adapter, logger, rawJson);
  }
}
