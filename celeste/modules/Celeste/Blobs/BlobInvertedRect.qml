import QtQuick
import QtQuick.Shapes

// Stub for celeste's C++ BlobInvertedRect (a frame: the group colour everywhere except a
// rounded hole inset by the four border widths). Drawn as an odd-even filled Shape.
// waku gap: no blending with other blobs, no deformation.
Item {
    id: root

    final property BlobGroup group
    final property real radius: 0
    final property real borderLeft: 0
    final property real borderRight: 0
    final property real borderTop: 0
    final property real borderBottom: 0
    final property matrix4x4 deformMatrix
    final property matrix4x4 rawDeformMatrix

    readonly final property real holeX: Math.max(0, borderLeft)
    readonly final property real holeY: Math.max(0, borderTop)
    readonly final property real holeW: Math.max(0, width - holeX - Math.max(0, borderRight))
    readonly final property real holeH: Math.max(0, height - holeY - Math.max(0, borderBottom))
    readonly final property real r: Math.max(0, Math.min(radius, holeW / 2, holeH / 2))

    Shape {
        anchors.fill: parent
        visible: root.group !== null
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.group ? Qt.rgba(root.group.color.r, root.group.color.g, root.group.color.b, 1) : "transparent"
            strokeWidth: -1
            fillRule: ShapePath.OddEvenFill

            PathSvg {
                path: `M0,0 H${root.width} V${root.height} H0 Z`
                    + ` M${root.holeX + root.r},${root.holeY}`
                    + ` H${root.holeX + root.holeW - root.r} A${root.r},${root.r} 0 0 1 ${root.holeX + root.holeW},${root.holeY + root.r}`
                    + ` V${root.holeY + root.holeH - root.r} A${root.r},${root.r} 0 0 1 ${root.holeX + root.holeW - root.r},${root.holeY + root.holeH}`
                    + ` H${root.holeX + root.r} A${root.r},${root.r} 0 0 1 ${root.holeX},${root.holeY + root.holeH - root.r}`
                    + ` V${root.holeY + root.r} A${root.r},${root.r} 0 0 1 ${root.holeX + root.r},${root.holeY} Z`
            }
        }
    }
}
