.pragma library

function cwd(dialog) { return dialog.cwd; }
function isRoot(dialog) { return dialog.cwd.length === 1; }
function goUp(dialog) { dialog.cwd.pop(); }
function isLast(dialog, index) { return index === dialog.cwd.length - 1; }
function navigate(dialog, index) { dialog.cwd = dialog.cwd.slice(0, index + 1); }
function isHome(index, name) { return index === 0 && name === "Home"; }
