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
