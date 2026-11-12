.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function windowCount(compositor) {
  return Number(field(field(compositor, "windows"), "count")) || 0;
}

function windowAt(compositor, index) {
  const windows = field(compositor, "windows");
  return windows ? windows.get(index) : null;
}

function iconForApp(themeIcons, appId) {
  const findAppEntry = field(themeIcons, "findAppEntry");
  const entry = findAppEntry ? findAppEntry(appId) : null;
  return field(entry, "icon");
}

function setSearchText(launcher, text) {
  const setText = field(launcher, "setSearchText");
  if (setText)
    setText(text);
}

function activateWindow(windowEntry, launcher, compositor) {
  if (launcher)
    launcher.close();
  Qt.callLater(function () {
    const count = windowCount(compositor);
    for (let i = 0; i < count; i++) {
      const window = windowAt(compositor, i);
      if (field(window, "id") === field(windowEntry, "id")) {
        compositor.focusWindow(window);
        break;
      }
    }
  });
}
