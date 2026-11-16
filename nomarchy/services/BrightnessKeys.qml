import QtQuick
import waku.services as S
import qs.Commons
import "BrightnessModel.js" as BrightnessModel

Item {
  id: root

  property var host: null

  function handle(action: var): bool {
    if (action !== "raise" && action !== "lower") return false
    if (!S.ControlCenter.brightnessAvailable) return true

    var percent = BrightnessModel.brightnessKeyTarget(action, S.ControlCenter.brightness)
    S.ControlCenter.setBrightness(percent)
    if (host) {
      host.summon("nomarchy.osd", JSON.stringify({
        icon: "brightness",
        message: "",
        value: String(percent),
        progressText: I18n.formatNumber(percent) + "%",
        max: "100",
        duration: ""
      }))
    }
    return true
  }
}
