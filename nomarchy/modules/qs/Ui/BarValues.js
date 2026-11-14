.pragma library

function foreground(bar) { return bar.foreground }
function fontFamily(bar) { return bar.fontFamily }
function urgent(bar) { return bar.urgent }
function barForeground(bar) { return bar.barForeground }

function vertical(bar) { return bar.vertical }
function barSize(bar) { return bar.barSize }

function switchPanel(bar, owner, direction) {
  return bar && typeof bar.switchPanelFrom === "function" ? bar.switchPanelFrom(owner, direction) : false
}

function setCenterHoverRevealSuppressed(bar, value) {
  if (bar && typeof bar.setCenterHoverRevealSuppressed === "function")
    bar.setCenterHoverRevealSuppressed(value)
  else if (bar && "centerHoverRevealSuppressed" in bar)
    bar.centerHoverRevealSuppressed = value
}

function moduleWidgets(bar, id, fallback) {
  return bar && typeof bar.moduleWidgets === "function" ? bar.moduleWidgets(id) : fallback
}
function broadcast(bar, id, fallback, method) {
  var items = moduleWidgets(bar, id, fallback)
  for (var i = 0; i < items.length; i++) {
    var item = items[i]
    if (item && typeof item[method] === "function") item[method].call(item)
  }
}

function position(bar) { return bar.position }
function sizeForScreen(bar, screen) {
  return typeof bar.barSizeFor === "function" && screen ? bar.barSizeFor(screen.name) : bar.barSize
}
function activePopout(bar) { return bar.activePopout }
function requestPopout(bar, owner) { bar.requestPopout(owner) }
function releasePopout(bar, owner) { bar.releasePopout(owner) }
function notePopoutCard(bar, card) {
  if (bar && typeof bar.notePopoutCard === "function") bar.notePopoutCard(card)
}
function popoutCardFor(bar, owner) {
  return bar && typeof bar.popoutCardFor === "function" ? bar.popoutCardFor(owner) : null
}
function clickTargets(bar) { return bar.clickTargets }
function targetBelongsToWindow(bar, target, window) {
  return !bar.targetBelongsToWindow || bar.targetBelongsToWindow(target, window)
}

function hasShell(bar) { return !!(bar && bar.shell) }
function hasUpdateEntryInline(bar) {
  return !!(bar && bar.shell && typeof bar.shell.updateEntryInline === "function")
}
function updateEntryInline(bar, id, entry) { return bar.shell.updateEntryInline(id, entry) }
function summon(bar, id, payload) { return bar.shell.summon(id, payload) }
function toggle(bar, id, payload) { return bar.shell.toggle(id, payload) }
function firstPartyServiceFor(bar, id) { return bar?.shell?.firstPartyServiceFor(id) }

function background(bar) { return bar.background }
function foregroundAnimationEnabled(bar) { return bar.foregroundAnimationEnabled }
function barHidden(bar) { return bar.barHidden }
function centerSectionRevealHeld(bar) { return bar.centerSectionRevealHeld }
function centerHoverRevealSuppressed(bar) { return bar.centerHoverRevealSuppressed }
function traySectionDragActive(bar) { return bar.traySectionDragActive }
function traySectionPopoutOpen(bar) { return bar.traySectionPopoutOpen }
function layoutConfig(bar) { return bar.layoutConfig }
function traySectionCount(bar) {
  return bar && bar.layoutConfig && Array.isArray(bar.layoutConfig.tray) ? bar.layoutConfig.tray.length : 0
}
function showTooltip(bar, target, text) { bar.showTooltip(target, text) }
function hideTooltip(bar, target) { bar.hideTooltip(target) }
function run(bar, command) { bar.run(command) }

function field(object, key) { return object === undefined || object === null ? undefined : object[key] }
function itemImplicitHeight(item) { return item ? item.implicitHeight : 0 }
function forceActiveFocus(item) {
  if (item && typeof item.forceActiveFocus === "function") item.forceActiveFocus()
}
function targetPressable(target) {
  return !!(target && target.triggerPress && target.visible !== false && target.opacity !== 0 && target.mapToItem)
}
function triggerPress(target, button) { target.triggerPress(button) }
function hasHeldButtons(target) { return !!(target && "heldButtons" in target) }
function setHeldButtons(target, buttons) {
  if (hasHeldButtons(target)) target.heldButtons = buttons
}
function screenName(screen) { return screen ? screen.name : "" }
function mapToItem(item, target, x, y) { return item.mapToItem(target, x, y) }
