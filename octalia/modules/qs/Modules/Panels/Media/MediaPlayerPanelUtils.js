.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function setting(settings, name, fallback) {
  const value = field(settings, name);
  return value === undefined ? fallback : value;
}

function arrayLength(value) {
  return value && typeof value.length === "number" ? value.length : 0;
}
