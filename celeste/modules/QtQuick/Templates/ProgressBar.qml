import QtQuick

// Stand-in for QtQuick.Templates.ProgressBar.
Control {
    property real from: 0
    property real to: 1
    property real value: 0
    property bool indeterminate: false
    readonly property real position: to !== from ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0
    readonly property real visualPosition: mirrored ? 1 - position : position
}
