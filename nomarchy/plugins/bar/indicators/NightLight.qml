import QtQuick
import qs.Commons
import qs.Ui
import "Dynamic.js" as Dynamic
import "../I18nModel.js" as I18nModel

BarIndicator {
  id: root

  readonly property var nightlightService: BarValues.firstPartyServiceFor(bar, "nomarchy.nightlight")

  active: nightlightService ? Dynamic.value(nightlightService, "nightlightEnabled") : false
  activeText: "󰔎"
  inactiveText: "󰔎"
  activeTooltipText: I18nModel.translate(I18n, "bar.dayLight")
  inactiveTooltipText: I18nModel.translate(I18n, "bar.nightLight")

  function toggle() {
    if (root.nightlightService) Dynamic.call(root.nightlightService, "setNightlight", [!root.active])
  }

  onPressed: function() { root.toggle() }
}
