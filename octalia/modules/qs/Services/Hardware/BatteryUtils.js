.pragma library

function isDevicePresent(device, batteryType) {
    if (!device) {
      return false;
    }

    // Handle Bluetooth devices (identified by having batteryAvailable property)
    if (device.batteryAvailable !== undefined) {
      return device.connected === true;
    }

    // Handle UPower devices
    if (device.type !== undefined) {
      if (device.type === batteryType && device.isPresent !== undefined) {
        return device.isPresent === true;
      }
      // Fallback for non-battery UPower devices or if isPresent is missing
      return device.ready && device.percentage !== undefined;
    }
    return false;
  }

function isDeviceReady(device, batteryType) {
    if (!isDevicePresent(device, batteryType)) {
      return false;
    }
    if (device.batteryAvailable !== undefined) {
      return device.battery !== undefined;
    }
    return device.ready && device.percentage !== undefined;
  }

function getPercentage(device) {
    if (!device) {
      return -1;
    }
    if (device.batteryAvailable !== undefined) {
      return Math.round((device.battery || 0) * 100);
    }
    return Math.round((device.percentage || 0) * 100);
  }

function isCharging(device, chargingState) {
    if (!device || isBluetoothDevice(device)) {
      // Tracking bluetooth devices can charge or not is a loop hole, none of my devices has it, even if it possible?!
      return false;  // Assuming not charging until someone/quickshell brings a way to do pretty unlikely.
    }
    if (device.state !== undefined) {
      return device.state === chargingState;
    }
    return false;
  }

function isPluggedIn(device, fullyChargedState, pendingChargeState) {
    if (!device || isBluetoothDevice(device)) {
      // Tracking bluetooth devices can charge or not is a loop hole, none of my devices has it, even if it possible?!
      return false;  // Assuming not charging until someone/quickshell brings a way to do pretty unlikely.
    }
    if (device.state !== undefined) {
      return device.state === fullyChargedState || device.state === pendingChargeState;
    }
    return false;
  }

function isBluetoothDevice(device) {
    if (!device) {
      return false;
    }
    // Check for Quickshell Bluetooth device property
    if (device.batteryAvailable !== undefined) {
      return true;
    }
    // Check for UPower device path indicating it's a Bluetooth device
    if (device.nativePath && (device.nativePath.includes("bluez") || device.nativePath.includes("bluetooth"))) {
      return true;
    }
    return false;
  }

function getDeviceName(device, root, I18n) {
    var match;
    if (!root.isDeviceReady(device)) {
      return "";
    }

    if (!root.isBluetoothDevice(device) && device.isLaptopBattery) {
      // If there is more than one battery explicitly name them
      // Logger.e("BatteryDebug", "Available Battery count: " + root.laptopBatteries.length); // can be useful for debugging
      if (root.laptopBatteries.length > 1 && device.nativePath) {
        if (device.nativePath === "DisplayDevice") {
          return I18n.tr("battery.all-batteries");
        }
        match = device.nativePath.match(/(\d+)$/);
        if (match) {
          // In case of 2 batteries: bat0 => bat1  bat1 => bat2
          return I18n.tr("common.battery") + " " + (parseInt(match[1]) + 1);  // Append numbers
        }
      }
      // Return Battery if there is only one
      return I18n.tr("common.battery");
    }

    if (root.isBluetoothDevice(device) && device.name) {
      return device.name;
    }

    if (device.model) {
      return device.model;
    }

    return "";
  }

function getIcon(percent, charging, pluggedIn, isReady) {
    if (!isReady) {
      return "battery-exclamation";
    }
    if (charging) {
      return "battery-charging";
    }
    if (pluggedIn) {
      return "battery-charging-2";
    }

    const icons = [
            {
              threshold: 86,
              icon: "battery-4"
            },
            {
              threshold: 56,
              icon: "battery-3"
            },
            {
              threshold: 31,
              icon: "battery-2"
            },
            {
              threshold: 11,
              icon: "battery-1"
            },
            {
              threshold: 0,
              icon: "battery"
            }
          ];

    const match = icons.find(tier => percent >= tier.threshold);
    return match ? match.icon : "battery-off"; // New fallback icon clearly represent if nothing is true here.
  }

function getRateText(device, I18n) {
    if (!device || device.changeRate === undefined) {
      return "";
    }
    const rate = Math.abs(device.changeRate);
    if (device.timeToFull > 0) {
      return I18n.trArgs("battery.charging-rate", {
                       "rate": rate.toFixed(2)
                     });
    } else if (device.timeToEmpty > 0) {
      return I18n.trArgs("battery.discharging-rate", {
                       "rate": rate.toFixed(2)
                     });
    }
  }

function getTimeRemainingText(device, root, I18n, Time) {
    if (!root.isDeviceReady(device)) {
      return I18n.tr("battery.no-battery-detected");
    }
    if (root.isPluggedIn(device)) {
      return I18n.tr("battery.plugged-in");
    } else if (device.timeToFull > 0) {
      return I18n.trArgs("battery.time-until-full", {
                       "time": Time.formatVagueHumanReadableDuration(device.timeToFull)
                     });
    } else if (device.timeToEmpty > 0) {
      return I18n.trArgs("battery.time-left", {
                       "time": Time.formatVagueHumanReadableDuration(device.timeToEmpty)
                     });
    }
    return I18n.tr("common.idle");
  }

function laptopBatteries(devices) {
  return devices.filter(d => d.isLaptopBattery).sort((x, y) => {
                                                                                                     // Force DisplayDevice to the top
                                                                                                     if (x.nativePath.includes("DisplayDevice"))
                                                                                                     return -1;
                                                                                                     if (y.nativePath.includes("DisplayDevice"))
                                                                                                     return 1;

                                                                                                     // Standard string comparison works for BAT0 vs BAT1
                                                                                                     return x.nativePath.localeCompare(y.nativePath, undefined, {
                                                                                                                                         numeric: true
                                                                                                                                       });
                                                                                                   });
}

function bluetoothBatteries(devices) {
    var btd, i;
    var list = [];
    var btArray = devices?.values || [];
    for (i = 0; i < btArray.length; i++) {
      btd = btArray[i];
      if (btd && btd.connected && btd.batteryAvailable) {
        list.push(btd);
      }
    }
    return list;
}

function findDevice(nativePath, root, UPower, linePowerType) {
    if (!nativePath || nativePath === "__default__" || nativePath === "DisplayDevice") {
      return root._laptopBattery;
    }

    if (!UPower.devices) {
      return null;
    }

    const devices = UPower.devices?.values || [];
    for (let d of devices) {
      if (d && d.nativePath === nativePath) {
        if (d.type === linePowerType) {
          continue;
        }
        return d;
      }
    }
    return null;
}

function checkDevice(device, root) {
    if (!device || !root.isDeviceReady(device)) {
      return;
    }

    const percentage = root.getPercentage(device);
    const charging = root.isCharging(device);
    const pluggedIn = root.isPluggedIn(device);
    const level = root.isLowBattery(device) ? "low" : (root.isCriticalBattery(device) ? "critical" : "");
    var deviceKey = device.nativePath;

    if (!root._hasNotified[deviceKey]) {
      root._hasNotified[deviceKey] = {
        low: false,
        critical: false
      };
    }

    if (charging || pluggedIn) {
      root._hasNotified[deviceKey].low = false;
      root._hasNotified[deviceKey].critical = false;
    }

    if (percentage > root.warningThreshold) {
      root._hasNotified[deviceKey].low = false;
      root._hasNotified[deviceKey].critical = false;
    } else if (percentage > root.criticalThreshold) {
      root._hasNotified[deviceKey].critical = false;
    }

    if (level) {
      if (!root._hasNotified[deviceKey][level]) {
        root.notify(device, level);
        root._hasNotified[deviceKey][level] = true;
      }
    }
}

function deviceModel(UPower, linePowerType, I18n) {
    var model = [
      {
        "key": "__default__",
        "name": I18n.tr("bar.battery.device-default")
      }
    ];
    const devices = UPower.devices?.values || [];
    for (let d of devices) {
      if (!d || d.type === linePowerType) {
        continue;
      }
      model.push({
                   key: d.nativePath || "",
                   name: d.model || d.nativePath || I18n.tr("common.unknown")
                 });
    }
    return model;
}

function firstOrNull(devices) {
  return devices.length > 0 ? devices[0] : null;
}

function deviceKey(modelData) {
  return modelData.key;
}

function skipDefaultNotification(device, modelData) {
  return device.isLaptopBattery && modelData.key !== "__default__";
}
