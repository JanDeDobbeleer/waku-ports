.pragma library

// qmlcachegen cannot compile callbacks held in `var`, loads from plain objects or for...of, so
// Nmcli keeps those here.

function invoke(callback, value) {
    if (callback)
        callback(value);
}

function unsupportedResult() {
    return {
        success: false,
        output: "",
        error: "Not supported on Windows",
        exitCode: 1
    };
}

function connectResult(ok) {
    return {
        success: ok,
        output: "",
        error: ok ? "" : "Unable to connect",
        exitCode: ok ? 0 : 1
    };
}

function needsPasswordResult() {
    return {
        success: false,
        needsPassword: true
    };
}

function interfacesResult(ethernet) {
    return {
        wireless: [],
        ethernet: ethernet
    };
}

function linkDetails(network, kind) {
    if (network.kind !== kind)
        return null;
    return {
        ipAddress: network.ipAddress,
        gateway: "",
        dns: [],
        subnet: "",
        macAddress: "",
        speed: ""
    };
}

function signature(networks) {
    return JSON.stringify(networks || []);
}

function savedSecurity(map, key) {
    return map[key] || "";
}

function containsLower(list, ssid) {
    const key = ssid.toLowerCase().trim();
    for (let i = 0; i < list.length; i++) {
        if (list[i].toLowerCase().trim() === key)
            return true;
    }
    return false;
}

function knownSsids(networks) {
    const known = [];
    for (const n of networks) {
        if (n.known)
            known.push(n.ssid);
    }
    return known;
}

// waku gap: no BSSID, so the SSID stands in for it and keeps rows distinct.
function buildAccessPoints(parent, component, networks) {
    const next = [];
    for (const n of networks) {
        next.push(component.createObject(parent, {
            ssid: n.ssid,
            bssid: n.ssid,
            strength: n.signal,
            frequency: 0,
            active: n.connected,
            security: n.secured ? "WPA2" : ""
        }));
    }
    return next;
}

function buildEthernet(parent, component, ipAddress) {
    return [component.createObject(parent, {
            iface: "Ethernet",
            type: "ethernet",
            state: "connected",
            connection: "Ethernet",
            connected: true,
            ipAddress: ipAddress
        })];
}

function copy(list) {
    const out = [];
    for (let i = 0; i < list.length; i++)
        out.push(list[i]);
    return out;
}

// The connected network is the "Connected to ..." line, so the list leaves it out.
function topInactive(networks, limit) {
    return copy(networks).filter(n => !n.active).sort((a, b) => b.strength - a.strength).slice(0, limit);
}

function sortedEthernet(devices, limit) {
    return copy(devices).sort((a, b) => {
        if (a.connected !== b.connected)
            return b.connected - a.connected;
        return (a.iface || "").localeCompare(b.iface || "");
    }).slice(0, limit);
}

function destroyAll(objects) {
    for (let i = 0; i < objects.length; i++)
        objects[i].destroy();
}
