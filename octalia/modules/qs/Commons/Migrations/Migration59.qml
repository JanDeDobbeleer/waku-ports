import QtQuick 6.10

QtObject {
  function migrate(adapter, logger, rawJson) {
    var oldValue;
    logger.i("Settings", "Migrating settings to v59 (wallpaper.transitionType: string -> array)");

    if (rawJson && rawJson.wallpaper && typeof rawJson.wallpaper.transitionType === "string") {
      oldValue = rawJson.wallpaper.transitionType;
      var newValue;

      if (oldValue === "random") {
        newValue = ["fade", "disc", "stripes", "wipe", "pixelate", "honeycomb"];
      } else if (oldValue === "none") {
        newValue = [];
      } else {
        newValue = [oldValue];
      }

      adapter.wallpaper.transitionType = newValue;
      logger.i("Settings", "Migrated wallpaper.transitionType:", oldValue, "->", JSON.stringify(newValue));
    }

    return true;
  }
}
