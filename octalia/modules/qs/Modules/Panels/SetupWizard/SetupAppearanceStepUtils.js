.pragma library

function arrayLength(value) {
  return value && typeof value.length === "number" ? value.length : 0;
}

function field(object, name) {
  return object ? object[name] : undefined;
}

function schemeColor(version, cache, darkMode, schemeName, key, fallback) {
  try {
    const mode = darkMode ? "dark" : "light";
    const scheme = field(cache, schemeName);
    const colors = field(scheme, mode);
    return field(colors, key) || fallback;
  } catch (e) {
    return fallback;
  }
}

function parseSchemeJson(text) {
  try {
    return JSON.parse(text);
  } catch (e) {
    return null;
  }
}
