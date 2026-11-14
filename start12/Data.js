// Reads of untyped data: the pins file and the engine's lists of plain objects (desktops, drives).
// They live here because qmlcachegen cannot compile a property read from a var value, or a
// try/catch, into C++; QML calls these and gets typed values back.
.pragma library

// The pinned ids in the pins file, or null when the text is not a pins file.
function pinIds(text) {
    try {
        const ids = JSON.parse(text).ids;
        return Array.isArray(ids) ? ids.filter(id => typeof id === "string") : [];
    } catch (e) {
        return null;
    }
}

function without(list, item) {
    return list.filter(x => x !== item);
}

function ids(entries) {
    return entries.map(e => e.id);
}

function rowEntry(row) {
    return row.entry;
}

// The desktops of the first monitor.
function desktops(monitors) {
    return monitors && monitors.length > 0 ? (monitors[0].workspaces || []) : [];
}

function isCurrent(desktop) {
    return !!(desktop && (desktop.active || desktop.focused));
}

function hasWindows(desktop) {
    return !!(desktop && desktop.hasWindows);
}

function driveLetter(disk) {
    return String(disk.mount).substring(0, 2);
}

function driveUsed(disk) {
    return disk.percent / 100;
}

function driveFree(disk) {
    return disk.free;
}

function isSystemDrive(disk) {
    return !!disk.system;
}
