import QtQuick
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons as Commons

// Stay awake: while it is on, Windows neither sleeps nor turns the display off. The choice is
// kept in state/.../indicators/stay-awake ("yes" or "no").
Item {
  id: root

  // Injected by the shell's service loader.
  property var shell: null

  readonly property string stayAwakeStateDir: Commons.Paths.home + "/.local/state/nomarchy/indicators"
  readonly property string stayAwakeStatePath: stayAwakeStateDir + "/stay-awake"
  readonly property bool idleEnabled: stayAwakeStateLoaded && !stayAwake

  property bool stayAwake: false
  property bool stayAwakeStateLoaded: false
  property string lastEvent: "starting"
  property string lastEventAt: ""

  function logEvent(event: string, details: var): void {
    var suffix = details === undefined || details === null || details === "" ? "" : ": " + String(details)
    root.lastEventAt = new Date().toISOString()
    root.lastEvent = event + suffix
    console.log("nomarchy idle " + root.lastEventAt + " " + root.lastEvent)
  }

  function statusJson(): string {
    return JSON.stringify({
      enabled: root.idleEnabled,
      stayAwake: root.stayAwake,
      stayAwakeStateLoaded: root.stayAwakeStateLoaded,
      stayAwakeStatePath: root.stayAwakeStatePath,
      lastEvent: root.lastEvent,
      lastEventAt: root.lastEventAt
    })
  }

  function applyStayAwake(value: bool, persist: bool, reason: string): string {
    var enabled = !!value
    var changed = !root.stayAwakeStateLoaded || root.stayAwake !== enabled

    if (persist) stayAwakeStateFile.setText(enabled ? "yes\n" : "no\n")

    root.stayAwake = enabled
    root.stayAwakeStateLoaded = true

    if (changed) logEvent("stay-awake", (enabled ? "enabled" : "disabled") + (reason ? " " + reason : ""))
    return enabled ? "disabled" : "enabled"
  }

  function setIdleEnabled(value: bool): string {
    return applyStayAwake(!value, true, "ipc")
  }

  // Waku maps the inhibitor to SetThreadExecutionState.
  IdleInhibitor {
    enabled: root.stayAwake
  }

  FileView {
    id: stayAwakeStateFile
    path: root.stayAwakeStatePath
    printErrors: false
    onLoaded: root.applyStayAwake(String(text() || "").trim() === "yes", false, "state-file")
    onLoadFailed: root.applyStayAwake(false, false, "state-file")
  }

  FileView {
    path: root.stayAwakeStateDir
    watchChanges: true
    printErrors: false
    onFileChanged: stayAwakeStateFile.reload()
  }

  Component.onCompleted: {
    logEvent("service-ready", undefined)
    stayAwakeStateFile.reload()
  }

  Commons.ShellIpc {
    target: "idle"

    function status(): string {
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
