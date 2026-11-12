.pragma library

function connectedNetworks(networks, wifiEnabled) {
  if (!wifiEnabled) {
    return [];
  }
  return networks.filter(n => n.connected).sort((a, b) => b.signal - a.signal);
}

function savedNetworks(networks, wifiEnabled) {
  if (!wifiEnabled) {
    return [];
  }
  return networks.filter(n => !n.connected && n.existing).sort((a, b) => b.signal - a.signal);
}

function availableNetworks(networks, wifiEnabled) {
  if (!wifiEnabled) {
    return [];
  }
  return networks.filter(n => !n.connected && !n.existing).sort((a, b) => b.signal - a.signal);
}

function read(target, key) {
  return target[key];
}

function length(array) {
  return array.length;
}

function hasValue(target, key) {
  return !!(target[key] && target[key].length > 0);
}

function hasForceLayout(layout) {
  return layout && layout.forceLayout;
}

function forceLayout(layout) {
  layout.forceLayout();
}

function isVisible(window) {
  return window.visible;
}

function signalIcon(signalInfo) {
  return signalInfo.icon;
}
