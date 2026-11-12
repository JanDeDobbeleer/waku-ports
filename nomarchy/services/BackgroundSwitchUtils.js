.pragma library

function field(object, key) { return object ? object[key] : undefined }
function call(object, name, args) {
  if (!object) return undefined
  var method = object[name]
  return typeof method === "function" ? method.apply(object, args) : undefined
}
function keepCover(paths, current, remove) {
  var kept = []
  for (var i = 0; i < (paths ? paths.length : 0); i++) {
    var path = paths[i]
    if (path === current) kept.push(path)
    else remove(path)
  }
  return kept
}
