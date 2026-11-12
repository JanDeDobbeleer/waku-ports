import QtQuick
import QtQuick.Shapes
import qs.components
import qs.services

ShapePath {
    id: root

    required final property Wrapper wrapper
    required final property var sidebar
    required final property real rounding
    readonly final property bool flatten: wrapper.height < rounding * 2
    readonly final property real roundingY: flatten ? wrapper.height / 2 : rounding

    strokeWidth: -1
    fillColor: Colours.palette.m3surface

    PathLine {
        relativeX: -(root.wrapper.width + root.rounding)
        relativeY: 0
    }
    PathArc {
        relativeX: root.rounding
        relativeY: -root.roundingY
        radiusX: root.rounding
        radiusY: Math.min(root.rounding, root.wrapper.height)
        direction: PathArc.Counterclockwise
    }
    PathLine {
        relativeX: 0
        relativeY: -(root.wrapper.height - root.roundingY * 2)
    }
    PathArc {
        relativeX: root.sidebar.utilsRoundingX
        relativeY: -root.roundingY
        radiusX: root.sidebar.utilsRoundingX
        radiusY: Math.min(root.rounding, root.wrapper.height)
    }
    PathLine {
        relativeX: root.wrapper.height > 0 ? root.wrapper.width - root.rounding - root.sidebar.utilsRoundingX : root.wrapper.width
        relativeY: 0
    }
    PathArc {
        relativeX: root.rounding
        relativeY: -root.rounding
        radiusX: root.rounding
        radiusY: root.rounding
        direction: PathArc.Counterclockwise
    }

    Behavior on fillColor {
        CAnim {}
    }
}
