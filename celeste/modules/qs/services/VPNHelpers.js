.pragma library

function providers(config) { return config.utilities.vpn.provider.values; }
function selectedProvider(providers, selected) {
    for (var i = 0; i < providers.length; i++) {
        if (providers[i].id === selected)
            return providers[i];
    }
    return null;
}
