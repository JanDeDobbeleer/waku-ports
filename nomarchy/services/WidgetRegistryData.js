.pragma library

function register(widgets, id, component, metadata) {
  var key = String(id)
  var next = {}
  for (var k in widgets) next[k] = widgets[k]
  next[key] = { component: component, metadata: metadata || {} }
  return next
}

function unregister(widgets, id) {
  var key = String(id)
  var next = {}
  for (var k in widgets) if (k !== key) next[k] = widgets[k]
  return next
}

function contains(widgets, id) { return !!widgets[String(id)] }
function has(widgets, id) { return widgets[String(id)] !== undefined }
function metadataFor(widgets, id) {
  var entry = widgets[String(id)]
  return entry ? entry.metadata : null
}
function availableIds(widgets) { return Object.keys(widgets) }
function barSize(sizes, screenName) {
  var name = String(screenName || "")
  return sizes && Object.prototype.hasOwnProperty.call(sizes, name) ? Number(sizes[name]) : 0
}
