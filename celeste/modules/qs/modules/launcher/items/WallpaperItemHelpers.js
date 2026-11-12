.pragma library

// Takes the PathView attached object: attached properties only resolve in QML scope.
function pathZ(attached) { return (attached && attached.z) || 0; }
function path(entry) { return entry ? entry.path : ""; }
function relativePath(entry) { return entry ? entry.relativePath : ""; }
function setWallpaper(service, entry) {
    if (entry)
        service.setWallpaper(entry.path);
}
