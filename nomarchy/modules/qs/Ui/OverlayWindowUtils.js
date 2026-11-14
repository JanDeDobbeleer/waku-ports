.pragma library

function field(object, key) { return object ? object[key] : undefined }
function number(object, key) { return object ? Number(object[key]) : 0 }
function targetMonitor(monitors, screen) {
  var values = field(monitors, "values") || []
  var name = field(screen, "name")
  for (var i = 0; i < values.length; i++) {
    var monitor = values[i]
    if (screen && field(monitor, "name") === name) return monitor
  }
  return screen ? { name: name, scale: number(screen, "devicePixelRatio") } : null
}
