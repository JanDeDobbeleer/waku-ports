import QtQuick
import "ControlHelpers.js" as ControlHelpers

// Pure QML stand-in for QtQuick.Templates.Control. The waku engine does not ship the real
// QtQuick.Templates module, so the port provides the subset celeste's components use.
// A control places its `background` over the full size (behind) and its `contentItem` inside the
// padding, like the C++ template. Subclasses add behaviour.
Item {
    id: control

    final property real padding: 0
    final property real horizontalPadding: padding
    final property real verticalPadding: padding
    final property real topPadding: verticalPadding
    final property real leftPadding: horizontalPadding
    final property real rightPadding: horizontalPadding
    final property real bottomPadding: verticalPadding
    final property real spacing: 0
    final property var locale: Qt.locale()
    final property bool mirrored: false
    final property bool hoverEnabled: true
    readonly final property bool hovered: hover.hovered
    readonly final property bool visualFocus: activeFocus
    readonly final property real availableWidth: Math.max(0, width - leftPadding - rightPadding)
    readonly final property real availableHeight: Math.max(0, height - topPadding - bottomPadding)

    final property Item background
    final property Item contentItem

    readonly final property real implicitBackgroundWidth: ControlHelpers.implicitWidth(background)
    readonly final property real implicitBackgroundHeight: ControlHelpers.implicitHeight(background)
    readonly final property real implicitContentWidth: ControlHelpers.implicitWidth(contentItem)
    readonly final property real implicitContentHeight: ControlHelpers.implicitHeight(contentItem)

    implicitWidth: Math.max(implicitBackgroundWidth, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight, implicitContentHeight + topPadding + bottomPadding)

    // Subclasses that position the content themselves (a scroll bar) turn this off.
    final property bool autoPlaceContent: true

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
