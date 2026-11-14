pragma ComponentBehavior: Bound
import QtQuick
import "ScaleSizes.js" as SS

// Tokens.anim: the easing curves and, in `durations`, the duration tokens times the duration
// scale. Each curve is a QEasingCurve value read from a carrier animation, so
// `easing: Tokens.anim.standard` assigns it like upstream does. The raw bezier control points are
// in `curves` for code that sets easing.bezierCurve itself.
QtObject {
    id: root

    readonly final property var curves: SS.get(TokenConfig.appearance, "curves")
    readonly final property var animDurations: SS.get(TokenConfig.appearance, "animDurations")

    readonly final property var emphasized: eEmphasized.easing
    readonly final property var emphasizedAccel: eEmphasizedAccel.easing
    readonly final property var emphasizedDecel: eEmphasizedDecel.easing
    readonly final property var standard: eStandard.easing
    readonly final property var standardAccel: eStandardAccel.easing
    readonly final property var standardDecel: eStandardDecel.easing
    readonly final property var expressiveFastSpatial: eExpressiveFastSpatial.easing
    readonly final property var expressiveDefaultSpatial: eExpressiveDefaultSpatial.easing
    readonly final property var expressiveSlowSpatial: eExpressiveSlowSpatial.easing
    readonly final property var expressiveFastEffects: eExpressiveFastEffects.easing
    readonly final property var expressiveDefaultEffects: eExpressiveDefaultEffects.easing
    readonly final property var expressiveSlowEffects: eExpressiveSlowEffects.easing
    readonly final property var linear: eLinear.easing

    readonly final property Durations durations: Durations {}

    component Durations: QtObject {
        readonly final property real scale: SS.get(GlobalConfig.appearance, "anim.durations.scale")
        readonly final property int small: SS.truncScaled(root.animDurations, "small", scale)
        readonly final property int normal: SS.truncScaled(root.animDurations, "normal", scale)
        readonly final property int large: SS.truncScaled(root.animDurations, "large", scale)
        readonly final property int extraLarge: SS.truncScaled(root.animDurations, "extraLarge", scale)
        readonly final property int expressiveFastSpatial: SS.truncScaled(root.animDurations, "expressiveFastSpatial", scale)
        readonly final property int expressiveDefaultSpatial: SS.truncScaled(root.animDurations, "expressiveDefaultSpatial", scale)
        readonly final property int expressiveSlowSpatial: SS.truncScaled(root.animDurations, "expressiveSlowSpatial", scale)
        readonly final property int expressiveFastEffects: SS.truncScaled(root.animDurations, "expressiveFastEffects", scale)
        readonly final property int expressiveDefaultEffects: SS.truncScaled(root.animDurations, "expressiveDefaultEffects", scale)
        readonly final property int expressiveSlowEffects: SS.truncScaled(root.animDurations, "expressiveSlowEffects", scale)
    }

    component Curve: NumberAnimation {
        required final property var points

        easing.type: Easing.BezierSpline
        easing.bezierCurve: points
    }

    readonly final property NumberAnimation cEmphasized: Curve {
        id: eEmphasized

        points: SS.get(root.curves, "emphasized")
    }

    readonly final property NumberAnimation cEmphasizedAccel: Curve {
        id: eEmphasizedAccel

        points: SS.get(root.curves, "emphasizedAccel")
    }

    readonly final property NumberAnimation cEmphasizedDecel: Curve {
        id: eEmphasizedDecel

        points: SS.get(root.curves, "emphasizedDecel")
    }

    readonly final property NumberAnimation cStandard: Curve {
        id: eStandard

        points: SS.get(root.curves, "standard")
    }

    readonly final property NumberAnimation cStandardAccel: Curve {
        id: eStandardAccel

        points: SS.get(root.curves, "standardAccel")
    }

    readonly final property NumberAnimation cStandardDecel: Curve {
        id: eStandardDecel

        points: SS.get(root.curves, "standardDecel")
    }

    readonly final property NumberAnimation cExpressiveFastSpatial: Curve {
        id: eExpressiveFastSpatial

        points: SS.get(root.curves, "expressiveFastSpatial")
    }

    readonly final property NumberAnimation cExpressiveDefaultSpatial: Curve {
        id: eExpressiveDefaultSpatial

        points: SS.get(root.curves, "expressiveDefaultSpatial")
    }

    readonly final property NumberAnimation cExpressiveSlowSpatial: Curve {
        id: eExpressiveSlowSpatial

        points: SS.get(root.curves, "expressiveSlowSpatial")
    }

    readonly final property NumberAnimation cExpressiveFastEffects: Curve {
        id: eExpressiveFastEffects

        points: SS.get(root.curves, "expressiveFastEffects")
    }

    readonly final property NumberAnimation cExpressiveDefaultEffects: Curve {
        id: eExpressiveDefaultEffects

        points: SS.get(root.curves, "expressiveDefaultEffects")
    }

    readonly final property NumberAnimation cExpressiveSlowEffects: Curve {
        id: eExpressiveSlowEffects

        points: SS.get(root.curves, "expressiveSlowEffects")
    }
    readonly final property NumberAnimation cLinear: NumberAnimation {
        id: eLinear

        easing.type: Easing.Linear
    }
}
