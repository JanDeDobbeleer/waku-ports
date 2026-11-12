.pragma library

function addWidget(settings, registry, widgetId, section) {
  const widget = { id: widgetId };
  if (registry.widgetHasUserSettings(widgetId)) {
    const metadata = registry.widgetMetadata[widgetId];
    if (metadata) Object.keys(metadata).forEach(function (key) { widget[key] = metadata[key]; });
  }
  settings.shortcuts[section].push(widget);
}

function removeWidget(settings, section, index) {
  const current = settings.shortcuts[section];
  if (index >= 0 && index < current.length) {
    const updated = current.slice();
    updated.splice(index, 1);
    settings.shortcuts[section] = updated;
  }
}

function reorderWidget(settings, section, fromIndex, toIndex) {
  const current = settings.shortcuts[section];
  if (fromIndex >= 0 && fromIndex < current.length && toIndex >= 0 && toIndex < current.length) {
    const updated = current.slice();
    const item = updated[fromIndex];
    updated.splice(fromIndex, 1);
    updated.splice(toIndex, 0, item);
    settings.shortcuts[section] = updated;
  }
}

function moveWidget(settings, fromSection, index, toSection) {
  const source = settings.shortcuts[fromSection];
  if (index >= 0 && index < source.length) {
    const widget = source[index];
    const updatedSource = source.slice();
    updatedSource.splice(index, 1);
    settings.shortcuts[fromSection] = updatedSource;
    const updatedTarget = settings.shortcuts[toSection].slice();
    updatedTarget.push(widget);
    settings.shortcuts[toSection] = updatedTarget;
  }
}

function updateWidgetSettings(data, section, index, value, settings) {
  const updated = data.shortcuts[section].slice();
  updated[index] = value;
  data.shortcuts[section] = updated;
  settings.saveImmediate();
}
