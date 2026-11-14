.pragma library

function isPlaying(player) { return player ? player.isPlaying : false; }
function progress(player) {
    if (!player || !player.length)
        return 0;
    return (player.position % player.length) / player.length;
}
function refreshPosition(player) { if (player) player.positionChanged(); }
function canGoPrevious(player) { return player ? player.canGoPrevious : false; }
function previous(player) { if (player) player.previous(); }
function canTogglePlaying(player) { return player ? player.canTogglePlaying : false; }
function togglePlaying(player) { if (player) player.togglePlaying(); }
function canGoNext(player) { return player ? player.canGoNext : false; }
function next(player) { if (player) player.next(); }

function sourcePath(path, shellDir) {
    return "file:///" + path.replace(/^root:\//, shellDir + "/").replace(/\\/g, "/");
}
