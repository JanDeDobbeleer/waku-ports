import QtQuick 6.10
import qs.Commons
import qs.compat

QtObject {
  id: root

  // Clear legacy emoji usage cache to adopt new format
  function migrate(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v36");

    const usagePath = Settings.cacheDir + "emoji_usage.json";

    if (!usagePath.endsWith("emoji_usage.json")) {
      logger.w("Settings", "Skipping emoji usage cleanup due to unexpected path: " + usagePath);
      return true;
    }

    try {
      // Ensure dir exists then remove the file
      Os.rm(usagePath, false);
      logger.i("Settings", "Cleared legacy emoji usage file at: " + usagePath);
    } catch (e) {
      logger.w("Settings", "Failed to clear emoji usage cache: " + e);
    }

    return true;
  }
}
