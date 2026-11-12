.pragma library

function arrayLength(value) {
  return value && typeof value.length === "number" ? value.length : 0;
}
