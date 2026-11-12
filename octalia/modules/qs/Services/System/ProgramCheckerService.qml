pragma Singleton

import QtQuick 6.10
import Quickshell

// Upstream probes for nmcli, bluetoothctl, wlsunset, python and others with `command -v`. None of
// them is used here (the adapters read the engine's services), so every probe is false and no
// process is started.
Singleton {
  id: root

  property bool nmcliAvailable: false
  property bool bluetoothctlAvailable: false
  property bool wlsunsetAvailable: false
  property bool gnomeCalendarAvailable: false
  property bool pythonAvailable: false
  property bool wtypeAvailable: false

  property var availableDiscordClients: []
  property var availableCodeClients: []
  property var availableEmacsClients: []

  signal checksCompleted

  function checkAllPrograms() {
    checksCompleted();
  }

  function checkProgram(programProperty: var) {
  }
}
