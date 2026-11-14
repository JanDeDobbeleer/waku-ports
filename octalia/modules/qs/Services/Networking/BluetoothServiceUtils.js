.pragma library

function connectedDevices(adapter) {
    if (!adapter || !adapter.devices) {
      return [];
    }
    return adapter.devices.values.filter(dev => dev && dev.connected);
}

function sortDevices(devices) {
    return devices.sort(function (a, b) {
      var aName = a.name || a.deviceName || "";
      var bName = b.name || b.deviceName || "";

      var aHasRealName = aName.indexOf(" ") !== -1 && aName.length > 3;
      var bHasRealName = bName.indexOf(" ") !== -1 && bName.length > 3;

      if (aHasRealName && !bHasRealName) {
        return -1;
      }
      if (!aHasRealName && bHasRealName) {
        return 1;
      }

      var aSignal = (a.signalStrength !== undefined && a.signalStrength > 0) ? a.signalStrength : 0;
      var bSignal = (b.signalStrength !== undefined && b.signalStrength > 0) ? b.signalStrength : 0;
      return bSignal - aSignal;
    });
}

function canConnect(device) {
    if (!device) {
      return false;
    }
    return !device.connected && (device.paired || device.trusted) && !device.pairing && !device.blocked;
}

function canDisconnect(device) {
    if (!device) {
      return false;
    }
    return device.connected && !device.pairing && !device.blocked;
}

function isDeviceBusy(device, connectingState, disconnectingState) {
    if (!device) {
      return false;
    }
    return device.pairing || device.state === disconnectingState || device.state === connectingState;
}

function canPair(device) {
    if (!device) {
      return false;
    }
    return !device.connected && !device.paired && !device.trusted && !device.pairing && !device.blocked;
}

function getStatusKey(device, connectingState, disconnectingState) {
    if (!device) {
      return "";
    }
    try {
      if (device.pairing)
        return "pairing";
      if (device.blocked)
        return "blocked";
      if (device.state === connectingState)
        return "connecting";
      if (device.state === disconnectingState)
        return "disconnecting";
    } catch (_) {}
    return "";
}

function getDeviceAutoConnect(device, cacheAdapter) {
    if (!device || !device.address || !cacheAdapter.autoConnectSettings) {
      return false;
    }
    const mac = device.address;
    const settings = cacheAdapter.autoConnectSettings[mac];
    return settings ? !!settings.autoConnect : false;
}

function setDeviceAutoConnect(device, enabled, cacheAdapter, cacheFileView) {
    if (!device || !device.address) {
      return;
    }
    const mac = device.address;
    let settings = cacheAdapter.autoConnectSettings || ({});
    if (enabled) {
      settings[mac] = {
        autoConnect: true,
        deviceName: device.name || device.deviceName || ""
      };
    } else {
      delete settings[mac];
    }
    cacheAdapter.autoConnectSettings = settings;
    cacheFileView.writeAdapter();
}

function setBluetoothEnabled(state, root, Logger, ToastService, I18n) {
    if (!root.adapter) {
      Logger.d("Bluetooth", "Enable/Disable skipped: no adapter");
      return;
    }
    try {
      root.adapter.enabled = state;
      Logger.i("Bluetooth", "SetBluetoothEnabled", state);
    } catch (e) {
      Logger.w("Bluetooth", "Enable/Disable failed", e);
      ToastService.showWarning(I18n.tr("common.bluetooth"), I18n.tr("toast.bluetooth.state-change-failed"));
    }
}

function setScanActive(active, root, Logger) {
    if (!root.adapter) {
      Logger.d("Bluetooth", "Scan request ignored: adapter unavailable");
      return;
    }
    try {
      if (active || root.adapter.discovering) { // Only attempt to set if activating, or if deactivating and currently currently discovering
        root.adapter.discovering = active;
      }
    } catch (e) {
      Logger.e("Bluetooth", "setScanActive failed", e);
    }
}

function setDiscoverable(state, root, Logger, ToastService, I18n) {
    if (!root.adapter) {
      Logger.d("Bluetooth", "Discoverable change skipped: no adapter");
      return;
    }
    try {
      root.adapter.discoverable = state;
      Logger.i("Bluetooth", "Discoverable state set to:", state);
    } catch (e) {
      Logger.w("Bluetooth", "Failed to change discoverable state", e);
      ToastService.showWarning(I18n.tr("common.bluetooth"), I18n.tr("toast.bluetooth.discoverable-change-failed"));
    }
}

function getDeviceIcon(device, BluetoothUtils) {
    if (!device) {
      return "bt-device-generic";
    }
    return BluetoothUtils.deviceIcon(device.name || device.deviceName, device.icon);
}

function pairDevice(device, root, Logger, ToastService, I18n) {
    if (!device) {
      return;
    }
    ToastService.showNotice(I18n.tr("common.bluetooth"), I18n.tr("common.pairing"), "bluetooth");
    try {
      root.pairWithBluetoothctl(device);
    } catch (e) {
      Logger.w("Bluetooth", "pairDevice failed", e);
      ToastService.showWarning(I18n.tr("common.bluetooth"), I18n.tr("toast.bluetooth.pair-failed"));
    }
}

function cancelPairing(root) {
    const list = root.adapter && root.adapter.devices ? (root.adapter.devices.values || []) : [];
    for (const d of list) {
      if (typeof d.cancelPair === "function")
        d.cancelPair();
    }
    root.pinRequired = false;
}

function pairWithBluetoothctl(device, root) {
    if (!device || typeof device.pair !== "function")
      return;
    root.pinRequired = false;
    root._discoveryWasRunning = root.scanningActive;
    if (root.scanningActive)
      root.setScanActive(false);
    device.pair();
}

function btExec(args, Logger, Quickshell) {
    try {
      Quickshell.execDetached(args);
    } catch (e) {
      Logger.w("Bluetooth", "btExec failed", e);
    }
}

function connectDeviceWithTrust(device, Logger, ToastService, I18n) {
    if (!device) {
      return;
    }
    try {
      device.trusted = true;
      device.connect();
    } catch (e) {
      Logger.w("Bluetooth", "connectDeviceWithTrust failed", e);
      ToastService.showWarning(I18n.tr("common.bluetooth"), I18n.tr("toast.bluetooth.connect-failed"));
    }
}

function disconnectDevice(device, Logger, ToastService, I18n) {
    if (!device) {
      return;
    }
    try {
      device.disconnect();
    } catch (e) {
      Logger.w("Bluetooth", "disconnectDevice failed", e);
      ToastService.showWarning(I18n.tr("common.bluetooth"), I18n.tr("toast.bluetooth.disconnect-failed"));
    }
}

function forgetDevice(device, Logger, ToastService, I18n) {
    if (!device) {
      return;
    }
    try {
      device.trusted = false;
      device.forget();
    } catch (e) {
      Logger.w("Bluetooth", "forgetDevice failed", e);
      ToastService.showWarning(I18n.tr("common.bluetooth"), I18n.tr("toast.bluetooth.forget-failed"));
    }
}

function attemptAutoConnect(root, NetworkService, Settings, autoConnectStepTimer) {
    if (NetworkService.airplaneModeEnabled || !root.adapter || !root.adapter.enabled || !Settings.data.network.bluetoothAutoConnect) {
      return;
    }

    root._autoConnectQueue = root.adapter.devices.values.filter(dev => dev && dev.paired && !dev.connected && !dev.blocked && root.getDeviceAutoConnect(dev) === true);

    if (root._autoConnectQueue.length > 0) {
      autoConnectStepTimer.restart();
    }
}

function autoConnectStep(root, Logger, autoConnectStepTimer) {
      var device = root._autoConnectQueue.shift();
      if (device && device.paired && !device.connected && !device.blocked) {
        Logger.i("Bluetooth", "Auto-connecting to:", device.name || device.deviceName);
        root.connectDeviceWithTrust(device);
      }
      if (root._autoConnectQueue.length > 0) {
        autoConnectStepTimer.restart();
      }
}

function rssiVersion(rssi) {
  return rssi.version;
}

function rssiCache(rssi) {
  return rssi.cache;
}
