.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function resolveWidgetSetting(settings, metadata, key, defaultValue) {
  const settingValue = field(settings, key);
  if (settingValue !== undefined)
    return settingValue;
  const metadataValue = field(metadata, key);
  return metadataValue !== undefined ? metadataValue : defaultValue;
}

function controllableMonitors(monitors) {
  const result = [];
  if (!monitors)
    return result;
  for (let i = 0; i < monitors.length; i++) {
    const monitor = monitors[i];
    if (monitor && field(monitor, "brightnessControlAvailable"))
      result.push(monitor);
  }
  return result;
}

function globalBrightnessState(monitors, changing) {
  const available = controllableMonitors(monitors);
  if (changing)
    return { "count": available.length, "update": false, "value": 0 };
  if (available.length === 0)
    return { "count": 0, "update": true, "value": 0 };
  let total = 0;
  for (let i = 0; i < available.length; i++) {
    const value = field(available[i], "brightness");
    total += isNaN(value) ? 0 : value;
  }
  return { "count": available.length, "update": true, "value": total / available.length };
}

function applyGlobalBrightness(monitors, value) {
  if (!monitors)
    return;
  for (let i = 0; i < monitors.length; i++) {
    const monitor = monitors[i];
    if (monitor && field(monitor, "brightnessControlAvailable"))
      monitor.setBrightness(value);
  }
}

function brightness(monitor, fallback) {
  const value = field(monitor, "brightness");
  return value === undefined ? fallback : value;
}

function controlAvailable(monitor) {
  return !!field(monitor, "brightnessControlAvailable");
}

function setBrightness(monitor, value) {
  if (monitor && typeof monitor.setBrightness === "function")
    monitor.setBrightness(value);
}
