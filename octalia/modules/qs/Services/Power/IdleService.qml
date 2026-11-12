pragma Singleton

import "IdleServiceUtils.js" as IdleServiceUtils

import QtQuick 6.10
import Quickshell
import qs.Commons
import qs.Services.Compositor

/**
* IdleService — native idle detection via ext-idle-notify-v1 Wayland protocol.
*
* Three configurable stages:
*   1. Screen-off (DPMS)  — dims / turns off monitors
*   2. Lock screen        — activates the session lock
*   3. Suspend            — systemctl suspend
*
* Each stage shows a fade-to-black overlay for a configurable grace period
* before executing the action. Any mouse movement cancels the fade.
*
* IdleMonitor instances are created with Qt.createQmlObject() so the shell
* does not crash on compositors that lack the protocol.
*
* Timeouts come from Settings.data.idle (in seconds). 0 = disabled.
*/
Singleton {
  id: root

  // True if ext-idle-notify-v1 is supported by the compositor
  readonly property bool nativeIdleMonitorAvailable: _monitorsCreated

  // Live idle time in seconds (updated by the 1s heartbeat monitor)
  property int idleSeconds: 0

  // Fade overlay state — "" means no fade in progress
  property string fadePending: ""
  readonly property int fadeDuration: Settings.data.idle.fadeDuration

  property bool _monitorsCreated: false
  property var _screenOffMonitor: null
  property var _lockMonitor: null
  property var _suspendMonitor: null
  property var _heartbeatMonitor: null
  property var _customMonitors: ({})
  property var _queuedStages: []
  property bool _screenOffActive: false

  // Signals for external listeners (plugins, modules)
  signal screenOffRequested
  signal lockRequested
  signal suspendRequested

  // -------------------------------------------------------
  function init() {
    Logger.i("IdleService", "Service started");
    _applyTimeouts();
  }

  // Grace period timer — fires when fade completes without cancellation
  Timer {
    id: graceTimer
    interval: root.fadeDuration * 1000
    repeat: false
    onTriggered: {
      const action = root.fadePending;
      root._executeAction(action);
      overlayCleanupTimer.start();
    }
  }

  Timer {
    id: overlayCleanupTimer
    interval: 500
    repeat: false
    onTriggered: {
      root.fadePending = "";
      root._runNextQueuedStage();
    }
  }

  // Counts up idleSeconds while the heartbeat monitor reports idle
  Timer {
    id: idleCounter
    interval: 1000
    repeat: true
    onTriggered: root.idleSeconds++
  }

  // -------------------------------------------------------
  function cancelFade() {
    if (fadePending === "") {
      _queuedStages = [];
      _restoreMonitors();
      return;
    }
    Logger.i("IdleService", "Fade cancelled for:", fadePending);
    fadePending = "";
    _queuedStages = [];
    graceTimer.stop();
    overlayCleanupTimer.stop();
    _restoreMonitors();
  }

  function _restoreMonitors() {
    if (!_screenOffActive)
      return;
    _screenOffActive = false;
    Logger.i("IdleService", "Restoring monitors (DPMS on)");
    CompositorService.turnOnMonitors();

    if (Settings.data.idle.resumeScreenOffCommand) {
      Logger.i("IdleService", "Executing screen-off resume command");
      Quickshell.execDetached(["cmd", "/c", Settings.data.idle.resumeScreenOffCommand]);
    }
  }

  function _queueStage(stage: var): void {
    if (!_isValidStage(stage)) {
      Logger.w("IdleService", "Ignoring unknown queued stage:", stage);
      return;
    }
    if (stage === fadePending)
      return;
    if (_queuedStages.indexOf(stage) !== -1)
      return;
    _queuedStages.push(stage);
    Logger.d("IdleService", "Queued idle stage while fade is active:", stage);
  }

  function _isValidStage(stage: var): bool {
    return stage === "screenOff" || stage === "lock" || stage === "suspend";
  }

  function _isStageEnabled(stage: var): bool {
    const idle = Settings.data.idle;
    if (stage === "screenOff")
      return idle.screenOffTimeout > 0;
    if (stage === "lock")
      return idle.lockTimeout > 0;
    if (stage === "suspend")
      return idle.suspendTimeout > 0;
    return false;
  }

  function _runNextQueuedStage() {
    if (fadePending !== "")
      return;
    if (idleSeconds <= 0) {
      _queuedStages = [];
      return;
    }

    while (IdleServiceUtils.hasQueuedStages(_queuedStages)) {
      const nextStage = _queuedStages.shift();
      if (!_isValidStage(nextStage)) {
        Logger.w("IdleService", "Dropping queued unknown stage:", nextStage);
        continue;
      }
      if (!_isStageEnabled(nextStage)) {
        Logger.d("IdleService", "Dropping queued disabled stage:", nextStage);
        continue;
      }

      Logger.i("IdleService", "Running queued idle stage:", nextStage);
      _onIdle(nextStage);
      return;
    }
  }

  function _onIdle(stage: var): void {
    if (!_isValidStage(stage)) {
      Logger.w("IdleService", "Idle fired with unknown stage:", stage);
      return;
    }
    if (!_isStageEnabled(stage)) {
      Logger.d("IdleService", "Ignoring idle stage because it is disabled:", stage);
      return;
    }

    if (fadePending !== "") {
      _queueStage(stage);
      return;
    }
    Logger.i("IdleService", "Idle fired:", stage);
    fadePending = stage;
    graceTimer.restart();
  }

  function _executeAction(stage: var): void {
    Logger.i("IdleService", "Executing action:", stage);
    if (stage === "screenOff") {
      if (Settings.data.idle.screenOffCommand)
        Quickshell.execDetached(["cmd", "/c", Settings.data.idle.screenOffCommand]);
      CompositorService.turnOffMonitors();
      root._screenOffActive = true;
      root.screenOffRequested();
    } else if (stage === "lock") {
      if (Settings.data.idle.lockCommand)
        Quickshell.execDetached(["cmd", "/c", Settings.data.idle.lockCommand]);
      // Windows: no Octalia lock screen; a custom lock command replaces the default
      if (!Settings.data.idle.lockCommand)
        CompositorService.lock();
      root.lockRequested();
    } else if (stage === "suspend") {
      if (Settings.data.idle.suspendCommand)
        Quickshell.execDetached(["cmd", "/c", Settings.data.idle.suspendCommand]);
      if (Settings.data.general.lockOnSuspend) {
        CompositorService.lockAndSuspend();
      } else {
        CompositorService.suspend();
      }
      root.suspendRequested();
    } else {
      Logger.w("IdleService", "Unknown idle stage action:", stage);
    }
  }

  // -------------------------------------------------------
  // Re-apply when settings change
  Connections {
    target: Settings
    function onSettingsLoaded() {
      root._applyTimeouts();
    }
  }

  Connections {
    target: Settings.data.idle
    function onScreenOffTimeoutChanged() {
      root._applyTimeouts();
    }
    function onLockTimeoutChanged() {
      root._applyTimeouts();
    }
    function onSuspendTimeoutChanged() {
      root._applyTimeouts();
    }
    function onEnabledChanged() {
      root._applyTimeouts();
    }
    function onCustomCommandsChanged() {
      root._applyCustomMonitors();
    }
  }

  function _applyTimeouts() {
    const idle = Settings.data.idle;
    const globalEnabled = idle.enabled;

    _setMonitor("screenOff", globalEnabled ? idle.screenOffTimeout : 0);
    _setMonitor("lock", globalEnabled ? idle.lockTimeout : 0);
    _setMonitor("suspend", globalEnabled ? idle.suspendTimeout : 0);
    _ensureHeartbeat();
    _applyCustomMonitors();
  }

  function _createIdleMonitor(qml: var, name: var): QtObject {
    return Qt.createQmlObject(qml, root, name);
  }

  function _applyCustomMonitors(): void {
    IdleServiceUtils._applyCustomMonitors(root, Settings, Logger);
  }

  function _executeCustomCommand(cmd: var): void {
    Logger.i("IdleService", "Executing custom command:", cmd);
    Quickshell.execDetached(["cmd", "/c", cmd]);
  }

  function _setMonitor(stage: var, timeoutSec: var): void {
    IdleServiceUtils._setMonitor(root, stage, timeoutSec, Logger);
  }

  function _ensureHeartbeat(): void {
    IdleServiceUtils._ensureHeartbeat(root, Settings, Logger, Quickshell, idleCounter, overlayCleanupTimer);
  }
}
