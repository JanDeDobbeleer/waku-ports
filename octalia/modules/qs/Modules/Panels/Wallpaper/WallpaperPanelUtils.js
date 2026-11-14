.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function arrayLength(value) {
  return value && typeof value.length === "number" ? value.length : 0;
}

function focusGrid(repeater, index) {
  const view = repeater ? repeater.itemAt(index) : null;
  const grid = field(view, "gridView");
  if (grid)
    grid.forceActiveFocus();
}

function navigate(content, direction) {
  if (!content)
    return;
  const repeater = field(content, "screenRepeater");
  const view = repeater ? repeater.itemAt(field(content, "currentScreenIndex")) : null;
  const grid = field(view, "gridView");
  if (!grid)
    return;
  if (direction === "down" && !grid.hasActiveFocus) {
    grid.forceActiveFocus();
    if (grid.currentIndex < 0 && arrayLength(grid.model) > 0)
      grid.currentIndex = 0;
    return;
  }
  if (!grid.hasActiveFocus)
    return;
  if (grid.currentIndex < 0 && arrayLength(grid.model) > 0) {
    grid.currentIndex = 0;
  } else if (direction === "down") {
    grid.moveCurrentIndexDown();
  } else if (direction === "up") {
    grid.moveCurrentIndexUp();
  } else if (direction === "left") {
    grid.moveCurrentIndexLeft();
  } else if (direction === "right") {
    grid.moveCurrentIndexRight();
  }
}

function activateCurrentItem(content) {
  if (!content)
    return;
  const wallhaven = field(content, "wallhavenViewItem");
  const pageInput = field(wallhaven, "pageInput");
  const inputItem = field(pageInput, "inputItem");
  if (field(wallhaven, "visible") && field(inputItem, "activeFocus")) {
    pageInput.submitPage();
    return;
  }
  const repeater = field(content, "screenRepeater");
  const view = repeater ? repeater.itemAt(field(content, "currentScreenIndex")) : null;
  const grid = field(view, "gridView");
  if (!grid || grid.currentIndex < 0 || grid.currentIndex >= grid.model.count)
    return;
  const item = grid.model.get(grid.currentIndex);
  view.selectItem(field(item, "path"), field(item, "isDirectory"));
}

function setScreen(item, screen) {
  if (item)
    item.screen = screen;
}

function focusInput(input) {
  if (input)
    input.forceActiveFocus();
}

function showSettings(item, button) {
  if (item)
    item.showAt(button);
}

function fuzzyResults(results) {
  const items = [];
  for (let i = 0; i < arrayLength(results); i++)
    items.push(field(results[i], "obj"));
  return items;
}

function scanDirectory(service, view, screenName, browsePath, generation, logger) {
  service.scanDirectoryWithDirs(screenName, browsePath, function (result) {
    if (generation !== field(view, "_browseScanGeneration"))
      return;
    const files = field(result, "files") || [];
    const directories = field(result, "directories") || [];
    view.wallpapersList = files;
    view.directoriesList = directories;
    logger.d("WallpaperPanel", "Browse mode: Got", arrayLength(files), "files and", arrayLength(directories), "directories for screen", screenName);
    view.updateFiltered(false);
  });
}

function isFavorite(revision, service, path) {
  return service.isFavorite(path);
}

function favoriteData(localRevision, serviceRevision, linkLightAndDark, service, path) {
  return service.getFavoriteForDisplay(path);
}

function resetGridSelections(content) {
  const repeater = field(content, "screenRepeater");
  if (repeater) {
    for (let i = 0; i < repeater.count; i++) {
      const view = repeater.itemAt(i);
      const grid = field(view, "gridView");
      if (grid)
        grid.currentIndex = -1;
    }
  }
  const wallhaven = field(content, "wallhavenViewItem");
  const wallhavenGrid = field(wallhaven, "gridView");
  if (wallhavenGrid)
    wallhavenGrid.currentIndex = -1;
}

function updateFilteredViews(repeater) {
  if (!repeater)
    return;
  for (let i = 0; i < repeater.count; i++) {
    const view = repeater.itemAt(i);
    if (view && typeof view.updateFiltered === "function")
      view.updateFiltered(false);
  }
}

function focusWallhavenGrid(wallhaven) {
  const grid = field(wallhaven, "gridView");
  if (grid)
    grid.forceActiveFocus();
}

function acceptEvent(event) {
  if (event)
    event.accepted = true;
}
