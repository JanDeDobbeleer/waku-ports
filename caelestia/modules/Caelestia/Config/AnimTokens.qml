import QtQuick

// Tokens.anim: the easing curves and, in `durations`, the duration tokens times the duration
// scale. Each curve is a QEasingCurve value read from a carrier animation, so
// `easing: Tokens.anim.standard` assigns it like upstream does. The raw bezier control points are
// in `curves` for code that sets easing.bezierCurve itself.
QtObject {
    id: root

    readonly property var curves: TokenConfig.appearance.curves

    readonly property var emphasized: cEmphasized.easing
    readonly property var emphasizedAccel: cEmphasizedAccel.easing
    readonly property var emphasizedDecel: cEmphasizedDecel.easing
    readonly property var standard: cStandard.easing
    readonly property var standardAccel: cStandardAccel.easing
    readonly property var standardDecel: cStandardDecel.easing
    readonly property var expressiveFastSpatial: cExpressiveFastSpatial.easing
    readonly property var expressiveDefaultSpatial: cExpressiveDefaultSpatial.easing
    readonly property var expressiveSlowSpatial: cExpressiveSlowSpatial.easing
    readonly property var expressiveFastEffects: cExpressiveFastEffects.easing
    readonly property var expressiveDefaultEffects: cExpressiveDefaultEffects.easing
    readonly property var expressiveSlowEffects: cExpressiveSlowEffects.easing
    readonly property var linear: cLinear.easing

    readonly property QtObject durations: QtObject {
        readonly property real scale: GlobalConfig.appearance.anim.durations.scale
        readonly property int small: Math.trunc(TokenConfig.appearance.animDurations.small * scale)
        readonly property int normal: Math.trunc(TokenConfig.appearance.animDurations.normal * scale)
        readonly property int large: Math.trunc(TokenConfig.appearance.animDurations.large * scale)
        readonly property int extraLarge: Math.trunc(TokenConfig.appearance.animDurations.extraLarge * scale)
        readonly property int expressiveFastSpatial: Math.trunc(TokenConfig.appearance.animDurations.expressiveFastSpatial * scale)
        readonly property int expressiveDefaultSpatial: Math.trunc(TokenConfig.appearance.animDurations.expressiveDefaultSpatial * scale)
        readonly property int expressiveSlowSpatial: Math.trunc(TokenConfig.appearance.animDurations.expressiveSlowSpatial * scale)
        readonly property int expressiveFastEffects: Math.trunc(TokenConfig.appearance.animDurations.expressiveFastEffects * scale)
        readonly property int expressiveDefaultEffects: Math.trunc(TokenConfig.appearance.animDurations.expressiveDefaultEffects * scale)
        readonly property int expressiveSlowEffects: Math.trunc(TokenConfig.appearance.animDurations.expressiveSlowEffects * scale)
    }

    component Curve: NumberAnimation {
        required property var points

        easing.type: Easing.BezierSpline
        easing.bezierCurve: points
    }

    readonly property NumberAnimation cEmphasized: Curve {
        points: root.curves.emphasized
    }
    readonly property NumberAnimation cEmphasizedAccel: Curve {
        points: root.curves.emphasizedAccel
    }
    readonly property NumberAnimation cEmphasizedDecel: Curve {
        points: root.curves.emphasizedDecel
    }
    readonly property NumberAnimation cStandard: Curve {
        points: root.curves.standard
    }
    readonly property NumberAnimation cStandardAccel: Curve {
        points: root.curves.standardAccel
    }
    readonly property NumberAnimation cStandardDecel: Curve {
        points: root.curves.standardDecel
    }
    readonly property NumberAnimation cExpressiveFastSpatial: Curve {
        points: root.curves.expressiveFastSpatial
    }
    readonly property NumberAnimation cExpressiveDefaultSpatial: Curve {
        points: root.curves.expressiveDefaultSpatial
    }
    readonly property NumberAnimation cExpressiveSlowSpatial: Curve {
        points: root.curves.expressiveSlowSpatial
    }
    readonly property NumberAnimation cExpressiveFastEffects: Curve {
        points: root.curves.expressiveFastEffects
    }
    readonly property NumberAnimation cExpressiveDefaultEffects: Curve {
        points: root.curves.expressiveDefaultEffects
    }
    readonly property NumberAnimation cExpressiveSlowEffects: Curve {
        points: root.curves.expressiveSlowEffects
    }
    readonly property NumberAnimation cLinear: NumberAnimation {
        easing.type: Easing.Linear
    }
}
