import QtQuick
import Celeste.Config
import qs.components
import qs.services

StyledRect {
    id: root

    enum ButtonType {
        Filled,
        Tonal,
        Text
    }

    final property bool checked
    property alias disabled: stateLayer.disabled
    final property bool isToggle
    final property bool isRound

    final property bool radiusMorph: true
    property alias shapeMorph: stateLayer.shapeMorph
    final property bool fillWidth // For ButtonRow

    final property font font: Tokens.font.body.small
    final property int type: ButtonBase.Filled

    final property real padding
    final property real horizontalPadding: padding
    final property real verticalPadding: padding

    readonly property alias pressed: stateLayer.pressed
    readonly property alias hovered: stateLayer.containsMouse
    readonly property alias stateLayer: stateLayer
    readonly property alias radiusAnim: radiusAnim

    final property color activeColour
    final property color inactiveColour
    final property color activeOnColour
    final property color inactiveOnColour
    final property color disabledColour: Qt.alpha(Colours.palette.m3onSurface, 0.1)
    final property color disabledOnColour: Qt.alpha(Colours.palette.m3onSurface, 0.38)

    final property bool internalChecked
    final property real shapeMorphExpansion: shapeMorph && pressed ? 24 : 0 // Apparently it's always 24px no matter the width of the button
    readonly final property color onColour: disabled ? disabledOnColour : internalChecked ? activeOnColour : inactiveOnColour

    final property real pressedRadius: Tokens.rounding.small
    final property real checkedRadius: Tokens.rounding.medium
    final property real defaultRadius: Tokens.rounding.large

    signal clicked

    onCheckedChanged: internalChecked = checked

    radius: {
        if (radiusMorph && pressed)
            return pressedRadius;
        if (internalChecked)
            return checkedRadius;
        if (isRound)
            return (height || implicitHeight) / 2 * Math.min(1, Tokens.rounding.scale);
        return defaultRadius;
    }
    color: type === ButtonBase.Text ? "transparent" : disabled ? disabledColour : internalChecked ? activeColour : inactiveColour

    // Make size required so we don't forget to set it
    required implicitWidth
    required implicitHeight

    StateLayer {
        id: stateLayer

        color: root.internalChecked ? root.activeOnColour : root.inactiveOnColour
        disabled: root.disabled
        onClicked: {
            if (root.isToggle)
                root.internalChecked = !root.internalChecked;
            root.clicked();
        }
    }

    Behavior on radius {
        Anim {
            id: radiusAnim

            type: Anim.DefaultEffects
        }
    }

    Behavior on shapeMorphExpansion {
        Anim {
            type: Anim.FastSpatial
        }
    }
}
