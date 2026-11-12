import Quickshell
import qs.Services.Networking
import qs.Services.UI
import qs.Widgets

NIconButtonHot {
  property ShellScreen screen
  icon: NetworkService.getIcon(undefined)
  onClicked: {
    var panel = PanelService.getPanel("networkPanel", screen);
    PanelService.invokePanel(panel, "toggle", [this]);
  }
  onRightClicked: {
    if (!NetworkService.airplaneModeEnabled) {
      NetworkService.setWifiEnabled(!NetworkService.wifiEnabled);
    }
  }
}
