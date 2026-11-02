pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Caelestia.I18n
import waku.services as S
import qs.compat
import qs.utils

// The quick actions of the dashboard's Utilities tab: each one opens a Windows window, flyout or
// settings page. No action changes a setting itself; a toggle is left to the Windows UI it opens.
// Every launch goes through S.Shell.open (ShellExecute "open"), which handles URIs (ms-settings:,
// ms-screenclip:, ...), .cpl and .msc files, shell: folders and programs that ask for elevation
// (Task Manager). With CAELESTIA_DRYRUN=1 a launch only logs `DRYRUN utilities <id> <target>`.
// The research behind the list is in docs/windows-utilities.md.
Singleton {
    id: root

    // id, group, Material icon, label, ShellExecute target. `probe`: a file whose absence hides the
    // button (environment variables are expanded). `battery`: shown only on a machine with a battery.
    readonly property var all: [
        {
            id: "snip",
            group: "capture",
            icon: "screenshot_region",
            label: Tr.tr("Screenshot"),
            target: "ms-screenclip:"
        },
        {
            id: "snippingTool",
            group: "capture",
            icon: "screen_record",
            label: Tr.tr("Snip & record"),
            target: "SnippingTool.exe",
            probe: "%LOCALAPPDATA%\\Microsoft\\WindowsApps\\SnippingTool.exe"
        },
        {
            id: "gameBar",
            group: "capture",
            icon: "sports_esports",
            label: Tr.tr("Game Bar"),
            target: "ms-gamebar:"
        },
        {
            id: "project",
            group: "display",
            icon: "cast_connected",
            label: Tr.tr("Project"),
            target: "ms-settings-displays-topology:"
        },
        {
            id: "display",
            group: "display",
            icon: "desktop_windows",
            label: Tr.tr("Display"),
            target: "ms-settings:display"
        },
        {
            id: "nightLight",
            group: "display",
            icon: "nightlight",
            label: Tr.tr("Night light"),
            target: "ms-settings:nightlight"
        },
        {
            id: "mixer",
            group: "display",
            icon: "tune",
            label: Tr.tr("Volume mixer"),
            target: "ms-settings:apps-volume"
        },
        {
            id: "sound",
            group: "display",
            icon: "volume_up",
            label: Tr.tr("Sound"),
            target: "ms-settings:sound"
        },
        {
            id: "soundPanel",
            group: "display",
            icon: "speaker",
            label: Tr.tr("Sound devices"),
            target: "mmsys.cpl",
            probe: "%SystemRoot%\\System32\\mmsys.cpl"
        },
        {
            id: "wifi",
            group: "connectivity",
            icon: "wifi",
            label: Tr.tr("Wi-Fi"),
            target: "ms-availablenetworks:"
        },
        {
            id: "cast",
            group: "connectivity",
            icon: "cast",
            label: Tr.tr("Cast"),
            target: "ms-settings-connectabledevices:devicediscovery"
        },
        {
            id: "bluetooth",
            group: "connectivity",
            icon: "bluetooth",
            label: Tr.tr("Bluetooth"),
            target: "ms-settings:bluetooth"
        },
        {
            id: "airplane",
            group: "connectivity",
            icon: "flight",
            label: Tr.tr("Airplane mode"),
            target: "ms-settings:network-airplanemode"
        },
        {
            id: "hotspot",
            group: "connectivity",
            icon: "wifi_tethering",
            label: Tr.tr("Hotspot"),
            target: "ms-settings:network-mobilehotspot"
        },
        {
            id: "vpn",
            group: "connectivity",
            icon: "vpn_key",
            label: Tr.tr("VPN"),
            target: "ms-settings:network-vpn"
        },
        {
            id: "quickSettings",
            group: "system",
            icon: "toggle_on",
            label: Tr.tr("Quick settings"),
            target: "ms-actioncenter:controlcenter/&showFooter=true"
        },
        {
            id: "notifications",
            group: "system",
            icon: "notifications",
            label: Tr.tr("Notifications"),
            target: "ms-actioncenter:"
        },
        {
            id: "focus",
            group: "system",
            icon: "do_not_disturb_on",
            label: Tr.tr("Focus"),
            target: "ms-settings:quiethours"
        },
        {
            id: "batterySaver",
            group: "system",
            icon: "battery_saver",
            label: Tr.tr("Battery saver"),
            target: "ms-settings:batterysaver",
            battery: true
        },
        {
            id: "accessibility",
            group: "system",
            icon: "accessibility_new",
            label: Tr.tr("Accessibility"),
            target: "ms-settings:easeofaccess"
        },
        {
            id: "keyboard",
            group: "system",
            icon: "keyboard",
            label: Tr.tr("On-screen keyboard"),
            target: "osk.exe",
            probe: "%SystemRoot%\\System32\\osk.exe"
        },
        {
            id: "taskManager",
            group: "tools",
            icon: "monitoring",
            label: Tr.tr("Task Manager"),
            target: "taskmgr.exe",
            probe: "%SystemRoot%\\System32\\Taskmgr.exe"
        },
        {
            id: "terminal",
            group: "tools",
            icon: "terminal",
            label: Tr.tr("Terminal"),
            target: "wt.exe",
            probe: "%LOCALAPPDATA%\\Microsoft\\WindowsApps\\wt.exe"
        },
        {
            id: "run",
            group: "tools",
            icon: "play_arrow",
            label: Tr.tr("Run"),
            target: "shell:::{2559a1f3-21d7-11d4-bdaf-00c04f60b9f0}"
        },
        {
            id: "deviceManager",
            group: "tools",
            icon: "developer_board",
            label: Tr.tr("Device Manager"),
            target: "devmgmt.msc",
            probe: "%SystemRoot%\\System32\\devmgmt.msc"
        },
        {
            id: "update",
            group: "tools",
            icon: "system_update",
            label: Tr.tr("Windows Update"),
            target: "ms-settings:windowsupdate"
        },
        {
            id: "settings",
            group: "tools",
            icon: "settings",
            label: Tr.tr("Settings"),
            target: "ms-settings:"
        }
    ]

    readonly property var groups: [
        {
            id: "capture",
            label: Tr.tr("Capture")
        },
        {
            id: "display",
            label: Tr.tr("Display & sound")
        },
        {
            id: "connectivity",
            label: Tr.tr("Connectivity")
        },
        {
            id: "system",
            label: Tr.tr("System")
        },
        {
            id: "tools",
            label: Tr.tr("Tools")
        }
    ]

    // Probe files the check found missing (expanded path -> true). Empty until the check ran, so
    // every button shows until then.
    property var missing: ({})
    property bool probed
    property string lastLogged

    readonly property var actions: all.filter(a => (!a.probe || !missing[a.probe]) && (!a.battery || UPower.displayDevice.isLaptopBattery))

    function inGroup(group: string): var {
        return actions.filter(a => a.group === group);
    }

    function find(id: string): var {
        return all.find(a => a.id === id) ?? null;
    }

    // Starts the existence check once. Read only: Test-Path on the probe files.
    function probe(): void {
        if (probed || probeProc.running)
            return;
        probeProc.running = true;
    }

    // Opens action `id`. Returns the target it launched (or would launch in a dry run), "" when
    // there is no such action.
    function launch(id: string): string {
        const a = find(id);
        if (!a || !a.target)
            return "";
        if (Paths.dryRun) {
            lastLogged = `DRYRUN utilities ${a.id} ${a.target}`;
            console.warn(lastLogged);
            return a.target;
        }
        lastLogged = `utilities ${a.id} ${a.target}`;
        S.Shell.open(a.target);
        return a.target;
    }

    Process {
        id: probeProc

        command: {
            const paths = root.all.filter(a => a.probe).map(a => `'${a.probe}'`).join(",");
            return ["powershell.exe", "-NoProfile", "-NonInteractive", "-Command", `@(${paths}) | ForEach-Object { if (Test-Path -LiteralPath ([Environment]::ExpandEnvironmentVariables($_))) { 'Y ' + $_ } else { 'N ' + $_ } }`];
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const next = {};
                for (const line of text.split(/\r?\n/))
                    if (line.startsWith("N "))
                        next[line.slice(2).trim()] = true;
                root.missing = next;
                root.probed = true;
            }
        }
    }
}
