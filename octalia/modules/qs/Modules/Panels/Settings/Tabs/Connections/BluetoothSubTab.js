.pragma library

function devices(adapter) {
  return adapter && adapter.devices ? adapter.devices.values : [];
}

function connectedDevices(adapter, service) {
  const filtered = devices(adapter).filter(dev => dev && !dev.blocked && dev.connected);
  return service.sortDevices(service.dedupeDevices(filtered));
}

function pairedDevices(adapter, service) {
  const filtered = devices(adapter).filter(dev => dev && !dev.blocked && !dev.connected && (dev.paired || dev.trusted));
  return service.sortDevices(service.dedupeDevices(filtered));
}

function unnamedAvailableDevices(adapter, service) {
  const filtered = devices(adapter).filter(dev => dev && !dev.blocked && !dev.paired && !dev.trusted);
  return filtered;
}

function availableDevices(list, hideUnnamed, service) {
  if (hideUnnamed) {
    list = list.filter(function (dev) {
      let normAddr, normName;
      const dn = dev.name || dev.deviceName || "";
      const name = String(dn).trim();
      if (name.length === 0) return false;
      const lower = name.toLowerCase();
      if (lower === "unknown" || lower === "unnamed" || lower === "n/a" || lower === "na") return false;
      const addr = dev.address || dev.bdaddr || dev.mac || "";
      if (addr.length > 0) {
        normName = name.toLowerCase().replace(/[^0-9a-z]/g, "");
        normAddr = String(addr).toLowerCase().replace(/[^0-9a-z]/g, "");
        if (normName.length > 0 && normName === normAddr) return false;
      }
      const macRegexComb = /^(([0-9A-Fa-f]{2}[:\-]){5}[0-9A-Fa-f]{2}|([0-9A-Fa-f]{4}\.){2}[0-9A-Fa-f]{4}|[0-9A-Fa-f]{12})$/;
      return !macRegexComb.test(name);
    });
  }
  return service.sortDevices(service.dedupeDevices(list));
}

function length(list) {
  return list.length;
}

function read(target, key) {
  return target[key];
}

function deviceName(device) {
  return device.name || device.deviceName;
}

function deviceAddress(device) {
  return device.address || "-";
}

function contentColors(device, defaultColors, connectingState, disconnectingState, primaryColors, errorColors) {
  if (device.pairing || device.state === connectingState) return primaryColors;
  if (device.connected && device.state !== disconnectingState) return primaryColors;
  if (device.blocked || device.state === disconnectingState) return errorColors;
  return defaultColors;
}
