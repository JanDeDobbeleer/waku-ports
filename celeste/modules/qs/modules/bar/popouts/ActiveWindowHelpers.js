.pragma library

function title(window) { return window ? window.title || "" : ""; }
function appClass(window) { return window ? window.appClass || "" : ""; }
function iconPath(window, icons) {
    return window && window.icon ? window.icon : icons.getAppIcon(appClass(window), "image-missing");
}
