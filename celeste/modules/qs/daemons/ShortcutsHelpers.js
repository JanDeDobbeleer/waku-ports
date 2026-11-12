.pragma library

function listDrawers(screenState) {
    var keys = Object.keys(screenState);
    var drawers = [];
    for (var i = 0; i < keys.length; i++) {
        var key = keys[i];
        if (typeof screenState[key] === "boolean")
            drawers.push(key);
    }
    return drawers.join("\n");
}
