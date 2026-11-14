.pragma library

function _applyCustomMonitors(root, Settings, Logger) {
    var key;
    var i;
    // Destroy all existing custom monitors
    for (key in root._customMonitors) {
      if (root._customMonitors[key]) {
        root._customMonitors[key].destroy();
      }
    }
    root._customMonitors = {};

    const idle = Settings.data.idle;
    if (!idle.enabled)
      return;

    var entries = [];
    try {
      entries = JSON.parse(idle.customCommands);
    } catch (e) {
      Logger.w("IdleService", "Failed to parse customCommands:", e);
      return;
    }

    var newMonitors = {};
    for (i = 0; i < entries.length; i++) {
      const entry = entries[i];
      const timeoutSec = parseInt(entry.timeout);
      const cmd = entry.command;
      const resumeCmd = entry.resumeCommand || "";
      if (!cmd && !resumeCmd || timeoutSec <= 0)
        continue;
      try {
        const qml = `
          import Quickshell.Wayland
          IdleMonitor { timeout: ${timeoutSec} }
        `;

        const monitor = root._createIdleMonitor(qml, "IdleMonitor_custom_" + i);
        const capturedCmd = cmd;
        const capturedResumeCmd = resumeCmd;
        monitor.isIdleChanged.connect(function () {
          if (monitor.isIdle) {
            if (capturedCmd)
              root._executeCustomCommand(capturedCmd);
          } else {
            if (capturedResumeCmd)
              root._executeCustomCommand(capturedResumeCmd);
          }
        });
        newMonitors[i] = monitor;
        root._monitorsCreated = true;
        Logger.i("IdleService", "Custom monitor " + i + " created, timeout", timeoutSec, "s");
      } catch (e) {
        Logger.w("IdleService", "Failed to create custom monitor " + i + ":", e);
      }
    }
    root._customMonitors = newMonitors;
}

function _setMonitor(root, stage, timeoutSec, Logger) {
    const propName = "_" + stage + "Monitor";
    const existing = root[propName];

    if (timeoutSec <= 0) {
      if (existing) {
        existing.destroy();
        root[propName] = null;
        Logger.d("IdleService", stage + " monitor disabled");
      }
      return;
    }

    if (existing) {
      if (existing.timeout === timeoutSec)
        return;
      // ext-idle-notify-v1 has no update-timeout request — must recreate
      existing.destroy();
      root[propName] = null;
      Logger.d("IdleService", stage + " monitor timeout changed to", timeoutSec, "s, recreating");
    }

    try {
      const qml = `
        import Quickshell.Wayland
        IdleMonitor { timeout: ${timeoutSec} }
      `;

      const monitor = root._createIdleMonitor(qml, "IdleMonitor_" + stage);
      monitor.isIdleChanged.connect(function () {
        if (monitor.isIdle)
          root._onIdle(stage);
        else
          root.cancelFade();
      });
      root[propName] = monitor;
      root._monitorsCreated = true;
      Logger.i("IdleService", stage + " monitor created, timeout", timeoutSec, "s");
    } catch (e) {
      Logger.w("IdleService", "IdleMonitor not available (compositor lacks ext-idle-notify-v1):", e);
      root._monitorsCreated = false;
    }
}

function _ensureHeartbeat(root, Settings, Logger, Quickshell, idleCounter, overlayCleanupTimer) {
    if (root._heartbeatMonitor)
      return;
    try {
      const qml = `
        import Quickshell.Wayland
        IdleMonitor { timeout: 1 }
      `;

      const monitor = root._createIdleMonitor(qml, "IdleMonitor_heartbeat");
      monitor.isIdleChanged.connect(function () {
        if (monitor.isIdle) {
          root.idleSeconds = 1;
          idleCounter.start();
        } else {
          idleCounter.stop();
          root.idleSeconds = 0;
          if (root.fadePending === "lock" && Settings.data.idle.resumeLockCommand) {
            Logger.i("IdleService", "Executing lock resume command");
            Quickshell.execDetached(["cmd", "/c", Settings.data.idle.resumeLockCommand]);
          } else if (root.fadePending === "suspend" && Settings.data.idle.resumeSuspendCommand) {
            Logger.i("IdleService", "Executing suspend resume command");
            Quickshell.execDetached(["cmd", "/c", Settings.data.idle.resumeSuspendCommand]);
          }
          root.cancelFade();
          overlayCleanupTimer.stop();
        }
      });
      root._heartbeatMonitor = monitor;
      root._monitorsCreated = true;
      Logger.d("IdleService", "Heartbeat monitor created");
    } catch (e) {
      Logger.w("IdleService", "Heartbeat monitor failed:", e);
    }
}

function hasQueuedStages(stages) {
  return stages.length > 0;
}
