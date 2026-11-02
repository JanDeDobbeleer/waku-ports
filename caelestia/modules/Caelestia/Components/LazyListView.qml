import QtQuick

// Stand-in for caelestia's C++ LazyListView (a virtualising, animated vertical list whose items
// are laid out from per-delegate heights). This one is a non-interactive ListView that grows to
// its content, so every delegate is created and the height is the sum of the delegate heights.
//
// The C++ type also has an attached object, read by delegates as `LazyListView.<name>`:
//   preferredHeight, visibleHeight (writable), layoutY, ready, adding, removing (read),
//   trackViewport (writable).
// waku gap: attached objects cannot be written in QML. Delegates that use them (the bar
// workspaces and the sidebar notification lists, ported later) must be edited to declare these as
// plain properties on the delegate root. This list view only reads `height` of each delegate.
ListView {
    id: root

    property real layoutHeight: contentHeight
    property bool useCustomViewport: false
    property rect viewport: Qt.rect(0, 0, width, height)
    property real estimatedHeight: -1
    property bool asynchronous: false
    property int removeDuration: 300
    property int readyDelay: 0
    // ListView has cacheBuffer, contentY and count already.
    // Bumped after the delegates change, so bindings that read itemAtIndex() run again.
    property int itemsDirty

    onCountChanged: Qt.callLater(() => itemsDirty++)

    function itemAt(x: real, y: real): Item {
        return itemAtIndex(indexAt(x, y));
    }

    interactive: false
    implicitHeight: contentHeight
    cacheBuffer: 100000
}
