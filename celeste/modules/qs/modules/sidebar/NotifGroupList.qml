pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Celeste
import Celeste.Components
import Celeste.Config
import qs.components
import qs.services
import "NotifGroupListHelpers.js" as NotifGroupListHelpers

LazyListView {
    id: root

    required final property Props props
    required final property list<var> notifs
    required final property bool expanded
    required final property Flickable container
    required final property ScreenState screenState

    signal requestToggleExpand(expand: bool)

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: contentHeight

    spacing: Math.round(Tokens.spacing.extraSmall)
    asynchronous: true

    readyDelay: 1
    cacheBuffer: 400
    removeDuration: Tokens.anim.durations.normal

    // Port: upstream's LazyListView `adding` state (opacity 0, scale 0.7) as a ListView add
    // transition. The first fill of the list does not run it, like upstream.
    add: Transition {
        Anim {
            properties: "opacity"
            from: 0
            type: Anim.DefaultEffects
        }
        Anim {
            properties: "scale"
            from: 0.7
        }
    }

    useCustomViewport: true
    viewport: NotifGroupListHelpers.viewport(Qt, CUtils, container, root, tWatcher, width)

    model: ScriptModel {
        values: NotifGroupListHelpers.previewItems(root.notifs, root.expanded, Config.notifs.groupPreviewNum)
    }

    delegate: Component {
        MouseArea {
            id: notif

            required final property int index
            required final property NotifData modelData

            final property int startY

            Component.onCompleted: NotifGroupListHelpers.lock(modelData, this)
            Component.onDestruction: NotifGroupListHelpers.unlock(modelData, this)

            // Port: LazyListView's attached layout properties are plain properties here, and the
            // list is a ListView, so the delegate sets its own height.
            readonly final property real preferredHeight: modelData?.closed ? 0 : notifInner.nonAnimHeight
            readonly final property real visibleHeight: modelData?.closed ? 0 : notifInner.implicitHeight
            readonly final property bool ready: true
            implicitHeight: notifInner.implicitHeight
            width: ListView.view?.width ?? 0
            height: visibleHeight

            opacity: modelData?.closed ? 0 : 1
            scale: modelData?.closed ? 0.7 : 1

            hoverEnabled: true
            cursorShape: NotifGroupListHelpers.cursorShape(notifInner.body, pressed, Qt)
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            preventStealing: !root.expanded
            enabled: !(modelData?.closed ?? true)

            drag.target: this
            drag.axis: Drag.XAxis

            onPressed: event => {
                startY = event.y;
                if (event.button === Qt.RightButton)
                    root.requestToggleExpand(!root.expanded);
                else if (event.button === Qt.MiddleButton)
                    NotifGroupListHelpers.close(modelData);
            }
            onPositionChanged: event => {
                if (pressed && !root.expanded) {
                    const diffY = event.y - startY;
                    if (Math.abs(diffY) > Config.notifs.expandThreshold)
                        root.requestToggleExpand(diffY > 0);
                }
            }
            onReleased: event => {
                if (Math.abs(x) < width * Config.notifs.clearThreshold)
                    x = 0;
                else
                    NotifGroupListHelpers.close(modelData);
            }

            ParallelAnimation {
                running: notif.modelData?.closed ?? false
                onFinished: NotifGroupListHelpers.unlock(notif.modelData, notif)

                Anim {
                    type: Anim.DefaultEffects
                    target: notif
                    property: "opacity"
                    to: 0
                }
                Anim {
                    target: notif
                    property: "x"
                    to: notif.x >= 0 ? notif.width : -notif.width
                }
            }

            Notif {
                id: notifInner

                anchors.fill: parent
                modelData: notif.modelData
                props: root.props
                expanded: root.expanded
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

    TransformWatcher {
        id: tWatcher

        a: NotifGroupListHelpers.contentItem(root.container)
        b: root
    }
}
