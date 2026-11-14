.pragma library

function networkName(network) { return String(network && network.ssid || "") }
function signalStrength(network) { return Number(network && network.signal || 0) / 100 }
function secured(network) { return !!(network && network.secured) }
function connected(network) { return !!(network && network.connected) }
function known(network) { return !!(network && network.known) }
function count(instantiator) { return instantiator ? instantiator.count : 0 }
function objectAt(instantiator, index) { return instantiator ? instantiator.objectAt(index) : null }
