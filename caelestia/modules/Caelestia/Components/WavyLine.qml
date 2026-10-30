import QtQuick
import QtQuick.Shapes

// Port of caelestia's C++ WavyLine (a QQuickPaintedItem) as a Shape with one polyline. The wave is
// recomputed in JS whenever an input changes, so it is heavier than the C++ original.
Item {
    id: root

    enum PathType {
        Linear,
        Arc
    }

    property int lineWidth: 4
    property real amplitudeMultiplier: 0
    property int frequency: 6
    property real startX: 0
    property real fullLength: 0
    property color color: "white"
    property real waveProgress: 0
    property int pathType: WavyLine.Linear
    property real startAngle: 0
    property real fullAngle: 360
    property real radius: 0
    property real value: 1

    readonly property var points: pathType === WavyLine.Arc ? arcPoints() : linearPoints()

    function linearPoints(): var {
        const pts = [];
        const amplitude = lineWidth * amplitudeMultiplier;
        const phase = waveProgress * 2 * Math.PI;
        const centerY = height / 2;
        const len = fullLength > 0 ? fullLength : 1;
        const start = lineWidth / 2;
        const fullEnd = width - lineWidth / 2;
        const drawEnd = start + (fullEnd - start) * value;
        if (amplitude === 0) {
            // A flat line needs only its end points.
            if (drawEnd >= Math.floor(start)) {
                pts.push(Qt.point(Math.floor(start), centerY));
                pts.push(Qt.point(Math.max(drawEnd, Math.floor(start) + 0.01), centerY));
            }
            return pts;
        }
        for (let x = Math.floor(start); x <= drawEnd; x++) {
            const theta = frequency * 2 * Math.PI * (x + startX) / len + phase;
            pts.push(Qt.point(x, centerY + amplitude * Math.sin(theta)));
        }
        return pts;
    }

    function arcPoints(): var {
        const pts = [];
        const fullRad = fullAngle * Math.PI / 180;
        if (fullRad <= 0)
            return pts;
        const amplitude = lineWidth * amplitudeMultiplier;
        const cx = width / 2, cy = height / 2;
        const r = radius > 0 ? radius : (Math.min(width, height) - lineWidth - 2 * amplitude) / 2;
        if (r <= 0)
            return pts;
        const phase = waveProgress * 2 * Math.PI;
        const arcLen = r * fullRad;
        const len = fullLength > 0 ? fullLength : arcLen;
        const drawRad = fullRad * value;
        if (drawRad <= 0)
            return pts;
        const startRad = startAngle * Math.PI / 180;
        const segments = amplitude === 0 ? 32 : Math.max(64, Math.ceil(r * drawRad));
        const dTheta = drawRad / segments;
        for (let i = 0; i <= segments; i++) {
            const theta = startRad + i * dTheta;
            const s = i * dTheta * r;
            const phi = frequency * 2 * Math.PI * (s + startX) / len + phase;
            const rr = r + amplitude * Math.sin(phi);
            pts.push(Qt.point(cx + rr * Math.cos(theta), cy + rr * Math.sin(theta)));
        }
        return pts;
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.color
            strokeWidth: root.points.length > 1 ? root.lineWidth : -1
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathPolyline {
                path: root.points
            }
        }
    }
}
