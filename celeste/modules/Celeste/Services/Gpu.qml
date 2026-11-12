pragma Singleton

import QtQuick
import Celeste.Config
import waku.services as S
import "SystemStatsHelpers.js" as SystemStatsHelpers

// Port of celeste's Gpu over waku's Gpu source (PDH engine counters, any vendor). type is
// Generic when the counters exist, else None. Temperature is NaN (no sensor access on Windows).
// The source polls until its first sample (to learn the type) and then only while referenced.
QtObject {
    id: root

    // Reference count driven by ServiceRef. The waku source polls only while something holds a ref.
    final property int refs: 0
    function ref(): void {
        refs++;
    }
    function unref(): void {
        refs = Math.max(0, refs - 1);
    }
    readonly final property int type: SystemStatsHelpers.gpuType(src, GpuType)
    readonly final property string name: SystemStatsHelpers.name(src)
    readonly final property bool detecting: !SystemStatsHelpers.ready(src)
    readonly final property real percentage: SystemStatsHelpers.percent(src)
    readonly final property real temperature: NaN

    readonly final property S.Gpu src: S.Gpu {
        active: root.refs > 0 || !ready
        interval: GlobalConfig.dashboard.resourceUpdateInterval
    }
}
