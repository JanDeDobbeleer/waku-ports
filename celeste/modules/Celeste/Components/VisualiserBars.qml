pragma ComponentBehavior: Bound

import QtQuick
import "VisualiserBarsHelpers.js" as VisualiserBarsHelpers

// Visible stub for celeste's C++ VisualiserBars. Draws one rounded bar per value along the
// bottom, no per-frame smoothing. Nothing feeds `values` on Windows (the cava source is dropped).
// waku gap: no animation between value updates, no mirrored left/right layout.
Item {
    id: root

    final property var values: []
    final property color primaryColor: "white"
    final property color secondaryColor: "gray"
    final property real rounding: 0
    final property real spacing: 0
    final property int animationDuration: 0
    readonly final property bool settled: true

    function advance(dt: real): void {
    }

    Row {
        anchors.fill: parent
        spacing: root.spacing

        Repeater {
            model: root.values

            Rectangle {
                required final property var modelData
                required final property int index

                readonly final property real level: Math.max(0, Math.min(1, Number(modelData) || 0))

                width: VisualiserBarsHelpers.barWidth(root)
                height: Math.max(1, level * root.height)
                y: root.height - height
                radius: root.rounding
                color: index % 2 === 0 ? root.primaryColor : root.secondaryColor
            }
        }
    }
}
