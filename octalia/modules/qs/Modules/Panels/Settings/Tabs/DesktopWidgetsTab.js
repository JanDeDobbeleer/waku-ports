.pragma library

function screenProperty(screen, key) {
  return screen[key];
}

function compositorScale(displayScales, screen) {
  const info = displayScales[screen.name];
  return (info && info.scale) ? info.scale : 1.0;
}

function screenSubtitle(screen, scale) {
  const formattedScale = scale.toFixed(2);
  return "(" + screen.width + "x" + screen.height + " @ " + formattedScale + "x)";
}

function getScreenNames(screens) {
  const names = [];
  for (let i = 0; i < screens.length; i++) {
    names.push(screens[i].name);
  }
  return names;
}

function getScreenLabels(screens) {
  const labels = {};
  for (let i = 0; i < screens.length; i++) {
    const screen = screens[i];
    labels[screen.name] = screen.name;
  }
  return labels;
}

function getScreenIcons(screens) {
  const icons = {};
  for (let i = 0; i < screens.length; i++) {
    icons[screens[i].name] = "device-desktop";
  }
  return icons;
}

function closeNearestOwner(item) {
  while (item) {
    if (item.closeRequested !== undefined) {
      item.closeRequested();
      break;
    }
    item = item.parent;
  }
}

function updateAvailableWidgetsModel(root, model, secondaryColor, logger) {
  model.clear();
  try {
    const registry = root.desktopWidgetRegistry();
    if (!registry) {
      logger.e("DesktopWidgetsTab", "DesktopWidgetRegistry is not available");
      Qt.callLater(function () {
        if (root.desktopWidgetRegistry()) {
          root.updateAvailableWidgetsModel();
        }
      });
      return;
    }
    const widgetIds = registry.getAvailableWidgets();
    logger.d("DesktopWidgetsTab", "Found widgets:", widgetIds, "count:", widgetIds ? widgetIds.length : 0);
    if (!widgetIds || widgetIds.length === 0) {
      logger.w("DesktopWidgetsTab", "No widgets found in registry");
      return;
    }
    for (let i = 0; i < widgetIds.length; i++) {
      const widgetId = widgetIds[i];
      const badges = [];
      if (registry.isCpuIntensive(widgetId)) {
        badges.push({ icon: "cpu-intensive", color: secondaryColor });
      }
      model.append({ key: widgetId, name: widgetId, badges: badges });
    }
    logger.d("DesktopWidgetsTab", "Available widgets model count:", model.count);
  } catch (e) {
    logger.e("DesktopWidgetsTab", "Error updating available widgets:", e, e.stack);
  }
}

function getWidgetsForMonitor(monitorWidgets, monitorName) {
  for (let i = 0; i < monitorWidgets.length; i++) {
    if (monitorWidgets[i].name === monitorName) {
      return monitorWidgets[i].widgets || [];
    }
  }
  return [];
}

function setWidgetsForMonitor(monitorWidgets, monitorName, widgets) {
  const newMonitorWidgets = monitorWidgets.slice();
  let found = false;
  for (let i = 0; i < newMonitorWidgets.length; i++) {
    if (newMonitorWidgets[i].name === monitorName) {
      newMonitorWidgets[i] = { name: monitorName, widgets: widgets };
      found = true;
      break;
    }
  }
  if (!found) {
    newMonitorWidgets.push({ name: monitorName, widgets: widgets });
  }
  return newMonitorWidgets;
}

function addWidget(monitorWidgets, monitorName, widgetId, registry) {
  let metadata;
  const widget = { id: widgetId };
  if (registry.widgetHasUserSettings(widgetId)) {
    metadata = registry.widgetMetadata[widgetId];
    if (metadata) {
      Object.keys(metadata).forEach(function (key) {
        widget[key] = metadata[key];
      });
    }
  }
  if (widgetId === "Clock") {
    widget.x = 50;
    widget.y = 50;
  } else if (widgetId === "MediaPlayer") {
    widget.x = 100;
    widget.y = 200;
  } else if (widgetId === "Weather") {
    widget.x = 100;
    widget.y = 300;
  } else {
    widget.x = 150;
    widget.y = 150;
  }
  const widgets = getWidgetsForMonitor(monitorWidgets, monitorName).slice();
  widgets.push(widget);
  return setWidgetsForMonitor(monitorWidgets, monitorName, widgets);
}

function validWidgetIndex(monitorWidgets, monitorName, index) {
  const widgets = getWidgetsForMonitor(monitorWidgets, monitorName);
  return index >= 0 && index < widgets.length;
}

function removeWidget(monitorWidgets, monitorName, index) {
  const widgets = getWidgetsForMonitor(monitorWidgets, monitorName);
  if (!validWidgetIndex(monitorWidgets, monitorName, index)) {
    return null;
  }
  const newArray = widgets.slice();
  newArray.splice(index, 1);
  return setWidgetsForMonitor(monitorWidgets, monitorName, newArray);
}

function updateWidgetSettings(monitorWidgets, monitorName, index, settings) {
  const widgets = getWidgetsForMonitor(monitorWidgets, monitorName);
  if (!validWidgetIndex(monitorWidgets, monitorName, index)) {
    return null;
  }
  const newArray = widgets.slice();
  newArray[index] = Object.assign({}, newArray[index], settings);
  return setWidgetsForMonitor(monitorWidgets, monitorName, newArray);
}

function moveWidget(monitorWidgets, fromMonitor, index, toMonitor) {
  const sourceWidgets = getWidgetsForMonitor(monitorWidgets, fromMonitor);
  const newSourceWidgets = sourceWidgets.slice();
  const widget = Object.assign({}, newSourceWidgets.splice(index, 1)[0]);
  widget.x = 100;
  widget.y = 100;
  widget.scale = 1.0;
  const destinationWidgets = getWidgetsForMonitor(monitorWidgets, toMonitor).slice();
  destinationWidgets.push(widget);
  return { sourceWidgets: newSourceWidgets, destinationWidgets: destinationWidgets };
}
