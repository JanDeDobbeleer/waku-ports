.pragma library

function length(value) { return value == null ? 0 : value.length }

function allReady(panels) {
  for (var i = 0; panels && i < panels.length; i++) {
    if (!panels[i].backgroundReady) return false
  }
  return true
}

function allIncomingReady(panels) {
  for (var i = 0; panels && i < panels.length; i++) {
    if (!panels[i].incomingReady()) return false
  }
  return true
}

function setMaskReady(panel) { if (panel) panel.maskReady = true }

function markIncomingReady(panels) {
  for (var i = 0; panels && i < panels.length; i++) {
    var panel = panels[i]
    if (panel.incomingReady()) panel.maskReady = true
  }
}
