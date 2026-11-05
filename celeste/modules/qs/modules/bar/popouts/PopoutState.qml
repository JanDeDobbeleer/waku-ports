import QtQuick

QtObject {
    property string currentName
    property bool hasCurrent
    // True when the flyout is fully open: not sliding and not resizing. Live window previews wait for it.
    property bool settled

    signal detachRequested(mode: string)
}
