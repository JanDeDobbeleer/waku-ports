.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function setBrightness(monitor, value) {
  if (monitor)
    monitor.setBrightness(value);
}
