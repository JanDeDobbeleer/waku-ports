.pragma library

function ethernetInterfaces(network) {
    const out = [];
    if (network.kind !== "ethernet")
      return out;
    for (const a of (network.adapters || [])) {
      if (a.isUp && !/wi-?fi|wlan|wireless|loopback|virtual|vethernet|bluetooth/i.test(a.name))
        out.push({
                   "ifname": a.name,
                   "connectionName": a.name,
                   "connected": true
                 });
    }
    return out;
}

function networks(network) {
    const map = {};
    for (const n of (network.networks || [])) {
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

function existingProfiles(network) {
    const map = {};
    for (const n of (network.networks || [])) {
      if (n.known)
        map[n.ssid] = true;
    }
    return map;
}

function hasInterfaces(interfaces) {
  return interfaces.length > 0;
}

function firstInterfaceName(interfaces) {
  return interfaces.length > 0 ? interfaces[0].ifname : "";
}

function getStatusText(root, showSpeed = false, I18n) {
    // This variable can be tied to a toggle
    if (root.connecting) {
      return root.connectingTo ? I18n.tr("common.connecting") + " " + root.connectingTo : I18n.tr("common.connecting");
    }

    if (root.airplaneModeEnabled) {
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

function getIcon(root, forceEthernet = false) {
    if (root.airplaneModeEnabled && !forceEthernet) {
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

function connect(root, network, I18n, connectTimeout, ssid, password = "", isHidden = false, securityKey = "", identity = "", enterpriseConfig = {}) {
    if (root.connecting)
      return;
    const known = root.networks[ssid] && root.networks[ssid].existing;
    if (!known || password || isHidden) {
      root.lastError = I18n.tr("common.error") + ": Windows connects only to saved networks here. Add this one in Windows' Wi-Fi settings first.";
      return;
    }
    root.lastError = "";
    if (network.connectTo(ssid)) {
      root.connecting = true;
      root.connectingTo = ssid;
      connectTimeout.restart();
    }
}
