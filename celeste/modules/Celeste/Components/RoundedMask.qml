import QtQuick
import QtQuick.Effects

// Stand-in for celeste's C++ RoundedMask (a custom scene graph node): draws `source` clipped to
// a rectangle with per-corner radii, through MultiEffect's mask.
// waku gap: `color` (the fill for the area cut off by the corners) is not drawn.
Item {
    id: root

    final property Item source
    final property real topLeftRadius: 0
    final property real topRightRadius: 0
    final property real bottomRightRadius: 0
    final property real bottomLeftRadius: 0
    final property color color: "transparent"

    MultiEffect {
        anchors.fill: parent
        source: root.source
        visible: root.source !== null && root.width > 0 && root.height > 0
        maskEnabled: true
        maskSource: maskShape
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    Rectangle {
        id: maskShape

        anchors.fill: parent
        visible: false
        layer.enabled: true
        color: "black"
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomRightRadius: root.bottomRightRadius
        bottomLeftRadius: root.bottomLeftRadius
    }
}
