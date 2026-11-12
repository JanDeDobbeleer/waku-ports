pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates
import Celeste
import Celeste.Components
import Celeste.Config
import qs.components
import qs.services
import "StyledSliderHelpers.js" as StyledSliderHelpers

Slider {
    id: root

    final property bool wavy
    final property bool animateWave
    final property real waveFrequency: 6
    final property int waveDuration: 1000
    final property int radius: Tokens.rounding.medium
    final property bool interactionOnMove: true
    readonly final property bool dragging: mouse.pressed

    final property color fgColour: enabled ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3onSurface, 0.38)
    final property color bgColour: enabled ? Colours.palette.m3secondaryContainer : Qt.alpha(Colours.palette.m3onSurface, 0.1)

    final property real pos: visualPosition
    final property real filledWidth

    signal interaction(v: real)

    Component.onCompleted: filledWidth = StyledSliderHelpers.widthBinding(Qt, root, handleItem)

    implicitWidth: Tokens.px(200)
    implicitHeight: Tokens.px(12)

    contentItem: Item {
        anchors.fill: parent

        StyledRect {
            id: remaining

            anchors.left: handleItem.right
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.spacing.extraSmall

            implicitHeight: parent.height * (parent.height <= 12 ? opacity : Math.min(opacity * 2, 1))
            opacity: Math.min(width, 12) / 12

            radius: root.radius
            topLeftRadius: Tokens.rounding.extraSmall / 2
            bottomLeftRadius: Tokens.rounding.extraSmall / 2
            color: root.bgColour
        }

        StyledRect {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 4 * remaining.opacity

            implicitWidth: implicitHeight
            implicitHeight: 4 * remaining.opacity
            opacity: remaining.opacity

            radius: Tokens.rounding.full
            color: root.fgColour
        }

        StyledRect {
            id: handleItem

            anchors.left: filled.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.spacing.extraSmall

            implicitWidth: Tokens.px(4)
            implicitHeight: StyledSliderHelpers.handleHeight(parent.height, mouse.pressed, CUtils)

            radius: Tokens.rounding.full
            color: root.fgColour

            Behavior on implicitHeight {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }

        Loader {
            id: filled

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            asynchronous: true

            sourceComponent: root.wavy ? waveComp : lineComp
        }

        Component {
            id: lineComp

            StyledRect {
                implicitWidth: root.filledWidth
                implicitHeight: root.height

                radius: root.radius
                topRightRadius: Tokens.rounding.extraSmall / 2
                bottomRightRadius: Tokens.rounding.extraSmall / 2
                color: root.fgColour
            }
        }

        Component {
            id: waveComp

            WavyLine {
                lineWidth: root.height * 0.7
                frequency: root.waveFrequency
                startX: x
                fullLength: root.width - handleItem.implicitWidth - handleItem.anchors.leftMargin
                color: root.fgColour

                implicitWidth: root.filledWidth
                implicitHeight: lineWidth * amplitudeMultiplier * 2 + lineWidth

                Anim on waveProgress {
                    running: true
                    paused: !root.animateWave
                    from: 0
                    to: 1
                    duration: root.waveDuration
                    easing.type: Easing.Linear
                    loops: Animation.Infinite
                }

                Behavior on color {
                    CAnim {}
                }
            }
        }
    }

    Binding {
        id: posBinding

        target: root
        property: "pos"
        value: CUtils.clamp(mouse.pressStartPos + mouse.dragMovement, 0, 1)
        when: mouse.pressed
    }

    MouseArea {
        id: mouse

        final property real pressStartX
        final property real pressStartPos
        final property real dragMovement

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        preventStealing: true
        implicitHeight: handleItem.implicitHeight

        onPressed: e => {
            widthBehavior.enabled = false;
            pressStartX = e.x;
            pressStartPos = root.visualPosition;
        }
        onPositionChanged: e => {
            dragMovement = (e.x - pressStartX) / width;
            if (root.interactionOnMove)
                root.interaction(posBinding.value);
        }
        onReleased: e => {
            const clickPos = e.x / width;
            const finalPos = mouse.dragMovement !== 0 ? posBinding.value : CUtils.clamp(clickPos, 0, 1);
            root.interaction(finalPos);
            widthBehavior.enabled = true;
            dragMovement = 0;
        }
    }

    Behavior on filledWidth {
        id: widthBehavior

        Anim {}
    }
}
