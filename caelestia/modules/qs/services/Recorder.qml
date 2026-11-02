pragma Singleton

import QtQuick
import Quickshell
import Caelestia
import Caelestia.I18n
import qs.compat

// Stub of upstream's screen recorder (gpu-screen-recorder through the caelestia CLI). waku has no
// recorder, so the state never leaves "stopped" and `start` says so in a toast.
Singleton {
    id: root

    readonly property bool running: false
    readonly property bool paused: false
    readonly property real elapsed: 0
    property int refCount: 0
    property bool needsStart
    property list<string> startArgs
    property bool needsStop
    property bool needsPause

    // waku gap: no screen recorder.
    function start(extraArgs = []): void {
        Toaster.toast(Tr.tr("Recording unavailable"), Tr.tr("waku has no screen recorder yet"), "screen_record", Toast.Warning);
    }

    function stop(): void {
    }

    function togglePause(): void {
    }
}
