.pragma library
function isValidImageName(name, extensions) {
    var lower = name.toLowerCase();
    for (var i = 0; i < extensions.length; i++) {
        if (lower.endsWith("." + extensions[i]))
            return true;
    }
    return false;
}
