import Quickshell
import qs.Services.Networking
import qs.Services.UI
import qs.Widgets
import "BluetoothWidgetUtils.js" as BluetoothWidgetUtils

NIconButtonHot {
  property ShellScreen screen

  icon: !BluetoothService.enabled ? "bluetooth-off" : ((BluetoothService.connectedDevices && BluetoothWidgetUtils.arrayLength(BluetoothService.connectedDevices) > 0) ? "bluetooth-connected" : "bluetooth")
  onClicked: {
    var p = PanelService.getPanel("bluetoothPanel", screen);
    if (p)
      p.toggle(this);
  }
  onRightClicked: {
    if (!NetworkService.airplaneModeEnabled) {
      BluetoothService.setBluetoothEnabled(!BluetoothService.enabled);
    }
  }
}
