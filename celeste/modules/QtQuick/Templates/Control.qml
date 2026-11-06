import QtQuick

// Pure QML stand-in for QtQuick.Templates.Control. The waku engine does not ship the real
// QtQuick.Templates module, so the port provides the subset celeste's components use.
// A control places its `background` over the full size (behind) and its `contentItem` inside the
// padding, like the C++ template. Subclasses add behaviour.
Item {
    id: control

    property real padding: 0
    property real horizontalPadding: padding
    property real verticalPadding: padding
    property real topPadding: verticalPadding
    property real leftPadding: horizontalPadding
    property real rightPadding: horizontalPadding
    property real bottomPadding: verticalPadding
    property real spacing: 0
    property var locale: Qt.locale()
    property bool mirrored: false
    property bool hoverEnabled: true
    readonly property bool hovered: hover.hovered
    readonly property bool visualFocus: activeFocus
    readonly property real availableWidth: Math.max(0, width - leftPadding - rightPadding)
    readonly property real availableHeight: Math.max(0, height - topPadding - bottomPadding)

    property Item background
    property Item contentItem

    readonly property real implicitBackgroundWidth: background ? background.implicitWidth : 0
    readonly property real implicitBackgroundHeight: background ? background.implicitHeight : 0
    readonly property real implicitContentWidth: contentItem ? contentItem.implicitWidth : 0
    readonly property real implicitContentHeight: contentItem ? contentItem.implicitHeight : 0

    implicitWidth: Math.max(implicitBackgroundWidth, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight, implicitContentHeight + topPadding + bottomPadding)

    // Subclasses that position the content themselves (a scroll bar) turn this off.
    property bool autoPlaceContent: true

    function layoutParts(): void {
        if (background) {
            background.x = 0;
            background.y = 0;
            background.width = width;
            background.height = height;
        }
        if (contentItem && autoPlaceContent) {
            contentItem.x = leftPadding;
            contentItem.y = topPadding;
            contentItem.width = availableWidth;
            contentItem.height = availableHeight;
        }
    }

    onBackgroundChanged: {
        if (background) {
            background.parent = control;
            background.z = -1;
        }
        layoutParts();
    }
    onContentItemChanged: {
        if (contentItem)
            contentItem.parent = control;
        layoutParts();
    }
    onWidthChanged: layoutParts()
    onHeightChanged: layoutParts()
    onLeftPaddingChanged: layoutParts()
    onRightPaddingChanged: layoutParts()
    onTopPaddingChanged: layoutParts()
    onBottomPaddingChanged: layoutParts()

    HoverHandler {
        id: hover

        enabled: control.hoverEnabled
    }
}
