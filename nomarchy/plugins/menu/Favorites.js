.pragma library

function defaults() {
  return ["browser", "explorer", "terminal"]
}

function parse(raw, previous) {
  var value
  try {
    value = JSON.parse(String(raw))
  } catch (error) {
    return previous
  }
  if (!Array.isArray(value)) return previous
  var result = []
  for (var i = 0; i < value.length; i++) {
    var id = value[i]
    if (defaults().indexOf(id) >= 0 && result.indexOf(id) < 0) result.push(id)
  }
  return result
}

function rows(ids, terminalAvailable, labels) {
  var definitions = {
    browser: { label: labels.browser, icon: "󰖟" },
    explorer: { label: labels.explorer, icon: "󰉋" },
    terminal: { label: labels.terminal, icon: "󰆍" }
  }
  var result = []
  for (var i = 0; i < ids.length; i++) {
    var id = ids[i]
    var definition = definitions[id]
    if (!definition) continue
    var unavailable = id === "terminal" && !terminalAvailable
    result.push({
      itemId: "favorite." + id, disabled: unavailable,
      kind: "favorite", icon: definition.icon, iconFont: "", appIcon: "", appId: "",
      label: unavailable ? definition.label + " (" + labels.unavailable + ")" : definition.label,
      target: "", detail: "", path: "", childCount: 0,
      action: id, provider: "", score: 0, section: "favorites"
    })
  }
  return result
}

function duplicatesFavorite(row, ids, terminalAvailable) {
  if (row.kind !== "app") return false
  var label = String(row.label || "").toLowerCase()
  return (ids.indexOf("explorer") >= 0 && label === "file explorer") ||
    (ids.indexOf("terminal") >= 0 && terminalAvailable && label === "windows terminal")
}
