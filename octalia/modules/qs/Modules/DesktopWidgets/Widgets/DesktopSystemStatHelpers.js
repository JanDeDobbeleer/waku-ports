.pragma library

function field(item, name) {
  return item ? item[name] : undefined;
}

function fieldOrDefault(item, name, fallback) {
  var value = field(item, name);
  return value === undefined ? fallback : value;
}
