pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Celeste
import Celeste.Config
import waku.services as S

// Port of celeste's Gpu over waku's Gpu source (PDH engine counters, any vendor). type is
// Generic when the counters exist, else None. Temperature is NaN (no sensor access on Windows).
// The source polls until its first sample (to learn the type) and then only while referenced.
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
    readonly property int type: src.available ? GpuType.Generic : GpuType.None
    readonly property string name: src.name
    readonly property bool detecting: !src.ready
    readonly property real percentage: src.percent / 100
    readonly property real temperature: NaN

    readonly property var src: S.Gpu {
        active: root.refs > 0 || !ready
        interval: GlobalConfig.dashboard.resourceUpdateInterval
    }
}
