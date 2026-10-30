import QtQuick
import QtQuick.Effects

// Stand-in for caelestia's C++ RoundedMask (a custom scene graph node): draws `source` clipped to
// a rectangle with per-corner radii, through MultiEffect's mask.
// wabar gap: `color` (the fill for the area cut off by the corners) is not drawn.
Item {
    id: root

    property Item source
    property real topLeftRadius: 0
    property real topRightRadius: 0
    property real bottomRightRadius: 0
    property real bottomLeftRadius: 0
    property color color: "transparent"

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
