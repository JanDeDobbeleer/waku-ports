.pragma library

function selectionValid(file, filters) {
    if (!file || file.isDir)
        return false;
    if (filters.includes("*"))
        return true;
    for (var i = 0; i < filters.length; i++) {
        if (filters[i].toLowerCase() === file.suffix.toLowerCase())
            return true;
    }
    return false;
}

function showLater(window) {
    Qt.callLater(function() { window.visible = true; });
}

function modelPath(dialog, home) {
    var cwd = dialog.cwd;
    if (cwd[0] === "Home")
        return home + "/" + cwd.slice(1).join("/");
    return cwd.join("/");
}
function acceptSelection(dialog, file) {
    if (selectionValid(file, dialog.filters))
        dialog.accepted(file.path);
}
function openItem(dialog, file) {
    if (file.isDir)
        dialog.cwd.push(file.name);
    else
        acceptSelection(dialog, file);
}
function iconText(dialog, file) {
    if (!file.isDir)
        return "draft";
    var cwd = dialog.cwd;
    if (cwd.length === 1) {
        var special = {
            "Desktop": "desktop_windows",
            "Documents": "folder_open",
            "Downloads": "download",
            "Music": "library_music",
            "Pictures": "photo_library",
            "Videos": "video_library"
        };
        if (special[file.name])
            return special[file.name];
    }
    return "folder";
}

function filtersText(dialog, separator) {
    var filters = dialog.filters;
    var patterns = [];
    for (var i = 0; i < filters.length; i++)
        patterns.push("*." + filters[i]);
    return patterns.join(separator);
}
function filterLabel(dialog) { return dialog.filterLabel; }
function validSelection(dialog, currentItem) {
    return selectionValid(currentItem ? currentItem.modelData : null, dialog.filters);
}
function acceptCurrent(dialog, currentItem) {
    if (currentItem)
        dialog.accepted(currentItem.modelData.path);
}
function reject(dialog) { dialog.rejected(); }
function isLocationSelected(dialog, location) {
    var cwd = dialog.cwd;
    return location === cwd[cwd.length - 1];
}
function selectLocation(dialog, location) {
    dialog.cwd = location === "Home" ? ["Home"] : ["Home", location];
}
