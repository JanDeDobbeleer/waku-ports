.pragma library

function value(object, key) {
  return object == null ? undefined : object[key]
}
