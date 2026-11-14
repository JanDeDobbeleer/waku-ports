import QtQuick
import "Bezier.js" as Bezier

// Port of celeste's C++ LinearIndicatorManager (Material linear indeterminate, two segments).
QtObject {
    id: root

    final property real progress: 0
    final property real completeEndProgress: 0
    final property int gap: 4
    readonly final property real duration: 1800
    readonly final property real completeEndDuration: 1800

    final property LinearIndicatorSegment segment0: LinearIndicatorSegment {}
    final property LinearIndicatorSegment segment1: LinearIndicatorSegment {}
    readonly final property var activeIndicators: [segment0, segment1]

    readonly final property var durations: [533, 567, 850, 750]
    readonly final property var delays: [1267, 1000, 333, 0]
    readonly final property var curves: [[0.2, 0.0, 0.8, 1.0], [0.4, 0.0, 1.0, 1.0], [0.0, 0.0, 0.65, 1.0], [0.1, 0.0, 0.45, 1.0]]

    onProgressChanged: refresh()
    onCompleteEndProgressChanged: refresh()
    onGapChanged: {
        segment0.gapSize = gap;
        segment1.gapSize = gap;
        refresh();
    }

    Component.onCompleted: {
        segment0.gapSize = gap;
        segment1.gapSize = gap;
    }

    function evalCurve(i: int, playtime: real): real {
        const c = curves[i];
        const f = Bezier.fractionInRange(playtime, delays[i], durations[i]);
        return Bezier.clamp01(Bezier.cubic(c[0], c[1], c[2], c[3], f));
    }

    function refresh(): void {
        const playtime = progress * 1800;
        for (let i = 0; i < 2; i++) {
            const seg = activeIndicators[i];
            seg.startFraction = evalCurve(i * 2, playtime);
            seg.endFraction = evalCurve(i * 2 + 1, playtime);
        }
    }
}
