.pragma library

function stringField(entry, key) {
    return entry && entry[key] !== undefined ? String(entry[key]) : "";
}

function settingsUri(entry) {
    return stringField(entry, "settingsUri");
}

function appId(entry) {
    return stringField(entry, "id");
}
