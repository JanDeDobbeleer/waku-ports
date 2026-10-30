pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import wabar.services as S

// Port of caelestia's Cpu over wabar's Cpu source. percentage is 0..1. The name comes from the
// registry (read only). Temperature is NaN: Windows exposes no CPU sensor without a driver, and
// HeroCard shows an indeterminate bar for NaN.
QtObject {
    id: root

    // Reference count driven by ServiceRef. The wabar source polls only while something holds a ref.
    property int refs: 0
    function ref(): void {
        refs++;
    }
    function unref(): void {
        refs = Math.max(0, refs - 1);
    }
    property string name
    readonly property real percentage: src.percent / 100
    readonly property real temperature: NaN

    readonly property var src: S.Cpu {
        active: root.refs > 0
        interval: GlobalConfig.dashboard.resourceUpdateInterval
    }

    readonly property var nameProc: Process {
        running: true
        command: ["reg", "query", "HKLM\\HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0", "/v", "ProcessorNameString"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/ProcessorNameString\s+REG_\w+\s+(.+)/);
                if (m)
                    root.name = m[1].trim().replace(/\s+/g, " ");
            }
        }
    }
}
