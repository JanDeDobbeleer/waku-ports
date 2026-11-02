import QtQuick
import Quickshell
import qs.Commons
import qs.Services.System
import qs.Services.Networking
import qs.Services.Hardware
import qs.Services.Compositor
ShellRoot {
  Timer { interval: 800; running: true; onTriggered: { SystemStatService.registerComponent("probe"); NetworkService.scan(); } }
  Timer {
    interval: 9000; running: true
    onTriggered: {
      const S = SystemStatService;
      console.log("LIVE|cpu|usage=" + S.cpuUsage.toFixed(1) + " cores=" + S.nproc + " perCore=" + S.coresUsage.length + " temp=" + S.cpuTemp + " freq=" + S.cpuFreq + " ratio=" + S.cpuFreqRatio.toFixed(2));
      console.log("LIVE|mem|used=" + S.memGb.toFixed(1) + "GB total=" + S.memTotalGb.toFixed(1) + "GB pct=" + S.memPercent.toFixed(0) + " swap=" + S.swapGb.toFixed(1) + "/" + S.swapTotalGb.toFixed(1));
      console.log("LIVE|disk|" + JSON.stringify(S.diskPercents) + " size=" + JSON.stringify(S.diskSizeGb));
      console.log("LIVE|net|rx=" + S.rxSpeed.toFixed(0) + " tx=" + S.txSpeed.toFixed(0) + " history=" + S.rxSpeedHistory.length);
      console.log("LIVE|gpu|available=" + S.gpuAvailable + " temp=" + S.gpuTemp);
      console.log("LIVE|hist|cpuHistoryNonZero=" + S.cpuHistory.filter(v => v > 0).length);
      const N = NetworkService;
      console.log("LIVE|network|wifiEnabled=" + N.wifiEnabled + " wifiConnected=" + N.wifiConnected + " ethernet=" + N.ethernetConnected + " networks=" + Object.keys(N.networks).length + " icon=" + N.getIcon() + " status=" + N.getStatusText(true));
      console.log("LIVE|vpn|connections=" + Object.keys(VPNService.connections).length + " active=" + VPNService.activeConnections.length);
      console.log("LIVE|bluetooth|available=" + BluetoothService.bluetoothAvailable + " enabled=" + BluetoothService.enabled + " connected=" + (BluetoothService.connectedDevices ? BluetoothService.connectedDevices.length : -1));
      console.log("LIVE|brightness|monitors=" + BrightnessService.monitors.length + " available=" + (BrightnessService.monitors.length ? BrightnessService.monitors[0].brightnessControlAvailable : "-") + " value=" + (BrightnessService.monitors.length ? BrightnessService.monitors[0].brightness : "-") + " sources=" + BrightnessService.availableBacklightDevices.length);
      console.log("LIVE|host|os=" + HostService.osPretty + " user=" + HostService.displayName + " host=" + HostService.hostName);
      console.log("LIVE|fonts|count=" + FontService.availableFonts.count + " mono=" + FontService.monospaceFonts.count);
      console.log("LIVE|windows|workspaces=" + CompositorService.workspaces.count + " windows=" + CompositorService.windows.count + " focused=" + CompositorService.focusedWindowIndex);
      const outs = [];
      for (let i = 0; i < CompositorService.workspaces.count; i++) outs.push(CompositorService.workspaces.get(i).output);
      console.log("LIVE|outputs|workspaceOutputs=" + JSON.stringify(Array.from(new Set(outs))) + " screens=" + JSON.stringify(Quickshell.screens.map(s => s.name)));
      console.log("LIVE|DONE");
    }
  }
}
