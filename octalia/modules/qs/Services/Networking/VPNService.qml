pragma Singleton

import "VPNUtils.js" as VPNUtils

import QtQuick 6.10
import Quickshell
import waku.services as S
import qs.Commons

// Octalia's VPNService over the engine's Network (waku.services): the Windows RAS phone book
// entries, dialled and hung up with `connectVpn` and `disconnectVpn`. A RAS entry has no uuid, so its
// name is the key ("uuid" in the entries). VPNs of third-party clients are not in the phone book and
// do not appear.
Singleton {
  id: root

  readonly property var connections: VPNUtils.connections(S.Network.vpnConnections)
  readonly property bool refreshing: false
  readonly property bool connecting: S.Network.vpnBusy && connectingUuid !== ""
  readonly property bool disconnecting: S.Network.vpnBusy && disconnectingUuid !== ""
  property string connectingUuid: ""
  property string disconnectingUuid: ""
  readonly property string lastError: S.Network.vpnError
  property bool refreshPending: false

  readonly property var activeConnections: VPNUtils.filterConnections(connections, true)
  readonly property var inactiveConnections: VPNUtils.filterConnections(connections, false)
  readonly property bool hasActiveConnection: VPNUtils.hasActive(activeConnections)

  Component.onCompleted: Logger.i("VPN", "Service started")

  // The busy flag ends the attempt.
  Connections {
    target: S.Network
    function onVpnChanged() {
      if (!S.Network.vpnBusy) {
        root.connectingUuid = "";
        root.disconnectingUuid = "";
      }
    }
  }

  function refresh() {
    S.Network.refresh();
  }

  function connect(uuid: var): void {
    if (!uuid || S.Network.vpnBusy)
      return;
    connectingUuid = uuid;
    if (!S.Network.connectVpn(uuid))
      connectingUuid = "";
  }

  function disconnect(uuid: var): void {
    if (!uuid || S.Network.vpnBusy)
      return;
    disconnectingUuid = uuid;
    if (!S.Network.disconnectVpn(uuid))
      disconnectingUuid = "";
  }

  function toggle(uuid: var): void {
    const conn = connections[uuid];
    if (!conn)
      return;
    if (conn.active)
      disconnect(uuid);
    else
      connect(uuid);
  }

  // Upstream edits a profile in place; a RAS entry has nothing to edit here.
  function setConnection(uuid: var, data: var): void {
  }

  function scheduleRefresh(interval: var): void {
    refresh();
  }
}
