pragma Singleton

import QtQuick 6.10
import Quickshell
import waku.services as S
import qs.Commons
import qs.Services.UI

// Octalia's NetworkService over the engine's Network (waku.services): Windows connectivity
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

  // Supported Wi-Fi security types
  readonly property var supportedSecurityTypes: [
    {
      key: "open",
      name: I18n.tr("wifi.panel.security-open")
    },
    {
      key: "wep",
      name: I18n.tr("wifi.panel.security-wep")
    },
    {
      key: "wpa-psk",
      name: I18n.tr("wifi.panel.security-wpa")
    },
    {
      key: "wpa2-psk",
      name: I18n.tr("wifi.panel.security-wpa23")
    },
    {
      key: "sae",
      name: I18n.tr("wifi.panel.security-wpa3")
    },
    {
      key: "wpa-eap",
      name: I18n.tr("wifi.panel.security-wpa-ent")
    },
    {
      key: "wpa2-eap",
      name: I18n.tr("wifi.panel.security-wpa2-ent")
    },
    {
      key: "wpa3-eap",
      name: I18n.tr("wifi.panel.security-wpa3-ent")
    }
  ]

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

  // Airplane mode: Windows has no switch for it that waku can use
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

  // Helper functions
  function getSignalInfo(signal, isConnected) {
    let icon = "";
    if (isConnected) {
      if (root._networkConnectivity === "limited") {
        icon = "wifi-exclamation";
      } else if (root._networkConnectivity === "portal" || root._networkConnectivity === "unknown") {
        icon = "wifi-question";
      }
    }
    const label = signal >= 80 ? I18n.tr("wifi.signal.excellent") : signal >= 60 ? I18n.tr("wifi.signal.good") : signal >= 35 ? I18n.tr("wifi.signal.fair") : signal >= 15 ? I18n.tr("wifi.signal.poor") : I18n.tr("wifi.signal.weak");
    if (!icon) {
      icon = signal >= 80 ? "wifi" : signal >= 60 ? "wifi-3" : signal >= 35 ? "wifi-2" : signal >= 15 ? "wifi-1" : "wifi-0";
    }
    return {
      icon,
      label
    };
  }

  function isSecured(security) {
    return security && security !== "--" && security.trim() !== "";
  }

  function isEnterprise(security) {
    if (!security) {
      return false;
    }
    const s = security.toUpperCase();
    return s.indexOf("802.1X") !== -1 || s.indexOf("EAP") !== -1 || s.indexOf("ENTERPRISE") !== -1;
  }

  function parseIpDetails(text) {
    return {};
  }

  function getStatusText(showSpeed = false) {
    // This variable can be tied to a toggle
    if (root.connecting) {
      return root.connectingTo ? I18n.tr("common.connecting") + " " + root.connectingTo : I18n.tr("common.connecting");
    }

    if (NetworkService.airplaneModeEnabled) {
      return I18n.tr("toast.airplane-mode.title");
    }
    if (!root.wifiEnabled) {
      return "";
    }

    // Ethernet
    if (root.ethernetConnected) {
      const eth = root.activeEthernetDetails;
      const name = eth.connectionName || (root.ethernetInterfaces.length > 0 ? root.ethernetInterfaces[0].connectionName : "") || "";
      const speed = eth.speed || "";
      return (name + (showSpeed && speed ? " - " + speed : ""));
    }

    // Wi-Fi
    if (root.wifiConnected) {
      const wl = root.activeWifiDetails;
      const speed = wl.rateShort || wl.rate || "";
      const connectedNet = Object.values(root.networks).find(net => net.connected);
      const name = connectedNet ? connectedNet.ssid : (wl.connectionName || "");
      return (name + (showSpeed && speed ? " - " + speed : ""));
    }
    return "";
  }

  function getIcon(forceEthernet = false) {
    if (NetworkService.airplaneModeEnabled && !forceEthernet) {
      return "plane";
    }

    // 1. Ethernet Priority: Show Ethernet icon if connected OR if specifically requested (Panel)
    if (root.ethernetConnected || forceEthernet) {
      switch (root._networkConnectivity) {
      case "limited":
        return "ethernet-exclamation";
      case "portal":
      case "unknown":
        return "ethernet-question";
      case "full":
        return "ethernet";
      default:
        return "ethernet-off";
      }
    }

    // 2. Wi-Fi Fallback
    if (root.wifiAvailable || !forceEthernet) {
      const networkCount = Object.values(root.networks).length;
      if (!root.wifiEnabled) {
        return "wifi-off";
      }
      if (root.wifiConnected) {
        let s = (root.activeWifiDetails && root.activeWifiDetails.signal !== undefined && root.activeWifiDetails.signal !== "") ? root.activeWifiDetails.signal : 0;
        return root.getSignalInfo(s, true).icon;
      }
      if (root.connecting || networkCount > 0) {
        return "wifi-question";
      }
    }
    return (root.ethernetAvailable || root.ethernetConnected) ? "ethernet-off" : root.wifiAvailable ? "wifi-0" : "wifi-off";
  }
}
