pragma Singleton

import QtQuick
import Quickshell
import qs.Commons
import qs.compat

// Telemetry is not part of the wabar port: nothing is collected or sent. The names stay so callers load.
Singleton {
  id: root

  property bool initialized: false
  property bool isSending: false
  property int totalRamGb: 0
  property string instanceId: ""

  function init() {
  }

  function getInstanceId() {
    return "";
  }

  function sendPing() {
  }

  function getMonitorInfo() {
    return [];
  }

  function getCompositorType() {
    return "wabar";
  }
}
