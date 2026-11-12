.pragma library

function alpha(value, opacity) {
  var color = value
  if (!color) return Qt.rgba(0, 0, 0, opacity)
  if (typeof color === "string") color = Qt.color(color)
  return Qt.rgba(color.r, color.g, color.b, opacity)
}
function decodeBase64(value) {
  try { return Qt.atob(value) } catch (error) { return "" }
}
function parseModuleJson(raw) {
  var text = String(raw || "").trim()
  if (!text) return {}
  var lines = text.split("\n")
  try { return JSON.parse(lines[lines.length - 1]) } catch (error) { return { text: text } }
}
function field(object, key) { return object ? object[key] : undefined }
function setField(object, key, value) { if (object) object[key] = value }
function arrayLength(value) { return value ? value.length : 0 }

function itemContainsPoint(target, source, x, y) {
  if (!target || !target.contains(target.mapFromItem(source, x, y))) return false
  for (var item = target; item; item = item.parent) {
    if (!item.visible || item.opacity === 0 || !item.enabled) return false
    if (item.clip && !item.contains(item.mapFromItem(source, x, y))) return false
  }
  return true
}
