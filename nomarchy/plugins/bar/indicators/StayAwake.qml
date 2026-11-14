import QtQuick
import qs.Commons
import qs.Ui
import "Dynamic.js" as Dynamic
import "../I18nModel.js" as I18nModel

BarIndicator {
  id: root

  readonly property var idleService: BarValues.firstPartyServiceFor(bar, "nomarchy.idle")

  active: idleService ? Dynamic.value(idleService, "stayAwake") : false
  // A mug without a saucer, which drew a line under the cup.
  activeText: ""
  inactiveText: ""
  activeTooltipText: I18nModel.translate(I18n, "bar.allowIdleLock")
  inactiveTooltipText: I18nModel.translate(I18n, "bar.stayAwake")

  function toggle() {
    if (root.idleService) Dynamic.call(root.idleService, "setIdleEnabled", [root.active])
  }

  onPressed: function() { root.toggle() }
}
