import QtQuick
import waku.services as S

// The Wi-Fi interface: its scan result as `networks.values`, and `scannerEnabled`, which asks the
// engine for a fresh scan.
QtObject {
    id: device

    property string name: "Wi-Fi"
    readonly property int type: DeviceType.Wifi
    readonly property bool connected: S.Network.kind === "wifi"
    property bool scannerEnabled: false
    onScannerEnabledChanged: if (scannerEnabled) S.Network.refresh()

    property var items: []
    readonly property var networks: ({ values: device.items })

    // Rebuilt from the engine's list; each record is {ssid, signal 0..100, secured, connected, known}.
    property Instantiator builder: Instantiator {
        model: S.Network.networks || []
        delegate: WifiNetworkItem {
            required property var modelData
            name: String(modelData.ssid || "")
            signalStrength: Number(modelData.signal || 0) / 100
            security: modelData.secured ? WifiSecurityType.Wpa : WifiSecurityType.Open
            connected: !!modelData.connected
            known: !!modelData.known
        }
        onObjectAdded: Qt.callLater(device.collect)
        onObjectRemoved: Qt.callLater(device.collect)
    }

    function collect() {
        var out = []
        for (var i = 0; i < builder.count; ++i) out.push(builder.objectAt(i))
        items = out
    }
}
