import QtQuick
import QtQuick.Shapes
import Celeste
import "SparklineItemHelpers.js" as SparklineItemHelpers

// Port of celeste's C++ SparklineItem: up to two CircularBuffer lines with a fill under each.
Item {
    id: root

    final property CircularBuffer line1
    final property CircularBuffer line2
    final property color line1Color: "white"
    final property color line2Color: "white"
    final property real line1FillAlpha: 0.15
    final property real line2FillAlpha: 0.2
    final property real maxValue: 1024
    final property real slideProgress: 0
    final property int historyLength: 30
    final property real lineWidth: 2

    // Re-evaluated when a buffer pushes (valuesChanged) so the point lists follow the data.
    final property int revision: 0

    Connections {
        target: root.line1
        function onValuesChanged(): void {
            root.revision++;
        }
    }

    Connections {
        target: root.line2
        function onValuesChanged(): void {
            root.revision++;
        }
    }

    function pointsFor(buffer: CircularBuffer, closed: bool): var {
        CUtils.dependency(revision);
        if (!buffer || buffer.count < 2 || historyLength < 2 || maxValue <= 0)
            return [];
        const w = width, h = height;
        const len = buffer.count;
        const stepX = w / (historyLength - 1);
        const startX = w - (len - 1) * stepX - stepX * slideProgress + stepX;
        const pts = [];
        for (let i = 0; i < len; i++)
            pts.push(Qt.point(startX + i * stepX, h - (SparklineItemHelpers.valueAt(buffer, i) / maxValue) * h));
        if (closed) {
            pts.push(Qt.point(startX + (len - 1) * stepX, h));
            pts.push(Qt.point(startX, h));
        }
        return pts;
    }

    readonly final property var line1Points: pointsFor(line1, false)
    readonly final property var line1Fill: pointsFor(line1, true)
    readonly final property var line2Points: pointsFor(line2, false)
    readonly final property var line2Fill: pointsFor(line2, true)

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Qt.alpha(root.line1Color, root.line1FillAlpha)
            strokeWidth: -1
            PathPolyline {
                path: root.line1Fill
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.line1Color
            strokeWidth: SparklineItemHelpers.length(root.line1Points) > 1 ? root.lineWidth : -1
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline {
                path: root.line1Points
            }
        }

        ShapePath {
            fillColor: Qt.alpha(root.line2Color, root.line2FillAlpha)
            strokeWidth: -1
            PathPolyline {
                path: root.line2Fill
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.line2Color
            strokeWidth: SparklineItemHelpers.length(root.line2Points) > 1 ? root.lineWidth : -1
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline {
                path: root.line2Points
            }
        }
    }
}
