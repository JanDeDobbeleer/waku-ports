.pragma library

function wiredAdapters(kind, adapters) {
  return kind !== "ethernet" ? [] : (adapters || []).filter(function(adapter) {
    return !!adapter.isUp && !/wi-?fi|wlan|wireless|loopback|virtual|vethernet|bluetooth|local area connection|vswitch|vpn|tunnel/i.test(String(adapter.name || ""))
  }).slice(0, 1)
}
function adapterName(adapter) { return String(adapter && adapter.name || "") }
function adapterConnected(adapter) { return !!(adapter && adapter.isUp) }
function count(instantiator) { return instantiator ? instantiator.count : 0 }
function objectAt(instantiator, index) { return instantiator ? instantiator.objectAt(index) : null }
