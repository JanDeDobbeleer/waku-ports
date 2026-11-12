pragma Singleton

import "DarkModeUtils.js" as DarkModeUtils

import QtQuick 6.10
import Quickshell
import qs.Commons

Singleton {
  id: root

  property bool initComplete: false
  property bool nextDarkModeState: false

  Connections {
    target: LocationService.data
    enabled: Settings.data.colorSchemes.schedulingMode == "location"
    function onWeatherChanged() {
      if (DarkModeUtils.weather(LocationService.data) !== null) {
        const changes = root.collectWeatherChanges(DarkModeUtils.weather(LocationService.data));
        if (!root.initComplete) {
          root.initComplete = true;
          root.applyCurrentMode(changes);
        }
        root.scheduleNextMode(changes);
      }
    }
  }

  Connections {
    target: Settings.data.colorSchemes
    enabled: Settings.data.colorSchemes.schedulingMode == "manual"
    function onManualSunriseChanged() {
      const changes = root.collectManualChanges();
      root.applyCurrentMode(changes);
      root.scheduleNextMode(changes);
    }
    function onManualSunsetChanged() {
      const changes = root.collectManualChanges();
      root.applyCurrentMode(changes);
      root.scheduleNextMode(changes);
    }
  }

  Connections {
    target: Settings.data.colorSchemes
    function onSchedulingModeChanged() {
      root.update();
    }
  }

  Connections {
    target: Time
    function onResumed() {
      Logger.i("DarkModeService", "System resumed - re-evaluating dark mode");
      root.update();
      resumeRetryTimer.restart();
    }
  }

  Timer {
    id: timer
    onTriggered: {
      Settings.data.colorSchemes.darkMode = root.nextDarkModeState;
      root.update();
    }
  }

  Timer {
    id: resumeRetryTimer
    interval: 2000
    repeat: false
    onTriggered: {
      Logger.i("DarkModeService", "Resume retry - re-evaluating dark mode again");
      root.update();
    }
  }

  function init() {
    Logger.i("DarkModeService", "Service started");
    root.update();
  }

  function update() {
    if (Settings.data.colorSchemes.schedulingMode == "manual") {
      const changes = collectManualChanges();
      initComplete = true;
      applyCurrentMode(changes);
      scheduleNextMode(changes);
    } else if (Settings.data.colorSchemes.schedulingMode == "location" && DarkModeUtils.weather(LocationService.data)) {
      const changes = collectWeatherChanges(DarkModeUtils.weather(LocationService.data));
      initComplete = true;
      applyCurrentMode(changes);
      scheduleNextMode(changes);
    }
  }

  function parseTime(timeString: var): var {
    const parts = timeString.split(":").map(Number);
    return {
      "hour": parts[0],
      "minute": parts[1]
    };
  }

  function collectManualChanges(): var {
    return DarkModeUtils.collectManualChanges(root, Settings);
  }

  function collectWeatherChanges(weather: var): var {
    return DarkModeUtils.collectWeatherChanges(weather);
  }

  function applyCurrentMode(changes: var): void {
    DarkModeUtils.applyCurrentMode(changes, Settings, Logger);
  }

  function scheduleNextMode(changes: var): void {
    DarkModeUtils.scheduleNextMode(changes, root, Logger, timer);
  }
}
