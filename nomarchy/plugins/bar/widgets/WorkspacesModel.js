.pragma library

function monitorFor(monitors, screenName) {
  var list = Array.from(monitors || [])
  var want = String(screenName || "").toLowerCase()
  for (var i = 0; i < list.length; i++) {
    var name = String(list[i].name).toLowerCase()
    if (want === name || want.endsWith("\\" + name)) return list[i]
  }
  return list.length > 0 ? list[0] : null
}

function screenName(window) {
  var screen = window ? window.screen : null
  return screen ? String(screen.name) : ""
}

function slots(monitor, minimumSlots) {
  var list = monitor ? Array.from(monitor.workspaces || []) : []
  var out = []
  for (var i = 0; i < list.length; i++) {
    out.push({
      number: i + 1,
      active: !!(list[i].active || list[i].focused),
      occupied: !!list[i].hasWindows,
      exists: true
    })
  }
  for (var n = out.length + 1; n <= minimumSlots; n++)
    out.push({ number: n, active: false, occupied: false, exists: false })
  return out
}

function scroll(root, delta, wheel) {
  root.wheelAccumulator = wheel.remainder
  if (wheel.steps === 0) return
  var list = Array.from(root.slots || [])
  var current = -1
  for (var i = 0; i < list.length; i++) if (list[i].active) current = i
  if (current === -1) return
  var target = Math.max(0, Math.min(list.length - 1, current - wheel.steps))
  if (target !== current && list[target].exists) root.focusWorkspace(list[target].number)
}

function count(values) { return values ? values.length : 0 }
function label(slot) { return slot.active ? "\uf0c8" : String(slot.number) }
function opacity(slot) { return slot.active || slot.occupied ? 1 : 0.5 }
function canFocus(slot) { return !!slot.exists && !slot.active }
function number(slot) { return slot.number }
