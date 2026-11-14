pragma Singleton

import QtQuick 6.10
import Quickshell

// Telemetry is not part of the waku port: nothing is collected or sent. The names stay so callers load.
Singleton {
  id: root

  property bool initialized: false
  property bool isSending: false
  property int totalRamGb: 0
  property string instanceId: ""

  function init() {
  }

  function getInstanceId(): string {
    return "";
  }

  function sendPing() {
  }

  function getMonitorInfo(): var {
    return [];
  }

  function getCompositorType(): string {
    return "waku";
  }
}
