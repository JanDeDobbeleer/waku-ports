import QtQuick

// M3Shapes MaterialShape stub: a Rectangle whose corner radius follows `shape`. waku gap:
// no polygon morphing, so every shape is a rounded rectangle, circle or pill; `fromShape`,
// `toShape` and `morphProgress` interpolate the radius only.
Rectangle {
    id: root

    enum Kind {
        Arch,
        Arrow,
        Circle,
        ClamShell,
        Clover4Leaf,
        Cookie12Sided,
        Cookie4Sided,
        Cookie6Sided,
        Cookie7Sided,
        Cookie9Sided,
        Diamond,
        Fan,
        Gem,
        Ghostish,
        Oval,
        Pentagon,
        Pill,
        SemiCircle,
        Slanted,
        SoftBurst,
        Square,
        Sunny,
        Triangle,
        VerySunny
    }

    final property real implicitSize: 0
    final property int shape: MaterialShape.Circle
    final property int fromShape: shape
    final property int toShape: shape
    final property real morphProgress: 1
    final property var animationEasing: null
    final property int animationDuration: 0
    final property bool batching_: false

    // Fraction of the half side used as the corner radius.
    function roundness_(kind: int): real {
        switch (kind) {
        case MaterialShape.Square:
        case MaterialShape.Slanted:
        case MaterialShape.Arch:
        case MaterialShape.ClamShell:
        case MaterialShape.Fan:
            return 0.3;
        case MaterialShape.Diamond:
        case MaterialShape.Triangle:
        case MaterialShape.Arrow:
        case MaterialShape.Gem:
        case MaterialShape.Pentagon:
            return 0.45;
        default:
            return 1;
        }
    }

    function beginBatchUpdate(): void {
        batching_ = true;
    }

    function endBatchUpdate(): void {
        batching_ = false;
    }

    function pathBounds(): rect {
        return Qt.rect(0, 0, width, height);
    }

    function pointAtAngle(degrees: real): point {
        const a = degrees * Math.PI / 180;
        return Qt.point(width / 2 + Math.cos(a) * width / 2, height / 2 + Math.sin(a) * height / 2);
    }

    function distanceAtAngle(degrees: real): real {
        return Math.min(width, height) / 2;
    }

    implicitWidth: implicitSize
    implicitHeight: implicitSize
    radius: Math.min(width, height) / 2 * (roundness_(fromShape) + (roundness_(toShape) - roundness_(fromShape)) * morphProgress)
}
