.pragma library

function anyPlaying(players) {
    for (let i = 0; i < players.length; i++) {
        if (players[i].isPlaying)
            return true;
    }
    return false;
}

function timeouts(config) { return config.values; }
function monitored(config, enabled, hasPlayer, isCharging) {
    if (!enabled || config.enabled === false)
        return false;
    if (config.inhibitWhenAudio && hasPlayer)
        return false;
    if (config.inhibitWhenCharging && isCharging)
        return false;
    return true;
}
function reachedTimeout(config, idleSeconds) { return idleSeconds >= config.timeout; }
function action(config, isIdle) { return isIdle ? config.idleAction : config.returnAction; }
function handleAction(lock, action) {
    if (!lock || !action)
        return;
    if (action === "lock")
        lock.lock.locked = true;
    else if (action === "unlock")
        lock.lock.locked = false;
}
