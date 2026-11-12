pragma Singleton

import QtQuick 6.10
import Quickshell
import qs.Commons

// Night light needs wlsunset (Wayland). Windows has its own Night light in its settings, which waku
// does not control, so apply() does nothing and the schedule helpers are not kept.
Singleton {
  id: root

  readonly property var params: Settings.data.nightLight
  property var lastCommand: []

  function apply(force: var): void {
    Logger.d("NightLight", "Not available on Windows");
  }
}
