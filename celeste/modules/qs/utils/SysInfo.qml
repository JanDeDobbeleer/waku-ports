pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Celeste.I18n
import qs.compat

// System facts for the dashboard. Windows has no /proc or /etc/os-release, so the values come from
// the environment, Windows registry values read through `reg query`, and a timer for uptime.
Singleton {
    id: root

    final property string osName: "Windows"
    final property string osPrettyName: "Windows"
    final property string osId: "windows"
    final property list<string> osIdLike: []
    final property string osLogo: Qt.resolvedUrl(`${Quickshell.shellDir}/assets/windows.svg`)

    final property string uptime
    // Uptime trimmed to its two largest components
    final property string uptimeShort
    readonly final property string user: Quickshell.env("USERNAME")
    readonly final property string wm: Quickshell.env("XDG_CURRENT_DESKTOP") || "Explorer" // waku gap: no compositor name on Windows
    readonly final property string shell: "waku"

    final property string kernel
    final property string hostname: Quickshell.env("COMPUTERNAME")
    final property string firmware

    // DMI vendor/model, combined into a single human-readable device name
    final property string boardVendor
    final property string boardName
    readonly final property string device: {
        if (!boardName)
            return boardVendor;
        if (!boardVendor || boardName.toLowerCase().startsWith(boardVendor.toLowerCase()))
            return boardName;
        return `${boardVendor} ${boardName}`;
    }

    final property double bootTime: Date.now() // until the boot time arrives, count from shell start

    // Strips the placeholder strings OEMs commonly leave in DMI fields
    function sanitiseDmi(s: string): string {
        const t = s.trim();
        const junk = ["to be filled by o.e.m.", "system product name", "system manufacturer", "system version", "default string", "o.e.m.", "not specified", "not applicable", "unknown", "none", ""];
        return junk.includes(t.toLowerCase()) ? "" : t;
    }

    function regValue(text: string, name: string): string {
        const m = text.match(new RegExp(name + "\\s+REG_\\w+\\s+(.+)"));
        return m ? m[1].trim() : "";
    }

    function formatUptime(up: real): void {
        const days = Math.floor(up / 86400);
        const hours = Math.floor((up % 86400) / 3600);
        const minutes = Math.floor((up % 3600) / 60);

        // TRANSLATORS: joins uptime components, e.g. "2 days, 3 hours"
        const sep = Tr.trCtx(", ", "uptime component separator");

        const parts = [];
        if (days > 0)
            parts.push(Tr.trN("%n day", "%n days", days));
        if (hours > 0)
            parts.push(Tr.trN("%n hour", "%n hours", hours));
        if (minutes > 0 || parts.length === 0)
            parts.push(Tr.trN("%n minute", "%n minutes", minutes));

        root.uptime = parts.join(sep);
        root.uptimeShort = parts.slice(0, 2).join(sep);
    }

    // Read only: HKLM\...\CurrentVersion and HKLM\HARDWARE\DESCRIPTION\System\BIOS.
    Process {
        running: true
        command: ["reg", "query", "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion"]
        stdout: StdioCollector {
            onStreamFinished: {
                const product = root.regValue(text, "ProductName");
                const build = root.regValue(text, "CurrentBuildNumber");
                const display = root.regValue(text, "DisplayVersion");
                if (product) {
                    // ProductName still says "Windows 10" on Windows 11; the build number tells them apart.
                    root.osName = parseInt(build) >= 22000 ? product.replace("Windows 10", "Windows 11") : product;
                    root.osPrettyName = display ? `${root.osName} ${display}` : root.osName;
                }
                root.kernel = build ? `NT ${root.regValue(text, "CurrentMajorVersionNumber") || "10"}.0.${build}` : "";
            }
        }
    }

    Process {
        running: true
        command: ["reg", "query", "HKLM\\HARDWARE\\DESCRIPTION\\System\\BIOS"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.boardVendor = root.sanitiseDmi(root.regValue(text, "SystemManufacturer"));
                root.boardName = root.sanitiseDmi(root.regValue(text, "SystemProductName"));
                root.firmware = root.sanitiseDmi(root.regValue(text, "BIOSVersion"));
            }
        }
    }

    // Read only: the boot time from CIM, once. waku has no uptime service.
    Process {
        running: true
        command: ["powershell.exe", "-NoProfile", "-NonInteractive", "-Command", "[DateTimeOffset]::new((Get-CimInstance Win32_OperatingSystem).LastBootUpTime).ToUnixTimeMilliseconds()"]
        stdout: StdioCollector {
            onStreamFinished: {
                const ms = Number(text.trim());
                if (Number.isFinite(ms) && ms > 0)
                    root.bootTime = ms;
                root.formatUptime((Date.now() - root.bootTime) / 1000);
            }
        }
    }

    Timer {
        running: true
        repeat: true
        triggeredOnStart: true
        interval: 15000
        onTriggered: root.formatUptime((Date.now() - root.bootTime) / 1000)
    }
}
