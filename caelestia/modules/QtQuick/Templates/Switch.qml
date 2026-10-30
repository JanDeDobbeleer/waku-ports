import QtQuick

// Stand-in for QtQuick.Templates.Switch.
AbstractButton {
    checkable: true
    readonly property real position: checked ? 1 : 0
    readonly property real visualPosition: position
}
