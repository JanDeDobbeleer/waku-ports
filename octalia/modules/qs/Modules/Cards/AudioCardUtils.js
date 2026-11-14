.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}
