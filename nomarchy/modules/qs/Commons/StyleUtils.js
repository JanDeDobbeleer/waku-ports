.pragma library

function get(object, key) {
  return object ? object[key] : undefined
}

function intField(raw) {
  try { return Number(JSON.parse(raw || "{}").int) } catch (error) { return NaN }
}

function gapsOutField(raw) {
  try {
    var json = JSON.parse(raw || "{}")
    var css = String(json.css || "")
    var parts = css.match(/-?\d+(?:\.\d+)?/g) || []
    return parts.length > 0 ? Number(parts[0]) : Number(json.int)
  } catch (error) { return NaN }
}

function reduceMotionValue(raw) {
  try { return JSON.parse(raw || "{}").bool === false } catch (error) { return undefined }
}

function boolValue(value, fallback) {
  if (value === undefined || value === null) return fallback
  var text = String(value).replace(/^\s+|\s+$/g, "").toLowerCase()
  if (text === "true" || text === "1" || text === "yes" || text === "on") return true
  if (text === "false" || text === "0" || text === "no" || text === "off") return false
  return fallback
}

function parseShellValues(values) {
  var fontOut = {}
  var barOut = {}
  var styleOut = {}
  var spacingOut = {}
  var nextBase = 12
  var nextSpacingScale = 1.0
  var nextSpacingScaleWithFont = true
  var nextBarScaleWithFont = true
  var input = values || {}
  for (var fullKey in input) {
    var dot = fullKey.indexOf(".")
    if (dot < 0) continue
    var section = fullKey.substr(0, dot)
    var key = fullKey.substr(dot + 1)
    var raw = input[fullKey]
    if (section === "font") {
      var integer = parseInt(raw, 10)
      if (!isFinite(integer)) continue
      if (key === "base-size") nextBase = integer
      else fontOut[key] = integer
    } else if (section === "bar") {
      if (key === "scale-with-font") nextBarScaleWithFont = boolValue(raw, nextBarScaleWithFont)
      else if (["size-horizontal", "size-vertical", "notch-height", "icon-slot", "icon-canvas", "icon-font", "icon-size", "status-slot"].indexOf(key) !== -1) {
        var barValue = parseInt(raw, 10)
        if (isFinite(barValue)) barOut[key] = barValue
      }
    } else if (section === "spacing") {
      if (key === "scale-with-font") nextSpacingScaleWithFont = boolValue(raw, nextSpacingScaleWithFont)
      else {
        var floatValue = parseFloat(raw)
        if (!isFinite(floatValue)) continue
        if (key === "scale") nextSpacingScale = floatValue
        else spacingOut[key] = floatValue
      }
    } else if (section === "controls" || section === "style") styleOut[key] = raw
  }
  if (!isFinite(nextBase) || nextBase < 1) nextBase = 1
  if (!isFinite(nextSpacingScale) || nextSpacingScale < 0) nextSpacingScale = 1.0
  return [fontOut, barOut, styleOut, spacingOut, nextBase, nextSpacingScale, nextSpacingScaleWithFont, nextBarScaleWithFont]
}
