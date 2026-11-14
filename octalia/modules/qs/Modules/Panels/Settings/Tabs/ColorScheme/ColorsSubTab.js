.pragma library

function getSchemeColor(cache, version, schemeName, colorKey, darkMode, fallback) {
  const entry = cache[schemeName];
  if (!entry) return fallback;
  let variant = entry;
  if (entry.dark || entry.light) {
    variant = darkMode ? (entry.dark || entry.light) : (entry.light || entry.dark);
  }
  return variant && variant[colorKey] ? variant[colorKey] : fallback;
}

function loadScheme(text, path, owner) {
  const schemeName = owner.extractSchemeName(path);
  try {
    owner.schemeLoaded(schemeName, JSON.parse(text));
  } catch (e) {
    Logger.w("ColorSchemeTab", "Failed to parse JSON for scheme:", schemeName, e);
    owner.schemeLoaded(schemeName, null);
  }
}
