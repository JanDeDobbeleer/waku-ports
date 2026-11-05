import QtQuick

// The `up` and `down` parts of a DoubleSpinBox: an indicator item and its pressed state.
QtObject {
    property Item indicator
    readonly property bool pressed: indicator ? (indicator.pressed ?? false) : false
    readonly property bool hovered: indicator ? (indicator.hovered ?? false) : false
}
