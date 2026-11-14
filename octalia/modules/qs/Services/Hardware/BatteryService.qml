pragma Singleton
pragma ComponentBehavior: Bound
import QtQml
import QtQuick 6.10

import Quickshell
import Quickshell.Services.UPower
import "BatteryUtils.js" as BatteryUtils
import qs.Commons
import qs.Services.Networking
import qs.Services.UI

Singleton {
  id: root

  readonly property var primaryDevice: _laptopBattery || _bluetoothBattery || null // Primary battery device (prioritizes laptop over Bluetooth)
  readonly property real batteryPercentage: getPercentage(primaryDevice)
  readonly property bool batteryCharging: isCharging(primaryDevice)
  readonly property bool batteryPluggedIn: isPluggedIn(primaryDevice)
  readonly property bool batteryReady: isDeviceReady(primaryDevice)
  readonly property bool batteryPresent: isDevicePresent(primaryDevice)
  readonly property real warningThreshold: Settings.data.systemMonitor.batteryWarningThreshold
  readonly property real criticalThreshold: Settings.data.systemMonitor.batteryCriticalThreshold
  readonly property string batteryIcon: getIcon(batteryPercentage, batteryCharging, batteryPluggedIn, batteryReady)

  readonly property var laptopBatteries: BatteryUtils.laptopBatteries(UPower.devices.values)

  readonly property var bluetoothBatteries: BatteryUtils.bluetoothBatteries(BluetoothService.devices)

  readonly property var _laptopBattery: UPower.displayDevice.isPresent ? UPower.displayDevice : BatteryUtils.firstOrNull(laptopBatteries)
  readonly property var _bluetoothBattery: BatteryUtils.firstOrNull(bluetoothBatteries)

  property var deviceModel: BatteryUtils.deviceModel(UPower, UPowerDeviceType.LinePower, I18n)

  property var _hasNotified: ({})

  function findDevice(nativePath: var): var {
    return BatteryUtils.findDevice(nativePath, root, UPower, UPowerDeviceType.LinePower);
  }

  function isDevicePresent(device: var): var {
    return BatteryUtils.isDevicePresent(device, UPowerDeviceType.Battery);
  }

  function isDeviceReady(device: var): var {
    return BatteryUtils.isDeviceReady(device, UPowerDeviceType.Battery);
  }

  function getPercentage(device: var): var {
    return BatteryUtils.getPercentage(device);
  }

  function isCharging(device: var): bool {
    return BatteryUtils.isCharging(device, UPowerDeviceState.Charging);
  }

  function isPluggedIn(device: var): var {
    return BatteryUtils.isPluggedIn(device, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge);
  }

  function isCriticalBattery(device: var): bool {
    return (!isCharging(device) && !isPluggedIn(device)) && getPercentage(device) <= criticalThreshold;
  }

  function isLowBattery(device: var): bool {
    return (!isCharging(device) && !isPluggedIn(device)) && getPercentage(device) <= warningThreshold && getPercentage(device) > criticalThreshold;
  }

  function isBluetoothDevice(device: var): bool {
    return BatteryUtils.isBluetoothDevice(device);
  }

  function getDeviceName(device: var): var {
    return BatteryUtils.getDeviceName(device, root, I18n);
  }

  function getIcon(percent: var, charging: var, pluggedIn: var, isReady: var): var {
    return BatteryUtils.getIcon(percent, charging, pluggedIn, isReady);
  }

  function getRateText(device: var): var {
    return BatteryUtils.getRateText(device, I18n);
  }

  function getTimeRemainingText(device: var): var {
    return BatteryUtils.getTimeRemainingText(device, root, I18n, Time);
  }

  function checkDevice(device: var): void {
    BatteryUtils.checkDevice(device, root);
  }

  function notify(device: var, level: var): void {
    if (!Settings.data.notifications.enableBatteryToast) {
      return;
    }
    var name = getDeviceName(device);
    var titleKey = level === "critical" ? "toast.battery.critical" : "toast.battery.low";
    var descKey = level === "critical" ? "toast.battery.critical-desc" : "toast.battery.low-desc";

    var title = I18n.tr(titleKey);
    var desc = I18n.trArgs(descKey, {
                         "percent": getPercentage(device)
                       });
    var icon = level === "critical" ? "battery-exclamation" : "battery-charging-2";

    if (device == _bluetoothBattery && name) {
      title = title + " " + name;
    }

    // Only 'showNotice' supports custom icons
    ToastService.showNoticeDetailed(title, desc, icon, 6000, undefined, undefined);
  }

  Instantiator {
    model: root.deviceModel
    delegate: Connections {
      required property var modelData
      property var device: root.findDevice(BatteryUtils.deviceKey(modelData))
      target: device

      function onPercentageChanged() {
        if (BatteryUtils.skipDefaultNotification(device, modelData)) {
          return;
        }
        root.checkDevice(device);
      }
      function onStateChanged() {
        if (BatteryUtils.skipDefaultNotification(device, modelData)) {
          return;
        }
        root.checkDevice(device);
      }
    }
  }
}
