import QtQuick
import Quickshell
import Quickshell.Bluetooth as QB
import wabar.services as S

ShellRoot {
    function dump(tag) {
        const b = S.Bluetooth, n = S.Network;
        console.log("qml: PROBE " + tag + " bt.available=" + b.available + " radioOn=" + b.radioOn
            + " devices=" + b.devices.length + " connected=" + b.connectedCount);
        for (const d of b.devices)
            console.log("qml: PROBE " + tag + " row connected=" + d.connected + " paired=" + d.paired + " type=" + d.type + " batt=" + d.batteryPercent);
        const a = QB.Bluetooth.defaultAdapter;
        console.log("qml: PROBE " + tag + " shim adapter=" + (a ? "yes" : "null") + " enabled=" + (a ? a.enabled : "-")
            + " shimDevices=" + QB.Bluetooth.devices.values.length);
        console.log("qml: PROBE " + tag + " net.available=" + n.available + " kind=" + n.kind + " wifiAvail=" + n.wifiAvailable
            + " wifiEnabled=" + n.wifiEnabled + " ssid.len=" + n.ssid.length + " networks=" + n.networks.length + " scanning=" + n.scanning);
    }
    Component.onCompleted: { S.Bluetooth.available; S.Network.refresh(); }
    Timer { interval: 45000; running: true; onTriggered: dump("45s") }
    Timer { interval: 1000; running: true; repeat: true; property int n: 0; onTriggered: { n++; if (S.Bluetooth.devices.length > 0 || n == 44) { console.log("qml: PROBE first-devices at " + n + "s count=" + S.Bluetooth.devices.length + " radioOn=" + S.Bluetooth.radioOn); running = false } } }
    Timer { interval: 5000; running: true; onTriggered: dump("5s") }
    Timer { interval: 20000; running: true; onTriggered: dump("20s") }
}
