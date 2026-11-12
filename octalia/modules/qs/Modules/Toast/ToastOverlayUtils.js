.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function visibleScreens(screens, monitors) {
  const visible = [];
  for (let i = 0; i < screens.length; i++) {
    if (monitors.includes(field(screens[i], "name")))
      visible.push(screens[i]);
  }
  return visible.length === 0 ? screens : visible;
}
