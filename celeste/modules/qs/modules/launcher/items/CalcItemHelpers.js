.pragma library

function expression(list, prefix) { return list.search.text.slice((prefix + "calc ").length); }
function closeLauncher(list) { list.screenState.launcher = false; }
