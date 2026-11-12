pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Celeste.Config
import Celeste.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required final property PopoutState popouts

    final property string connectingToSsid: ""
    final property string view: "wireless" // "wireless" or "ethernet"
    final property AccessPoint passwordNetwork: null
    final property bool showPasswordDialog: false

    spacing: Tokens.spacing.small
    width: Tokens.sizes.bar.networkWidth

    // Password is required - show password dialog
    function showPasswordFor(network: AccessPoint): void {
        passwordNetwork = network;
        showPasswordDialog = true;
        popouts.currentName = "wirelesspassword";
    }

    // Wireless section
    StyledText {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Tokens.padding.medium : 0
        Layout.rightMargin: Tokens.padding.extraSmall
        text: Tr.tr("Wireless")
        font: Tokens.styled("body", "medium", { weight: Font.Medium })
    }

    Toggle {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        label: Tr.trCtx("Enabled", "toggle label")
        checked: Nmcli.wifiEnabled
        toggle.onToggled: Nmcli.enableWifi(checked, null)
    }

    // The current link, shown at once: the scan list below fills only after the first scan.
    RowLayout {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: Nmcli.active ? Icons.getNetworkIcon(Nmcli.active.strength ?? 0, false) : "wifi_off"
            color: Nmcli.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            Layout.fillWidth: true
            text: Nmcli.active ? Tr.tr("Connected to %1").arg(Nmcli.active.ssid) : Tr.tr("Not connected to wireless")
            elide: Text.ElideRight
            color: Nmcli.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            font: Tokens.styled("body", "medium", { weight: Font.Medium })
        }
    }

    // waku gap: read only. The tunnel is shown beside the Wi-Fi link, not instead of it.
    RowLayout {
        visible: root.view === "wireless" && Nmcli.vpnActive
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "vpn_key"
            color: Colours.palette.m3tertiary
        }

        StyledText {
            Layout.fillWidth: true
            text: Nmcli.vpnName ? Tr.tr("VPN: %1").arg(Nmcli.vpnName) : Tr.tr("VPN active")
            elide: Text.ElideRight
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.medium
        }
    }

    StyledText {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Tokens.spacing.small : 0
        Layout.rightMargin: Tokens.padding.extraSmall
        text: Tr.trN("%n network available", "%n networks available", Nmcli.inactiveCount())
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }

    Repeater {
        visible: root.view === "wireless"
        model: ScriptModel {
            // The connected network is the "Connected to ..." line above, and the count above leaves
            // it out, so the list does too.
            values: Nmcli.topInactive(8)
        }

        RowLayout {
            id: networkItem

            required final property AccessPoint modelData
            readonly final property bool isConnecting: root.connectingToSsid === modelData.ssid
            readonly final property bool loading: networkItem.isConnecting

            visible: root.view === "wireless"
            Layout.preferredHeight: visible ? implicitHeight : 0
            Layout.fillWidth: true
            Layout.rightMargin: Tokens.padding.extraSmall
            spacing: Tokens.spacing.small

            opacity: 0
            scale: 0.7

            Component.onCompleted: {
                opacity = 1;
                scale = 1;
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                Anim {}
            }

            MaterialIcon {
                text: Icons.getNetworkIcon(networkItem.modelData.strength, false)
                color: networkItem.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }

            MaterialIcon {
                visible: networkItem.modelData.isSecure
                text: "lock"
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                Layout.leftMargin: Tokens.spacing.extraSmall
                Layout.rightMargin: Tokens.spacing.extraSmall
                Layout.fillWidth: true
                text: networkItem.modelData.ssid
                elide: Text.ElideRight
                font: Tokens.styled("body", "medium", { weight: networkItem.modelData.active ? Font.Medium : Font.Normal })
                color: networkItem.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: wirelessConnectIcon.implicitHeight + Tokens.padding.extraSmall

                radius: Tokens.rounding.full
                color: Qt.alpha(Colours.palette.m3primary, networkItem.modelData.active ? 1 : 0)

                CircularIndicator {
                    anchors.fill: parent
                    running: networkItem.loading
                }

                StateLayer {
                    color: networkItem.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    disabled: networkItem.loading || !Nmcli.wifiEnabled

                    onClicked: {
                        if (networkItem.modelData.active) {
                            Nmcli.disconnectFromNetwork();
                        } else {
                            root.connectingToSsid = networkItem.modelData.ssid;
                            NetworkConnection.handleConnect(networkItem.modelData, root.showPasswordFor);

                            // Clear connecting state if connection succeeds immediately (saved profile)
                            // This is handled by the onActiveChanged connection below
                        }
                    }
                }

                MaterialIcon {
                    id: wirelessConnectIcon

                    anchors.centerIn: parent
                    animate: true
                    text: networkItem.modelData.active ? "link_off" : "link"
                    color: networkItem.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                    opacity: networkItem.loading ? 0 : 1

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }
            }
        }
    }

    StyledRect {
        id: rescanBg

        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Tokens.spacing.small : 0
        Layout.fillWidth: true
        implicitHeight: rescanBtn.implicitHeight + Tokens.padding.small

        radius: Tokens.rounding.full
        color: Colours.palette.m3primaryContainer

        StateLayer {
            color: Colours.palette.m3onPrimaryContainer
            disabled: Nmcli.scanning || !Nmcli.wifiEnabled
            onClicked: Nmcli.rescanWifi()
        }

        RowLayout {
            id: rescanBtn

            anchors.centerIn: parent
            spacing: Tokens.spacing.small
            opacity: Nmcli.scanning ? 0 : 1

            MaterialIcon {
                id: scanIcon

                Layout.topMargin: Math.round(fontInfo.pointSize * 0.0575)
                animate: true
                text: "wifi_find"
                color: Colours.palette.m3onPrimaryContainer
            }

            StyledText {
                Layout.topMargin: -Math.round(scanIcon.fontInfo.pointSize * 0.0575)
                text: Tr.tr("Rescan networks")
                color: Colours.palette.m3onPrimaryContainer
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        CircularIndicator {
            anchors.centerIn: parent
            strokeWidth: Tokens.padding.extraSmall / 2
            bgColour: "transparent"
            implicitSize: rescanBg.implicitHeight - Tokens.padding.large
            running: Nmcli.scanning
        }
    }

    // Ethernet section
    StyledText {
        visible: root.view === "ethernet"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Tokens.padding.medium : 0
        Layout.rightMargin: Tokens.padding.extraSmall
        text: Tr.tr("Ethernet")
        font: Tokens.styled("body", "medium", { weight: Font.Medium })
    }

    StyledText {
        visible: root.view === "ethernet"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Tokens.spacing.small : 0
        Layout.rightMargin: Tokens.padding.extraSmall
        text: Tr.trN("%n device available", "%n devices available", Nmcli.ethernetDevices.length)
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }

    Repeater {
        visible: root.view === "ethernet"
        model: ScriptModel {
            values: Nmcli.sortedEthernet(8)
        }

        RowLayout {
            id: ethernetItem

            required final property EthernetDevice modelData
            readonly final property bool loading: false

            visible: root.view === "ethernet"
            Layout.preferredHeight: visible ? implicitHeight : 0
            Layout.fillWidth: true
            Layout.rightMargin: Tokens.padding.extraSmall
            spacing: Tokens.spacing.small

            opacity: 0
            scale: 0.7

            Component.onCompleted: {
                opacity = 1;
                scale = 1;
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                Anim {}
            }

            MaterialIcon {
                text: "cable"
                color: ethernetItem.modelData.connected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                Layout.leftMargin: Tokens.spacing.extraSmall
                Layout.rightMargin: Tokens.spacing.extraSmall
                Layout.fillWidth: true
                text: ethernetItem.modelData.iface || Tr.trCtx("Unknown", "unknown network interface")
                elide: Text.ElideRight
                font: Tokens.styled("body", "medium", { weight: ethernetItem.modelData.connected ? Font.Medium : Font.Normal })
                color: ethernetItem.modelData.connected ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: connectIcon.implicitHeight + Tokens.padding.extraSmall

                radius: Tokens.rounding.full
                color: Qt.alpha(Colours.palette.m3primary, ethernetItem.modelData.connected ? 1 : 0)

                CircularIndicator {
                    anchors.fill: parent
                    running: ethernetItem.loading
                }

                StateLayer {
                    color: ethernetItem.modelData.connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    disabled: ethernetItem.loading

                    onClicked: {
                        if (ethernetItem.modelData.connected && ethernetItem.modelData.connection) {
                            Nmcli.disconnectEthernet(ethernetItem.modelData.connection, null);
                        } else {
                            Nmcli.connectEthernet(ethernetItem.modelData.connection || "", ethernetItem.modelData.iface || "", null);
                        }
                    }
                }

                MaterialIcon {
                    id: connectIcon

                    anchors.centerIn: parent
                    animate: true
                    text: ethernetItem.modelData.connected ? "link_off" : "link"
                    color: ethernetItem.modelData.connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                    opacity: ethernetItem.loading ? 0 : 1

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }
            }
        }
    }

    Connections {
        function onActiveChanged(): void {
            if (Nmcli.active && root.connectingToSsid === Nmcli.active.ssid) {
                root.connectingToSsid = "";
                // Close password dialog if we successfully connected
                if (root.showPasswordDialog && root.passwordNetwork && Nmcli.active.ssid === root.passwordNetwork.ssid) {
                    root.showPasswordDialog = false;
                    root.passwordNetwork = null;
                    if (root.popouts.currentName === "wirelesspassword") {
                        root.popouts.currentName = "network";
                    }
                }
            }
        }

        function onScanningChanged(): void {
            if (!Nmcli.scanning)
                scanIcon.rotation = 0;
        }

        target: Nmcli
    }

    Connections {
        function onCurrentNameChanged(): void {
            // Clear password network when leaving password dialog
            if (root.popouts.currentName !== "wirelesspassword" && root.showPasswordDialog) {
                root.showPasswordDialog = false;
                root.passwordNetwork = null;
            }
        }

        target: root.popouts
    }

    component Toggle: RowLayout {
        required final property string label
        property alias checked: toggle.checked
        property alias toggle: toggle

        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.medium

        StyledText {
            Layout.fillWidth: true
            text: parent.label
        }

        StyledSwitch {
            id: toggle
        }
    }
}
