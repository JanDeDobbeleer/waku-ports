.pragma library

function field(object, key) { return object ? object[key] : undefined }
function idleConfig(shell) {
  var config = field(shell, "shellConfig")
  var idle = field(config, "idle")
  return idle ? idle : (field(shell, "idleConfig") || ({}))
}
function runProcess(root, process, label, command) {
  if (field(process, "running")) {
    root.logEvent("process-skip", label + " already running")
    return false
  }
  root.logEvent("process-start", label + " " + command)
  process.command = ["C:/Program Files/Git/usr/bin/bash.exe", "-lc", command]
  process.running = true
  return true
}
