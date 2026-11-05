import QtQuick
import Quickshell
import qs.Commons
import qs.compat

QtObject {
  id: root

  function migrate(adapter, logger, rawJson) {
    logger.i("Migration47", "Removing network_stats.json cache");

    const networkStatsFile = Settings.cacheDir + "network_stats.json";
    Os.rm(networkStatsFile);

    logger.d("Migration47", "Removed network_stats.json");

    return true;
  }
}
