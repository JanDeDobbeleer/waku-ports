import QtQuick

// Stub for celeste's C++ BlobGroup (a shared metaball/SDF material for its BlobRect members).
// waku gap: no blending between shapes; each shape paints itself as a plain rectangle in `color`.
QtObject {
    final property real smoothing: 0
    final property color color: "transparent"
    final property bool cornerFill: true
}
