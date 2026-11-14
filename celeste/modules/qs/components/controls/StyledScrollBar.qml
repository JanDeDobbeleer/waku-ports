import QtQuick
import QtQuick.Templates
import Celeste.Config
import qs.components
import qs.services
import "StyledScrollBarHelpers.js" as StyledScrollBarHelpers

ScrollBar {
    id: root

    required final property Flickable flickable
    // waku: the QtQuick.Templates shim has no attached ScrollBar, so follow the flickable here.
    size: StyledScrollBarHelpers.visibleSize(flickable)
    position: StyledScrollBarHelpers.visiblePosition(flickable)
    final property bool shouldBeActive
    final property real nonAnimPosition
    final property bool animating
    final property bool _updatingFromFlickable: false
    final property bool _updatingFromUser: false

    onHoveredChanged: {
        if (hovered)
            shouldBeActive = true;
        else
            shouldBeActive = StyledScrollBarHelpers.isMoving(flickable);
    }

    // Sync nonAnimPosition with Qt's automatic position binding
    onPositionChanged: {
        if (_updatingFromUser) {
            _updatingFromUser = false;
            return;
        }
        if (position === nonAnimPosition) {
            animating = false;
            return;
        }
        if (!animating && !_updatingFromFlickable && !fullMouse.pressed) {
            nonAnimPosition = position;
        }
    }

    Component.onCompleted: {
        if (flickable) {
            nonAnimPosition = StyledScrollBarHelpers.currentPosition(flickable);
        }
    }
    implicitWidth: Tokens.padding.extraSmall

    contentItem: StyledRect {
        anchors.left: parent.left
        anchors.right: parent.right
        opacity: {
            if (root.size === 1)
                return 0;
            if (fullMouse.pressed)
                return 1;
            if (mouse.containsMouse)
                return 0.8;
            if (root.policy === ScrollBar.AlwaysOn || root.shouldBeActive)
                return 0.6;
            return 0;
        }
        radius: Tokens.rounding.full
        color: Colours.palette.m3secondary

        MouseArea {
            id: mouse

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    // Sync nonAnimPosition with flickable when not animating
    Connections {
        function onContentYChanged() {
            if (!root.animating && !fullMouse.pressed) {
                root._updatingFromFlickable = true;
                root.nonAnimPosition = StyledScrollBarHelpers.currentPosition(root.flickable);
                root._updatingFromFlickable = false;
            }
        }

        target: root.flickable
    }

    Connections {
        function onMovingChanged(): void {
            if (StyledScrollBarHelpers.isMoving(root.flickable))
                root.shouldBeActive = true;
            else
                hideDelay.restart();
        }

        target: root.flickable
    }

    Timer {
        id: hideDelay

        interval: 600
        onTriggered: root.shouldBeActive = StyledScrollBarHelpers.isMoving(root.flickable) || root.hovered
    }

    CustomMouseArea {
        id: fullMouse

        function onWheel(event: WheelEvent): void {
            root.animating = true;
            root._updatingFromUser = true;
            let newPos = root.nonAnimPosition;
            if (event.angleDelta.y > 0)
                newPos = Math.max(0, root.nonAnimPosition - 0.1);
            else if (event.angleDelta.y < 0)
                newPos = Math.min(1 - root.size, root.nonAnimPosition + 0.1);
            root.nonAnimPosition = newPos;
            // Update flickable position
            // Map scrollbar position [0, 1-size] to contentY [0, maxContentY]
            StyledScrollBarHelpers.setContentPosition(root.flickable, root.size, newPos);
        }

        anchors.fill: parent
        preventStealing: true

        onPressed: event => {
            root.animating = true;
            root._updatingFromUser = true;
            const newPos = Math.max(0, Math.min(1 - root.size, event.y / root.height - root.size / 2));
            root.nonAnimPosition = newPos;
            // Update flickable position
            // Map scrollbar position [0, 1-size] to contentY [0, maxContentY]
            StyledScrollBarHelpers.setContentPosition(root.flickable, root.size, newPos);
        }

        onPositionChanged: event => {
            root._updatingFromUser = true;
            const newPos = Math.max(0, Math.min(1 - root.size, event.y / root.height - root.size / 2));
            root.nonAnimPosition = newPos;
            // Update flickable position
            // Map scrollbar position [0, 1-size] to contentY [0, maxContentY]
            StyledScrollBarHelpers.setContentPosition(root.flickable, root.size, newPos);
        }
    }

    Behavior on position {
        enabled: !fullMouse.pressed

        Anim {}
    }
}
