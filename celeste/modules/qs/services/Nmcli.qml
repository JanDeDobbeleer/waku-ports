pragma Singleton

import QtQuick
import Quickshell
import Celeste.I18n
import waku.services as S
import qs.compat

// Celeste's Nmcli API over waku's Network service. Upstream wraps nmcli (1800 lines); waku gives
// the active link, the Wi-Fi scan list and `connectTo`, so everything else is a neutral stub
// marked `// waku gap:`.
Singleton {
    id: root

    // True when the engine sees a Wi-Fi link. A VPN tunnel can become the default route, so `kind`
    // may read something else while the SSID stays set; the SSID is the better witness.
    readonly property bool wifiLinked: S.Network.kind === "wifi" || (S.Network.kind !== "ethernet" && S.Network.ssid !== "")
    readonly property bool vpnActive: S.Network.vpnActive
    readonly property string vpnName: S.Network.vpnName

    property bool isConnected: wifiLinked || S.Network.kind === "ethernet"
    readonly property bool connecting: pendingConnection !== null
    property string activeInterface: wifiLinked ? "Wi-Fi" : S.Network.kind === "ethernet" ? "Ethernet" : ""
    property string activeConnection: wifiLinked ? S.Network.ssid : ""
    // The radio state Windows reports; before it is known, a Wi-Fi link or a scan result counts.
    property bool wifiEnabled: S.Network.wifiAvailable ? S.Network.wifiEnabled : (wifiLinked || networks.length > 0)
    readonly property bool scanning: S.Network.scanning

    property list<AccessPoint> networks: []
    readonly property AccessPoint active: networks.find(n => n.active) ?? syntheticActive
    property list<string> savedConnections: []
    // The scan list marks `known` networks.
    property list<string> savedConnectionSsids: []
    property var savedConnectionSecurity: ({})

    property var pendingConnection: null
    property var wirelessDeviceDetails: null
    property var ethernetDeviceDetails: null
    property string ethernetDataUsage: ""
    property string ethernetSpeed: ""
    property list<EthernetDevice> ethernetDevices: []
    readonly property EthernetDevice activeEthernet: ethernetDevices.find(d => d.connected) ?? null
    readonly property bool hasAvailableEthernet: ethernetDevices.some(d => d.state !== "unavailable")

    readonly property alias connectionCheckTimer: connectionCheckTimer
    readonly property alias immediateCheckTimer: immediateCheckTimer

    // The link waku reports when the scan list has no entry for it yet.
    readonly property AccessPoint syntheticActive: wifiLinked && S.Network.ssid ? synthetic : null
    readonly property AccessPoint synthetic: AccessPoint {
        lastIpcObject: ({
                ssid: S.Network.ssid,
                bssid: "",
                strength: S.Network.signalPercent,
                frequency: 0,
                active: true,
                security: ""
            })
    }

    signal connectionFailed(string ssid)

    function connectingSsid(): string {
        return pendingConnection?.ssid ?? "";
    }

    function isConnectedState(state: string): bool {
        return state?.startsWith("connected") ?? false;
    }

    function isConnectingState(state: string): bool {
        return state?.startsWith("connecting") ?? false;
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
        return savedConnectionSecurity[(ssid ?? "").toLowerCase().trim()] || "";
    }

    function hasSavedProfile(ssid: string): bool {
        if (!ssid)
            return false;
        const key = ssid.toLowerCase().trim();
        return savedConnectionSsids.some(s => s.toLowerCase().trim() === key);
    }

    function findNetwork(ssid: string): var {
        return networks.find(n => n.ssid === ssid) ?? null;
    }

    function rescanWifi(): void {
        S.Network.refresh();
    }

    function refreshStatus(callback: var): void {
        S.Network.refresh();
        if (callback)
            callback(null);
    }

    function loadSavedConnections(callback: var): void {
        if (callback)
            callback(savedConnections);
    }

    function unsupported(callback: var): void {
        if (callback)
            callback({
                success: false,
                output: "",
                error: "Not supported on Windows",
                exitCode: 1
            });
    }

    // waku gap: waku switches to a known profile only. An unknown secured network needs the
    // password dialog, and waku has nothing to hand the password to.
    function connectToNetwork(ssid: string, password: string, bssid: string, callback: var): void {
        const ok = S.Network.connectTo(ssid);
        if (callback)
            callback({
                success: ok,
                output: "",
                error: ok ? "" : "Unable to connect",
                exitCode: ok ? 0 : 1
            });
        if (!ok)
            connectionFailed(ssid);
    }

    function connectWireless(ssid: string, password: string, bssid: string, callback: var, retryCount: int): void {
        connectToNetwork(ssid, password, bssid, callback);
    }

    function connectToNetworkWithPasswordCheck(ssid: string, isSecure: bool, callback: var, bssid: string): void {
        if (isSecure && !hasSavedProfile(ssid)) {
            if (callback)
                callback({
                    success: false,
                    needsPassword: true
                });
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
        if (callback)
            callback(true);
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
        if (callback)
            callback(wifiEnabled);
    }

    function getNetworks(callback: var): void {
        if (callback)
            callback(networks);
    }

    function getEthernetInterfaces(callback: var): void {
        if (callback)
            callback(ethernetDevices);
    }

    function getAllInterfaces(callback: var): void {
        if (callback)
            callback({
                wireless: [],
                ethernet: ethernetDevices
            });
    }

    function connectEthernet(connectionName: string, interfaceName: string, callback: var): void {
        unsupported(callback);
    }

    function disconnectEthernet(connectionName: string, callback: var): void {
        unsupported(callback);
    }

    function linkDetails(kind: string): var {
        if (S.Network.kind !== kind)
            return null;
        return {
            ipAddress: S.Network.ipAddress,
            gateway: "",
            dns: [],
            subnet: "",
            macAddress: "",
            speed: ""
        };
    }

    function getWirelessDeviceDetails(interfaceName: string, callback: var): void {
        wirelessDeviceDetails = linkDetails("wifi");
        if (callback)
            callback(wirelessDeviceDetails);
    }

    function getEthernetDeviceDetails(interfaceName: string, callback: var): void {
        ethernetDeviceDetails = linkDetails("ethernet");
        if (callback)
            callback(ethernetDeviceDetails);
    }

    function getEthernetSpeed(interfaceName: string): void {
        ethernetSpeed = "";
    }

    function getEthernetDataUsage(interfaceName: string, callback: var): void {
        ethernetDataUsage = "";
        if (callback)
            callback("");
    }

    function getIpv4Config(connectionName: string, callback: var): void {
        if (callback)
            callback(null);
    }

    function setIpv4Config(connectionName: string, config: var, callback: var): void {
        unsupported(callback);
    }

    // refresh() emits networksChanged when a scan starts, with the same list. Rebuilding then would
    // destroy every row the UI shows, so only a changed list rebuilds.
    property string networksSignature: ""

    function rebuild(): void {
        const signature = JSON.stringify(S.Network.networks || []);
        if (signature === networksSignature)
            return;
        networksSignature = signature;
        const old = [...networks];
        const next = [];
        const known = [];
        // waku gap: no BSSID, so the SSID stands in for it and keeps rows distinct.
        for (const n of S.Network.networks) {
            if (n.known)
                known.push(n.ssid);
            next.push(accessPointComp.createObject(root, {
                lastIpcObject: {
                    ssid: n.ssid,
                    bssid: n.ssid,
                    strength: n.signal,
                    frequency: 0,
                    active: n.connected,
                    security: n.secured ? "WPA2" : ""
                }
            }));
        }
        networks = next;
        savedConnectionSsids = known;
        savedConnections = known;
        for (const o of old)
            o.destroy();
    }

    function rebuildEthernet(): void {
        const old = [...ethernetDevices];
        const up = S.Network.kind === "ethernet";
        const next = [];
        if (up)
            next.push(ethernetComp.createObject(root, {
                lastIpcObject: {
                    interface: "Ethernet",
                    type: "ethernet",
                    state: "connected",
                    connection: "Ethernet",
                    connected: true,
                    ipAddress: S.Network.ipAddress
                }
            }));
        ethernetDevices = next;
        for (const o of old)
            o.destroy();
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
        id: connectionCheckTimer

        interval: 4000
    }

    Timer {
        id: immediateCheckTimer

        property int checkCount: 0

        interval: 500
    }

    component AccessPoint: QtObject {
        required property var lastIpcObject
        readonly property string ssid: lastIpcObject.ssid
        readonly property string bssid: lastIpcObject.bssid
        readonly property int strength: lastIpcObject.strength
        readonly property int frequency: lastIpcObject.frequency
        readonly property bool active: lastIpcObject.active
        readonly property string security: lastIpcObject.security
        readonly property bool isSecure: security.length > 0
    }

    component EthernetDevice: QtObject {
        required property var lastIpcObject
        readonly property string iface: lastIpcObject.interface
        readonly property string type: lastIpcObject.type
        readonly property string state: lastIpcObject.state
        readonly property string connection: lastIpcObject.connection
        readonly property bool connected: lastIpcObject.connected
        readonly property string ipAddress: lastIpcObject.ipAddress ?? ""
        readonly property string gateway: lastIpcObject.gateway ?? ""
        readonly property var dns: lastIpcObject.dns ?? []
        readonly property string subnet: lastIpcObject.subnet ?? ""
        readonly property string macAddress: lastIpcObject.macAddress ?? ""
        readonly property string speed: lastIpcObject.speed ?? ""
    }
}
