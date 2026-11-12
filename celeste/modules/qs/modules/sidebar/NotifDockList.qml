pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Celeste.Components
import Celeste.Config
import qs.components
import qs.services

LazyListView {
    id: root

    required final property Props props
    required final property Flickable container
    required final property ScreenState screenState

    anchors.left: parent?.left
    anchors.right: parent?.right
    implicitHeight: contentHeight

    spacing: Tokens.spacing.small
    readyDelay: 1
    cacheBuffer: 400
    asynchronous: true

    // Port: the ListView stand-in never asks for a viewport adjustment (onViewportAdjustNeeded).

    useCustomViewport: true
    viewport: Qt.rect(0, container.contentY, width, container.height)

    removeDuration: Tokens.anim.durations.normal

    // Port: upstream's LazyListView `adding` state (opacity 0, scale 0) as a ListView add
    // transition. The first fill of the list does not run it, like upstream.
    add: Transition {
        Anim {
            properties: "opacity"
            from: 0
            type: Anim.DefaultEffects
        }
        Anim {
            properties: "scale"
            from: 0
        }
    }

    model: ScriptModel {
        values: {
            const map = new Map();
            for (const n of Notifs.notClosed)
                map.set(n.appName, null);
            for (const n of Notifs.list)
                map.set(n.appName, null);
            return [...map.keys()];
        }
    }

    delegate: Component {
        MouseArea {
            id: notif

            required final property int index
            required final property string modelData

            readonly final property bool closed: notifInner.notifCount === 0
            final property int startY

            function closeAll(): void {
                clearTimer.start();
            }

            // Port: LazyListView's attached layout properties are plain properties here, and the
            // list is a ListView, so the delegate sets its own height. Adding runs the list's add
            // transition; removing is the fade and shrink on `closed`.
            readonly final property real preferredHeight: closed ? 0 : notifInner.nonAnimHeight
            readonly final property real visibleHeight: closed ? 0 : notifInner.implicitHeight
            readonly final property bool removing: false
            readonly final property bool adding: false
            readonly final property bool ready: true
            implicitHeight: notifInner.implicitHeight
            width: ListView.view?.width ?? 0
            height: visibleHeight

            opacity: closed ? 0 : 1
            scale: closed ? 0.6 : 1

            hoverEnabled: true
            cursorShape: pressed ? Qt.ClosedHandCursor : undefined
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            preventStealing: true
            enabled: !closed

            drag.target: this
            drag.axis: Drag.XAxis

            onPressed: event => {
                startY = event.y;
                if (event.button === Qt.RightButton)
                    notifInner.toggleExpand(!notifInner.expanded);
                else if (event.button === Qt.MiddleButton)
                    closeAll();
            }
            onPositionChanged: event => {
                if (pressed) {
                    const diffY = event.y - startY;
                    if (Math.abs(diffY) > Config.notifs.expandThreshold)
                        notifInner.toggleExpand(diffY > 0);
                }
            }
            onReleased: event => {
                if (Math.abs(x) < width * Config.notifs.clearThreshold)
                    x = 0;
                else
                    closeAll();
            }

            Timer {
                id: clearTimer

                interval: 15
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    const notifs = Notifs.notClosed.filter(n => n.appName === notif.modelData);
                    if (notifs.length === 0) {
                        stop();
                        return;
                    }

                    for (const n of notifs.slice(0, 30))
                        n.close();
                }
            }

            NotifGroup {
                id: notifInner

                modelData: notif.modelData
                props: root.props
                container: root.container
                screenState: root.screenState
            }

            Behavior on y {
                enabled: notif.ready

                Anim {}
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                Anim {}
            }

            Behavior on x {
                Anim {}
            }
        }
    }

    Anim {
        id: contentYAnim

        target: root.container
        property: "contentY"
    }
}
