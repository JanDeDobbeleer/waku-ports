import QtQuick

// Stand-in for QtQuick.Templates.Switch.
AbstractButton {
    checkable: true
    readonly final property real position: checked ? 1 : 0
    readonly final property real visualPosition: position
}
