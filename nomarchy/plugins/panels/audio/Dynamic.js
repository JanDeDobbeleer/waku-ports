.pragma library

function value(object, key) {
  return object == null ? undefined : object[key]
}

function set(object, key, value) {
  object[key] = value
}

function call(object, key, args) {
  return object[key].apply(object, args || [])
}
