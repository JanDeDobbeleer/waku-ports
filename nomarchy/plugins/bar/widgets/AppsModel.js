.pragma library

function activationIndex(group, last) {
  if (!group || group.windows.length === 0) return -1
  var target = group.windows[last ? group.windows.length - 1 : 0]
  var focusedAt = -1
  for (let i = 0; i < group.windows.length; i++) if (group.windows[i].active) focusedAt = i
  if (focusedAt >= 0 && group.windows.length === 1) return -1
  if (focusedAt >= 0 && !last) target = group.windows[(focusedAt + 1) % group.windows.length]
  return target.index
}

// A Repeater hands each group over as a converted object whose `windows` is array-like, not an Array.
function windows(group) { var list = group ? group.windows : null; return list && typeof list.length === "number" ? Array.from(list) : [] }
function length(value) { return value && typeof value.length === "number" ? value.length : 0 }
function shown(groups, maxVisible) { var list = Array.from(groups || []); return list.length > maxVisible ? list.slice(0, maxVisible) : list }
function isPreviewOpen(group, item) { return !!group && !!item && windows(group).length > 0 }
function findGroup(groups, target) {
  if (!target || !Array.isArray(groups)) return null
  for (let i = 0; i < groups.length; i++) if (groups[i].key === target.key) return groups[i]
  return null
}
function hasActive(group) { return windows(group).some(function(w) { return !!w.active }) }
function allMinimized(group) { return windows(group).length > 0 && windows(group).every(function(w) { return !!w.minimized }) }
function field(object, name) { return object ? object[name] : undefined }
function stringField(object, name) { var value = field(object, name); return value == null ? "" : String(value) }
function textForApp(group) { var exe = stringField(group, "exe"); return exe.length > 0 ? exe.charAt(0).toUpperCase() : "?" }
function previewRectY(item, root) { return item.mapToItem(root, 0, 0).y }

// The progress a program shows on its tile: the most pressing state among its windows (error, then
// paused, normal, indeterminate) and, within a state, the least advanced value.
function groupProgress(group) {
  var priority = { error: 0, paused: 1, normal: 2, indeterminate: 3, none: 4 }
  var state = "none"
  var value = 0
  var list = windows(group)
  for (let i = 0; i < list.length; i++) {
    let next = list[i].progressState || "none"
    let p = next in priority ? priority[next] : 4
    let v = Number(list[i].progress) || 0
    if (p < priority[state] || (p === priority[state] && v < value)) { state = next; value = v }
  }
  return { state: state, value: Math.max(0, Math.min(1, value)) }
}
function progressState(group) { return groupProgress(group).state }
function progressValue(group) { return groupProgress(group).value }