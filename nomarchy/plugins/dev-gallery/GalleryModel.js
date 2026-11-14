.pragma library

function requestedSection(payload) {
  if (!payload) return ""
  try {
    var parsed = JSON.parse(String(payload))
    return parsed && typeof parsed.section === "string" ? parsed.section : ""
  } catch (e) {
    return ""
  }
}

function value(object, key) { return object == null ? undefined : object[key] }

function set(object, key, value) { if (object != null) object[key] = value }

function call(object, key, args) {
  var method = value(object, key)
  return typeof method === "function" ? method.apply(object, args || []) : undefined
}

function openCallback(root, requested) {
  return function() { call(root, "finishOpen", [requested]) }
}
