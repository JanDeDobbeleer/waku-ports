.pragma library

function availableDevices(sources) {
  return (sources || []).map(s => String(s.id ?? s.name ?? s));
}

function getMonitorForScreen(monitors, screen) {
  return monitors.find(m => m.modelData === screen);
}

function increaseBrightness(monitors) {
  monitors.forEach(m => m.increaseBrightness());
}

function decreaseBrightness(monitors) {
  monitors.forEach(m => m.decreaseBrightness());
}

function getBacklightDeviceName(devicePath, root, controlCenter) {
    const key = root.normalizeBacklightDevicePath(devicePath);
    for (const s of (controlCenter.brightnessSources || [])) {
      if (String(s.id ?? s.name ?? s) === key)
        return String(s.name ?? s.id ?? key);
    }
    return key;
}
