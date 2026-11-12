.pragma library

function findFirstFocusable(item) {
  if (!item) return null;
  if (item.focus !== undefined && item.focus === true) return item;
  if (item.children) {
    for (let i = 0; i < item.children.length; i++) {
      const child = item.children[i];
      if (child && child.focus !== undefined && child.focus === true) return child;
      const found = findFirstFocusable(child);
      if (found) return found;
    }
  }
  return null;
}

function focusFirstFocusable(item, fallback) {
  Qt.callLater(function () {
    const firstInput = findFirstFocusable(item);
    if (firstInput) firstInput.forceActiveFocus();
    else fallback.forceActiveFocus();
  });
}

function saveSettings(item) {
  if (item && typeof item.saveSettings === "function") return item.saveSettings();
  return null;
}

function loadWidgetSettings(loader, registry, widgetData, monitorWidgets, sectionId, widgetIndex, widgetId, shellDir) {
  const source = registry.widgetSettingsMap[widgetId];
  if (!source) return;
  let currentWidgetData = widgetData;
  for (let i = 0; i < monitorWidgets.length; i++) {
    if (monitorWidgets[i].name === sectionId) {
      const widgets = monitorWidgets[i].widgets || [];
      if (widgetIndex >= 0 && widgetIndex < widgets.length) currentWidgetData = widgets[widgetIndex];
      break;
    }
  }
  const fullPath = Qt.resolvedUrl(shellDir + "/modules/qs/Modules/Panels/Settings/DesktopWidgets/" + source);
  loader.setSource(fullPath, {
    widgetData: currentWidgetData,
    widgetMetadata: registry.widgetMetadata[widgetId]
  });
}
