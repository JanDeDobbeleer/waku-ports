pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Compositor
import qs.Widgets

ColumnLayout {
  id: root
  enabled: true
  spacing: Style.marginL
  Layout.fillWidth: true

  // Helper functions to update arrays immutably
  function addMonitor(list, name) {
    const arr = (list || []).slice();
    if (!arr.includes(name))
      arr.push(name);
    return arr;
  }
  function removeMonitor(list, name) {
    return (list || []).filter(function (n) {
      return n !== name;
    });
  }

  NText {
    text: I18n.tr("panels.lock-screen.monitors-desc")
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }

  Repeater {
    model: Quickshell.screens || []
    delegate: NCheckbox {
      id: monitorOption
      required property ShellScreen modelData
      Layout.fillWidth: true
      readonly property real compositorScale: {
        const info = CompositorService.displayScales[monitorOption.modelData.name];
        return (info && info.scale) ? info.scale : 1.0;
      }
      label: monitorOption.modelData.name || "Unknown"
      description: {
        I18n.tr("system.monitor-description", {
                  "model": monitorOption.modelData.model,
                  "width": monitorOption.modelData.width * compositorScale,
                  "height": monitorOption.modelData.height * compositorScale,
                  "scale": compositorScale
                });
      }
      checked: (Settings.data.general.lockScreenMonitors || []).indexOf(monitorOption.modelData.name) !== -1
      onToggled: checked => {
                   if (checked) {
                     Settings.data.general.lockScreenMonitors = root.addMonitor(Settings.data.general.lockScreenMonitors, monitorOption.modelData.name);
                   } else {
                     Settings.data.general.lockScreenMonitors = root.removeMonitor(Settings.data.general.lockScreenMonitors, monitorOption.modelData.name);
                   }
                 }
    }
  }
}
