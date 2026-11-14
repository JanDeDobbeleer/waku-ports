pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Celeste.Config
import qs.components
import qs.utils
import "BluetoothStatusHelpers.js" as BluetoothStatusHelpers

Item {
    id: root

    required final property color colour

    // Port: the waku shim reports every device as plain "bluetooth", so the icon name comes from the
    // service's device type (row.type) and, for "Generic", from the device name. The result is a
    // freedesktop-style name that Icons.getBluetoothIcon understands.
    function iconNameFor(device: var): string {
        return BluetoothStatusHelpers.iconNameFor(device);
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
                if (BluetoothStatusHelpers.hasConnected(Bluetooth.devices.values))
                    return "bluetooth_connected";
                return "bluetooth";
            }
            color: root.colour
        }

        // Connected bluetooth devices
        Repeater {
            model: ScriptModel {
                values: BluetoothStatusHelpers.connectedDevices(Bluetooth.devices.values, BluetoothDeviceState.Disconnected)
            }

            MaterialIcon {
                id: device

                required final property BluetoothDevice modelData

                animate: true
                text: Icons.getBluetoothIcon(root.iconNameFor(modelData))
                color: root.colour
                // Port: outlined, not filled. A filled phone is a solid block at this size.
                fill: 0

                SequentialAnimation on opacity {
                    running: !BluetoothStatusHelpers.isConnected(device.modelData, BluetoothDeviceState.Connected)
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
