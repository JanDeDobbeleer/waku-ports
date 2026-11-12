.pragma library

function getWidgetsContainer(root, settings, qtObjectConverter) {
  if (!settings.hasScreenOverride(root.screenName, "widgets")) {
    const currentWidgets = settings.getBarWidgetsForScreen(root.screenName);
    const widgetsCopy = qtObjectConverter.qtObjectToPlainObject(currentWidgets);
    settings.setScreenOverride(root.screenName, "widgets", widgetsCopy);
  }
  const entry = settings.getScreenOverrideEntry(root.screenName);
  return entry ? entry.widgets : settings.data.bar.widgets;
}

function saveWidgets(root, settings, widgets) {
  settings.setScreenOverride(root.screenName, "widgets", widgets);
}

function addWidget(root, settings, qtObjectConverter, registry, barService, widgetId, section) {
  const widget = { id: widgetId };
  if (registry.widgetHasUserSettings(widgetId)) {
    const metadata = registry.widgetMetadata[widgetId];
    if (metadata) Object.keys(metadata).forEach(function (key) { widget[key] = metadata[key]; });
  }
  const widgets = getWidgetsContainer(root, settings, qtObjectConverter);
  widgets[section].push(widget);
  saveWidgets(root, settings, widgets);
  barService.widgetsRevision++;
}

function removeWidget(root, settings, qtObjectConverter, barService, toastService, i18n, section, index) {
  const widgets = getWidgetsContainer(root, settings, qtObjectConverter);
  if (index >= 0 && index < widgets[section].length) {
    const updated = widgets[section].slice();
    const removed = updated.splice(index, 1);
    widgets[section] = updated;
    saveWidgets(root, settings, widgets);
    barService.widgetsRevision++;
    if (removed[0].id === "ControlCenter" && barService.lookupWidget("ControlCenter", undefined) === undefined) {
      toastService.showWarningDetailed(i18n.tr("toast.missing-control-center.label"), i18n.tr("toast.missing-control-center.description"), 12000, undefined, undefined);
    }
  }
}

function reorderWidget(root, settings, qtObjectConverter, barService, section, fromIndex, toIndex) {
  const widgets = getWidgetsContainer(root, settings, qtObjectConverter);
  if (fromIndex >= 0 && fromIndex < widgets[section].length && toIndex >= 0 && toIndex < widgets[section].length) {
    const updated = widgets[section].slice();
    const item = updated[fromIndex];
    updated.splice(fromIndex, 1);
    updated.splice(toIndex, 0, item);
    widgets[section] = updated;
    saveWidgets(root, settings, widgets);
    barService.widgetsRevision++;
  }
}

function updateWidgetSettings(root, settings, qtObjectConverter, section, index, value) {
  const widgets = getWidgetsContainer(root, settings, qtObjectConverter);
  widgets[section][index] = value;
  saveWidgets(root, settings, widgets);
}

function moveWidget(root, settings, qtObjectConverter, barService, fromSection, index, toSection) {
  const widgets = getWidgetsContainer(root, settings, qtObjectConverter);
  if (index >= 0 && index < widgets[fromSection].length) {
    const widget = widgets[fromSection][index];
    const source = widgets[fromSection].slice();
    source.splice(index, 1);
    widgets[fromSection] = source;
    const target = widgets[toSection].slice();
    target.push(widget);
    widgets[toSection] = target;
    saveWidgets(root, settings, widgets);
    barService.widgetsRevision++;
  }
}

function updateAvailableWidgetsModel(model, registry, colors) {
  model.clear();
  const widgetIds = registry.getAvailableWidgets();
  if (!widgetIds) return;
  for (let i = 0; i < widgetIds.length; i++) {
    const id = widgetIds[i];
    const badges = [];
    if (registry.isCpuIntensive(id)) badges.push({ icon: "cpu-intensive", color: colors.mSecondary });
    model.append({ key: id, name: id, badges: badges });
  }
}
