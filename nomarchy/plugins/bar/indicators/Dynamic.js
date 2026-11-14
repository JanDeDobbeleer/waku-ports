.pragma library

function value(object, key) {
  return object == null ? undefined : object[key]
}

function call(object, key, args) {
  var method = value(object, key)
  return typeof method === "function" ? method.apply(object, args || []) : undefined
}

function array(value) {
  return value == null ? [] : Array.from(value)
}

function length(value) {
  return value == null ? 0 : value.length
}

function join(value, separator) {
  return array(value).join(separator)
}
