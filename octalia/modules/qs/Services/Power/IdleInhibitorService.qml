pragma Singleton

import "IdleInhibitorUtils.js" as IdleUtils

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Singleton {
  id: root

  property bool isInhibited: false
  property string reason: I18n.tr("system.user-requested")
  property var activeInhibitors: []
  property var timeout: null // in seconds

  // True when the native Wayland IdleInhibitor is handling inhibition
  // (set by the IdleInhibitor element in MainScreen via the nativeInhibitor property)
  property bool nativeInhibitorAvailable: false

  function init() {
    Logger.i("IdleInhibitor", "Service started");
  }

  // Add an inhibitor
  function addInhibitor(id: var, reason: var): bool {
    return IdleUtils.addInhibitor(root, Logger, id, reason);
  }

  // Remove an inhibitor
  function removeInhibitor(id: var): bool {
    return IdleUtils.removeInhibitor(root, Logger, id);
  }

  // Update the actual system inhibition
  function updateInhibition(newReason: var): void {
    IdleUtils.updateInhibition(root, newReason);
  }

  // Start system inhibition
  function startInhibition(newReason: var): void {
    reason = newReason;

    if (nativeInhibitorAvailable) {
      // Native IdleInhibitor in MainScreen handles it via isInhibited binding
      Logger.d("IdleInhibitor", "Native inhibitor active");
    } else {
      startSubprocessInhibition();
    }

    isInhibited = true;
    Logger.i("IdleInhibitor", "Started inhibition:", reason);
  }

  // Stop system inhibition
  function stopInhibition() {
    if (!isInhibited)
      return;

    if (!nativeInhibitorAvailable && inhibitorProcess.running) {
      inhibitorProcess.signal(15); // SIGTERM
    }

    isInhibited = false;
    Logger.i("IdleInhibitor", "Stopped inhibition");
  }

  // Subprocess fallback using systemd-inhibit
  function startSubprocessInhibition() {
    inhibitorProcess.command = ["systemd-inhibit", "--what=idle", "--why=" + reason, "--mode=block", "sleep", "infinity"];
    inhibitorProcess.running = true;
  }

  // Process for maintaining the inhibition (subprocess fallback only)
  Process {
    id: inhibitorProcess
    running: false

    onExited: function (exitCode, exitStatus) {
      if (root.isInhibited) {
        Logger.w("IdleInhibitor", "Inhibitor process exited unexpectedly:", exitCode);
        root.isInhibited = false;
      }
    }

    onStarted: function () {
      Logger.d("IdleInhibitor", "Inhibitor process started successfully");
    }
  }

  Timer {
    id: inhibitorTimeout
    repeat: true
    interval: 1000 // 1 second
    onTriggered: function () {
      if (root.timeout == null) {
        inhibitorTimeout.stop();
        return;
      }

      root.timeout -= 1;
      if (root.timeout <= 0) {
        root.removeManualInhibitor();
        return;
      }
    }
  }

  // Manual toggle for user control
  function manualToggle(): bool {
    // clear any existing timeout
    timeout = null;
    if (activeInhibitors.includes("manual")) {
      removeManualInhibitor();
      return false;
    } else {
      addManualInhibitor(null);
      return true;
    }
  }

  function changeTimeout(delta: var): void {
    if (timeout == null && delta < 0) {
      // no inhibitor, ignored
      return;
    }

    if (timeout == null && delta > 0) {
      // enable manual inhibitor and set timeout
      addManualInhibitor(timeout + delta);
      return;
    }

    if (timeout + delta <= 0) {
      // disable manual inhibitor
      removeManualInhibitor();
      return;
    }

    if (timeout + delta > 0) {
      // change timeout
      addManualInhibitor(timeout + delta);
      return;
    }
  }

  function removeManualInhibitor() {
    if (timeout !== null) {
      timeout = null;
      if (inhibitorTimeout.running) {
        inhibitorTimeout.stop();
      }
    }

    if (activeInhibitors.includes("manual")) {
      removeInhibitor("manual");
      ToastService.showNotice(I18n.tr("tooltips.keep-awake"), I18n.tr("common.disabled"), "keep-awake-off");
      Logger.i("IdleInhibitor", "Manual inhibition disabled");
    }
  }

  function addManualInhibitor(timeoutSec: var): void {
    if (!activeInhibitors.includes("manual")) {
      addInhibitor("manual", "Manually activated by user");
      ToastService.showNotice(I18n.tr("tooltips.keep-awake"), I18n.tr("common.enabled"), "keep-awake-on");
    }

    if (timeoutSec === null && timeout === null) {
      Logger.i("IdleInhibitor", "Manual inhibition enabled");
      return;
    } else if (timeoutSec !== null && timeout === null) {
      timeout = timeoutSec;
      inhibitorTimeout.start();
      Logger.i("IdleInhibitor", "Manual inhibition enabled with timeout:", timeoutSec);
      return;
    } else if (timeoutSec !== null && timeout !== null) {
      timeout = timeoutSec;
      Logger.i("IdleInhibitor", "Manual inhibition timeout changed to:", timeoutSec);
      return;
    } else if (timeoutSec === null && timeout !== null) {
      timeout = null;
      inhibitorTimeout.stop();
      Logger.i("IdleInhibitor", "Manual inhibition timeout cleared");
      return;
    }
  }

  // Clean up on shutdown
  Component.onDestruction: {
    stopInhibition();
  }
}
