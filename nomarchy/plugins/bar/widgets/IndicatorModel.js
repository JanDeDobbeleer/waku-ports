.pragma library

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value)
}

function entryId(entry) {
  if (typeof entry === "string") return entry
  if (isPlainObject(entry)) {
    let id = entry["id"]
    if (id !== undefined && id !== null && String(id) !== "") return String(id)
  }
  return ""
}

function entrySettings(entry) {
  if (!isPlainObject(entry)) return {}
  var copy = {}
  for (let key in entry) {
    if (key === "id") continue
    copy[key] = entry[key]
  }
  return copy
}

function entries(settings, defaults) {
  var source = defaults
  if (settings.items && typeof settings.items.length === "number" && settings.items.length > 0) source = settings.items
  else if (settings.indicators && typeof settings.indicators.length === "number" && settings.indicators.length > 0) source = settings.indicators
  var result = []
  for (let i = 0; i < source.length; i++) {
    let item = source[i]
    if (typeof item !== "string" && item !== null && typeof item === "object") {
      try {
        item = JSON.parse(JSON.stringify(item))
      } catch (error) {
      }
    }
    if (entryId(item) !== "") result.push(item)
  }
  return result
}

function orderedActiveIds(states, preferredOrder, entries) {
  var preferred = Array.from(preferredOrder || [])
  var available = Array.from(entries || [])
  var ids = []
  for (var i = 0; i < preferred.length; i++) {
    var id = preferred[i]
    var exists = false
    for (var j = 0; j < available.length; j++) {
      if (entryId(available[j]) === id) { exists = true; break }
    }
    if (ids.indexOf(id) === -1 && exists && states[id] === true) ids.push(id)
  }
  return ids
}

function updatedActiveStates(states, id, active) {
  var result = {}
  for (var key in states || {}) if (states[key] === true) result[key] = true
  if (active) result[id] = true
  else delete result[id]
  return result
}

function itemImplicitWidth(item) { return item ? item.implicitWidth : 0 }
function itemImplicitHeight(item) { return item ? item.implicitHeight : 0 }
function hasActiveSetter(module) { return !!module && typeof module.setIndicatorActive === "function" }
function setIndicatorActive(module, entry, active) {
  if (hasActiveSetter(module)) module.setIndicatorActive(entry, active)
}

function injectProps(target, bar, id, settings, block, host) {
  if (!target) return
  if ("bar" in target) target.bar = bar
  if ("moduleName" in target) target.moduleName = id
  if ("settings" in target) target.settings = settings
  if ("indicatorBlock" in target) target.indicatorBlock = block
  if ("indicatorHost" in target) target.indicatorHost = host
  if ("activeOverride" in target) target.activeOverride = block === "active" ? true : null
}

function isActive(target) { return !!target && target.active === true }
