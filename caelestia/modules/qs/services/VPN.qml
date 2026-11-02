pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Config
import waku.services as S
import qs.compat

// Stub of upstream's VPN service (WireGuard, WARP, NetBird and Tailscale adapters that shell out to
// their CLIs). waku knows only whether a VPN link is up (`Network.vpnActive`, `vpnName`), so
// `connected` follows that and every action is a no-op. The properties keep upstream's names so
// the utilities toggle and the nexus network page load.
Singleton {
    id: root

    // waku gap: read only. waku cannot connect or disconnect a VPN.
    readonly property bool connected: S.Network.vpnActive
    readonly property var status: ({
            connected: connected,
            state: connected ? "connected" : "disconnected",
            reason: "",
            authUrl: "",
            server: S.Network.vpnName
        })

    property bool connectPending: false
    property bool disconnectPending: false
    readonly property bool connecting: connectPending
    readonly property bool disconnecting: disconnectPending

    readonly property string selectedProvider: GlobalConfig.utilities.vpn.selectedProvider
    property double connectedSince: 0
    property string bytesIn: ""
    property string bytesOut: ""
    property int pingMs: -1
    property string serverLocation: ""

    readonly property var providers: GlobalConfig.utilities.vpn.provider.values
    readonly property var selected: providers.find(p => p.id === selectedProvider) ?? null
    readonly property var active: selected ?? ({
            name: S.Network.vpnName,
            interface: ""
        })
    readonly property string providerName: S.Network.vpnName
    readonly property string interfaceName: ""
    readonly property var currentConfig: active

    function connect(): void {
    }

    function disconnect(): void {
    }

    function toggle(): void {
    }

    function checkStatus(): void {
        S.Network.refresh();
    }

    function refreshStats(): void {
    }

    function addProvider(data: var): void {
    }

    function updateProvider(index: int, data: var): void {
    }

    function deleteProvider(index: int): void {
    }

    function setActiveProvider(index: int): void {
    }
}
