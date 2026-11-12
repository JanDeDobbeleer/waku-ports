import QtQuick
import "Bezier.js" as Bezier

// Port of celeste's C++ CircularIndicatorManager (Material circular indeterminate animation).
// startFraction, endFraction and rotation are plain properties here, written by the manager only.
QtObject {
    id: root

    enum IndeterminateAnimationType {
        Advance = 0,
        Retreat
    }

    // Outputs (read only by convention).
    final property real startFraction: 0
    final property real endFraction: 0
    final property real rotation: 0

    final property real progress: 0
    final property real completeEndProgress: 0
    final property int indeterminateAnimationType: CircularIndicatorManager.Advance

    readonly final property real duration: indeterminateAnimationType === CircularIndicatorManager.Advance ? 5400 : 6000
    readonly final property real completeEndDuration: indeterminateAnimationType === CircularIndicatorManager.Advance ? 333 : 500

    readonly final property var expandDelays: [0, 1350, 2700, 4050]
    readonly final property var collapseDelays: [667, 2017, 3367, 4717]
    readonly final property var spinDelays: [0, 1500, 3000, 4500]

    onProgressChanged: refresh()
    onCompleteEndProgressChanged: refresh()
    onIndeterminateAnimationTypeChanged: refresh()

    function refresh(): void {
        if (indeterminateAnimationType === CircularIndicatorManager.Advance)
            advance();
        else
            retreat();
    }

    function advance(): void {
        const playtime = progress * 5400;
        let start = 1520 * progress - 20;
        let end = 1520 * progress;
        for (let i = 0; i < 4; i++) {
            end += Bezier.fastOutSlowIn(Bezier.fractionInRange(playtime, expandDelays[i], 667)) * 250;
            start += Bezier.fastOutSlowIn(Bezier.fractionInRange(playtime, collapseDelays[i], 667)) * 250;
        }
        start += (end - start) * completeEndProgress;
        startFraction = start / 360;
        endFraction = end / 360;
    }

    function retreat(): void {
        const playtime = progress * 6000;
        let spin = 0;
        for (let i = 0; i < 4; i++)
            spin += Bezier.fastOutSlowIn(Bezier.fractionInRange(playtime, spinDelays[i], 500)) * 90;
        rotation = 1080 * progress + spin;

        const frac = Bezier.fastOutSlowIn(Bezier.fractionInRange(playtime, 0, 3000)) - Bezier.fastOutSlowIn(Bezier.fractionInRange(playtime, 3000, 3000));
        startFraction = 0;
        let end = 0.10 + (0.87 - 0.10) * frac;
        if (completeEndProgress > 0)
            end *= 1 - completeEndProgress;
        endFraction = end;
    }
}
