pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Celeste.Components
import Celeste.Config
import qs.components
import qs.services

Item {
    id: root

    required final property var workspaces
    required final property int wsSpacing

    readonly final property color colour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
    final property color colourAnimated: colour

    Behavior on colourAnimated {
        CAnim {}
    }

    // Item wrappers because `layer.enabled` clips the content, and the rects extend 1px outside the parent
    Item {
        anchors.fill: parent
        anchors.margins: -1

        opacity: root.colourAnimated.a
        layer.enabled: opacity < 1 // Forces opacity to apply to children as a single layer

        Item {
            anchors.fill: parent
            anchors.margins: 1

            AnimatedRepeater {
                model: ScriptModel {
                    values: root.workspaces
                }

                removeDuration: Tokens.anim.durations.expressiveDefaultEffects

                OccupiedRect {}
            }
        }
    }

    component OccupiedRect: StyledRect {
        required final property int index
        required final property Workspace modelData

        final property real topRadius: ifAdjacent(0, -1, 0, width / 2)
        final property real bottomRadius: ifAdjacent(root.workspaces.length - 1, 1, 0, width / 2)
        final property real topPadding: ifAdjacent(0, -1, root.wsSpacing, 0)
        final property real bottomPadding: ifAdjacent(root.workspaces.length - 1, 1, root.wsSpacing, 0)

        function ifAdjacent(exclIdx: int, adj: int, yes: real, no: real): real {
            if (!modelData?.isOccupied || index === exclIdx)
                return no;
            return root.workspaces[index + adj]?.isOccupied ? yes : no;
        }

        anchors.left: parent?.left
        anchors.right: parent?.right
        anchors.margins: -1

        y: modelData ? modelData.y + anchors.margins - topPadding : 0
        implicitHeight: modelData ? modelData.visibleHeight - anchors.margins * 2 + topPadding + bottomPadding : 0

        color: Qt.alpha(root.colour, 1)
        topLeftRadius: topRadius
        topRightRadius: topRadius
        bottomLeftRadius: bottomRadius
        bottomRightRadius: bottomRadius

        opacity: modelData?.isOccupied ? 1 : 0

        Behavior on topRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on bottomRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on topPadding {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on bottomPadding {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
