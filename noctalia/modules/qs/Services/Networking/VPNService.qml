pragma Singleton

import QtQuick
import Quickshell
import wabar.services as S
import qs.Commons
import qs.Services.UI
import qs.compat

// Noctalia's VPNService over the engine's Network (wabar.services): the Windows RAS phone book
// entries, dialled and hung up with `connectVpn` and `disconnectVpn`. A RAS entry has no uuid, so its
// name is the key ("uuid" in the entries). VPNs of third-party clients are not in the phone book and
// do not appear.
Singleton {
  id: root

  readonly property var connections: {
    const map = {};
    for (const v of (S.Network.vpnConnections || [])) {
      map[v.name] = {
        "uuid": v.name,
        "name": v.name,
        "type": "vpn",
        "active": !!v.connected
      };
    }
    return map;
  }
  readonly property bool refreshing: false
  readonly property bool connecting: S.Network.vpnBusy && connectingUuid !== ""
  readonly property bool disconnecting: S.Network.vpnBusy && disconnectingUuid !== ""
  property string connectingUuid: ""
  property string disconnectingUuid: ""
  readonly property string lastError: S.Network.vpnError
  property bool refreshPending: false

  readonly property var activeConnections: Object.values(connections).filter(c => c.active)
  readonly property var inactiveConnections: Object.values(connections).filter(c => !c.active)
  readonly property bool hasActiveConnection: activeConnections.length > 0

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

  function connect(uuid) {
    if (!uuid || S.Network.vpnBusy)
      return;
    connectingUuid = uuid;
    if (!S.Network.connectVpn(uuid))
      connectingUuid = "";
  }

  function disconnect(uuid) {
    if (!uuid || S.Network.vpnBusy)
      return;
    disconnectingUuid = uuid;
    if (!S.Network.disconnectVpn(uuid))
      disconnectingUuid = "";
  }

  function toggle(uuid) {
    const conn = connections[uuid];
    if (!conn)
      return;
    if (conn.active)
      disconnect(uuid);
    else
      connect(uuid);
  }

  // Upstream edits a profile in place; a RAS entry has nothing to edit here.
  function setConnection(uuid, data) {
  }

  function scheduleRefresh(interval) {
    refresh();
  }
}
