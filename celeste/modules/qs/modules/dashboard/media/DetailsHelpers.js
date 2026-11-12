.pragma library

function isPlaying(player) { return player ? player.isPlaying : false; }
function position(player) { return player ? player.position : -1; }
function length(player) { return player ? player.length : -1; }
function refreshPosition(player) { if (player) player.positionChanged(); }
function positionRatio(player) { return player ? player.position / (player.length || 1) : 0; }
function canSeek(player) { return player ? player.canSeek : false; }
function seek(player, value) {
    if (player && player.canSeek && player.positionSupported)
        player.position = value * player.length;
}
function shuffle(player) { return player ? player.shuffle : false; }
function shuffleSupported(player) { return player ? player.shuffleSupported : false; }
function toggleShuffle(player) { if (player) player.shuffle = !player.shuffle; }
function canGoPrevious(player) { return player ? player.canGoPrevious : false; }
function previous(player) { if (player) player.previous(); }
function canTogglePlaying(player) { return player ? player.canTogglePlaying : false; }
function togglePlaying(player) { if (player) player.togglePlaying(); }
function canGoNext(player) { return player ? player.canGoNext : false; }
function next(player) { if (player) player.next(); }
function loopIcon(player, trackState) { return player && player.loopState === trackState ? "repeat_one" : "repeat"; }
function isLooping(player, trackState, playlistState) {
    return player && (player.loopState === trackState || player.loopState === playlistState);
}
function loopSupported(player) { return player ? player.loopSupported : false; }
function cycleLoop(player, noneState, trackState, playlistState) {
    if (!player) return;
    if (player.loopState === noneState) player.loopState = trackState;
    else if (player.loopState === trackState) player.loopState = playlistState;
    else player.loopState = noneState;
}
