function text(value) {
  return String(value || "").toLowerCase()
}

function itemNamed(item, name) {
  if (!item) return false
  return text(item.id).indexOf(name) !== -1
    || text(item.title).indexOf(name) !== -1
    || text(item.tooltipTitle).indexOf(name) !== -1
}

function entryId(entry) {
  if (typeof entry === "string") return entry
  if (entry && typeof entry === "object") {
    var id = entry.id
    if (id !== undefined && id !== null && String(id) !== "") return String(id)
  }
  return ""
}

function layoutHasWidget(layout, id) {
  var sections = ["left", "centerBegin", "center", "centerEnd", "right", "tray"]
  for (var s = 0; s < sections.length; s++) {
    var entries = layout && layout[sections[s]]
    if (!Array.isArray(entries)) continue
    for (var i = 0; i < entries.length; i++) {
      if (entryId(entries[i]) === id) return true
    }
  }
  return false
}

// A bar widget that stands in for an app's tray item takes its place: the app's
// own icon would only show the same thing twice.
var widgetsForTrayItems = [
  { widget: "nomarchy.dropbox", item: "dropbox" },
  { widget: "superwhisper.panel", item: "superwhisper" }
]

// LocalSend's item shows no state, offers only Open and Quit, and its primary
// click is a no-op, so Share > Receive is the whole surface. Hiding it by hand
// doesn't stick either: LocalSend picks a fresh tray id every launch.
function ownedByNomarchy(item, layout) {
  if (itemNamed(item, "localsend")) return true
  for (var i = 0; i < widgetsForTrayItems.length; i++) {
    var owner = widgetsForTrayItems[i]
    if (itemNamed(item, owner.item) && layoutHasWidget(layout, owner.widget)) return true
  }
  return false
}

// The stretch of the tray section, from `start` and `length` long along the
// bar, that the drawer's clip, from `clipStart` and `clipLength` long, shows:
// { start, length }, or null while it shows none of it. An empty section
// shows once it is within a pixel of the clip's edge, as the drawer eases to
// rest.
function shownSpan(clipStart, clipLength, start, length) {
  var from = Math.max(start, clipStart)
  var to = Math.min(start + length, clipStart + clipLength)
  if (to < from) {
    if (from - to > 1) return null
    from = to
  }
  return { start: from, length: to - from }
}


function sectionShown(item) { return item ? item.sectionShown : null }

if (typeof module !== "undefined") {
  module.exports = {
    shownSpan: shownSpan,
    itemNamed: itemNamed,
    entryId: entryId,
    layoutHasWidget: layoutHasWidget,
    ownedByNomarchy: ownedByNomarchy,
    field: field,
    fieldString: fieldString,
    currentTitle: currentTitle,
    currentChildren: currentChildren,
    resetTrayMenu: resetTrayMenu,
    leaveSubmenu: leaveSubmenu,
    openTrayMenu: openTrayMenu,
    tooltip: tooltip,
    classifyItem: classifyItem,
    bucket: bucket,
    sectionExtent: sectionExtent,
    itemTitle: itemTitle,
    itemMenu: itemMenu,
    triggered: triggered,
    displayName: displayName,
    isActive: isActive,
    activate: activate,
    scroll: scroll
  }
}

function settingArray(settings, key) {
  var value = settings ? settings[key] : null
  return value instanceof Array ? value : []
}

function field(item, key) { return item ? item[key] : undefined }
function fieldString(item, key) { return String(field(item, key) || "") }
function stackDepth(stack) { return stack.length }
function currentTitle(stack) {
  return stack && stack.length > 0 ? (stack[stack.length - 1].title || "") : ""
}
function currentChildren(stack, rootOpener) {
  return stack && stack.length > 0 ? stack[stack.length - 1].opener.children : rootOpener.children
}

function resetTrayMenu(root, flickable, timer) {
  root.menuLevelSettling = false
  timer.stop()
  flickable.contentY = 0
  var openers = root.submenuStack
  root.submenuStack = []
  for (var i = openers.length - 1; i >= 0; i--) openers[i].opener.destroy()
}

function leaveSubmenu(root) {
  if (root.submenuStack.length === 0) return
  var stack = root.submenuStack.slice()
  var top = stack.pop()
  root.submenuStack = stack
  top.opener.destroy()
  root.settleMenuLevel()
}

function openTrayMenu(root, item, anchorItem, mouse, openerComponent) {
  root.resetTrayMenu()
  root.activeTrayItem = item
  root.activeTrayAnchor = anchorItem
  root.trayMenuOpen = true
}

function tooltip(item) {
  return item ? (item.tooltipTitle || item.title || item.id || "") : ""
}
function classifyItem(item, pinned, hidden) {
  var id = String(field(item, "id") || "")
  if (hidden.indexOf(id) !== -1) return "hidden"
  if (pinned.indexOf(id) !== -1) return "pinned"
  return "drawer"
}
function bucket(values, category, pinned, hidden, owner, passiveStatus) {
  var list = values || []
  var result = []
  for (var i = 0; i < list.length; i++) {
    var item = list[i]
    if (item.status === passiveStatus || owner(item)) continue
    if (category === "all" || classifyItem(item, pinned, hidden) === category) result.push(item)
  }
  return result
}
function sectionExtent(section, vertical) {
  return section ? (vertical ? section.implicitHeight : section.implicitWidth) : 0
}
function itemTitle(item) {
  return item ? String(item.title || item.id || "") : ""
}
function itemMenu(item) { return item ? item.menu : null }
function triggered(item) { if (item) item.triggered() }
function displayName(item, fallback) {
  var title = String(field(item, "title") || "").trim()
  if (title) return title
  var tooltipTitle = String(field(item, "tooltipTitle") || "").trim()
  if (tooltipTitle) return tooltipTitle
  var id = String(field(item, "id") || "")
  var slash = id.lastIndexOf("/")
  return slash !== -1 ? id.substring(slash + 1) : (id || fallback)
}

function isActive(item, passiveStatus) { return !!item && item.status !== passiveStatus }
function activate(item, method) { if (item && typeof item[method] === "function") item[method]() }
function scroll(item, delta, horizontal) { if (item && typeof item.scroll === "function") item.scroll(delta, horizontal) }

function hasMenu(item) { return !!item && !!item.menu }
function mouseX(mouse) { return mouse ? Number(mouse.x) : 0 }
function mouseY(mouse) { return mouse ? Number(mouse.y) : 0 }

function mapAnchor(contentItem, anchor, x, y) { return contentItem.mapFromItem(anchor, x, y) }
