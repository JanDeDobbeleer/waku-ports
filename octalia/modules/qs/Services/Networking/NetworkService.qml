pragma Singleton
import "NetworkServiceUtils.js" as NetworkUtils

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
  readonly property bool ethernetAvailable: S.Network.kind === "ethernet" || NetworkUtils.hasInterfaces(ethernetInterfaces)
  readonly property bool internetConnectivity: S.Network.kind === "wifi" || S.Network.kind === "ethernet"
  readonly property string networkConnectivity: internetConnectivity ? "full" : "none"
  readonly property var _networkConnectivity: undefined
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
  readonly property var ethernetInterfaces: NetworkUtils.ethernetInterfaces(S.Network)
  readonly property bool ethernetConnected: S.Network.kind === "ethernet"
  readonly property string activeEthernetIf: ethernetConnected ? NetworkUtils.firstInterfaceName(ethernetInterfaces) : ""
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
  readonly property var networks: NetworkUtils.networks(S.Network)
  readonly property var existingProfiles: NetworkUtils.existingProfiles(S.Network)

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
  function setWifiEnabled(enabled: var): void {
    Logger.i("Wi-Fi", "SetWifiEnabled", enabled);
    S.Network.setWifiEnabled(enabled);
  }

  function setAirplaneMode(state: var): void {
    Logger.w("Network", "Airplane mode is not available on Windows");
  }

  function scan() {
    if (!wifiEnabled)
      return;
    lastError = "";
    S.Network.refresh();
  }

  function connect(ssid: var, password: var, isHidden: var, securityKey: var, identity: var, enterpriseConfig: var): void {
    NetworkUtils.connect(root, S.Network, I18n, connectTimeout, ssid, password, isHidden, securityKey, identity, enterpriseConfig);
  }

  function disconnect(ssid: var): void {
    lastError = "Disconnecting is not available here. Use Windows' Wi-Fi settings.";
  }

  function forget(ssid: var): void {
    lastError = "Forgetting a network is not available here. Use Windows' Wi-Fi settings.";
  }

  function refreshActiveWifiDetails() {
    activeWifiDetailsTimestamp = Date.now();
  }

  function refreshActiveEthernetDetails() {
    activeEthernetDetailsTimestamp = Date.now();
  }

  // The engine updates the scan list itself; kept for callers of the upstream API.
  function updateNetworkStatus(ssid: var, connected: var): void {
  }

  // Helper functions
  function getSignalInfo(signal: var, isConnected: var): var {
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

  function isSecured(security: var): var {
    return security && security !== "--" && security.trim() !== "";
  }

  function isEnterprise(security: var): bool {
    if (!security) {
      return false;
    }
    const s = security.toUpperCase();
    return s.indexOf("802.1X") !== -1 || s.indexOf("EAP") !== -1 || s.indexOf("ENTERPRISE") !== -1;
  }

  function parseIpDetails(text: var): var {
    return {};
  }

  function getStatusText(showSpeed: var): string {
    return NetworkUtils.getStatusText(root, showSpeed, I18n);
  }

  function getIcon(forceEthernet: var): string {
    return NetworkUtils.getIcon(root, forceEthernet);
  }
}
