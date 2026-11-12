.pragma library

function pathZ(item) { return item.PathView.z || 0; }
function path(entry) { return entry ? entry.path : ""; }
function relativePath(entry) { return entry ? entry.relativePath : ""; }
function setWallpaper(service, entry) {
    if (entry)
        service.setWallpaper(entry.path);
}
