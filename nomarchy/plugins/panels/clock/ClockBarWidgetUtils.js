.pragma library

function field(object, name) { return object ? object[name] : undefined }
function hasProperty(object, name) { return !!object && name in object }
function setProperty(object, name, value) { if (object) object[name] = value }
function arrayLength(value) { return value ? value.length : 0 }
function call(object, name, args) {
  if (!object) return undefined
  var method = object[name]
  return typeof method === "function" ? method.apply(object, args) : undefined
}
