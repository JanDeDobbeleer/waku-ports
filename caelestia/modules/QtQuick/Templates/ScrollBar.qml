import QtQuick

// Stand-in for QtQuick.Templates.ScrollBar.
// wabar gap: the real type is also an attached object (`Flickable { ScrollBar.vertical: ... }`)
// that follows its Flickable. Pure QML cannot attach, so an instance must be placed next to the
// Flickable and fed `size` and `position` (e.g. from Flickable.visibleArea).
Control {
    id: bar

    enum Policy {
        AsNeeded,
        AlwaysOff,
        AlwaysOn
    }

    property real size: 1
    property real position: 0
    property int orientation: Qt.Vertical
    property int policy: ScrollBar.AsNeeded
    property real minimumSize: 0
    property bool interactive: true
    readonly property bool horizontal: orientation === Qt.Horizontal
    readonly property bool vertical: orientation === Qt.Vertical
    readonly property real visualSize: Math.max(minimumSize, Math.min(1, size))
    readonly property real visualPosition: Math.max(0, Math.min(1 - visualSize, position))
    readonly property bool pressed: false
    readonly property bool active: policy === ScrollBar.AlwaysOn || (policy === ScrollBar.AsNeeded && size < 1)

    autoPlaceContent: false

    function placeContent(): void {
        if (!contentItem)
            return;
        if (vertical) {
            contentItem.x = leftPadding;
            contentItem.y = topPadding + visualPosition * availableHeight;
            contentItem.width = availableWidth;
            contentItem.height = visualSize * availableHeight;
        } else {
            contentItem.x = leftPadding + visualPosition * availableWidth;
            contentItem.y = topPadding;
            contentItem.width = visualSize * availableWidth;
            contentItem.height = availableHeight;
        }
    }

    onContentItemChanged: placeContent()
    onVisualPositionChanged: placeContent()
    onVisualSizeChanged: placeContent()
    onWidthChanged: placeContent()
    onHeightChanged: placeContent()
}
