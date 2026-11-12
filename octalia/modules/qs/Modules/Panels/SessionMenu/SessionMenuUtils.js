.pragma library

function arrayLength(items) {
  return items ? items.length : 0;
}

function buildPowerOptions(settingsOptions, metadata, version) {
  void version;
  var options = [];
  for (var i = 0; i < settingsOptions.length; ++i) {
    var setting = settingsOptions[i];
    var actionMetadata = metadata[setting.action];
    if (setting.enabled && actionMetadata) {
      options.push({
        action: setting.action,
        icon: actionMetadata.icon,
        title: actionMetadata.title,
        isShutdown: actionMetadata.isShutdown,
        countdownEnabled: setting.countdownEnabled !== undefined ? setting.countdownEnabled : true,
        command: setting.command || "",
        keybind: setting.keybind || ""
      });
    }
  }
  return options;
}

function field(record, name) {
  return record ? record[name] : undefined;
}

function isCountdownDisabled(options, action) {
  for (var i = 0; i < options.length; ++i) {
    if (options[i].action === action)
      return options[i].countdownEnabled === false;
  }
  return false;
}

function hasOption(options, index) {
  return !!options && !!options[index];
}

function actionAt(options, index) {
  return hasOption(options, index) ? options[index].action : "";
}

function keybindIndex(options, keybind) {
  for (var i = 0; i < options.length; ++i) {
    if (options[i].keybind === keybind)
      return i;
  }
  return -1;
}

function navigateGrid(count, selectedIndex, layout, direction) {
  var columns, rows;
  if (layout === "single-row") {
    columns = count;
    rows = 1;
  } else {
    columns = Math.min(3, Math.ceil(Math.sqrt(count)));
    rows = Math.ceil(count / columns);
  }

  var currentRow = selectedIndex >= 0 ? Math.floor(selectedIndex / columns) : -1;
  var currentCol = selectedIndex >= 0 ? selectedIndex % columns : -1;
  var newRow = currentRow >= 0 ? currentRow : 0;
  var newCol = currentCol >= 0 ? currentCol : 0;
  var itemsInRow = function(row) { return Math.min(columns, count - row * columns); };

  switch (direction) {
  case "left":
    newCol = newCol - 1 < 0 ? itemsInRow(newRow) - 1 : newCol - 1;
    break;
  case "right":
    newCol = currentCol < 0 ? newRow : newCol + 1 >= itemsInRow(newRow) ? 0 : newCol + 1;
    break;
  case "up":
    newRow = newRow - 1 < 0 ? rows - 1 : newRow - 1;
    break;
  case "down":
    newRow = currentRow < 0 ? newRow : newRow + 1 >= rows ? 0 : newRow + 1;
    break;
  }

  if (direction === "up" || direction === "down")
    newCol = Math.min(newCol, itemsInRow(newRow) - 1);
  var newIndex = newRow * columns + newCol;
  return newIndex < count ? newIndex : selectedIndex;
}
