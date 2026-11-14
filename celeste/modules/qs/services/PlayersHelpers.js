.pragma library

function players(model) {
    return model.values.slice();
}

function getIdentity(player, services) {
    if (!player)
        return "";
    const aliases = services.playerAliases.values;
    for (let i = 0; i < aliases.length; i++) {
        if (aliases[i].from === player.identity)
            return aliases[i].to || player.identity;
    }
    return player.identity;
}

function active(manualPlayer, players, services) {
    if (manualPlayer)
        return manualPlayer;
    const defaultPlayer = services.defaultPlayer;
    for (let i = 0; i < players.length; i++) {
        if (getIdentity(players[i], services) === defaultPlayer)
            return players[i];
    }
    return players.length ? players[0] : null;
}

function getArtUrl(player) {
    if (!player)
        return "";
    if (player.trackArtUrl)
        return player.trackArtUrl;
    const url = player.metadata["xesam:url"] || "";
    if (url.startsWith("https://www.youtube.com/watch")) {
        const match = url.match(/[?&]v=([\w-]{11})/);
        return match ? "https://img.youtube.com/vi/" + match[1] + "/hqdefault.jpg" : "";
    }
    return "";
}

function invoke(player, operation) {
    if (!player)
        return;
    if (operation === "play") {
        if (player.canPlay) player.play();
    } else if (operation === "pause") {
        if (player.canPause) player.pause();
    } else if (operation === "togglePlaying") {
        if (player.canTogglePlaying) player.togglePlaying();
    } else if (operation === "previous") {
        if (player.canGoPrevious) player.previous();
    } else if (operation === "next") {
        if (player.canGoNext) player.next();
    } else if (operation === "stop") {
        player.stop();
    }
}

function getActiveProperty(player, property) {
    return player ? (player[property] === undefined ? "Invalid property" : player[property]) : "No active player";
}

function list(players, root) {
    const identities = [];
    for (let i = 0; i < players.length; i++)
        identities.push(root.getIdentity(players[i]));
    return identities.join("\n");
}
