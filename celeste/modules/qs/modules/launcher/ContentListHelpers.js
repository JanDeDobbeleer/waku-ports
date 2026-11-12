.pragma library

function showWallpapers(search, prefix) { return search.text.startsWith(prefix + "wallpaper "); }
function isEmpty(list) { return !list || list.count === 0; }
