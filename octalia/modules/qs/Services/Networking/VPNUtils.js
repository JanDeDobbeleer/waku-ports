.pragma library

function connections(vpnConnections) {
    const map = {};
    for (const v of (vpnConnections || [])) {
      map[v.name] = {
        "uuid": v.name,
        "name": v.name,
        "type": "vpn",
        "active": !!v.connected
      };
    }
    return map;
}

function filterConnections(connections, active) {
  return Object.values(connections).filter(c => active ? c.active : !c.active);
}

function hasActive(connections) {
  return connections.length > 0;
}
