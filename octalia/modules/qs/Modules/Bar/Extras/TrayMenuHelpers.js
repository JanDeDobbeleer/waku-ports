.pragma library

function field(object, name) {
  return object === null || object === undefined ? undefined : object[name];
}

function trayItemName(item) {
  return item.tooltipTitle || item.name || item.id || "";
}

function menuText(item) {
  return item?.text !== "" ? item?.text.replace(/[\n\r]+/g, " ") : "...";
}

function setMenuScreen(trayMenu, screen) {
  if (trayMenu)
    trayMenu.menuScreen = screen;
}

function isTrayItemPinned(trayItem, screenName, widgetSection, widgetIndex, settings) {
  if (!trayItem || widgetSection === "" || widgetIndex < 0)
    return false;
  var widgets = settings.getBarWidgetsForScreen(screenName)[widgetSection];
  if (!widgets || widgetIndex >= widgets.length)
    return false;
  var widgetSettings = widgets[widgetIndex];
  if (!widgetSettings || widgetSettings.id !== "Tray")
    return false;
  var pinnedList = widgetSettings.pinned || [];
  var itemName = trayItem.tooltipTitle || trayItem.name || trayItem.id || "";
  for (var i = 0; i < pinnedList.length; i++) {
    if (pinnedList[i] === itemName)
      return true;
  }
  return false;
}function closeSubMenus(children, exceptItem) {
  for (var i = 0; i < children.length; i++) {
    var child = children[i];
    if (child !== exceptItem && child && child.subMenu) {
      child.subMenu.hideMenu();
      child.subMenu.destroy();
      child.subMenu = null;
    }
  }
}

function withoutItem(items, itemName) {
  var result = [];
  for (var i = 0; i < items.length; i++) {
    if (items[i] !== itemName)
      result.push(items[i]);
  }
  return result;
}
function copyChildren(children) {
  return children ? [...children.values] : [];
}

function mappedCoordinate(item, axis) {
  return item.mapToItem(null, 0, 0)[axis];
}

function strictField(object, name) {
  return object[name];
}

function focusItem(item) {
  item.forceActiveFocus();
}

function destroyItem(item) {
  item.destroy();
}

function closeAndDestroyMenu(menu) {
  menu.hideMenu();
  menu.destroy();
}

function createSubMenu(component, parent, menu, screen) {
  return component.createObject(parent, { menu: menu, isSubMenu: true, menuScreen: screen });
}

function positionSubMenu(menu, item, x) {
  menu.anchorItem = item;
  menu.anchorX = x;
  menu.anchorY = 0;
  menu.visible = true;
}

function callDynamicMenuCallback(window, action) {
  return window.dynamicMenuCallback(action);
}

function closePopupItem(item) {
  if (typeof item.hideMenu === "function")
    item.hideMenu();
  else if (typeof item.close === "function")
    item.close();
}

// Calling a method on an object reached through a property is shadowable to qmllint, so popups
// place themselves again through here.
function updateAnchor(anchor) {
  if (anchor)
    anchor.updateAnchor();
}
