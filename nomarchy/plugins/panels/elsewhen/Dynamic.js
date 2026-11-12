.pragma library

function value(object, key) {
  return object == null ? undefined : object[key]
}

function length(object) {
  return object == null ? 0 : object.length
}

function call(object, key, args) {
  return object[key].apply(object, args || [])
}

function set(object, key, value) {
  object[key] = value
}
