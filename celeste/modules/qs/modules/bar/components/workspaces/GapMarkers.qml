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

    AnimatedRepeater {
        model: ScriptModel {
            values: root.workspaces
        }

        removeDuration: Tokens.anim.durations.expressiveDefaultEffects

        StyledRect {
            required final property int index
            required final property Workspace modelData

            final property real shift: {
                if (!modelData || index === 0)
                    return 0;
                if (modelData.focused)
                    return -root.wsSpacing / 2 - implicitHeight;
                return (root.workspaces[index - 1]?.focused ?? false) ? root.wsSpacing / 2 : 0;
            }

            anchors.left: parent?.left
            anchors.right: parent?.right
            anchors.margins: Tokens.padding.extraSmall

            y: modelData ? modelData.y - root.wsSpacing / 2 + shift : 0
            implicitHeight: 1
            color: Colours.palette.m3outline

            opacity: !modelData || index === 0 || root.workspaces[index - 1]?.ws === modelData?.ws - 1 ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on shift {
                Anim {}
            }
        }
    }
}
