import "BluetoothRssiUtils.js" as RssiUtils

import QtQuick 6.10
import Quickshell.Io
import "../../Helpers/BluetoothUtils.js" as BluetoothUtils

QtObject {
  id: root

  // Controls
  property bool enabled: false
  property int intervalMs: 10000
  property var connectedDevices: []

  // Output cache and version for bindings
  property var cache: ({}) // addr -> percent (0..100)
  property int version: 0

  // Internal rotation state
  property int _index: 0
  property string _currentAddr: ""

  // Single process reused for RSSI queries
  property Process rssiProcess: Process {
    id: proc
    running: false
    stdout: StdioCollector {
      id: out
    }
    onExited: function (exitCode, exitStatus) {
      RssiUtils.onExited(root, out, BluetoothUtils);
    }
  }

  // Periodic RSSI polling timer
  property Timer rssiTimer: Timer {
    interval: root.intervalMs
    repeat: true
    running: root.enabled
    onTriggered: RssiUtils.onTriggered(root, proc, BluetoothUtils)
  }
}
