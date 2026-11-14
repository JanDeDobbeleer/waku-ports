.pragma library

function field(object, key) { return object ? object[key] : undefined }
function arrayLength(value) { return value ? value.length : 0 }
function call(object, name, args) {
  if (!object) return undefined
  var method = object[name]
  return typeof method === "function" ? method.apply(object, args) : undefined
}
