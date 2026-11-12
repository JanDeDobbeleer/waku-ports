import QtQuick
import "SpinButtonHelpers.js" as SpinButtonHelpers

// The `up` and `down` parts of a DoubleSpinBox: an indicator item and its pressed state.
QtObject {
    final property Item indicator
    readonly final property bool pressed: SpinButtonHelpers.pressed(indicator)
    readonly final property bool hovered: SpinButtonHelpers.hovered(indicator)
}
