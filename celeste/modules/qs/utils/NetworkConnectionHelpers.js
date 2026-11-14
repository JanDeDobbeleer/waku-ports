.pragma library

// Callbacks held in `var` cannot be compiled by qmlcachegen, so they are wired up here. `nmcli` is
// the Nmcli singleton.

function connectWithPasswordCheck(nmcli, network, onPasswordNeeded) {
    nmcli.connectToNetworkWithPasswordCheck(network.ssid, network.isSecure, function (result) {
        if (!result.needsPassword)
            return;
        // Clear pending connection if exists
        if (nmcli.pendingConnection) {
            nmcli.connectionCheckTimer.stop();
            nmcli.immediateCheckTimer.stop();
            nmcli.immediateCheckTimer.checkCount = 0;
            nmcli.pendingConnection = null;
        }
        if (onPasswordNeeded)
            onPasswordNeeded(network);
    }, network.bssid);
}

function orNull(callback) {
    return callback || null;
}

function orEmpty(value) {
    return value || "";
}
