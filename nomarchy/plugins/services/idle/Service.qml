import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "IdleModel.js" as IdleModel
import "IdleUtils.js" as IdleUtils
import qs.Commons as Commons

Item {
  id: root

  // Injected by nomarchy-shell (the first-party service loader).
  property var shell: null

  readonly property string home: (Quickshell.env("HOME") || "")
  readonly property string stayAwakeStateDir: home + "/.local/state/nomarchy/indicators"
  readonly property string stayAwakeStatePath: stayAwakeStateDir + "/stay-awake"
  readonly property int defaultScreensaverSeconds: 150
  readonly property int defaultLockSeconds: 300
  readonly property var idleConfig: IdleUtils.idleConfig(shell)
  readonly property int screensaverTimeoutSeconds: secondsFromConfig(IdleUtils.field(idleConfig, "screensaver"), defaultScreensaverSeconds)
  readonly property int lockTimeoutSeconds: secondsFromConfig(IdleUtils.field(idleConfig, "lock"), defaultLockSeconds)
  readonly property bool screensaverEnabled: screensaverTimeoutSeconds > 0
  readonly property bool lockEnabled: lockTimeoutSeconds > 0
  readonly property bool idleTimersEnabled: screensaverEnabled || lockEnabled
  readonly property int firstIdleTimeoutSeconds: IdleModel.firstIdleTimeout(screensaverTimeoutSeconds, lockTimeoutSeconds)
  readonly property int screensaverDelaySeconds: IdleModel.delayAfterFirstIdle(screensaverTimeoutSeconds, firstIdleTimeoutSeconds)
  readonly property int lockDelaySeconds: IdleModel.delayAfterFirstIdle(lockTimeoutSeconds, firstIdleTimeoutSeconds)
  readonly property bool idleEnabled: stayAwakeStateLoaded && !stayAwake

  property bool stayAwake: false
  property bool stayAwakeStateLoaded: false
  property bool hasPendingStayAwakePersist: false
  property bool pendingStayAwakePersist: false
  property bool idledThisCycle: false
  property bool screensaverStartedThisCycle: false
  property string lastEvent: "starting"
  property string lastEventAt: ""

  function secondsFromConfig(value: var, fallback: int): int {
    return IdleModel.secondsFromConfig(value, fallback)
  }

  function nowIso(): string {
    return new Date().toISOString()
  }

  function logEvent(event: string, details: var): void {
    var suffix = details === undefined || details === null || details === "" ? "" : ": " + String(details)
    root.lastEventAt = nowIso()
    root.lastEvent = event + suffix
    console.log("nomarchy idle " + root.lastEventAt + " " + root.lastEvent)
  }

  function runProcess(process: var, label: string, command: string): bool {
    return IdleUtils.runProcess(root, process, label, command)
  }

  function launchScreensaver(): void {
    root.screensaverStartedThisCycle = true
    screensaverLaunchGraceTimer.restart()
    runProcess(screensaverProcess, "screensaver", "[[ $(nomarchy-shell lock isLocked 2>/dev/null) == \"true\" ]] || nomarchy-launch-screensaver")
  }

  function lockSystem(reason: string): void {
    logEvent("lock-system", reason || "requested")
    screensaverTimer.stop()
    lockTimer.stop()
    screensaverLaunchGraceTimer.stop()
    root.idledThisCycle = false
    root.screensaverStartedThisCycle = false
    runProcess(lockProcess, "lock", "nomarchy-system-lock")
  }

  function startIdleCycle(): void {
    if (root.idledThisCycle) {
      logEvent("idle-cycle-already-running", undefined)
      return
    }

    logEvent("idle-cycle-start", "screensaver=" + root.screensaverTimeoutSeconds + " lock=" + root.lockTimeoutSeconds)
    root.idledThisCycle = true
    root.screensaverStartedThisCycle = false

    // Set this cycle's deadlines once: a bound interval would restart a pending
    // timer from the moment shell.json changes, locking early or late.
    if (root.screensaverEnabled) {
      if (root.screensaverDelaySeconds === 0) launchScreensaver()
      else {
        screensaverTimer.interval = root.screensaverDelaySeconds * 1000
        screensaverTimer.restart()
      }
    }

    if (root.lockEnabled) {
      if (root.lockDelaySeconds === 0) lockSystem("lock-timeout-immediate")
      else {
        lockTimer.interval = root.lockDelaySeconds * 1000
        lockTimer.restart()
      }
    }
  }

  function cancelIdleCycle(reason: string): void {
    logEvent("idle-cycle-cancel", reason || "requested")
    screensaverTimer.stop()
    lockTimer.stop()
    screensaverLaunchGraceTimer.stop()

    if (root.idledThisCycle) runProcess(wakeProcess, "wake", "nomarchy-system-wake")

    root.idledThisCycle = false
    root.screensaverStartedThisCycle = false
  }

  function handleActiveSignal(): void {
    if (!root.idledThisCycle) return

    // Starting the screensaver can make the compositor report activity, so the
    // launch grace ignores it.
    if (root.screensaverStartedThisCycle && screensaverLaunchGraceTimer.running) {
      logEvent("idle-monitor-active", "screensaver cycle remains armed")
      return
    }

    userReturned()
  }

  function userReturned(): void {
    // Input the screensaver never sees (a bound media key, a touchscreen) still means the user is back.
    if (root.screensaverStartedThisCycle) screensaverStopProcess.running = true
    cancelIdleCycle("activity")
  }

  function handleScreensaverExited(): void {
    // Closing while the user is active is a dismissal, even inside the launch grace.
    if (root.idleEnabled && root.idledThisCycle && root.screensaverStartedThisCycle && !idleMonitor.isIdle) {
      cancelIdleCycle("screensaver-dismissed")
    }
  }

  function handleIdleChanged(): void {
    logEvent("idle-monitor", idleMonitor.isIdle ? "idle" : "active")
    if (!root.idleEnabled || !root.idleTimersEnabled) return

    if (idleMonitor.isIdle) startIdleCycle()
    else handleActiveSignal()
  }

  function statusJson(): string {
    return JSON.stringify({
      enabled: root.idleEnabled,
      stayAwake: root.stayAwake,
      stayAwakeStateLoaded: root.stayAwakeStateLoaded,
      stayAwakeStatePath: root.stayAwakeStatePath,
      idle: idleMonitor.isIdle,
      inIdleCycle: root.idledThisCycle,
      screensaverStarted: root.screensaverStartedThisCycle,
      screensaver: root.screensaverTimeoutSeconds,
      lock: root.lockTimeoutSeconds,
      screensaverDelay: root.screensaverDelaySeconds,
      lockDelay: root.lockDelaySeconds,
      timers: {
        screensaver: screensaverTimer.running,
        lock: lockTimer.running,
        screensaverLaunchGrace: screensaverLaunchGraceTimer.running
      },
      processes: {
        screensaver: screensaverProcess.running,
        lock: lockProcess.running,
        wake: wakeProcess.running
      },
      lastEvent: root.lastEvent,
      lastEventAt: root.lastEventAt
    })
  }

  function persistStayAwake(value: bool): void {
    var command = value
      ? "mkdir -p \"$HOME/.local/state/nomarchy/indicators\" && touch \"$HOME/.local/state/nomarchy/indicators/stay-awake\""
      : "rm -f \"$HOME/.local/state/nomarchy/indicators/stay-awake\""

    if (stayAwakeStateWriter.running) {
      root.pendingStayAwakePersist = !!value
      root.hasPendingStayAwakePersist = true
      return
    }

    stayAwakeStateWriter.command = ["C:/Program Files/Git/usr/bin/bash.exe", "-lc", command]
    stayAwakeStateWriter.running = true
  }

  function refreshStayAwakeState(): void {
    if (!stayAwakeStateProbe.running) stayAwakeStateProbe.running = true
  }

  function applyStayAwake(value: bool, persist: bool, reason: string): string {
    var enabled = !!value
    var changed = !root.stayAwakeStateLoaded || root.stayAwake !== enabled

    if (persist) persistStayAwake(enabled)

    root.stayAwake = enabled
    root.stayAwakeStateLoaded = true

    if (!changed) return enabled ? "disabled" : "enabled"

    logEvent("stay-awake", (enabled ? "enabled" : "disabled") + (reason ? " " + reason : ""))
    if (enabled) cancelIdleCycle("stay-awake")
    else Qt.callLater(root.handleIdleChanged)

    return enabled ? "disabled" : "enabled"
  }

  function setIdleEnabled(value: bool): string {
    return applyStayAwake(!value, true, "ipc")
  }

  // With both timeouts at 0 the monitor stops reporting, so nothing else would end a running cycle.
  onIdleTimersEnabledChanged: if (!idleTimersEnabled) cancelIdleCycle("idle-timers-disabled")

  IdleMonitor {
    id: idleMonitor
    enabled: root.idleEnabled && root.idleTimersEnabled
    timeout: Math.max(1, root.firstIdleTimeoutSeconds)
    respectInhibitors: true
    onIsIdleChanged: root.handleIdleChanged()
  }

  Timer {
    id: screensaverTimer
    repeat: false
    onTriggered: if (root.screensaverEnabled) root.launchScreensaver()
  }

  Timer {
    id: lockTimer
    repeat: false
    onTriggered: {
      if (!root.idleEnabled || !root.idledThisCycle || !root.lockEnabled) return
      // A deadline inside the launch grace must not lock a user who is already back.
      if (root.screensaverStartedThisCycle && screensaverLaunchGraceTimer.running && !idleMonitor.isIdle) root.userReturned()
      else root.lockSystem("lock-timeout")
    }
  }

  Timer {
    id: screensaverLaunchGraceTimer
    interval: 3000
    repeat: false
    onTriggered: {
      if (root.idleEnabled && root.idledThisCycle && root.screensaverStartedThisCycle && !idleMonitor.isIdle) root.userReturned()
    }
  }

  Process {
    id: screensaverProcess
    onExited: function(exitCode, exitStatus) {
      root.logEvent("process-exit", "screensaver exitCode=" + exitCode + " status=" + exitStatus)
      root.handleScreensaverExited()
    }
  }
  Process {
    id: screensaverStopProcess
    command: ["pkill", "-f", "[/]usr/lib/nomarchy-screensaver/nomarchy-screensaver"]
  }
  Process {
    id: lockProcess
    onExited: function(exitCode, exitStatus) { root.logEvent("process-exit", "lock exitCode=" + exitCode + " status=" + exitStatus) }
  }
  Process {
    id: wakeProcess
    onExited: function(exitCode, exitStatus) { root.logEvent("process-exit", "wake exitCode=" + exitCode + " status=" + exitStatus) }
  }

  Process {
    id: stayAwakeStateProbe
    command: ["C:/Program Files/Git/usr/bin/bash.exe", "-c", "mkdir -p \"$HOME/.local/state/nomarchy/indicators\"; if [[ -f $HOME/.local/state/nomarchy/indicators/stay-awake ]]; then echo yes; else echo no; fi"]
    stdout: SplitParser {
      onRead: function(line) { root.applyStayAwake(String(line).trim() === "yes", false, "state-file") }
    }
    onExited: function() { stayAwakeStateDirWatcher.reload() }
  }

  Process {
    id: stayAwakeStateWriter
    onExited: function() {
      if (root.hasPendingStayAwakePersist) {
        let pending = root.pendingStayAwakePersist
        root.hasPendingStayAwakePersist = false
        root.persistStayAwake(pending)
        return
      }

      root.refreshStayAwakeState()
    }
  }

  FileView {
    id: stayAwakeStateDirWatcher
    path: root.stayAwakeStateDir
    watchChanges: true
    printErrors: false
    onFileChanged: root.refreshStayAwakeState()
  }

  Component.onCompleted: {
    logEvent("service-ready", undefined)
    refreshStayAwakeState()
  }

  Commons.ShellIpc {
    target: "idle"

    function status(): string {
      return root.statusJson()
    }

    function debug(): string {
      return root.statusJson()
    }

    function enable(): string {
      return root.setIdleEnabled(true)
    }

    function disable(): string {
      return root.setIdleEnabled(false)
    }

    function toggle(): string {
      return root.setIdleEnabled(!root.idleEnabled)
    }
  }
}
