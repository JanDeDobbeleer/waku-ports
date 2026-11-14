pragma Singleton

import QtQuick
import Quickshell
import Celeste.I18n
import waku.services as S
import qs.compat
import "NmcliHelpers.js" as H

// Celeste's Nmcli API over waku's Network service. Upstream wraps nmcli (1800 lines); waku gives
// the active link, the Wi-Fi scan list and `connectTo`, so everything else is a neutral stub
// marked `// waku gap:`.
Singleton {
    id: root

    // True when the engine sees a Wi-Fi link. A VPN tunnel can become the default route, so `kind`
    // may read something else while the SSID stays set; the SSID is the better witness.
    readonly final property bool wifiLinked: S.Network.kind === "wifi" || (S.Network.kind !== "ethernet" && S.Network.ssid !== "")
    readonly final property bool vpnActive: S.Network.vpnActive
    readonly final property string vpnName: S.Network.vpnName

    final property bool isConnected: wifiLinked || S.Network.kind === "ethernet"
    readonly final property bool connecting: pendingConnection !== null
    final property string activeInterface: wifiLinked ? "Wi-Fi" : S.Network.kind === "ethernet" ? "Ethernet" : ""
    final property string activeConnection: wifiLinked ? S.Network.ssid : ""
    // The radio state Windows reports; before it is known, a Wi-Fi link or a scan result counts.
    final property bool wifiEnabled: S.Network.wifiAvailable ? S.Network.wifiEnabled : (wifiLinked || networks.length > 0)
    readonly final property bool scanning: S.Network.scanning

    final property list<AccessPoint> networks: []
    readonly final property AccessPoint active: findActive() ?? syntheticActive
    final property list<string> savedConnections: []
    // The scan list marks `known` networks.
    final property list<string> savedConnectionSsids: []
    final property var savedConnectionSecurity: ({})

    final property AccessPoint pendingConnection: null
    final property var wirelessDeviceDetails: null
    final property var ethernetDeviceDetails: null
    final property string ethernetDataUsage: ""
    final property string ethernetSpeed: ""
    final property list<EthernetDevice> ethernetDevices: []
    readonly final property EthernetDevice activeEthernet: findActiveEthernet()
    readonly final property bool hasAvailableEthernet: anyEthernetAvailable()

    readonly final property Timer connectionCheckTimer: connectionCheckTimerItem
    readonly final property CheckTimer immediateCheckTimer: immediateCheckTimerItem

    // The link waku reports when the scan list has no entry for it yet.
    readonly final property AccessPoint syntheticActive: wifiLinked && S.Network.ssid ? synthetic : null
    readonly final property AccessPoint synthetic: AccessPoint {
        ssid: S.Network.ssid
        bssid: ""
        strength: S.Network.signalPercent
        frequency: 0
        active: true
        security: ""
    }

    signal connectionFailed(string ssid)

    function findActive(): AccessPoint {
        for (let i = 0; i < networks.length; i++) {
            if (networks[i].active)
                return networks[i];
        }
        return null;
    }

    function inactiveCount(): int {
        let count = 0;
        for (let i = 0; i < networks.length; i++) {
            if (!networks[i].active)
                count++;
        }
        return count;
    }

    function topInactive(limit: int): var {
        return H.topInactive(networks, limit);
    }

    function sortedEthernet(limit: int): var {
        return H.sortedEthernet(ethernetDevices, limit);
    }

    function findActiveEthernet(): EthernetDevice {
        for (let i = 0; i < ethernetDevices.length; i++) {
            if (ethernetDevices[i].connected)
                return ethernetDevices[i];
        }
        return null;
    }

    function anyEthernetAvailable(): bool {
        for (let i = 0; i < ethernetDevices.length; i++) {
            if (ethernetDevices[i].state !== "unavailable")
                return true;
        }
        return false;
    }

    function connectingSsid(): string {
        return pendingConnection ? pendingConnection.ssid : "";
    }

    function isConnectedState(state: string): bool {
        return state.startsWith("connected");
    }

    function isConnectingState(state: string): bool {
        return state.startsWith("connecting");
    }

    function securityLabel(keyMgmt: string): string {
        switch ((keyMgmt || "").trim().toLowerCase()) {
        case "":
        case "none":
            return Tr.trCtx("Open", "wifi security type");
        case "sae":
            return "WPA3";
        case "wpa-psk":
        case "wpa2":
            return "WPA2";
        case "wpa-eap":
            return Tr.tr("Enterprise");
        default:
            return keyMgmt.trim();
        }
    }

    function savedSecurityFor(ssid: string): string {
        return H.savedSecurity(savedConnectionSecurity, ssid.toLowerCase().trim());
    }

    function hasSavedProfile(ssid: string): bool {
        if (!ssid)
            return false;
        return H.containsLower(savedConnectionSsids, ssid);
    }

    function findNetwork(ssid: string): AccessPoint {
        for (let i = 0; i < networks.length; i++) {
            if (networks[i].ssid === ssid)
                return networks[i];
        }
        return null;
    }

    function rescanWifi(): void {
        S.Network.refresh();
    }

    function refreshStatus(callback: var): void {
        S.Network.refresh();
        H.invoke(callback, null);
    }

    function loadSavedConnections(callback: var): void {
        H.invoke(callback, savedConnections);
    }

    function unsupported(callback: var): void {
        H.invoke(callback, H.unsupportedResult());
    }

    // waku gap: waku switches to a known profile only. An unknown secured network needs the
    // password dialog, and waku has nothing to hand the password to.
    function connectToNetwork(ssid: string, password: string, bssid: string, callback: var): void {
        const ok = S.Network.connectTo(ssid);
        H.invoke(callback, H.connectResult(ok));
        if (!ok)
            connectionFailed(ssid);
    }

    function connectWireless(ssid: string, password: string, bssid: string, callback: var, retryCount: int): void {
        connectToNetwork(ssid, password, bssid, callback);
    }

    function connectToNetworkWithPasswordCheck(ssid: string, isSecure: bool, callback: var, bssid: string): void {
        if (isSecure && !hasSavedProfile(ssid)) {
            H.invoke(callback, H.needsPasswordResult());
            return;
        }
        connectToNetwork(ssid, "", bssid, callback);
    }

    // waku gap: no disconnect call.
    function disconnectFromNetwork(): void {
    }

    function disconnect(interfaceName: string, callback: var): void {
        unsupported(callback);
    }

    // waku gap: no profile management.
    function forgetNetwork(ssid: string, callback: var): void {
        unsupported(callback);
    }

    function addHiddenNetwork(ssid: string, password: string, security: string, hidden: bool, callback: var): void {
        unsupported(callback);
    }

    function getAutoconnect(connectionName: string, callback: var): void {
        H.invoke(callback, true);
    }

    function setAutoconnect(connectionName: string, enabled: bool, callback: var): void {
        unsupported(callback);
    }

    // waku gap: no radio switch.
    function enableWifi(enabled: bool, callback: var): void {
        unsupported(callback);
    }

    function toggleWifi(callback: var): void {
        enableWifi(!wifiEnabled, callback);
    }

    function getWifiStatus(callback: var): void {
        H.invoke(callback, wifiEnabled);
    }

    function getNetworks(callback: var): void {
        H.invoke(callback, networks);
    }

    function getEthernetInterfaces(callback: var): void {
        H.invoke(callback, ethernetDevices);
    }

    function getAllInterfaces(callback: var): void {
        H.invoke(callback, H.interfacesResult(ethernetDevices));
    }

    function connectEthernet(connectionName: string, interfaceName: string, callback: var): void {
        unsupported(callback);
    }

    function disconnectEthernet(connectionName: string, callback: var): void {
        unsupported(callback);
    }

    function getWirelessDeviceDetails(interfaceName: string, callback: var): void {
        wirelessDeviceDetails = H.linkDetails(S.Network, "wifi");
        H.invoke(callback, wirelessDeviceDetails);
    }

    function getEthernetDeviceDetails(interfaceName: string, callback: var): void {
        ethernetDeviceDetails = H.linkDetails(S.Network, "ethernet");
        H.invoke(callback, ethernetDeviceDetails);
    }

    function getEthernetSpeed(interfaceName: string): void {
        ethernetSpeed = "";
    }

    function getEthernetDataUsage(interfaceName: string, callback: var): void {
        ethernetDataUsage = "";
        H.invoke(callback, "");
    }

    function getIpv4Config(connectionName: string, callback: var): void {
        H.invoke(callback, null);
    }

    function setIpv4Config(connectionName: string, config: var, callback: var): void {
        unsupported(callback);
    }

    // refresh() emits networksChanged when a scan starts, with the same list. Rebuilding then would
    // destroy every row the UI shows, so only a changed list rebuilds.
    final property string networksSignature: ""

    function rebuild(): void {
        const signature = H.signature(S.Network.networks);
        if (signature === networksSignature)
            return;
        networksSignature = signature;
        const old = H.copy(networks);
        networks = H.buildAccessPoints(root, accessPointComp, S.Network.networks);
        const known = H.knownSsids(S.Network.networks);
        savedConnectionSsids = known;
        savedConnections = known;
        H.destroyAll(old);
    }

    function rebuildEthernet(): void {
        const old = H.copy(ethernetDevices);
        ethernetDevices = S.Network.kind === "ethernet" ? H.buildEthernet(root, ethernetComp, S.Network.ipAddress) : [];
        H.destroyAll(old);
    }

    Component.onCompleted: {
        rebuild();
        rebuildEthernet();
        // S.Network.networks stays empty until the first refresh() (a read-only WlanScan).
        S.Network.refresh();
    }

    Connections {
        function onNetworksChanged(): void {
            root.rebuild();
        }

        function onUpdated(): void {
            root.rebuildEthernet();
        }

        target: S.Network
    }

    Component {
        id: accessPointComp

        AccessPoint {}
    }

    Component {
        id: ethernetComp

        EthernetDevice {}
    }

    Timer {
        id: connectionCheckTimerItem

        interval: 4000
    }

    CheckTimer {
        id: immediateCheckTimerItem

        interval: 500
    }
}
