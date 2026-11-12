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
