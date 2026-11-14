.pragma library

function hasValues(values) {
  return values && values.length > 0;
}

function contains(values, value) {
  return !!values && values.indexOf(value) !== -1;
}

function hasEnabledCard(cards, id) {
  if (!cards)
    return false;
  for (var i = 0; i < cards.length; ++i) {
    if (cards[i].enabled && cards[i].id === id)
      return true;
  }
  return false;
}

function showOSD(item) {
  if (item)
    item.showOSD();
}

function hideLoadedOSD(item) {
  if (!item || !item.osdItem)
    return false;
  item.osdItem.hideImmediately();
  return true;
}

function disconnectBrightnessMonitor(monitor, handler) {
  try {
    monitor.brightnessUpdated.disconnect(handler);
  } catch (e) {
  }
}

function screensForOSD(screens, monitors, enabled) {
  if (!enabled)
    return [];
  var selected = [];
  for (var i = 0; i < screens.length; ++i) {
    if (monitors.includes(screens[i].name) || monitors.length === 0)
      selected.push(screens[i]);
  }
  return selected;
}

function isPanelOpen(panel) { return panel && panel.isPanelOpen; }
