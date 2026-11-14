import QtQuick
import qs.Commons
import qs.Ui
import "Dynamic.js" as Dynamic
import "../I18nModel.js" as I18nModel

BarIndicator {
  id: root

  readonly property var notificationService: BarValues.firstPartyServiceFor(bar, "nomarchy.notifications")
  readonly property bool dnd: notificationService ? Dynamic.value(notificationService, "doNotDisturb") : false

  active: dnd
  activeText: "󰂛"
  inactiveText: "󰂛"
  activeTooltipText: I18nModel.translate(I18n, "bar.allowNotifications")
  inactiveTooltipText: I18nModel.translate(I18n, "bar.silenceNotifications")

  onPressed: function() {
    if (root.notificationService) {
      Dynamic.call(root.notificationService, "setDoNotDisturb", [!Dynamic.value(root.notificationService, "doNotDisturb")])
    }
  }
}
