.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function hasPreview(provider) {
  return !!field(provider, "hasPreview");
}

function previewComponentPath(provider) {
  return field(provider, "previewComponentPath") || "";
}

function updatePreviewItem(item, launcherCore) {
  const index = field(launcherCore, "selectedIndex");
  const results = field(launcherCore, "results");
  if (!item || !results || index < 0 || !results[index])
    return;
  const provider = field(launcherCore, "activeProvider");
  const getPreviewData = field(provider, "getPreviewData");
  item.currentItem = typeof getPreviewData === "function" ? getPreviewData.call(provider, results[index]) : results[index];
}

function screensForOverview(screens, enabled) {
  return enabled ? screens : [];
}

function setScreen(window, screen) {
  if (window)
    window.screen = screen;
}
