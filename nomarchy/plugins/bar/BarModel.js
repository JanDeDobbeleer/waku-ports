// The bar's sections in the order they run along it, and tray, drawn inside
// the tray's drawer, as Util.barSections has them. The center box sits in
// the middle of the bar, holding whatever the center section does as one
// centered group; centerBegin and centerEnd hang off its two edges.
var sections = ["left", "centerBegin", "center", "centerEnd", "right", "tray"]
var centerSections = ["centerBegin", "center", "centerEnd"]

function isPlainObject(value) {
  return !!value && typeof value === "object" && !Array.isArray(value)
}

function normalizePosition(value) {
  var next = String(value || "").trim()
  return /^(top|bottom|left|right)$/.test(next) ? next : "top"
}

function entrySettings(entry) {
  if (!isPlainObject(entry)) return {}
  var copy = {}
  for (var key in entry) {
    if (key === "id") continue
    copy[key] = entry[key]
  }
  return copy
}

function entryId(entry) {
  if (typeof entry === "string") return entry
  if (isPlainObject(entry)) {
    var id = entry["id"]
    if (id !== undefined && id !== null && String(id) !== "") return String(id)
  }
  return ""
}

function moduleString(entry, key, fallback) {
  var settings = entrySettings(entry)
  var value = settings[key]
  return value === undefined || value === null ? fallback : String(value)
}

// Panel tabbing and positional hotkeys take the center as one section: the
// box and the two sections hanging off it, in the order they read.
function navigationRegions(region) {
  var name = String(region || "")
  return centerSections.indexOf(name) !== -1 ? centerSections.slice() : [name]
}

// The edge the widget at `index` of the `count` in a section grows from: the
// section's own, or for the first and last of several, `firstEdge` and
// `lastEdge` where given. By the layout's order, so a widget hiding itself
// or a drag doesn't turn its neighbour around.
function slotEdge(count, index, fixedEdge, firstEdge, lastEdge) {
  if (count < 2) return fixedEdge
  if (firstEdge && index === 0) return firstEdge
  if (lastEdge && index === count - 1) return lastEdge
  return fixedEdge
}

function expandPath(value, home) {
  var path = String(value || "")
  if (path === "") return ""
  if (path.indexOf("~/") === 0) return home + path.substring(1)
  if (path.indexOf("$HOME/") === 0) return home + path.substring(5)
  return path
}

function customModuleSafeName(name) {
  var value = String(name || "")
  return value !== "" && value.indexOf("..") === -1 && value[0] !== "/"
}

function customModuleType(entry) {
  var settings = entrySettings(entry)
  var type = String(settings.type || "")
  if (type) return type
  if (settings.exec) return "command"
  if (settings.source) return "qml"
  return ""
}

function customModulePath(entry, home, configDir) {
  var settings = entrySettings(entry)
  var name = entryId(entry)
  var source = settings.source ? expandPath(settings.source, home) : ""
  if (!source && customModuleSafeName(name))
    source = String(configDir || "") + "/bar/modules/" + String(name) + ".qml"
  return source
}

// A widget's slot can be on a bar without being drawn: the widget has hidden
// itself, or a drag has folded its slot away. Panel routing has to pick a
// drawn one — it is the only one that can anchor a popup, carry the
// open-panel mark, or be found again by switchPanelFrom — and fall back to
// an undrawn one only when nothing is on screen.
function isDrawnSlot(slot) {
  return !!slot && slot.visible === true && slot.width > 0 && slot.height > 0
}

function pickDrawnSlot(slots) {
  var placeholder = null
  var list = slots || []
  for (var i = 0; i < list.length; i++) {
    if (!list[i]) continue
    if (isDrawnSlot(list[i])) return list[i]
    if (!placeholder) placeholder = list[i]
  }
  return placeholder
}

// A bar surface is built per monitor, so a panel hotkey has several live
// copies of the same widget to route to, and the panel opens on whichever
// monitor's copy answers. Candidates are `{ slot, screenName, opened }`.
//
// An open copy wins first: hide and toggle have to reach the panel the user
// can actually see, wherever it was opened from. Otherwise the focused
// monitor's copy wins, so a summon lands where the user is working instead of
// on whichever output registered its slot first. Neither narrowing applies on
// a single monitor, or when the focused output has no bar of its own.
function pickPanelSlot(candidates, focusedScreen) {
  var rows = Array.isArray(candidates) ? candidates : []
  var pool = rows.filter(function(row) { return row && row.opened === true })
  if (pool.length === 0) pool = rows.filter(function(row) { return !!row })

  var focused = String(focusedScreen || "")
  if (focused) {
    var onFocused = pool.filter(function(row) { return row.screenName === focused })
    if (onFocused.length > 0) pool = onFocused
  }

  return pickDrawnSlot(pool.map(function(row) { return row.slot }))
}

// Resolve a pointer anywhere along the bar to the closest insertion edge.
// Requiring the pointer to sit inside another widget makes the empty space
// around a centered group a dead zone, even though it visually reads as the
// most natural place to drop.
function nearestDropTarget(candidates, point, vertical) {
  var axis = vertical ? Number(point && point.y) : Number(point && point.x)
  var nearest = nearestEdge(candidates, axis, vertical)
  return nearest ? nearest.target : null
}

function nearestEdge(candidates, axis, vertical) {
  var rows = Array.isArray(candidates) ? candidates : []
  if (!isFinite(axis)) return null

  var best = null
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i]
    if (!row || !row.slot) continue

    var start = Number(vertical ? row.y : row.x)
    // A widget lifted out by a drag has no room left, but still answers at
    // the point it left, so the pointer can put it back.
    var size = Number(vertical ? row.height : row.width)
    if (!isFinite(start) || !isFinite(size) || size < 0) continue

    var beforeDistance = Math.abs(axis - start)
    var afterDistance = Math.abs(axis - (start + size))
    var after = afterDistance < beforeDistance
    var distance = after ? afterDistance : beforeDistance
    if (!best || distance < best.distance)
      best = { target: { slot: row.slot, after: after }, distance: distance }
  }
  return best
}

// A drop over the room the dragged widget (`source`, a candidate's slot)
// still holds, which puts it back, or null off it.
function ownRoomTarget(rows, axis, vertical, source) {
  var own = source ? rows.filter(function(row) { return row && row.slot === source })[0] : null
  if (!own) return null
  var start = Number(vertical ? own.y : own.x)
  var size = Number(vertical ? own.height : own.width)
  return size > 0 && axis >= start && axis <= start + size ? { slot: source, after: false } : null
}

// nearestDropTarget for a bar that draws the center box, given as where a
// drop lands in it ({ x, y, width, height }, centerDropZone). Over the box, a
// drop lands among the widgets it holds, or in it when it holds none. Off it,
// those widgets are out of reach, and the box's outer edges stand for the
// inner ends of centerBegin and centerEnd, which may be empty. A drop at the
// end of a section rather than beside a widget comes back as
// { region, after }: after its last widget, or before its first. Over the
// room the dragged widget (`source`, a candidate's slot) still holds, a drop
// puts it back, so a widget picked up beside an empty box, whose reach
// covers its inner end, isn't thrown into it as the drag starts.
function centerDropTarget(candidates, box, point, vertical, source) {
  var rows = Array.isArray(candidates) ? candidates : []
  if (!box) return nearestDropTarget(rows, point, vertical)
  var axis = vertical ? Number(point && point.y) : Number(point && point.x)
  var start = Number(vertical ? box.y : box.x)
  var end = start + Number(vertical ? box.height : box.width)
  if (!isFinite(axis) || !isFinite(start) || !isFinite(end)) return null

  var own = ownRoomTarget(rows, axis, vertical, source)
  if (own) return own

  if (axis >= start && axis <= end) {
    var inside = nearestEdge(rows.filter(function(row) { return row && row.region === "center" }), axis, vertical)
    return inside ? inside.target : { region: "center", after: true }
  }

  var outside = nearestEdge(rows.filter(function(row) { return row && row.region !== "center" }), axis, vertical)
  var beginDistance = Math.abs(axis - start)
  var endDistance = Math.abs(axis - end)
  var edge = beginDistance <= endDistance
    ? { target: { region: "centerBegin", after: true }, distance: beginDistance }
    : { target: { region: "centerEnd", after: false }, distance: endDistance }
  return outside && outside.distance <= edge.distance ? outside.target : edge.target
}

// The stretch of the bar over which a drop lands in the center box: the box
// ({ x, y, width, height }), or where it is shorter along the bar than
// `reach`, that length centered on it, so an empty box, which takes no room,
// can still be hit.
function centerDropZone(box, reach, vertical) {
  if (!box) return null
  var length = Number(vertical ? box.height : box.width)
  var grown = Math.max(length, Number(reach) || 0)
  var shift = (length - grown) / 2
  return vertical
    ? { x: box.x, y: box.y + shift, width: box.width, height: grown }
    : { x: box.x + shift, y: box.y, width: grown, height: box.height }
}

// The stretch of the bar over which a drop lands in the tray's drawer
// section ({ x, y, width, height }): the section and half of `reach`, the
// bar's thickness, past either end of it, so an empty section, which takes no
// room, is hit across the bar's thickness, as the empty center box is. The
// section grows from one end as room opens in it, and the stretch with it,
// so it always covers where it reached before. It stops that same half short
// of the tray's own ends (`tray`, where given), so a drop there lands beside
// the tray even where the section reaches them, with no pinned icons between;
// the stretch then runs on inward for the bar's thickness, as far as the
// tray allows.
function sectionDropZone(section, reach, vertical, tray) {
  if (!section) return null
  var pad = (Number(reach) || 0) / 2
  var start = (vertical ? section.y : section.x) - pad
  var end = (vertical ? section.y + section.height : section.x + section.width) + pad
  if (tray) {
    var low = (vertical ? tray.y : tray.x) + pad
    var high = Math.max(low, (vertical ? tray.y + tray.height : tray.x + tray.width) - pad)
    if (start < low) {
      start = low
      end = Math.max(end, Math.min(low + pad * 2, high))
    }
    if (end > high) {
      end = high
      start = Math.max(low, Math.min(start, high - pad * 2))
    }
  }
  return vertical
    ? { x: section.x, y: start, width: section.width, height: end - start }
    : { x: start, y: section.y, width: end - start, height: section.height }
}

// A drop over the tray's drawer section, given as where a drop lands in it
// (sectionDropZone): among the widgets in the section, or in it when it holds
// none. Over the room the dragged widget (`source`) still holds, it goes
// back. Null off the section, where the widgets in it are out of reach.
function traySectionDropTarget(candidates, zone, point, vertical, source) {
  if (!zone) return null
  var rows = Array.isArray(candidates) ? candidates : []
  var axis = vertical ? Number(point && point.y) : Number(point && point.x)
  var start = Number(vertical ? zone.y : zone.x)
  var end = start + Number(vertical ? zone.height : zone.width)
  if (!isFinite(axis) || !isFinite(start) || !isFinite(end) || axis < start || axis > end) return null

  var own = ownRoomTarget(rows, axis, vertical, source)
  if (own) return own

  var inside = nearestEdge(rows.filter(function(row) { return row && row.region === "tray" }), axis, vertical)
  return inside ? inside.target : { region: "tray", after: true }
}

// Where a drop opens room for the dragged widget (`source`, { key, region }):
// its section, and the index there of the widget the room goes before, or
// the section's length for its end, among the keys each section shows
// (`sections`, layoutWidgets). A place counts back over the widgets that
// draw nothing (missing from `drawn`, a set of keys, when given) and over the
// dragged widget, so after one widget and before the next drawn one are the
// same place, and the room cannot jump between the two as the pointer
// crosses it; either side of the dragged widget is where it already is,
// `home`. No drop, the pointer off the bar, is home too.
function dropRoom(drop, source, sections, drawn) {
  var keys = sections || {}
  function place(region, index) {
    var list = keys[region] || []
    while (index > 0 && (list[index - 1] === source.key || (drawn && !drawn[list[index - 1]]))) index--
    return index
  }
  var home = { region: source.region, index: place(source.region, (keys[source.region] || []).indexOf(source.key)), home: true }
  if (!drop || (drop.slot && drop.slot.widgetKey === source.key)) return home

  var region = drop.slot ? drop.slot.region : drop.region
  var list = keys[region] || []
  var index = drop.after ? list.length : 0
  if (drop.slot) {
    var at = list.indexOf(drop.slot.widgetKey)
    if (at === -1) return home
    index = at + (drop.after ? 1 : 0)
  }
  index = place(region, index)
  return { region: region, index: index, home: region === home.region && index === home.index }
}

// An entry as JSON with its keys in order, so a config written back with its
// keys sorted (nomarchy-shell-config does) reads as the same entry.
function entryJson(value) {
  if (Array.isArray(value)) return "[" + value.map(entryJson).join(",") + "]"
  if (isPlainObject(value))
    return "{" + Object.keys(value).sort().map(function(key) { return JSON.stringify(key) + ":" + entryJson(value[key]) }).join(",") + "}"
  var json = JSON.stringify(value)
  return json === undefined ? "null" : json
}

// Every widget on the bar, under a key it keeps wherever it moves, so that a
// widget moved to another section can be handed over rather than built again.
// `memo` holds the last layout's widgets. A move the bar writes itself sets
// `memo.expected` to the keys each section will show, so every widget keeps
// its own key, even beside another of the same id and settings. A layout
// written from elsewhere says nothing of which widget went where, so it is
// matched by entry: one that hasn't changed keeps its widget, and its entry
// object, so the widget hears of nothing; one whose settings changed takes a
// widget of its id the layout no longer needs, and is updated in place.
// Either looks in the entry's own section first, and there at the widget in
// the entry's place, so entries with one id don't trade widgets when one of
// them changes.
// Anything else is a new widget under a new key, as is a custom module whose
// entry changed, since it reads its entry directly and has to be rebuilt to
// pick a change up. Gives back the keys each section shows, in order, every
// key in a fixed order, and each key's entry. A widget the layout has just
// dropped keeps its entry there too, as it was, so it isn't handed empty
// settings on its way out. Maps keyed by id have no prototype, so an id like
// "constructor" is just an id.
function layoutWidgets(layout, memo) {
  var source = isPlainObject(layout) ? layout : {}
  var state = memo || {}
  var previous = state.widgets || Object.create(null)
  var planned = []
  for (var s = 0; s < sections.length; s++) {
    var list = Array.isArray(source[sections[s]]) ? source[sections[s]] : []
    for (var i = 0; i < list.length; i++)
      planned.push({ section: sections[s], index: i, id: entryId(list[i]), json: entryJson(list[i]), entry: list[i], custom: !!customModuleType(list[i]), key: "" })
  }

  var byId = Object.create(null)
  for (var old in previous) (byId[previous[old].id] || (byId[previous[old].id] = [])).push(old)
  var taken = Object.create(null)
  var expected = state.expected
  state.expected = null
  if (expected) planned.forEach(function(plan) {
    var key = (expected[plan.section] || [])[plan.index]
    var widget = key ? previous[key] : null
    if (!widget || taken[key] || widget.id !== plan.id || ((plan.custom || widget.custom) && widget.json !== plan.json)) return
    taken[key] = true
    plan.key = key
  })
  function take(fits) {
    planned.forEach(function(plan) {
      var keys = (plan.key ? [] : byId[plan.id] || []).filter(function(key) { return !taken[key] && fits(plan, previous[key]) })
      var inPlace = keys.filter(function(key) { return previous[key].section === plan.section && previous[key].index === plan.index })
      var key = inPlace[0] || keys[0]
      if (!key) return
      taken[key] = true
      plan.key = key
    })
  }
  take(function(plan, widget) { return widget.json === plan.json && widget.section === plan.section && widget.index === plan.index })
  take(function(plan, widget) { return widget.json === plan.json && widget.section === plan.section })
  take(function(plan, widget) { return widget.json === plan.json })
  take(function(plan, widget) { return !plan.custom && !widget.custom && widget.section === plan.section })
  take(function(plan, widget) { return !plan.custom && !widget.custom })

  var next = Object.create(null)
  var bySection = {}
  var entries = Object.create(null)
  for (var r = 0; r < sections.length; r++) bySection[sections[r]] = []
  for (var gone in previous) entries[gone] = previous[gone].entry
  planned.forEach(function(plan) {
    if (!plan.key) plan.key = plan.id + "#" + (state.serial = (state.serial || 0) + 1)
    var kept = previous[plan.key]
    var entry = kept && kept.json === plan.json ? kept.entry : plan.entry
    next[plan.key] = { id: plan.id, json: plan.json, entry: entry, custom: plan.custom, section: plan.section, index: plan.index }
    bySection[plan.section].push(plan.key)
    entries[plan.key] = entry
  })
  state.widgets = next
  return { sections: bySection, keys: Object.keys(next).sort(), entries: entries }
}

// The rows a section's model shows: one per widget, under its key
// (layoutWidgets), and a spacer before the widget at each index in `places`,
// or after the last for the section's length. A row holds nothing but its
// key and what kind it is, so a row comes back from `memo` as the same
// object for as long as it is shown, and a rebuilt layout signals only the
// rows added, moved and removed.
function sectionRows(keys, places, memo) {
  // Array.from, not Array.isArray: a QML list<string> is a sequence, not an Array.
  var list = keys ? Array.from(keys) : []
  var gaps = (Array.isArray(places) ? places : []).slice().sort(function(a, b) { return a - b })
  var state = memo || {}
  var cache = state.rows || Object.create(null)
  var next = Object.create(null)
  var rows = []

  function show(key, row) {
    next[key] = cache[key] || row
    rows.push(next[key])
  }

  var g = 0
  for (var i = 0; i <= list.length; i++) {
    for (; g < gaps.length && gaps[g] <= i; g++)
      show("room:" + gaps[g], { key: "room:" + gaps[g], kind: "spacer", place: gaps[g] })
    if (i === list.length) break
    show(String(list[i]), { key: String(list[i]), kind: "widget" })
  }
  state.rows = next
  return rows
}

// One frame of the room moving: every place but the target gives up `step`
// of the whole room, and the target holds what is left. A move crossfades
// the place left behind into the new one, however far apart, and the places
// together always hold the whole room, so a section keeps its length even
// when the target changes again before the last move has finished. Shares
// are keyed "region:index" (dropRoom); a place that has given up all of it
// is dropped.
function fadeShares(shares, target, step) {
  var next = {}
  var others = 0
  for (var key in shares || {}) {
    if (key === target) continue
    var share = Number(shares[key]) - step
    if (share > 0) {
      next[key] = share
      others += share
    }
  }
  if (target) next[target] = Math.max(0, 1 - others)
  return next
}

// The length each place takes of a room `extent` long, in whole pixels, since
// a layout places its items on whole pixels: the room's rounded length shared
// out by largest remainder, so the places add up to it exactly.
function roomLengths(extent, shares) {
  var places = Object.keys(shares || {})
  var raw = places.map(function(place) { return Number(extent) * Number(shares[place]) })
  var lengths = {}
  var total = Math.round(raw.reduce(function(sum, value) { return sum + value }, 0))
  var given = 0
  for (var i = 0; i < places.length; i++) {
    lengths[places[i]] = Math.floor(raw[i])
    given += lengths[places[i]]
  }
  var byRemainder = places.map(function(place, at) { return at })
  byRemainder.sort(function(a, b) { return (raw[b] - Math.floor(raw[b])) - (raw[a] - Math.floor(raw[a])) })
  for (var r = 0; r < total - given; r++) lengths[places[byRemainder[r]]]++
  return lengths
}

// The bar leaves out layout entries that aren't widgets, so it counts a
// section by the widgets in it. Where the widget the bar draws at `index`
// sits among a section's raw entries, or past them all for one past the last
// widget; -1 for an index further out than that.
function rawEntryIndex(entries, index, normalize) {
  var widgets = 0
  for (var i = 0; i < entries.length; i++) {
    if (!normalize(entries[i])) continue
    if (widgets === index) return i
    widgets++
  }
  return index === widgets ? entries.length : -1
}

function entryNormalizer(normalizeEntry) {
  return typeof normalizeEntry === "function" ? normalizeEntry : function(entry) { return entryId(entry) ? entry : null }
}

// Moves a dragged widget's entry in a shell config. `move` is
// { from: { region, index, id }, to: { region, index } }, with indexes into
// the sections as the bar draws them (rawEntryIndex) and `to.index` -1 for
// the end of the section. An entry at `from` that doesn't have the dragged
// widget's id leaves the config alone. Returns whether the layout changed.
function moveEntry(config, move, normalizeEntry) {
  var normalize = entryNormalizer(normalizeEntry)
  if (!isPlainObject(config) || !move || !move.from || !move.to) return false
  if (sections.indexOf(move.from.region) === -1 || sections.indexOf(move.to.region) === -1) return false
  if (!isPlainObject(config.bar)) config.bar = {}
  if (!isPlainObject(config.bar.layout)) config.bar.layout = {}
  var layout = config.bar.layout
  if (!Array.isArray(layout[move.from.region])) layout[move.from.region] = []
  if (!Array.isArray(layout[move.to.region])) layout[move.to.region] = []

  var fromEntries = layout[move.from.region]
  var toEntries = layout[move.to.region]
  var fromIndex = rawEntryIndex(fromEntries, Number(move.from.index), normalize)
  if (fromIndex < 0 || fromIndex >= fromEntries.length || entryId(normalize(fromEntries[fromIndex])) !== String(move.from.id)) return false

  var toIndex = Number(move.to.index) >= 0 ? rawEntryIndex(toEntries, Number(move.to.index), normalize) : toEntries.length
  if (toIndex < 0) toIndex = toEntries.length
  var sameSection = fromEntries === toEntries
  if (sameSection && fromIndex < toIndex) toIndex -= 1
  if (sameSection && fromIndex === toIndex) return false

  var entry = fromEntries.splice(fromIndex, 1)[0]
  toEntries.splice(toIndex, 0, entry)
  return true
}

// Drops a widget dragged off the bar from a shell config. `from` is
// { region, index, id }, as moveEntry's. Just the layout entry goes, the way
// a move only moves it: a clone dragged off vanishes rather than bringing
// back the widget it shadows, as disabling it in settings would. Returns
// whether the layout changed.
function removeEntry(config, from, normalizeEntry) {
  var normalize = entryNormalizer(normalizeEntry)
  if (!isPlainObject(config) || !from || sections.indexOf(from.region) === -1) return false
  var layout = isPlainObject(config.bar) && isPlainObject(config.bar.layout) ? config.bar.layout : null
  var entries = layout && Array.isArray(layout[from.region]) ? layout[from.region] : null
  if (!entries) return false

  var index = rawEntryIndex(entries, Number(from.index), normalize)
  if (index < 0 || index >= entries.length || entryId(normalize(entries[index])) !== String(from.id)) return false
  entries.splice(index, 1)
  return true
}

// How far a point sits outside a bar strip `width` by `height` at the
// origin, in pixels. Zero anywhere over the strip, so a drag along the bar
// never arms removal; past it, the straight-line distance to the nearest
// edge, so escaping by a corner takes the same pull as going straight off.
function dragDistanceOutside(point, width, height) {
  var x = Number(point && point.x)
  var y = Number(point && point.y)
  var w = Number(width)
  var h = Number(height)
  if (!isFinite(x) || !isFinite(y) || !isFinite(w) || !isFinite(h)) return 0

  var dx = x < 0 ? -x : (x > w ? x - w : 0)
  var dy = y < 0 ? -y : (y > h ? y - h : 0)
  return Math.sqrt(dx * dx + dy * dy)
}

// Display cutouts (a camera notch at the top of a laptop panel) are described
// by the platform's own package, in /usr/share/nomarchy-platform/display-cutouts.json:
//
//   { "panels": [ { "connector": "eDP", "width": 3024, "height": 1964, "top": 64 } ] }
//
// A panel matches a screen whose connector name starts with `connector` and
// whose mode is width x height physical pixels; `top` is how many physical rows
// at its top the cutout covers. Anything malformed is dropped.
function parseCutouts(text) {
  var parsed
  try {
    parsed = JSON.parse(String(text || ""))
  } catch (error) {
    return []
  }
  var panels = parsed && Array.isArray(parsed.panels) ? parsed.panels : []
  var cutouts = []
  for (var i = 0; i < panels.length; i++) {
    var panel = panels[i] || {}
    var width = Number(panel.width)
    var height = Number(panel.height)
    var top = Number(panel.top)
    if (typeof panel.connector !== "string" || panel.connector === "") continue
    if (!(width > 0) || !(height > 0) || !(top > 0) || top >= height) continue
    cutouts.push({ connector: panel.connector, width: width, height: height, top: top })
  }
  return cutouts
}

// The cutout at the top of this screen, in logical pixels, or 0. `mode` is the
// output's physical mode as Hyprland reports it ({ width, height, transform }).
// Qt's devicePixelRatio is a whole number even at a fractional scale, so the
// logical size times it rebuilds the mode only at whole scales; that stands in
// just until Hyprland's answer arrives. A mode Hyprland reports that matches no
// panel has no cutout.
function cutoutTop(cutouts, screenName, logicalWidth, logicalHeight, devicePixelRatio, mode) {
  var name = String(screenName || "")
  var logical = Number(logicalWidth)
  var logicalTall = Number(logicalHeight)
  if (!(logical > 0) || !(logicalTall > 0)) return 0
  var width = Number(mode && mode.width)
  var height = Number(mode && mode.height)
  if (width > 0 && height > 0) {
    // Turned a quarter or upside down, the cutout is on another edge.
    var transform = Number(mode.transform) || 0
    if (transform !== 0 && transform !== 4) return 0
    if ((width > height) !== (logical > logicalTall)) return 0
  } else {
    var scale = Number(devicePixelRatio) > 0 ? Number(devicePixelRatio) : 1
    width = Math.round(logical * scale)
    height = Math.round(logicalTall * scale)
  }
  var list = Array.isArray(cutouts) ? cutouts : []
  for (var i = 0; i < list.length; i++) {
    var panel = list[i]
    if (name.indexOf(panel.connector) !== 0) continue
    // Logical sizes are rounded, so a rebuilt mode can be a couple of pixels off.
    if (Math.abs(width - panel.width) <= 4 && Math.abs(height - panel.height) <= 4)
      return Math.ceil(panel.top * logical / width)
  }
  return 0
}

// The height a top bar on this screen must reach to cover its cutout, or a
// calibrated [bar] notch-height in its place. A screen without a cutout, or a
// bar on another edge, has no floor, so a calibration never reaches an
// external monitor.
function notchFloor(cutouts, position, screenName, logicalWidth, logicalHeight, devicePixelRatio, mode, calibrated) {
  if (position !== "top") return 0
  var top = cutoutTop(cutouts, screenName, logicalWidth, logicalHeight, devicePixelRatio, mode)
  if (!(top > 0)) return 0
  return Number(calibrated) > 0 ? Math.round(Number(calibrated)) : top
}

// A cutout covers the middle of a top bar, so that bar draws its center
// section beside the right one.
function centerBesideRight(cutouts, position, screenName, logicalWidth, logicalHeight, devicePixelRatio, mode) {
  return position === "top" && cutoutTop(cutouts, screenName, logicalWidth, logicalHeight, devicePixelRatio, mode) > 0
}

// Whether a top bar can't tell its floor yet: Hyprland hasn't reported the
// screen's mode, the logical size times Qt's ratio matched no panel (as at a
// fractional scale), and a described panel's connector matches the screen, so
// the mode may still bring a cutout. Such a bar waits for the mode before it
// maps rather than guess a floor. A screen no entry's connector matches never
// waits.
function cutoutPending(cutouts, position, screenName, logicalWidth, logicalHeight, devicePixelRatio, mode) {
  if (position !== "top") return false
  if (Number(mode && mode.width) > 0 && Number(mode && mode.height) > 0) return false
  var name = String(screenName || "")
  var list = Array.isArray(cutouts) ? cutouts : []
  var described = false
  for (var i = 0; i < list.length; i++) {
    if (name.indexOf(list[i].connector) === 0) described = true
  }
  return described && !(cutoutTop(cutouts, screenName, logicalWidth, logicalHeight, devicePixelRatio, mode) > 0)
}

// The bar's thickness on the screen with this name, from the sizes a bar
// publishes by screen name, or `fallback` (its configured size) for a screen
// it has none for.
function barSizeFor(sizes, screenName, fallback) {
  var name = String(screenName || "")
  var size = sizes && Object.prototype.hasOwnProperty.call(sizes, name) ? Number(sizes[name]) : 0
  return size > 0 ? size : fallback
}

// The indicator peek opens over the bar from its start up to where the center
// box starts, and stays shut past it, over the clock and the panel icons.
// `position` is the pointer's point on the bar surface.
function peeksAt(position, edge, vertical) {
  if (!position) return false
  return (vertical ? position.y : position.x) < edge
}

// Revealing the indicators can move the center box's start: beside a display
// notch the center sections hang off the right section, so indicators in
// centerEnd or the right section pull it toward the start. An edge that
// followed would slip out from under a stationary pointer and close the peek,
// and closing would slide it back and reopen it. So the edge is measured only
// while the peek is shut and held where it was while it is open.
function nextPeekEdge(edge, measured, held) {
  return held ? edge : measured
}

// Whether a workspace holds a real fullscreen window, which fades the bar out
// and has to take the clicks along its edge. Hyprland reports a maximized
// window as fullscreen 1 and a real one with bit 2 set; only the latter hides
// the bar. `toplevels` are Quickshell's Hyprland toplevels.
function fullscreenOn(toplevels, workspaceId) {
  var list = toplevels || []
  for (var i = 0; i < list.length; i++) {
    var toplevel = list[i]
    if (!toplevel || !toplevel.workspace || toplevel.workspace.id !== workspaceId) continue
    var ipc = toplevel.lastIpcObject
    if (ipc && (Number(ipc.fullscreen) & 2) !== 0) return true
  }
  return false
}

if (typeof module !== "undefined") {
  module.exports = {
    barSizeFor: barSizeFor,
    nextPeekEdge: nextPeekEdge,
    peeksAt: peeksAt,
    fullscreenOn: fullscreenOn,
    centerBesideRight: centerBesideRight,
    cutoutPending: cutoutPending,
    cutoutTop: cutoutTop,
    isDrawnSlot: isDrawnSlot,
    notchFloor: notchFloor,
    parseCutouts: parseCutouts,
    pickDrawnSlot: pickDrawnSlot,
    pickPanelSlot: pickPanelSlot,
    nearestDropTarget: nearestDropTarget,
    centerDropTarget: centerDropTarget,
    centerDropZone: centerDropZone,
    traySectionDropTarget: traySectionDropTarget,
    sectionDropZone: sectionDropZone,
    dropRoom: dropRoom,
    sectionRows: sectionRows,
    layoutWidgets: layoutWidgets,
    fadeShares: fadeShares,
    roomLengths: roomLengths,
    moveEntry: moveEntry,
    removeEntry: removeEntry,
    dragDistanceOutside: dragDistanceOutside,
    navigationRegions: navigationRegions,
    slotEdge: slotEdge,
    sections: sections,
    normalizePosition: normalizePosition,
    entrySettings: entrySettings,
    entryId: entryId,
    moduleString: moduleString,
    expandPath: expandPath,
    customModuleSafeName: customModuleSafeName,
    customModuleType: customModuleType,
    customModulePath: customModulePath,
    pluginObjectRecord: pluginObjectRecord,
    markPluginObject: markPluginObject,
    unmarkPluginObject: unmarkPluginObject,
    pluginOwnsBarObject: pluginOwnsBarObject,
    pluginShellFor: pluginShellFor,
    targetWindow: targetWindow,
    sameScreen: sameScreen,
    sameWindow: sameWindow,
    targetTooltipHovered: targetTooltipHovered,
    setShellBarPosition: setShellBarPosition,
    isFullscreenEvent: isFullscreenEvent,
    layoutSections: layoutSections,
    layoutWidgetKeys: layoutWidgetKeys,
    layoutWidgetEntries: layoutWidgetEntries,
    colorHex: colorHex,
    windowScreenPoint: windowScreenPoint,
    nearestScreenEdge: nearestScreenEdge,
    dragMove: dragMove,
    moduleRemoveDistance: moduleRemoveDistance,
    moduleTargetClickable: moduleTargetClickable,
    moduleClickTargetAt: moduleClickTargetAt,
    traySectionContains: traySectionContains,
    slotTraySectionContains: slotTraySectionContains,
    layoutSection: layoutSection,
    panelNavigationSlots: panelNavigationSlots,
    switchPanelFrom: switchPanelFrom,
    slotScreenName: slotScreenName,
    findPanelWidget: findPanelWidget,
    debugBarGeometry: debugBarGeometry,
    beginBarDrag: beginBarDrag,
    startDragRoom: startDragRoom,
    dropLandingItem: dropLandingItem,
    updateBarSettle: updateBarSettle,
    finishBarSettle: finishBarSettle,
    writeLayout: writeLayout,
    removeBarDrag: removeBarDrag,
    commitBarRemoval: commitBarRemoval,
    isPendingRemoval: isPendingRemoval,
    moduleHostsTraySection: moduleHostsTraySection,
    beginBarMove: beginBarMove,
    thicknessFor: thicknessFor,
    normalizeLayout: normalizeLayout,
    configObject: configObject,
    configPosition: configPosition,
    configBackground: configBackground,
    configLayout: configLayout,
    panelAction: panelAction,
    traySectionDropRectForSlot: traySectionDropRectForSlot,
    dragShareKey: dragShareKey,
    showTooltip: showTooltip,
    dropNonTrayCandidates: dropNonTrayCandidates,
    poofShown: poofShown,
    poofSpanX: poofSpanX,
    poofSpanY: poofSpanY,
    poofSize: poofSize,
    poofNoise: poofNoise,
    poofX: poofX,
    poofY: poofY,
    poofWidth: poofWidth,
    poofHeight: poofHeight,
    poofImage: poofImage,
    grabbedImageUrl: grabbedImageUrl,
    panelIndicatorItem: panelIndicatorItem,
    traySectionGeometry: traySectionGeometry,
    traySectionNow: traySectionNow,
    canReorder: canReorder,
    holdTarget: holdTarget,
    syncPluginBarApiObjects: syncPluginBarApiObjects,
    centerBoxDropRect: centerBoxDropRect,
    dragSourceItem: dragSourceItem,
    dragGhostWidth: dragGhostWidth,
    dragGhostHeight: dragGhostHeight,
    traySectionDragActive: traySectionDragActive,
    rectOrEmpty: rectOrEmpty,
    syncPeekEdge: syncPeekEdge,
    pointX: pointX,
    pointY: pointY,
    updateCommandModule: updateCommandModule,
    listHasRows: listHasRows,
    rowKey: rowKey,
    rowPlace: rowPlace,
    hostDragSource: hostDragSource,
    isFirstParty: isFirstParty,
    widgetWidth: widgetWidth,
    widgetHeight: widgetHeight,
    widgetWidthFromHost: widgetWidthFromHost,
    widgetHeightFromHost: widgetHeightFromHost,
    widgetParent: widgetParent,
    injectWidgetProps: injectWidgetProps,
    ownerFixedEdge: ownerFixedEdge,
    rectLength: rectLength,
    rectX: rectX,
    rectY: rectY,
    releaseWidgetSlot: releaseWidgetSlot,
    removeWidgetHost: removeWidgetHost,
    claimWidgetSlot: claimWidgetSlot,
    addWidgetHost: addWidgetHost,
    draggedWidgetWidth: draggedWidgetWidth,
    draggedWidgetHeight: draggedWidgetHeight,
    pluginBarApiFor: pluginBarApiFor,
    draggedLength: draggedLength,
    moveDragRoom: moveDragRoom,
    drawnKeys: drawnKeys
  }
}

function mapToItemSafely(item, x, y) {
  try { return item.mapToItem(null, x, y) } catch (e) { return null }
}

function traySectionDropRect(area, shown, reach, vertical) {
  try {
    var origin = area.mapToItem(null, shown.x, shown.y)
    var section = { x: origin.x, y: origin.y, width: shown.width, height: shown.height }
    var corner = area.mapToItem(null, 0, 0)
    var tray = { x: corner.x, y: corner.y, width: area.width, height: area.height }
    return sectionDropZone(section, reach, vertical, tray)
  } catch (e) {
    return null
  }
}

function mutateShellConfig(shell, memo, expected, edit) {
  memo.expected = expected
  try {
    shell.mutateShellConfig(edit)
  } finally {
    memo.expected = null
  }
}

function copyPopoutCard(card, section) {
  return card ? { screen: String(card.screen || ""), section: section,
    x: Number(card.x) || 0, y: Number(card.y) || 0,
    width: Number(card.width) || 0, height: Number(card.height) || 0 } : null
}

function popoutCardFor(card, section) {
  if (!card || !card.section || card.section !== section) return null
  return { screen: card.screen, x: card.x, y: card.y, width: card.width, height: card.height }
}

function dropRegion(target) {
  return target ? (target.slot ? target.slot.region : target.region) : ""
}

function pluginObjectRecord(owners, target) {
  return target ? (owners.get(target) || null) : null
}

function markPluginObject(owners, pluginId, target, role) {
  if (!pluginId || !target) return false
  var record = pluginObjectRecord(owners, target)
  if (record && record.pluginId !== pluginId) return false
  if (!record) {
    record = { target: target, pluginId: pluginId, clickTarget: false, popout: false }
    owners.set(target, record)
  }
  record[role] = true
  return true
}

function unmarkPluginObject(owners, pluginId, target, role) {
  var record = pluginObjectRecord(owners, target)
  if (!record || record.pluginId !== pluginId) return
  record[role] = false
  if (!record.clickTarget && !record.popout) owners.delete(target)
}

function pluginOwnsBarObject(owners, pluginId, target) {
  var record = target ? pluginObjectRecord(owners, target) : null
  return !!record && record.pluginId === String(pluginId || "")
}

function pluginShellFor(shell, registered, moduleName, key) {
  if (registered && shell && typeof shell.pluginShellForId === "function")
    return shell.pluginShellForId(moduleName)
  if (shell && typeof shell.pluginShellForBarEntry === "function")
    return shell.pluginShellForBarEntry(key, moduleName)
  return null
}

var windowResolver = null

function setWindowResolver(resolver) {
  windowResolver = resolver
}

function targetWindow(target) {
  return target && windowResolver ? windowResolver(target) : null
}

function sameScreen(left, right) {
  if (!left || !right) return false
  if (left === right) return true
  return !!left.name && !!right.name && left.name === right.name
}

function sameWindow(left, right) {
  if (!left || !right) return false
  if (left === right) return true
  return sameScreen(left.screen, right.screen)
}

function targetTooltipHovered(target) {
  return !!target && target.visible !== false && target.opacity !== 0 && target.tooltipHovered === true
}

function setShellBarPosition(shell, position) {
  if (!shell || typeof shell.mutateShellConfig !== "function") return false
  shell.mutateShellConfig(function(config) {
    if (!isPlainObject(config.bar)) config.bar = {}
    config.bar.position = position
  })
  return true
}

function isFullscreenEvent(event) {
  return !!event && String(event.name) === "fullscreen"
}

function layoutSections(widgets) {
  return widgets ? widgets.sections : {}
}

function layoutWidgetKeys(widgets) {
  return widgets ? widgets.keys : []
}

function layoutWidgetEntries(widgets) {
  return widgets ? widgets.entries : {}
}

function colorHex(value) {
  function channel(number) {
    var s = Math.round(Math.max(0, Math.min(1, number)) * 255).toString(16)
    return s.length < 2 ? "0" + s : s
  }
  return "#" + channel(value.r) + channel(value.g) + channel(value.b)
}

function windowScreenPoint(scenePoint, window, position) {
  var x = scenePoint ? scenePoint.x : 0
  var y = scenePoint ? scenePoint.y : 0
  if (!window || !window.screen) return { x: x, y: y }
  if (position === "bottom") y += Math.max(0, window.screen.height - window.height)
  else if (position === "right") x += Math.max(0, window.screen.width - window.width)
  return { x: x, y: y }
}

function nearestScreenEdge(point, screen) {
  var nx = screen.width > 0 ? Math.max(0, Math.min(1, point.x / screen.width)) : 0.5
  var ny = screen.height > 0 ? Math.max(0, Math.min(1, point.y / screen.height)) : 0.5
  var edge = "top"
  var best = ny
  if (1 - ny < best) { edge = "bottom"; best = 1 - ny }
  if (nx < best) { edge = "left"; best = nx }
  if (1 - nx < best) edge = "right"
  return edge
}

function dragMove(room, source, sections, keys) {
  if (!room || room.home || !source) return null
  var list = sections || {}
  var region = room.region
  var section = list[region] || []
  var fromSection = list[source.region] || []
  var count = section.length
  return {
    key: source.widgetKey,
    from: { region: source.region, index: fromSection.indexOf(source.widgetKey), id: entryId(source.entry) },
    to: { region: region, index: room.index < count ? room.index : -1 },
    keys: keys
  }
}

function moduleRemoveDistance(screenPoint, screen, thickness, vertical, position) {
  if (!screen) return 0
  var x = screenPoint.x
  var y = screenPoint.y
  if (vertical) {
    if (position === "right") x -= Math.max(0, screen.width - thickness)
    return dragDistanceOutside({ x: x, y: y }, thickness, screen.height)
  }
  if (position === "bottom") y -= Math.max(0, screen.height - thickness)
  return dragDistanceOutside({ x: x, y: y }, screen.width, thickness)
}

function moduleTargetClickable(target) {
  return !!target && target.visible !== false && target.opacity !== 0
    && target.interactive !== false && target.pressable !== false && target.concealed !== true
    && typeof target.triggerPress === "function"
}

function moduleClickTargetAt(targets, slot, localX, localY, util) {
  var list = targets || []
  for (var i = list.length - 1; i >= 0; i--) {
    var target = list[i]
    if (moduleTargetClickable(target) && util.itemContainsPoint(target, slot, localX, localY)) return target
  }
  return slot && moduleTargetClickable(slot.activeItem) ? slot.activeItem : null
}

function traySectionContains(slot, area, x, y) {
  if (!area || !area.visible || area.width <= 0 || area.height <= 0) return false
  try {
    var point = slot.mapToItem(area, x, y)
    return point.x >= 0 && point.y >= 0 && point.x <= area.width && point.y <= area.height
  } catch (error) {
    return false
  }
}

function slotTraySectionContains(slot, x, y) {
  var area = slot && slot.hostsTraySection && slot.activeItem ? slot.activeItem.sectionHost : null
  return traySectionContains(slot, area, x, y)
}

function layoutSection(sections, name) {
  return sections && Array.isArray(sections[name]) ? sections[name] : []
}

function slotWindow(slot) {
  if (!slot) return null
  return targetWindow(slot.activeItem) || targetWindow(slot)
}

function panelNavigationSlots(root, region, window) {
  var regions = navigationRegions(region)
  var slots = []
  for (var r = 0; r < regions.length; r++) {
    var entries = root.layoutEntries(regions[r])
    for (var i = 0; i < entries.length; i++) {
      var id = entryId(entries[i])
      for (var j = 0; j < root.moduleSlots.length; j++) {
        var slot = root.moduleSlots[j]
        if (!slot || slot.region !== regions[r] || slot.moduleName !== id) continue
        if (window && !root.sameWindow(slotWindow(slot), window)) continue
        var item = slot.activeItem
        if (!item || item.visible !== true || slot.visible !== true || slot.width <= 0 || slot.height <= 0) continue
        if (typeof item.open !== "function" || typeof item.close !== "function" || item.opened === undefined) continue
        slots.push(slot)
        break
      }
    }
  }
  return slots
}

function switchPanelFrom(root, owner, direction) {
  if (!owner) return false
  var currentSlot = null
  for (var i = 0; i < root.moduleSlots.length; i++) {
    var slot = root.moduleSlots[i]
    if (slot && slot.activeItem === owner) { currentSlot = slot; break }
  }
  if (!currentSlot) return false
  var slots = panelNavigationSlots(root, currentSlot.region, slotWindow(currentSlot))
  if (slots.length < 2) return false
  var currentIndex = slots.indexOf(currentSlot)
  if (currentIndex < 0) return false
  var step = direction < 0 ? -1 : 1
  var nextSlot = slots[(currentIndex + step + slots.length) % slots.length]
  if (!nextSlot || !nextSlot.activeItem || nextSlot.activeItem === owner) return false
  nextSlot.activeItem.open()
  return true
}

function slotScreenName(slot) {
  var window = slotWindow(slot)
  return window && window.screen ? String(window.screen.name || "") : ""
}

function findPanelWidget(root, pluginId) {
  var id = String(pluginId || "")
  if (!id) return null
  var candidates = []
  for (var i = 0; i < root.moduleSlots.length; i++) {
    var slot = root.moduleSlots[i]
    if (!slot || !slot.activeItem || slot.moduleName !== id) continue
    var item = slot.activeItem
    if (typeof item.open !== "function" || typeof item.close !== "function" || item.opened === undefined) continue
    candidates.push({ slot: slot, screenName: slotScreenName(slot), opened: item.opened === true })
  }
  var chosen = pickPanelSlot(candidates, root.focusedScreenName())
  return chosen ? chosen.activeItem : null
}

function debugBarGeometry(slots) {
  var out = []
  var list = slots || []
  for (var i = 0; i < list.length; i++) {
    var slot = list[i]
    if (!slot || !slot.activeItem) continue
    var point = { x: slot.x, y: slot.y }
    point = mapToItemSafely(slot, 0, 0) || point
    out.push({
      id: slot.moduleName, section: slot.region,
      x: Math.round(point.x), y: Math.round(point.y),
      width: Math.round(slot.width), height: Math.round(slot.height),
      visible: slot.visible === true && slot.width > 0 && slot.height > 0,
      itemVisible: slot.activeItem.visible === true,
      itemWidth: Math.round(slot.activeItem.implicitWidth || 0),
      itemHeight: Math.round(slot.activeItem.implicitHeight || 0)
    })
  }
  return out
}

function beginBarDrag(root, sourceSlot, pressX, pressY) {
  root.commitBarRemoval()
  var item = sourceSlot.activeItem
  if (item && item.opened === true && typeof item.close === "function") item.close()
  root.barDragWindow = targetWindow(sourceSlot.activeItem) || targetWindow(sourceSlot)
  root.barDragScreen = root.barDragWindow ? root.barDragWindow.screen : null
  root.barDragOffsetX = pressX
  root.barDragOffsetY = pressY
  root.captureBarDragGhost(sourceSlot)
  root.barDragExtent = Math.ceil(root.vertical ? sourceSlot.widgetHeight : sourceSlot.widgetWidth)
  root.startDragRoom(sourceSlot)
  root.barDragSource = sourceSlot
}

function startDragRoom(root, sourceSlot) {
  var sections = root.layoutSections
  root.barDragKeys = JSON.stringify(sections)
  root.barDragRoom = dropRoom(null, { key: sourceSlot.widgetKey, region: sourceSlot.region }, sections, root.drawnKeys(root.barDragWindow))
  root.barDragHome = root.dragShareKey(root.barDragRoom)
  var shares = {}
  shares[root.barDragHome] = 1
  root.barDragShares = shares
}

function dropLandingItem(root, sourceSlot, room) {
  if (!sourceSlot) return null
  if (!room || room.home) return sourceSlot.widgetRoom
  var sourceWindow = slotWindow(sourceSlot) || root.barDragWindow
  for (var i = 0; i < root.dragSpacers.length; i++) {
    var spacer = root.dragSpacers[i]
    if (spacer && spacer.region === room.region && spacer.place === room.index && sameWindow(spacer.window, sourceWindow)) return spacer
  }
  return null
}

function updateBarSettle(root) {
  var settle = root.barSettle
  if (!settle) return
  var landing = dropLandingItem(root, settle.source, settle.room)
  if (!landing) return
  var point = mapToItemSafely(landing, landing.width / 2, landing.height / 2)
  if (!point) return
  var center = root.barDragScreenPoint(point)
  var toX = center.x - root.barDragGhostWidth / 2 + root.barDragOffsetX
  var toY = center.y - root.barDragGhostHeight / 2 + root.barDragOffsetY
  root.barDragScreenX = settle.fromX + (toX - settle.fromX) * root.barSettleProgress
  root.barDragScreenY = settle.fromY + (toY - settle.fromY) * root.barSettleProgress
}

function finishBarSettle(root) {
  var settle = root.barSettle
  if (!settle) return
  root.barSettle = null
  root.barSettleAnimation.stop()
  root.landBarDrag(settle.move)
}

function writeLayout(shell, memo, expected, edit) {
  if (!shell || typeof shell.mutateShellConfig !== "function") return
  mutateShellConfig(shell, memo, expected, edit)
}

function removeBarDrag(root, sourceSlot) {
  root.barRemoval = { key: sourceSlot.widgetKey, region: sourceSlot.region, id: entryId(sourceSlot.entry) }
  root.playPoof()
  root.clearBarDrag()
  if (!root.barPoof) root.commitBarRemoval()
}

function commitBarRemoval(root, util) {
  var removal = root.barRemoval
  root.barRemoval = null
  if (!removal) return
  var expected = JSON.parse(JSON.stringify(root.layoutSections))
  var list = expected[removal.region] || []
  var index = list.indexOf(removal.key)
  if (index < 0) return
  list.splice(index, 1)
  root.writeLayout(expected, function(config) {
    removeEntry(config, { region: removal.region, index: index, id: removal.id }, function(entry) { return util.normalizeLayoutEntry(entry) })
  })
}

function isPendingRemoval(removal, key) {
  return !!removal && removal.key === key
}

function moduleHostsTraySection(slot) {
  return !!slot && !!slot.hostsTraySection
}

function beginBarMove(root, window) {
  root.barMoveWindow = window
  root.barMoveScreen = window ? window.screen : null
  root.barMoveCandidate = root.position
  root.barMoveActive = true
}

function thicknessFor(root, screen, notchHeight) {
  if (root.vertical || !screen) return root.barSize
  return Math.max(root.barSize, notchFloor(root.displayCutouts, root.position, screen.name,
    screen.width, screen.height, screen.devicePixelRatio, root.panelModeFor(screen), notchHeight))
}

function normalizeLayout(layout, fallback, util) {
  return util.normalizeLayout(isPlainObject(layout) ? layout : (fallback ? fallback.layout : {}))
}

function configObject(config, fallback) {
  return isPlainObject(config) ? config : fallback
}

function configPosition(config) {
  return config ? config.position : undefined
}

function configBackground(config) {
  return config && config.background || (config && config.transparent === true ? "none" : "opaque")
}

function configLayout(config) {
  return config ? config.layout : undefined
}

function panelAction(root, pluginId, action) {
  var item = findPanelWidget(root, pluginId)
  if (action === "isOpen") return !!item && item.opened === true
  if (!item || typeof item[action] !== "function") return false
  item[action]()
  return true
}

function traySectionDropRectForSlot(slot, window, root, vertical) {
  var shown = slot ? slot.traySectionNow() : null
  if (!shown || !window || !window.contentItem) return null
  return traySectionDropRect(slot.widgetRoom, shown, root.thicknessFor(window.screen), vertical)
}

function dragShareKey(room) {
  return room ? room.region + ":" + room.index : ""
}

function showTooltip(root, target, text, callLater) {
  var warm = root.tooltipShown || root.tooltipWarmTimer.running
  root.clearTooltip()
  if (!root.targetTooltipHovered(target) || !text) {
    root.tooltipRequest += 1
    return
  }
  var request = root.tooltipRequest + 1
  root.tooltipRequest = request
  root.pendingTooltipTarget = target
  root.pendingTooltipText = text
  callLater(function() {
    if (request !== root.tooltipRequest) return
    if (!root.targetTooltipHovered(root.pendingTooltipTarget)) {
      root.clearTooltip()
      return
    }
    root.tooltipTarget = root.pendingTooltipTarget
    root.tooltipText = root.pendingTooltipText
    root.pendingTooltipTarget = null
    root.pendingTooltipText = ""
    if (warm) root.tooltipShown = true
    else root.tooltipTimer.restart()
  })
}

function dropNonTrayCandidates(candidates) {
  var rows = candidates || []
  return rows.filter(function(row) { return row.region !== "tray" })
}

function poofShown(spec, screen) {
  return !!spec && sameScreen(spec.screen, screen)
}

function poofSpanX(spec, minimum) {
  return Math.max(minimum, spec.width / 2)
}

function poofSpanY(spec, minimum) {
  return Math.max(minimum, spec.height / 2)
}

function poofSize(spec, minimum, maximum) {
  return Math.max(minimum, Math.min(maximum, Math.min(spec.width, spec.height) * 1.1))
}

function poofNoise(index, spec) {
  var value = Math.sin(index * 12.9898 + spec.seed * 78.233) * 43758.5453
  return value - Math.floor(value)
}

function poofX(spec) { return Math.round(spec.x) }
function poofY(spec) { return Math.round(spec.y) }
function poofWidth(spec) { return spec.width }
function poofHeight(spec) { return spec.height }
function poofImage(spec) { return spec.image }

function grabbedImageUrl(result) {
  return result && result.url ? result.url : ""
}

function panelIndicatorItem(item) {
  return item && "openPanelIndicatorItem" in item ? item.openPanelIndicatorItem : null
}

function traySectionGeometry(hosts, item, holder) {
  var shown = hosts && item ? item.sectionShown : null
  if (!shown) return null
  return { x: holder.x + shown.x, y: holder.y + shown.y, width: shown.width, height: shown.height }
}

function traySectionNow(hosts, item, geometry, widgetArea) {
  if (!hosts || !item) return null
  if ("sectionShown" in item) return geometry
  var area = item.sectionHost
  if (!area) return null
  var point = area.mapToItem(widgetArea, 0, 0)
  return { x: point.x, y: point.y, width: area.width, height: area.height }
}

function canReorder(shell) {
  return !!shell && typeof shell.mutateShellConfig === "function"
}

function holdTarget(previous, target, button, noButton) {
  if (previous && previous !== target && "heldButtons" in previous) previous.heldButtons = noButton
  var held = target && "heldButtons" in target ? target : null
  if (held) held.heldButtons = button
  return held
}

function listHasRows(rows) {
  return !!rows && rows.length > 0
}

function rowKey(row) { return row ? String(row.key || "") : "" }
function rowPlace(row) { return row ? Number(row.place) : 0 }
function hostDragSource(owner) { return !!owner && !!owner.dragSource }
function isFirstParty(metadata) { return !!metadata && metadata.firstParty === true }
function widgetWidth(item, vertical, barSize) {
  return item && item.visible ? (vertical ? barSize : item.implicitWidth) : 0
}
function widgetHeight(item) { return item && item.visible ? item.implicitHeight : 0 }
function widgetWidthFromHost(host) { return host ? host.widgetWidth : 0 }
function widgetHeightFromHost(host) { return host ? host.widgetHeight : 0 }
function widgetParent(owner, pool) { return owner ? owner.widgetHolder : pool }
function ownerFixedEdge(owner) { return owner ? owner.fixedEdge : "center" }
function rectLength(rect, vertical) { return vertical ? rect.height : rect.width }
function rectX(rect) { return rect.x }
function rectY(rect) { return rect.y }

function injectWidgetProps(root, host, target) {
  if (!target) return
  if ("fixedEdge" in target) target.fixedEdge = host.fixedEdge
  if ("bar" in target) target.bar = host.firstParty
    ? root : root.pluginBarApiFor(host.pluginApiId, host.moduleName, host.registered)
  if ("moduleName" in target) target.moduleName = host.moduleName
  if ("settings" in target) target.settings = host.moduleSettings
}

function releaseWidgetSlot(slots, hosts, slot) {
  var key = slot.widgetKey
  if (slots[key] !== slot) return
  delete slots[key]
  slot.host = null
  if (hosts[key]) hosts[key].owner = null
}

function removeWidgetHost(hosts, slots, host) {
  if (hosts[host.key] !== host) return
  delete hosts[host.key]
  var slot = slots[host.key]
  if (slot) slot.host = null
}

function syncPluginBarApiObjects(root, api, layoutSnapshot) {
  if (!api) return
  api.activePopout = root.pluginOwnsBarObject(api.pluginId, root.activePopout)
    ? root.activePopout : (root.activePopout ? api.foreignPopoutMarker : null)
  api.clickTargets = root.pluginClickTargets(api.pluginId)
  api.layoutConfig = layoutSnapshot !== undefined ? JSON.parse(layoutSnapshot) : root.publicLayoutConfig()
}

function centerBoxDropRect(box, vertical) {
  if (!box) return null
  var point = mapToItemSafely(box, 0, 0)
  return point ? centerDropZone({ x: point.x, y: point.y, width: box.width, height: box.height }, box.crossSize, vertical) : null
}

function dragSourceItem(source) { return source ? source.activeItem : null }
function dragGhostWidth(vertical, source, extent) { return vertical ? (source ? source.widgetWidth : 0) : extent }
function dragGhostHeight(vertical, source, extent) { return vertical ? extent : (source ? source.widgetHeight : 0) }
function traySectionDragActive(source) { return !!source && !source.hostsTraySection }
function rectOrEmpty(rect) { return rect || { x: 0, y: 0, width: 0, height: 0 } }
function syncPeekEdge(window, measured, held) { window.peekEdge = nextPeekEdge(window.peekEdge, measured, held) }
function pointX(point) { return point ? point.x : 0 }
function pointY(point) { return point ? point.y : 0 }

function updateCommandModule(module, raw, util) {
  var data = util.parseModuleJson(raw)
  var klass = data.class || data.alt || ""
  module.outputText = data.text || String(raw || "").trim()
  module.outputTooltip = data.tooltip || String(module.setting("tooltip", ""))
  module.outputActive = klass === "active" || (Array.isArray(klass) && klass.indexOf("active") !== -1)
}

function claimWidgetSlot(slots, hosts, slot) {
  var key = slot.widgetKey
  var last = slots[key]
  if (last && last !== slot) last.host = null
  slots[key] = slot
  var host = hosts[key] || null
  slot.host = host
  if (host) host.owner = slot
}

function addWidgetHost(hosts, slots, host) {
  hosts[host.key] = host
  var slot = slots[host.key] || null
  host.owner = slot
  if (slot) slot.host = host
}

function draggedWidgetWidth(dragged) { return dragged ? dragged.widgetWidth : 0 }
function draggedWidgetHeight(dragged) { return dragged ? dragged.widgetHeight : 0 }

function pluginBarApiFor(root, component, pluginId, moduleName, registered) {
  var key = String(pluginId || "")
  if (!key) return null
  var pluginShell = pluginShellFor(root.shell, registered, moduleName, key)
  if (root.pluginBarApis[key]) {
    root.pluginBarApis[key].shell = pluginShell
    return root.pluginBarApis[key]
  }
  var api = component.createObject(null, {
    pluginId: key,
    moduleName: String(moduleName || ""),
    shell: pluginShell,
    _showTooltip: function(target, text) { root.showTooltip(target, text) },
    _hideTooltip: function(target) { root.hideTooltip(target) },
    _registerClickTarget: function(target) { root.registerPluginClickTarget(key, target) },
    _unregisterClickTarget: function(target) { root.unregisterPluginClickTarget(key, target) },
    _requestPopout: function(owner) { root.requestPluginPopout(key, owner) },
    _releasePopout: function(owner) { root.releasePluginPopout(key, owner) },
    _switchPanelFrom: function(owner, direction) { return root.switchPanelFrom(owner, direction) },
    _notePopoutCard: function(card) { root.notePopoutCard(card) },
    _popoutCardFor: function(owner) { return root.popoutCardFor(owner) },
    _targetBelongsToWindow: function(target, window) { return root.targetBelongsToWindow(target, window) },
    _moduleWidgets: function(requestedId) {
      return String(requestedId || "") === String(moduleName || "") ? root.moduleWidgets(moduleName) : []
    },
    _run: function(command) { root.run(command) },
    _setCenterHoverRevealSuppressed: function(value) { root.centerHoverRevealSuppressed = !!value }
  })
  if (!api) return null
  root.bindPluginBarApi(api)
  var next = {}
  for (var id in root.pluginBarApis) next[id] = root.pluginBarApis[id]
  next[key] = api
  root.pluginBarApis = next
  return api
}

function draggedLength(dragged, lengths, region, place) {
  return dragged ? (lengths[region + ":" + place] || 0) : 0
}

function drawnKeys(slots, window) {
  var drawn = {}
  var list = slots || []
  for (var i = 0; i < list.length; i++) {
    var slot = list[i]
    if (slot && slot.visible && slot.widgetWidth > 0 && slot.widgetHeight > 0 && sameWindow(slotWindow(slot), window)) drawn[slot.widgetKey] = true
  }
  return drawn
}

function moveDragRoom(root, drop) {
  var source = root.barDragSource
  if (!source) return
  var next = dropRoom(drop, { key: source.widgetKey, region: source.region }, root.layoutSections, drawnKeys(root.moduleSlots, root.barDragWindow))
  var last = root.barDragRoom
  root.barDragRoom = next
  if (next.home) root.barDragHome = dragShareKey(next)
  if (!next || (last && dragShareKey(last) === dragShareKey(next))) return false
  return true
}
