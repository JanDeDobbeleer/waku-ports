pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Celeste.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.bar.components.status

StyledRect {
    id: root

    final property color colour: Colours.palette.m3secondary
    readonly property alias items: iconColumn

    readonly final property int spacing: Tokens.spacing.medium / 2
    readonly final property int padding: Config.bar.status.background ? Tokens.padding.medium : Tokens.padding.extraSmall

    // Index of the first/last entry that isn't collapsed, for edge margin gating
    readonly final property int firstPresent: {
        const values = model.values;
        for (let i = 0; i < values.length; i++)
            if (!collapsed(values[i]))
                return i;
        return -1;
    }
    readonly final property int lastPresent: {
        const values = model.values;
        for (let i = values.length - 1; i >= 0; i--)
            if (!collapsed(values[i]))
                return i;
        return -1;
    }

    // Entries that can shrink to nothing, spacing included
    function collapsed(entry: var): bool {
        if (entry.id === "lockStatus")
            return !Hypr.capsLock && !Hypr.numLock;
        return false;
    }

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.status.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    clip: true
    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: iconColumn.implicitHeight + root.padding * 2

    ColumnLayout {
        id: iconColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: root.padding

        spacing: 0

        Repeater {
            model: ScriptModel {
                id: model

                values: Config.bar.statusIcons.values.filter(e => e.enabled)
            }

            DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "lockStatus"
                    delegate: EntryWrapper {
                        LockStatus {
                            colour: root.colour
                            parentSpacing: root.spacing
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "audio"
                    delegate: EntryWrapper {
                        margin: Tokens.spacing.extraSmall / 2

                        MaterialIcon {
                            animate: true
                            text: Icons.getVolumeIcon(Audio.volume, Audio.muted)
                            color: root.colour
                            fontStyle: Tokens.font.icon.medium
                            fill: 1
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "microphone"
                    delegate: EntryWrapper {
                        margin: Tokens.spacing.extraSmall / 2
                        name: "audio" // Mic opens audio popout

                        MaterialIcon {
                            animate: true
                            text: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
                            color: root.colour
                            fontStyle: Tokens.font.icon.medium
                            fill: 1
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "kbLayout"
                    delegate: EntryWrapper {
                        StyledText {
                            animate: true
                            text: Hypr.kbLayout
                            color: root.colour
                            font: Tokens.font.mono.medium
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "network"
                    delegate: EntryWrapper {
                        MaterialIcon {
                            animate: true
                            text: Nmcli.activeEthernet ? "cable" : Nmcli.active ? Icons.getNetworkIcon(Nmcli.active.strength ?? 0, false) : "wifi_off"
                            color: root.colour

                            // waku gap: upstream has no VPN badge; a small key marks an active tunnel.
                            MaterialIcon {
                                visible: Nmcli.vpnActive
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.rightMargin: -7
                                anchors.topMargin: -5
                                text: "vpn_key"
                                color: root.colour
                                scale: 0.5
                            }
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: EntryWrapper {
                        BluetoothStatus {
                            colour: root.colour
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "battery"
                    delegate: EntryWrapper {
                        BatteryStatus {
                            colour: root.colour
                        }
                    }
                }
            }
        }
    }

    component EntryWrapper: Item {
        required final property var modelData
        required final property int index
        final property int margin: root.spacing / 2
        readonly final property bool present: !root.collapsed(modelData)
        final property real topGap: present && index !== root.firstPresent ? margin : 0
        final property real bottomGap: present && index !== root.lastPresent ? margin : 0
        default final property Item item
        final property string name: modelData.id.toLowerCase()

        Layout.topMargin: Math.round(topGap)
        Layout.bottomMargin: Math.round(bottomGap)
        Layout.alignment: Qt.AlignHCenter

        implicitWidth: item?.implicitWidth ?? 0
        implicitHeight: item?.implicitHeight ?? 0

        children: item

        Behavior on topGap {
            Anim {
                type: Anim.SlowEffects
            }
        }

        Behavior on bottomGap {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }
}
