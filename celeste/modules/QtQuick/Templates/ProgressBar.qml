import QtQuick

// Stand-in for QtQuick.Templates.ProgressBar.
Control {
    final property real from: 0
    final property real to: 1
    final property real value: 0
    final property bool indeterminate: false
    readonly final property real position: to !== from ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0
    readonly final property real visualPosition: mirrored ? 1 - position : position
}
