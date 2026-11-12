.pragma library

function collapsed(entry, capsLock, numLock) {
    return entry.id === "lockStatus" && !capsLock && !numLock;
}
function enabledEntries(configuration) {
    var result = [];
    var values = configuration.values;
    for (var i = 0; i < values.length; i++) {
        if (values[i].enabled)
            result.push(values[i]);
    }
    return result;
}
function entryName(entry) { return entry.id.toLowerCase(); }
function implicitWidth(item) { return item ? item.implicitWidth : 0; }
function implicitHeight(item) { return item ? item.implicitHeight : 0; }
