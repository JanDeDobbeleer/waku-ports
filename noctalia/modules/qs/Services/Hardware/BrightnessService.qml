pragma Singleton

import QtQuick
import Quickshell
import waku.services as S
import qs.Commons
import qs.compat

// Noctalia's BrightnessService over the engine's ControlCenter: one brightness (0..100) of the display
// source the engine picked (WinRT or DDC/CI), shared by every screen. Upstream's sysfs, ddcutil and Apple
// display paths are gone, so `ddcMonitors` stays empty and every monitor reports method "internal". The
// backlight list of the settings tab is the engine's brightness sources; picking one calls
// setBrightnessSource.
Singleton {
  id: root

  property list<var> ddcMonitors: []
  readonly property list<Monitor> monitors: variants.instances
  property bool appleDisplayPresent: false
  // The engine's sources, as the identifiers the settings tab shows and sends back.
  readonly property list<var> availableBacklightDevices: (S.ControlCenter.brightnessSources || []).map(s => String(s.id ?? s.name ?? s))

  function getMonitorForScreen(screen: ShellScreen): var {
    return monitors.find(m => m.modelData === screen);
  }

  // Signal emitted when a specific monitor's brightness changes, includes monitor context
  signal monitorBrightnessChanged(var monitor, real newBrightness)

  function getAvailableMethods(): list<string> {
    return S.ControlCenter.brightnessAvailable ? ["internal"] : [];
  }

  // Global helpers for IPC and shortcuts
  function increaseBrightness(): void {
    monitors.forEach(m => m.increaseBrightness());
  }

  function decreaseBrightness(): void {
    monitors.forEach(m => m.decreaseBrightness());
  }

  function setBrightness(value: real): void {
    S.ControlCenter.setBrightness(Math.round(Math.max(0, Math.min(1, value)) * 100));
  }

  function getDetectedDisplays(): list<var> {
    return [];
  }

  function normalizeBacklightDevicePath(devicePath): string {
    return devicePath === undefined || devicePath === null ? "" : String(devicePath).trim();
  }

  function getBacklightDeviceName(devicePath): string {
    const key = normalizeBacklightDevicePath(devicePath);
    for (const s of (S.ControlCenter.brightnessSources || [])) {
      if (String(s.id ?? s.name ?? s) === key)
        return String(s.name ?? s.id ?? key);
    }
    return key;
  }

  function getMappedBacklightDevice(outputName): string {
    return String(S.ControlCenter.brightnessSource || "");
  }

  function setMappedBacklightDevice(outputName, devicePath): void {
    S.ControlCenter.setBrightnessSource(normalizeBacklightDevicePath(devicePath));
  }

  function scanBacklightDevices(): void {
    S.ControlCenter.refresh();
  }

  Component.onCompleted: Logger.i("Brightness", "Service started")

  Variants {
    id: variants
    model: Quickshell.screens
    Monitor {}
  }

  component Monitor: QtObject {
    id: monitor

    required property ShellScreen modelData
    readonly property bool isDdc: false
    readonly property string busNum: ""
    readonly property bool isAppleDisplay: false
    readonly property string method: "internal"
    readonly property bool brightnessControlAvailable: S.ControlCenter.brightnessAvailable

    // 0..1; the engine's value is a percentage
    readonly property real brightness: S.ControlCenter.brightness / 100

    signal brightnessUpdated(real newBrightness)

    readonly property Connections follow: Connections {
      target: S.ControlCenter
      function onBrightnessChanged() {
        monitor.brightnessUpdated(monitor.brightness);
        root.monitorBrightnessChanged(monitor, monitor.brightness);
      }
    }

    function setBrightness(value: real): void {
      root.setBrightness(value);
    }

    function setBrightnessDebounced(value: real): void {
      root.setBrightness(value);
    }

    function increaseBrightness(): void {
      const step = (Settings.data.brightness.brightnessStep || 5) / 100;
      setBrightness(Math.min(1, brightness + step));
    }

    function decreaseBrightness(): void {
      const step = (Settings.data.brightness.brightnessStep || 5) / 100;
      setBrightness(Math.max(0, brightness - step));
    }
  }
}
