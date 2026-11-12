.pragma library

function field(object, name) {
  return object[name];
}

function screenField(windowRoot, name) {
  return windowRoot?.screen?.[name];
}

function panelRegion(panel) {
  return panel?.panelRegion ?? null;
}

function includesScreen(monitors, screenName) {
  return monitors.length === 0 || monitors.includes(screenName);
}
