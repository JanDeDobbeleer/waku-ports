import QtQuick
import Quickshell
import Quickshell.Services.UPower
import wabar.services as S
import Caelestia.Config
import qs.services
import qs.utils
import qs.daemons

// WP4 smoke shell: live values of the ported services in a centred 900x600 panel.
ShellRoot {
    id: root

    // Daemons that start with the shell.
    BatteryMonitor {}
    GameMode {}
    IdleInhibit {}
    IdleMonitors {}
    Shortcuts {}

    S.Cpu {
        id: cpu

        interval: 1000
    }

    S.Memory {
        id: mem

        interval: 1000
    }

    PanelWindow {
        id: win

        readonly property var scr: Quickshell.screens[0]

        anchors.top: true
        anchors.left: true
        margins.left: Math.max(0, ((scr?.width ?? 1920) - 900) / 2)
        margins.top: Math.max(0, ((scr?.height ?? 1080) - 600) / 2)
        implicitWidth: 900
        implicitHeight: 600
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 24
            color: Colours.palette.m3surfaceContainer
            border.color: Colours.palette.m3outlineVariant
            border.width: 2

            Column {
                x: 28
                y: 24
                width: parent.width - 56
                spacing: 8

                Text {
                    color: Colours.palette.m3onSurface
                    font.pixelSize: 22
                    font.bold: true
                    text: `WP4 services smoke  ${Time.hourStr}:${Time.minuteStr}  (${Time.format("dddd d MMMM")})`
                }

                Row {
                    spacing: 12

                    Repeater {
                        model: ["primary", "secondary", "tertiary", "error", "primaryContainer", "surface", "background"]

                        Rectangle {
                            required property string modelData

                            width: 112
                            height: 40
                            radius: 10
                            color: Colours.palette["m3" + modelData]
                            border.color: Colours.palette.m3outline

                            Text {
                                anchors.centerIn: parent
                                color: Colours.on(parent.color)
                                font.pixelSize: 11
                                text: parent.modelData
                            }
                        }
                    }
                }

                Text {
                    color: Colours.palette.m3primary
                    font.pixelSize: 13
                    text: `Colours.palette.m3primary = ${Colours.palette.m3primary}   scheme ${Colours.scheme}/${Colours.flavour}   light ${Colours.light}   wallLum ${Colours.wallLuminance.toFixed(2)}`
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Colours.palette.m3outlineVariant
                }

                Text {
                    color: Colours.palette.m3onSurface
                    font.pixelSize: 15
                    lineHeight: 1.25
                    wrapMode: Text.Wrap
                    width: parent.width
                    text: [
                        `Audio.volume        ${Math.round(Audio.volume * 100)}%  muted ${Audio.muted}  sink ${Audio.sink?.description ?? "-"}  sinks ${Audio.sinks.length}  streams ${Audio.streams.length}`,
                        `Nmcli.active        ${Nmcli.active ? `${Nmcli.active.ssid} (${Nmcli.active.strength}%)` : "none"}  networks ${Nmcli.networks.length}  wifiEnabled ${Nmcli.wifiEnabled}  ethernet ${Nmcli.activeEthernet?.iface ?? "-"}`,
                        `Notifs.list.length  ${Notifs.list.length}   popups ${Notifs.popups.length}   VPN.connected ${VPN.connected}`,
                        `Players.active      ${Players.active ? `${Players.active.trackTitle} - ${Players.active.trackArtist}` : "no player"}   (${Players.list.length} players)`,
                        `Battery             ${Math.round(UPower.displayDevice.percentage * 100)}%  onBattery ${UPower.onBattery}`,
                        `Hypr.workspaces     ${Hypr.workspaces.values.length}  hasWm ${Hypr.hasWm}  activeWsId ${Hypr.activeWsId}  monitors ${Hypr.monitors.values.length}  caps ${Hypr.capsLock} num ${Hypr.numLock} kb ${Hypr.kbLayout}`,
                        `Hypr.activeToplevel ${Hypr.activeToplevel ? `${Hypr.activeToplevel.title} [${Hypr.activeToplevel.lastIpcObject.class}]` : "none"}`,
                        `Brightness          ${Brightness.getMonitorForScreen(win.scr) ? Math.round(Brightness.getMonitorForScreen(win.scr).brightness * 100) + "%" : "n/a"}  available ${Brightness.available}`,
                        `CPU ${Math.round(cpu.percent)}%   RAM ${Math.round(mem.percent)}%   SysInfo ${SysInfo.osPrettyName} | ${SysInfo.device} | up ${SysInfo.uptimeShort} | ${SysInfo.user}@${SysInfo.hostname}`,
                        `WallpaperService.current  ${WallpaperService.current}`,
                        `WallpaperService.list     ${WallpaperService.list.length} images in ${Paths.wallsdir}`,
                        `Weather             ${Weather.description} ${Weather.temp}`,
                        `Icons               volume ${Icons.getVolumeIcon(Audio.volume, Audio.muted)}  wifi ${Icons.getNetworkIcon(Nmcli.active?.strength ?? 0)}  battery ${Icons.getBatteryIcon(UPower.displayDevice.percentage, !UPower.onBattery)}`,
                        `Screens             ${Screens.screens.map(s => s.name).join(", ")}   ShellState.anySidebarOpen ${ShellState.anySidebarOpen()}`
                    ].join("\n")
                }
            }
        }
    }
}
