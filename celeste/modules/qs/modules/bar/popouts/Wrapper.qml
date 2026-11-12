pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Celeste.Config
import qs.components
import qs.services
import "WrapperHelpers.js" as WrapperHelpers

Item {
    id: root

    required final property ShellScreen screen
    required final property real offsetScale

    readonly property alias content: contentItem

    readonly final property real nonAnimWidth: WrapperHelpers.activeWidth(children, contentItem.implicitWidth)
    readonly final property real nonAnimHeight: WrapperHelpers.activeHeight(children, contentItem.implicitHeight)
    // Port: the submenu depth of the open tray menu. The port has no tray menu popout, so it is 0.
    readonly final property int currentDepth: 0
    readonly final property Item current: (contentItem.item as Content)?.current ?? null
    readonly final property bool isDetached: detachedMode.length > 0

    property alias currentName: popoutState.currentName
    property alias hasCurrent: popoutState.hasCurrent
    final property real currentCenter

    final property string detachedMode
    final property string queuedMode

    // Dummy object so Tokens attached prop resolves to global config
    // Anim configs are not per-monitor
    readonly final property QtObject dummy: QtObject {}
    final property int animLength: Tokens.anim.durations.expressiveDefaultSpatial
    final property var animCurve: Tokens.anim.expressiveDefaultSpatial // The easingCurve type is Qt 6.11+ so we gotta use var for now

    function setAnims(detach: bool): void {
        const type = `expressive${detach ? "Slow" : "Default"}Spatial`;
        animLength = Tokens.anim.durations[type];
        animCurve = Tokens.anim[type];
    }

    function detach(mode: string): void {
        setAnims(true);
        if (mode === "winfo") {
            detachedMode = mode;
        } else {
            queuedMode = mode;
            detachedMode = "any";
        }
        setAnims(false);
        focus = true;
    }

    function close(): void {
        hasCurrent = false;
        detachedMode = "";
    }

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    focus: hasCurrent
    Keys.onEscapePressed: {
        // Forward escape to password popout if active, otherwise close
        if (WrapperHelpers.closePassword(currentName, contentItem.item))
            return;
        close();
    }

    Keys.onPressed: event => {
        // Don't intercept keys when password popout is active - let it handle them
        if (currentName === "wirelesspassword") {
            event.accepted = false;
        }
    }

    // Port: a DWM thumbnail is not clipped by the slide-in clip, so previews wait until the
    // flyout is open and its size has settled, and go as soon as it starts to close.
    Binding {
        target: popoutState
        property: "settled"
        value: root.hasCurrent && root.offsetScale < 0.01 && root.implicitWidth === root.nonAnimWidth && root.implicitHeight === root.nonAnimHeight
    }

    PopoutState {
        id: popoutState

        onDetachRequested: mode => root.detach(mode)
    }

    // Port: the winfo and nexus popouts are not ported (deferred), so detach() only queues.
    HyprlandFocusGrab {
        active: root.isDetached
        windows: [QsWindow.window]
        onCleared: root.close()
    }

    Binding {
        when: root.isDetached || (root.hasCurrent && root.currentName === "wirelesspassword")

        target: QsWindow.window
        property: "WlrLayershell.keyboardFocus"
        value: WlrKeyboardFocus.OnDemand
    }

    Comp {
        id: contentItem

        shouldBeActive: root.hasCurrent && !root.detachedMode
        anchors.fill: parent

        sourceComponent: Content {
            popouts: popoutState
            screenState: ShellState.forScreen(root.screen)
        }
    }

    Behavior on implicitWidth {
        Anim {
            duration: root.animLength
            easing: root.animCurve
        }
    }

    Behavior on implicitHeight {
        enabled: root.offsetScale < 1

        Anim {
            duration: root.animLength
            easing: root.animCurve
        }
    }

    component Comp: Loader {
        id: comp

        final property bool shouldBeActive

        active: false
        opacity: 0

        // Makes the loader load on the same frame shouldBeActive becomes true, which ensures size is set
        states: State {
            name: "active"
            when: comp.shouldBeActive

            PropertyChanges {
                comp.opacity: 1
                comp.active: true
            }
        }

        transitions: [
            Transition {
                from: ""
                to: "active"

                SequentialAnimation {
                    PropertyAction {
                        property: "active"
                    }
                    Anim {
                        type: Anim.DefaultEffects
                        property: "opacity"
                    }
                }
            },
            Transition {
                from: "active"
                to: ""

                SequentialAnimation {
                    Anim {
                        type: Anim.DefaultEffects
                        property: "opacity"
                    }
                    PropertyAction {
                        property: "active"
                    }
                }
            }
        ]
    }
}
