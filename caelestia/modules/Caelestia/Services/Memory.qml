pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import wabar.services as S

// Port of caelestia's Memory over wabar's Memory source. Sizes are KiB, percentage is 0..1.
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
    readonly property real used: src.used / 1024
    readonly property real total: src.total / 1024
    readonly property real percentage: src.percent / 100

    readonly property var src: S.Memory {
        active: root.refs > 0
        interval: GlobalConfig.dashboard.resourceUpdateInterval
    }
}
