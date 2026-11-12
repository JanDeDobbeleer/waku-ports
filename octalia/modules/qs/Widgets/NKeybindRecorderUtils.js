.pragma library

function length(keybinds) {
  return keybinds.length;
}

function denseKeybinds(keybinds, maxKeybinds) {
  return keybinds.filter(k => k !== undefined && k !== "").slice(0, maxKeybinds);
}
