# One-off: rewrites Services\Networking\NetworkService.qml as an adapter over the engine's Network.
# Keeps upstream's public names and its helper functions (getSignalInfo, isSecured, isEnterprise,
# getStatusText, getIcon); the nmcli processes are gone. Run once on the pristine upstream file.
$p = Join-Path $PSScriptRoot '..\modules\qs\Services\Networking\NetworkService.qml'
$t = [IO.File]::ReadAllText($p) -replace "`r`n", "`n"
if ($t.Contains('wabar.services')) { Write-Host 'already ported'; return }

function Between($text, $from, $to) {
  $i = $text.IndexOf($from); if ($i -lt 0) { throw "missing: $from" }
  $j = $text.IndexOf($to, $i); if ($j -lt 0) { throw "missing: $to" }
  $text.Substring($i, $j - $i)
}
$helpers = (Between $t "  // Helper functions`n  function getSignalInfo" "  function parseIpDetails").TrimEnd()
$status = (Between $t "  function getStatusText" "  // Processes`n").TrimEnd()
$security = (Between $t "  // Supported Wi-Fi security types" "  // Core properties").TrimEnd()

$new = @"
pragma Singleton

import QtQuick
import Quickshell
import wabar.services as S
import qs.Commons
import qs.Services.UI
import qs.compat

// Noctalia's NetworkService over the engine's Network (wabar.services): Windows connectivity
// profiles, wlanapi scans, the Wi-Fi radio switch and interface counters. Public names are upstream's.
//
// What Windows does differently, and so what this adapter does not do:
//   - The engine connects only to networks Windows already has a profile for: connect() with a
//     password, a hidden network or an enterprise config sets lastError. Forget and disconnect have no
//     engine call either. Use Windows' Wi-Fi settings for those (the panel's buttons report the error).
//   - There is no airplane-mode switch, so airplaneModeEnabled stays false and setAirplaneMode logs.
//   - Ethernet details are the adapter's name and the address; speed, gateway, DNS and MAC are empty.
//   - Connectivity is "full" while an interface is connected: Windows' internet probe is not exposed.
Singleton {
  id: root

  // Core properties
  readonly property bool wifiAvailable: S.Network.wifiAvailable
  readonly property bool ethernetAvailable: S.Network.kind === "ethernet" || ethernetInterfaces.length > 0
  readonly property bool internetConnectivity: S.Network.kind === "wifi" || S.Network.kind === "ethernet"
  readonly property string networkConnectivity: internetConnectivity ? "full" : "none"
  property string lastError: ""
  property int activeDetailsTtlMs: 10000

$security

  // Ethernet properties
  readonly property var ethernetInterfaces: {
    const out = [];
    if (S.Network.kind !== "ethernet")
      return out;
    for (const a of (S.Network.adapters || [])) {
      if (a.isUp && !/wi-?fi|wlan|wireless|loopback|virtual|vethernet|bluetooth/i.test(a.name))
        out.push({
                   "ifname": a.name,
                   "connectionName": a.name,
                   "connected": true
                 });
    }
    return out;
  }
  readonly property bool ethernetConnected: S.Network.kind === "ethernet"
  readonly property string activeEthernetIf: ethernetConnected && ethernetInterfaces.length > 0 ? ethernetInterfaces[0].ifname : ""
  readonly property var activeEthernetDetails: ethernetConnected ? ({
                                                                      "ifname": activeEthernetIf,
                                                                      "connectionName": activeEthernetIf,
                                                                      "ipv4": S.Network.ipAddress,
                                                                      "speed": "",
                                                                      "hwAddr": "",
                                                                      "ipv6": "",
                                                                      "gateway4": "",
                                                                      "gateway6": "",
                                                                      "dns4": "",
                                                                      "dns6": ""
                                                                    }) : ({})
  property bool ethernetDetailsLoading: false
  property double activeEthernetDetailsTimestamp: Date.now()

  // Wi-Fi properties
  readonly property bool wifiEnabled: S.Network.wifiEnabled
  readonly property bool wifiConnected: S.Network.kind === "wifi"
  readonly property string activeWifiIf: wifiConnected ? "Wi-Fi" : ""
  readonly property var activeWifiDetails: wifiConnected ? ({
                                                              "connectionName": S.Network.ssid,
                                                              "ifname": "Wi-Fi",
                                                              "signal": S.Network.signalPercent,
                                                              "ipv4": S.Network.ipAddress,
                                                              "rate": "",
                                                              "rateShort": "",
                                                              "band": "",
                                                              "ipv6": "",
                                                              "gateway4": "",
                                                              "gateway6": "",
                                                              "dns4": "",
                                                              "dns6": ""
                                                            }) : ({})
  property bool wifiDetailsLoading: false
  property double activeWifiDetailsTimestamp: Date.now()
  property bool wifiInit: false

  // The scan, as upstream's map keyed by ssid: {ssid, security, signal, connected, existing}
  readonly property var networks: {
    const map = {};
    for (const n of (S.Network.networks || [])) {
      map[n.ssid] = {
        "ssid": n.ssid,
        "security": n.secured ? "WPA2" : "--",
        "signal": n.signal,
        "connected": !!n.connected,
        "existing": !!n.known,
        "cached": false,
        "lastSeen": Date.now()
      };
    }
    return map;
  }
  readonly property var existingProfiles: {
    const map = {};
    for (const n of (S.Network.networks || [])) {
      if (n.known)
        map[n.ssid] = true;
    }
    return map;
  }

  // Connection state
  property bool connecting: false
  property string connectingTo: ""
  property string disconnectingFrom: ""
  property string forgettingNetwork: ""
  property bool scanPending: false
  readonly property bool scanningActive: S.Network.scanning

  // Airplane mode: Windows has no switch for it that wabar can use
  property bool airplaneModeEnabled: false
  property bool airplaneModeToggled: false

  Component.onCompleted: {
    Logger.i("Network", "Service started");
    wifiInit = true;
    if (wifiEnabled)
      scan();
  }

  onWifiEnabledChanged: {
    if (!wifiInit)
      return;
    ToastService.showNotice(I18n.tr("common.wifi"), wifiEnabled ? I18n.tr("common.enabled") : I18n.tr("common.disabled"), wifiEnabled ? "wifi" : "wifi-off");
    if (wifiEnabled)
      scan();
  }

  // A connect attempt ends when the connected network is the one asked for, or after a while.
  Connections {
    target: S.Network
    function onUpdated() {
      if (root.connecting && S.Network.ssid === root.connectingTo) {
        root.connecting = false;
        root.connectingTo = "";
        connectTimeout.stop();
      }
    }
  }

  Timer {
    id: connectTimeout
    interval: 15000
    onTriggered: {
      root.connecting = false;
      root.connectingTo = "";
    }
  }

  // Core functions
  function setWifiEnabled(enabled) {
    Logger.i("Wi-Fi", "SetWifiEnabled", enabled);
    S.Network.setWifiEnabled(enabled);
  }

  function setAirplaneMode(state) {
    Logger.w("Network", "Airplane mode is not available on Windows");
  }

  function scan() {
    if (!wifiEnabled)
      return;
    lastError = "";
    S.Network.refresh();
  }

  function connect(ssid, password = "", isHidden = false, securityKey = "", identity = "", enterpriseConfig = {}) {
    if (connecting)
      return;
    const known = networks[ssid] && networks[ssid].existing;
    if (!known || password || isHidden) {
      lastError = I18n.tr("common.error") + ": Windows connects only to saved networks here. Add this one in Windows' Wi-Fi settings first.";
      return;
    }
    lastError = "";
    if (S.Network.connectTo(ssid)) {
      connecting = true;
      connectingTo = ssid;
      connectTimeout.restart();
    }
  }

  function disconnect(ssid) {
    lastError = "Disconnecting is not available here. Use Windows' Wi-Fi settings.";
  }

  function forget(ssid) {
    lastError = "Forgetting a network is not available here. Use Windows' Wi-Fi settings.";
  }

  function refreshActiveWifiDetails() {
    activeWifiDetailsTimestamp = Date.now();
  }

  function refreshActiveEthernetDetails() {
    activeEthernetDetailsTimestamp = Date.now();
  }

  // The engine updates the scan list itself; kept for callers of the upstream API.
  function updateNetworkStatus(ssid, connected) {
  }

$helpers

  function parseIpDetails(text) {
    return {};
  }

$status
}
"@
[IO.File]::WriteAllText($p, $new + "`n", (New-Object Text.UTF8Encoding $false))
Write-Host "ported network: $($new.Split("`n").Count) lines (was $($t.Split("`n").Count))"
