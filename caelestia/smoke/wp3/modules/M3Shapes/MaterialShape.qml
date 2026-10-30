import QtQuick

// SMOKE STUB of M3Shapes.MaterialShape (work package 2 supplies the real stub): a circle.
// Delete smoke/wp3/modules once work package 2 is merged.
Item {
    id: root

    enum Shape {
        Circle, Square, Slanted, Arch, Fan, Arrow, SemiCircle, Oval, Pill, Triangle, Diamond, ClamShell,
        Pentagon, Gem, Sunny, VerySunny, Cookie4Sided, Cookie6Sided, Cookie7Sided, Cookie9Sided,
        Cookie12Sided, Ghostish, Clover4Leaf, SoftBurst
    }

    property real implicitSize: 48
    property color color: "white"
    property int fromShape: MaterialShape.Circle
    property int toShape: MaterialShape.Circle
    property int shape: MaterialShape.Circle
    property real morphProgress: 1

    function beginBatchUpdate(): void {
    }

    function endBatchUpdate(): void {
    }

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.color
    }
}
