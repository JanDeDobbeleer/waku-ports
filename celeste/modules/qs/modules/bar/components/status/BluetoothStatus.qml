pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Celeste.Config
import qs.components
import qs.utils

Item {
    id: root

    required property color colour

    // Port: the waku shim reports every device as plain "bluetooth", so the icon name comes from the
    // service's device type (row.type) and, for "Generic", from the device name. The result is a
    // freedesktop-style name that Icons.getBluetoothIcon understands.
    function iconNameFor(device: var): string {
        const type = String(device?.row?.type ?? "").toLowerCase();
        const byType = {
            headphones: "audio-headphones",
            headset: "audio-headset",
            speaker: "audio-speakers",
            phone: "phone",
            tablet: "tablet",
            laptop: "computer",
            computer: "computer",
            keyboard: "input-keyboard",
            mouse: "input-mouse",
            controller: "input-gaming",
            watch: "watch",
            camera: "camera"
        };
        if (byType[type])
            return byType[type];

        const name = String(device?.name ?? "").toLowerCase();
        const byName = [[/headphone|buds|airpods|wh-|wf-|earbud|headset/, "audio-headset"], [/speaker|soundbar|boom|echo/, "audio-speakers"], [/mouse|mx master|pebble|trackpad/, "input-mouse"], [/keyboard|keys/, "input-keyboard"], [/phone|iphone|pixel|galaxy/, "phone"], [/watch/, "watch"], [/controller|gamepad|xbox|dualsense/, "input-gaming"]];
        for (const [re, icon] of byName)
            if (re.test(name))
                return icon;
        return "bluetooth";
    }

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    Behavior on implicitHeight {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    ColumnLayout {
        id: layout

        spacing: Tokens.spacing.medium / 2

        // Bluetooth icon
        MaterialIcon {
            animate: true
            text: {
                if (!Bluetooth.defaultAdapter?.enabled)
                    return "bluetooth_disabled";
                if (Bluetooth.devices.values.some(d => d.connected))
                    return "bluetooth_connected";
                return "bluetooth";
            }
            color: root.colour
        }

        // Connected bluetooth devices
        Repeater {
            model: ScriptModel {
                values: Bluetooth.devices.values.filter(d => d.state !== BluetoothDeviceState.Disconnected)
            }

            MaterialIcon {
                id: device

                required property BluetoothDevice modelData

                animate: true
                text: Icons.getBluetoothIcon(root.iconNameFor(modelData))
                color: root.colour
                // Port: outlined, not filled. A filled phone is a solid block at this size.
                fill: 0

                SequentialAnimation on opacity {
                    running: device.modelData?.state !== BluetoothDeviceState.Connected
                    alwaysRunToEnd: true
                    loops: Animation.Infinite

                    Anim {
                        from: 1
                        to: 0
                        duration: Tokens.anim.durations.large
                        easing: Tokens.anim.standardAccel
                    }
                    Anim {
                        from: 0
                        to: 1
                        duration: Tokens.anim.durations.large
                        easing: Tokens.anim.standardDecel
                    }
                }
            }
        }
    }
}
