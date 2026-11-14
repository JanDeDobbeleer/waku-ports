import QtQuick

QtObject {
    final property string currentName
    final property bool hasCurrent
    // True when the flyout is fully open: not sliding and not resizing. Live window previews wait for it.
    final property bool settled

    signal detachRequested(mode: string)
}
