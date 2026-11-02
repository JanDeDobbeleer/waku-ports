pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import waku.services as S

// Port of caelestia's NetworkUsage. waku's Network source has no throughput, so this polls
// `netstat -e` (interface byte counters, summed over all interfaces) while referenced. Speeds are
// bytes per second; totals count from the first sample.
QtObject {
    id: root

    // Reference count driven by ServiceRef. The waku source polls only while something holds a ref.
    property int refs: 0
    function ref(): void {
        refs++;
    }
    function unref(): void {
        refs = Math.max(0, refs - 1);
    }
    readonly property int historyLength: 30
    property real downloadSpeed: 0
    property real uploadSpeed: 0
    property real downloadTotal: 0
    property real uploadTotal: 0
    readonly property CircularBuffer downloadBuffer: CircularBuffer {
        capacity: root.historyLength + 1
    }
    readonly property CircularBuffer uploadBuffer: CircularBuffer {
        capacity: root.historyLength + 1
    }

    property real _lastRx: -1
    property real _lastTx: -1
    property double _lastTime: 0

    readonly property var timer: Timer {
        running: root.refs > 0
        repeat: true
        triggeredOnStart: true
        interval: GlobalConfig.dashboard.resourceUpdateInterval
        onTriggered: {
            if (!proc.running)
                proc.running = true;
        }
    }

    readonly property var proc: Process {
        command: ["netstat", "-e"]
        stdout: StdioCollector {
            onStreamFinished: {
                // The first line that ends in two numbers is the byte row; the label is localised.
                const m = text.match(/^\D*(\d{4,})\s+(\d{4,})\s*$/m);
                if (!m)
                    return;
                const rx = Number(m[1]);
                const tx = Number(m[2]);
                const now = Date.now();
                if (root._lastRx >= 0 && now > root._lastTime) {
                    const dt = (now - root._lastTime) / 1000;
                    root.downloadSpeed = Math.max(0, rx - root._lastRx) / dt;
                    root.uploadSpeed = Math.max(0, tx - root._lastTx) / dt;
                    root.downloadTotal += Math.max(0, rx - root._lastRx);
                    root.uploadTotal += Math.max(0, tx - root._lastTx);
                    root.downloadBuffer.push(root.downloadSpeed);
                    root.uploadBuffer.push(root.uploadSpeed);
                }
                root._lastRx = rx;
                root._lastTx = tx;
                root._lastTime = now;
            }
        }
    }
}
