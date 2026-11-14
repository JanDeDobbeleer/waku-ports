pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Celeste.Config
import qs.components
import qs.components.containers
import qs.components.effects
import qs.services
import "NotifActionListHelpers.js" as NotifActionListHelpers

Item {
    id: root

    required final property NotifData notif

    Layout.fillWidth: true
    implicitHeight: flickable.contentHeight

    layer.enabled: true
    layer.smooth: true
    layer.effect: Mask {
        maskSource: gradientMask
    }

    Item {
        id: gradientMask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent

            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: Qt.rgba(0, 0, 0, 0)
                }
                GradientStop {
                    position: 0.1
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 0.9
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(0, 0, 0, 0)
                }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left

            implicitWidth: parent.width / 2
            opacity: flickable.contentX > 0 ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right

            implicitWidth: parent.width / 2
            opacity: flickable.contentX < flickable.contentWidth - parent.width ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    StyledFlickable {
        id: flickable

        anchors.fill: parent
        contentWidth: Math.max(width, actionList.implicitWidth)
        contentHeight: actionList.implicitHeight

        RowLayout {
            id: actionList

            anchors.fill: parent
            spacing: Tokens.spacing.small

            Repeater {
                model: NotifActionListHelpers.actions(root.notif)

                StyledRect {
                    id: action

                    required final property var modelData

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitWidth: actionInner.implicitWidth + Tokens.padding.medium * 2
                    implicitHeight: actionInner.implicitHeight + Tokens.padding.small

                    Layout.preferredWidth: implicitWidth + (actionStateLayer.pressed ? Tokens.padding.large : 0)
                    radius: actionStateLayer.pressed ? Tokens.rounding.medium / 2 : Tokens.rounding.medium
                    color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 4)

                    Timer {
                        id: copyTimer

                        interval: 3000
                        onTriggered: NotifActionListHelpers.setIconText(actionInner.item, "content_copy")
                    }

                    StateLayer {
                        id: actionStateLayer

                        onClicked: NotifActionListHelpers.activate(action.modelData, root.notif, Quickshell, actionInner.item, copyTimer)
                    }

                    Loader {
                        id: actionInner

                        anchors.centerIn: parent
                        sourceComponent: NotifActionListHelpers.isSpecial(action.modelData) ? iconBtn : root.notif?.hasActionIcons ? iconComp : textComp
                    }

                    Component {
                        id: iconBtn

                        MaterialIcon {
                            animate: NotifActionListHelpers.isCopy(action.modelData)
                            text: NotifActionListHelpers.iconText(action.modelData)
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }

                    Component {
                        id: iconComp

                        IconImage {
                            asynchronous: true
                            source: Quickshell.iconPath(NotifActionListHelpers.identifier(action.modelData))
                        }
                    }

                    Component {
                        id: textComp

                        StyledText {
                            text: NotifActionListHelpers.actionText(action.modelData)
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }

                    Behavior on Layout.preferredWidth {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }

                    Behavior on radius {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }
                }
            }
        }
    }
}
