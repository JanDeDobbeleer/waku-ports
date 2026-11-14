import QtQuick
import qs.Commons as Commons
import qs.Ui
import "Dynamic.js" as Dynamic
import "../I18nModel.js" as I18nModel

BarIndicator {
  id: root

  readonly property var remoteSessionService: BarValues.firstPartyServiceFor(bar, "nomarchy.remote-session")
  readonly property var peers: Dynamic.array(Dynamic.value(remoteSessionService, "peers"))

  active: remoteSessionService ? Dynamic.value(remoteSessionService, "active") : false
  activeText: "󰢹"
  activeTooltipText: Dynamic.length(peers) > 0 ? I18nModel.translate(Commons.I18n, "bar.remoteSessionFrom").arg(Dynamic.join(peers, ", ")) : I18nModel.translate(Commons.I18n, "bar.remoteSession")
  useActiveColor: true
  activeColor: Commons.Color.urgent
  revealWhenInactive: false

  Connections {
    target: root.indicatorHost
    ignoreUnknownSignals: true
    function onRefreshRequested() {
      if (root.remoteSessionService) root.remoteSessionService.refresh()
    }
  }
}
