import QtQuick

// The `up` and `down` parts of a DoubleSpinBox: an indicator item and its pressed state.
QtObject {
    final property Item indicator
    readonly final property bool pressed: indicator ? (indicator.pressed ?? false) : false
    readonly final property bool hovered: indicator ? (indicator.hovered ?? false) : false
}
