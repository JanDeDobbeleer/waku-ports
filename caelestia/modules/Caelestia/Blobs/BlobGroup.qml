import QtQuick

// Stub for caelestia's C++ BlobGroup (a shared metaball/SDF material for its BlobRect members).
// wabar gap: no blending between shapes; each shape paints itself as a plain rectangle in `color`.
QtObject {
    property real smoothing: 0
    property color color: "transparent"
    property bool cornerFill: true
}
