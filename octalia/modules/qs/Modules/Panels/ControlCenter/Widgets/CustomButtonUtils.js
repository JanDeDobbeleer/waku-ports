.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function arrayLength(value) {
  return value && typeof value.length === "number" ? value.length : 0;
}

function parseStateChecks(value, logger) {
  try {
    return JSON.parse(value);
  } catch (error) {
    logger.e("CustomButton", "Failed to parse stateChecksJson:", error.message);
    return [];
  }
}
