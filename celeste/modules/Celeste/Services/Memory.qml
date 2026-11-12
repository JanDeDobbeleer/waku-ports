pragma Singleton

import QtQuick
import Celeste.Config
import waku.services as S
import "SystemStatsHelpers.js" as SystemStatsHelpers

// Port of celeste's Memory over waku's Memory source. Sizes are KiB, percentage is 0..1.
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
    readonly final property real used: SystemStatsHelpers.used(src)
    readonly final property real total: SystemStatsHelpers.total(src)
    readonly final property real percentage: SystemStatsHelpers.percent(src)

    readonly final property S.Memory src: S.Memory {
        active: root.refs > 0
        interval: GlobalConfig.dashboard.resourceUpdateInterval
    }
}
