pragma ComponentBehavior: Bound

import QtQuick
import Celeste.Config
import qs.components
import qs.components.effects
import qs.services

StyledRect {
    id: root

    required final property Workspace activeWs
    required final property Item mask
    property alias contentColour: colouriser.colorizationColor

    final property real start
    final property real end

    function runAnim(): void {
        if (!activeWs)
            return;

        const newStart = activeWs.layoutY;
        const goingUp = newStart < start;
        const leadingDuration = Tokens.anim.durations.expressiveDefaultSpatial;
        const trailingDuration = leadingDuration * (Config.bar.workspaces.activeTrail ? 1.5 : 1);

        startAnim.stop();
        endAnim.stop();
        startAnim.to = newStart;
        endAnim.to = newStart + activeWs.preferredHeight;
        startAnim.duration = goingUp ? leadingDuration : trailingDuration;
        endAnim.duration = goingUp ? trailingDuration : leadingDuration;
        startAnim.start();
        endAnim.start();
    }

    onActiveWsChanged: runAnim()
    Component.onCompleted: runAnim()

    clip: true
    // Smaller than the slot; scaling keeps the pill centred on its desktop.
    scale: 0.7
    y: start + mask.y
    implicitHeight: end - start
    radius: Tokens.rounding.full
    color: Colours.palette.m3primary

    Anim on start {
        id: startAnim
    }

    Anim on end {
        id: endAnim
    }

    Connections {
        function onLayoutYChanged(): void {
            root.runAnim();
        }

        function onPreferredHeightChanged(): void {
            root.runAnim();
        }

        target: root.activeWs
    }

    Colouriser {
        id: colouriser

        // Solid indicator: the pill stays plain primary, without the tinted dot cut into it.
        visible: false

        source: root.mask
        sourceColor: Colours.palette.m3onSurface
        colorizationColor: Colours.palette.m3onPrimary

        x: 0
        y: -parent.start
        implicitWidth: root.mask.width
        implicitHeight: root.mask.height

        anchors.horizontalCenter: parent.horizontalCenter
    }
}
