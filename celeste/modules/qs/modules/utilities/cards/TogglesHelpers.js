.pragma library

function quickToggles(toggleConfig, vpnProviderSelected) {
    const values = toggleConfig.values;
    const visible = [];
    const seenIds = new Set();
    for (let i = 0; i < values.length; i++) {
        const item = values[i];
        if (!item.enabled || seenIds.has(item.id))
            continue;
        if (item.id === "vpn" && !vpnProviderSelected)
            continue;
        seenIds.add(item.id);
        visible.push(item);
    }
    return visible;
}

function splitIndex(toggles) { return Math.ceil(toggles.length / 2); }
function needsExtraRow(toggles) { return toggles.length > 6; }
function vpnToggleAllowed(status) { return status.state !== "needs-auth" && status.state !== "error"; }
function vpnChecked(connected, status) { return connected && vpnToggleAllowed(status); }
