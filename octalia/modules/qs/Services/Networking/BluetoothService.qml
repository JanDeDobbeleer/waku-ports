pragma Singleton

import QtQuick 6.10
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import waku.services as S
import "../../Helpers/BluetoothUtils.js" as BluetoothUtils
import "BluetoothServiceUtils.js" as BluetoothServiceUtils
import qs.Commons
import qs.Services.UI

Singleton {
  id: root

  readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter

  // Power/availability state
  readonly property bool bluetoothAvailable: !!adapter
  readonly property bool enabled: adapter?.enabled ?? false
  readonly property bool blocked: adapter?.state === BluetoothAdapterState.Blocked

  // Exposed scanning flag for UI button state; reflects adapter discovery when available
  readonly property bool scanningActive: adapter?.discovering ?? false

  // Adapter discoverability (advertising) flag
  readonly property bool discoverable: adapter?.discoverable ?? false
  readonly property var devices: adapter ? adapter.devices : null
  readonly property var connectedDevices: BluetoothServiceUtils.connectedDevices(adapter)

  // Experimental: best‑effort RSSI polling for connected devices (without root)
  // Enabled in debug mode or via user setting in Settings > Network
  property bool rssiPollingEnabled: Settings?.data?.network?.bluetoothRssiPollingEnabled || Settings?.isDebug || false
  // Interval can be configured from Settings; defaults to 60s
  property int rssiPollIntervalMs: Settings?.data?.network?.bluetoothRssiPollIntervalMs || 60000
  // RSSI helper sub‑component
  property BluetoothRssi rssi: BluetoothRssi {
    enabled: false // RSSI polling shells out to bluetoothctl; Windows has no equivalent
    intervalMs: root.rssiPollIntervalMs
    connectedDevices: root.connectedDevices
  }

  // Tunables for CLI pairing/connect flow
  property int pairWaitSeconds: 45
  property int connectAttempts: 5
  property int connectRetryIntervalMs: 2000

  // Interaction state
  property bool pinRequired: false

  // Internal variables
  property bool _discoveryWasRunning: false
  property bool _ctlInit: false
  property var _autoConnectQueue: []

  // Persistent cache for per-device auto-connect toggle
  property string cacheFile: Settings.cacheDir + "bluetooth_devices.json"

  FileView {
    id: cacheFileView
    path: root.cacheFile
    printErrors: false

    JsonAdapter {
      id: cacheAdapter
      property var autoConnectSettings: ({})
    }
  }

  // Handle potential case where Quickshell doesnt't properly update adapter after system wakeup
  Connections {
    target: Time
    function onResumed() {
    }
  }

  // Track adapter state changes
  Connections {
    target: root.adapter
    function onStateChanged() {
      if (!root.adapter || root.adapter.state === BluetoothAdapterState.Enabling || root.adapter.state === BluetoothAdapterState.Disabling) {
        return;
      }
      root.checkAirplaneMode();
    }
    function onEnabledChanged() {
      if (root.adapter?.enabled && Settings.data.network.bluetoothAutoConnect) {
        autoConnectTimer.restart();
      }
    }
  }

  // A failed connect or disconnect never throws: the engine reports it in its Bluetooth.error.
  Connections {
    target: S.Bluetooth
    function onErrorChanged() {
      if (S.Bluetooth.error !== "") {
        Logger.w("Bluetooth", S.Bluetooth.error);
        ToastService.showWarning(I18n.tr("common.bluetooth"), S.Bluetooth.error);
      }
    }
  }

  Connections {
    target: Settings.data.network
    function onBluetoothAutoConnectChanged() {
      if (Settings.data.network.bluetoothAutoConnect && root.adapter?.enabled) {
        autoConnectTimer.restart();
      } else {
        autoConnectTimer.stop();
      }
    }
  }

  Component.onCompleted: {
    Logger.i("Bluetooth", "Service started");
    autoConnectTimer.restart();
  }

  Timer {
    id: autoConnectTimer
    interval: 1500
    repeat: false
    onTriggered: root.attemptAutoConnect()
  }

  Timer {
    id: autoConnectStepTimer
    interval: 500
    repeat: false
    onTriggered: BluetoothServiceUtils.autoConnectStep(root, Logger, autoConnectStepTimer)
  }

  // Adapter power (enable/disable) via bluetoothctl
  function setBluetoothEnabled(state: var): void {
    BluetoothServiceUtils.setBluetoothEnabled(state, root, Logger, ToastService, I18n);
  }

  // Check if airplane mode has been toggled
  function checkAirplaneMode() {
    var isAirplaneModeActive = !NetworkService.wifiEnabled && adapter.state === BluetoothAdapterState.Blocked;
    if (isAirplaneModeActive && !NetworkService.airplaneModeEnabled) {
      NetworkService.airplaneModeToggled = true;
      NetworkService.airplaneModeEnabled = true;
      ToastService.showNotice(I18n.tr("toast.airplane-mode.title"), I18n.tr("common.enabled"), "plane");
      Logger.i("AirplaneMode", "Enabled");
    } else if (!isAirplaneModeActive && NetworkService.airplaneModeEnabled) {
      NetworkService.airplaneModeToggled = true;
      NetworkService.airplaneModeEnabled = false;
      ToastService.showNotice(I18n.tr("toast.airplane-mode.title"), I18n.tr("common.disabled"), "plane-off");
      Logger.i("AirplaneMode", "Disabled");
    } else {
      // Only a real on/off change after startup is worth a toast. The adapter reports state changes
      // while it settles at startup (and for other reasons), which popped up "Bluetooth enabled" on
      // every launch.
      const nowEnabled = !!adapter.enabled;
      const changed = _lastEnabled !== null && _lastEnabled !== nowEnabled;
      _lastEnabled = nowEnabled;
      if (!changed || !_startupSettled) {
        Logger.d("Bluetooth", "Adapter state update (no toast):", nowEnabled ? "enabled" : "disabled");
      } else if (nowEnabled) {
        ToastService.showNotice(I18n.tr("common.bluetooth"), I18n.tr("common.enabled"), "bluetooth");
        Logger.d("Bluetooth", "Adapter enabled");
      } else {
        ToastService.showNotice(I18n.tr("common.bluetooth"), I18n.tr("common.disabled"), "bluetooth-off");
        Logger.d("Bluetooth", "Adapter disabled");
      }
    }
  }

  // Last adapter on/off state seen (null until the first update), and whether startup is over
  property var _lastEnabled: null
  property bool _startupSettled: false
  Timer {
    interval: 8000
    running: true
    onTriggered: root._startupSettled = true
  }

  // Unify discovery controls
  function setScanActive(active: var): void {
    BluetoothServiceUtils.setScanActive(active, root, Logger);
  }

  // Toggle adapter discoverability (advertising visibility) via bluetoothctl
  function setDiscoverable(state: var): void {
    BluetoothServiceUtils.setDiscoverable(state, root, Logger, ToastService, I18n);
  }

  function sortDevices(devices: var): var {
    return BluetoothServiceUtils.sortDevices(devices);
  }

  function getDeviceIcon(device: var): var {
    return BluetoothServiceUtils.getDeviceIcon(device, BluetoothUtils);
  }

  function canConnect(device: var): var {
    return BluetoothServiceUtils.canConnect(device);
  }

  function canDisconnect(device: var): var {
    return BluetoothServiceUtils.canDisconnect(device);
  }

  // Textual signal quality (translated)
  function getSignalStrength(device: var): var {
    var p = getSignalPercent(device);
    if (p === null) {
      return I18n.tr("bluetooth.panel.signal-text-unknown");
    }
    if (p >= 80) {
      return I18n.tr("bluetooth.panel.signal-text-excellent");
    }
    if (p >= 60) {
      return I18n.tr("bluetooth.panel.signal-text-good");
    }
    if (p >= 40) {
      return I18n.tr("bluetooth.panel.signal-text-fair");
    }
    if (p >= 20) {
      return I18n.tr("bluetooth.panel.signal-text-poor");
    }
    return I18n.tr("bluetooth.panel.signal-text-very-poor");
  }

  // Numeric helpers for UI rendering
  function getSignalPercent(device: var): var {
    // Establish binding dependency so UI updates when RSSI cache changes
    var _v = BluetoothServiceUtils.rssiVersion(rssi);
    return BluetoothUtils.signalPercent(device, BluetoothServiceUtils.rssiCache(rssi), _v);
  }

  function getBatteryPercent(device: var): var {
    return BluetoothUtils.batteryPercent(device);
  }

  function getSignalIcon(device: var): var {
    var p = getSignalPercent(device);
    return BluetoothUtils.signalIcon(p);
  }

  function isDeviceBusy(device: var): var {
    return BluetoothServiceUtils.isDeviceBusy(device, BluetoothDeviceState.Connecting, BluetoothDeviceState.Disconnecting);
  }

  // Return a stable unique key for a device (prefer MAC address)
  function deviceKey(device: var): var {
    return BluetoothUtils.deviceKey(device);
  }

  // Deduplicate a list of devices using the stable key
  function dedupeDevices(devList: var): var {
    return BluetoothUtils.dedupeDevices(devList);
  }

  // Separate capability helpers
  function canPair(device: var): var {
    return BluetoothServiceUtils.canPair(device);
  }

  // Pairing and unpairing helpers
  function pairDevice(device: var): void {
    BluetoothServiceUtils.pairDevice(device, root, Logger, ToastService, I18n);
  }

  // Windows pairs without a PIN prompt of ours, so there is nothing to submit.
  function submitPin(pin: var): void {
    root.pinRequired = false;
  }

  function cancelPairing() {
    BluetoothServiceUtils.cancelPairing(root);
  }

  // Pairing goes through the engine's BluetoothDevice.pair(); the name is upstream's.
  function pairWithBluetoothctl(device: var): void {
    BluetoothServiceUtils.pairWithBluetoothctl(device, root);
  }

  // Helper to run bluetoothctl and scripts with consistent error logging
  function btExec(args: var): void {
    BluetoothServiceUtils.btExec(args, Logger, Quickshell);
  }

  // Status key for a device (untranslated)
  function getStatusKey(device: var): string {
    return BluetoothServiceUtils.getStatusKey(device, BluetoothDeviceState.Connecting, BluetoothDeviceState.Disconnecting);
  }

  function unpairDevice(device: var): void {
    forgetDevice(device);
  }

  function getDeviceAutoConnect(device: var): bool {
    return BluetoothServiceUtils.getDeviceAutoConnect(device, cacheAdapter);
  }

  function setDeviceAutoConnect(device: var, enabled: var): void {
    BluetoothServiceUtils.setDeviceAutoConnect(device, enabled, cacheAdapter, cacheFileView);
  }

  function attemptAutoConnect(): void {
    BluetoothServiceUtils.attemptAutoConnect(root, NetworkService, Settings, autoConnectStepTimer);
  }

  function connectDeviceWithTrust(device: var): void {
    BluetoothServiceUtils.connectDeviceWithTrust(device, Logger, ToastService, I18n);
  }

  function disconnectDevice(device: var): void {
    BluetoothServiceUtils.disconnectDevice(device, Logger, ToastService, I18n);
  }

  function forgetDevice(device: var): void {
    BluetoothServiceUtils.forgetDevice(device, Logger, ToastService, I18n);
  }

  // Poll Bluetooth power state with bluetoothctl to handle a Quickshell bug on resume after suspend

  // Interactive pairing process
}
