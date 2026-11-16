.pragma library

function field(object, key) { return object ? object[key] : undefined }
function setField(object, key, value) { if (object) object[key] = value }
function number(object, key) { var v = object ? Number(object[key]) : 0; return isFinite(v) ? v : 0 }
function flag(object, key) { return !!object && object[key] === true }
function arrayLength(value) { return value ? value.length : 0 }

// 75 -> "1:15", 3725 -> "1:02:05".
function clock(seconds) {
  var total = Math.max(0, Math.floor(Number(seconds) || 0))
  var h = Math.floor(total / 3600), m = Math.floor(total / 60) % 60, s = total % 60
  var ss = (s < 10 ? "0" : "") + s
  if (h > 0) return h + ":" + (m < 10 ? "0" : "") + m + ":" + ss
  return m + ":" + ss
}
function call(object, name, args) {
  if (!object) return undefined
  var method = object[name]
  return typeof method === "function" ? method.apply(object, args) : undefined
}
