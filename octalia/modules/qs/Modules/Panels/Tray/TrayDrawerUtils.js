.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function fieldOrDefault(object, name, fallback) {
  const value = field(object, name);
  return value === undefined ? fallback : value;
}

function arrayLength(value) {
  return value && typeof value.length === "number" ? value.length : 0;
}

function wildcardMatch(str, rule) {
  if (!str || !rule)
    return false;
  const placeholder = "\uE000";
  const processedRule = String(rule).replace(/\*/g, placeholder);
  const escaped = processedRule.replace(/[.+?^${}()|[\]\\]/g, "\\$&");
  const pattern = "^" + escaped.replace(new RegExp(placeholder, "g"), ".*") + "$";
  try {
    return new RegExp(pattern, "i").test(String(str));
  } catch (e) {
    return false;
  }
}

function isPinned(item, pinnedList) {
  if (!item || arrayLength(pinnedList) === 0)
    return false;
  const title = field(item, "tooltipTitle") || field(item, "name") || field(item, "id") || "";
  for (let i = 0; i < arrayLength(pinnedList); i++) {
    if (wildcardMatch(title, pinnedList[i]))
      return true;
  }
  return false;
}

function iconSource(item) {
  const icon = field(item, "icon") || "";
  if (!icon)
    return "";
  if (icon.indexOf("?path=") >= 0) {
    const chunks = icon.split("?path=");
    const name = chunks[0];
    const path = chunks[1];
    const fileName = name.substring(name.lastIndexOf("/") + 1);
    return "file://" + path + "/" + fileName;
  }
  return icon;
}

function activate(item) {
  if (item && typeof item.activate === "function")
    item.activate();
}

function secondaryActivate(item) {
  if (item && typeof item.secondaryActivate === "function")
    item.secondaryActivate();
}

function scroll(item, up) {
  if (!item)
    return;
  if (up && typeof item.scrollUp === "function")
    item.scrollUp();
  else if (!up && typeof item.scrollDown === "function")
    item.scrollDown();
}

function closeOpenedPanel(panel) {
  if (panel && !field(panel, "isClosing") && typeof panel.close === "function")
    panel.close();
}

function trayMenuLoader(window) {
  return field(window, "trayMenuLoader") || null;
}

function popupVisible(window) {
  return !!field(window, "visible");
}

function closePopup(window) {
  if (window && typeof window.close === "function")
    window.close();
}

function hasMenu(item) {
  return !!(field(item, "hasMenu") && field(item, "menu"));
}

function showTrayMenu(service, screen, item, loader, icon, position, margin, section, index) {
  const menu = field(loader, "item");
  if (!service || !menu)
    return;
  let x;
  let y;
  if (position === "left") {
    x = icon.width + margin;
    y = 0;
  } else if (position === "right") {
    x = -menu.width - margin;
    y = 0;
  } else if (position === "bottom") {
    x = (icon.width / 2) - (menu.width / 2);
    y = icon.height + margin;
  } else {
    x = (icon.width / 2) - (menu.width / 2);
    y = icon.height + margin;
  }
  service.showTrayMenu(screen, item, menu, icon, x, y, section, index);
}

function isPassive(status, systemTray) {
  if (status === undefined)
    return false;
  return status === field(systemTray, "Passive") || status === 0;
}
