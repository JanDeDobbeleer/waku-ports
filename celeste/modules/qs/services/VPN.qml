pragma Singleton

import QtQuick
import Quickshell
import Celeste.Config
import waku.services as S
import qs.compat

// Stub of upstream's VPN service (WireGuard, WARP, NetBird and Tailscale adapters that shell out to
// their CLIs). waku knows only whether a VPN link is up (`Network.vpnActive`, `vpnName`), so
// `connected` follows that and every action is a no-op. The properties keep upstream's names so
// the utilities toggle and the nexus network page load.
Singleton {
    id: root

    // waku gap: read only. waku cannot connect or disconnect a VPN.
    readonly final property bool connected: S.Network.vpnActive
    readonly final property var status: ({
            connected: connected,
            state: connected ? "connected" : "disconnected",
            reason: "",
            authUrl: "",
            server: S.Network.vpnName
        })

    final property bool connectPending: false
    final property bool disconnectPending: false
    readonly final property bool connecting: connectPending
    readonly final property bool disconnecting: disconnectPending

    readonly final property string selectedProvider: GlobalConfig.utilities.vpn.selectedProvider
    final property double connectedSince: 0
    final property string bytesIn: ""
    final property string bytesOut: ""
    final property int pingMs: -1
    final property string serverLocation: ""

    readonly final property var providers: GlobalConfig.utilities.vpn.provider.values
    readonly final property var selected: providers.find(p => p.id === selectedProvider) ?? null
    readonly final property var active: selected ?? ({
            name: S.Network.vpnName,
            interface: ""
        })
    readonly final property string providerName: S.Network.vpnName
    readonly final property string interfaceName: ""
    readonly final property var currentConfig: active

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
