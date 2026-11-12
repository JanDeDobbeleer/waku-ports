pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Celeste.Config
import qs.components
import qs.utils
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required final property ShellScreen screen
    required final property ScreenState screenState
    required final property BarPopouts.Wrapper popouts
    required final property bool fullscreen

    readonly final property bool disabled: Strings.testRegexList(Config.bar.excludedScreens, screen.name)

    readonly final property int clampedWidth: Math.max(Config.border.minThickness, implicitWidth)
    readonly final property int padding: Math.max(Tokens.padding.small, Config.border.thickness)
    readonly final property int contentWidth: Tokens.sizes.bar.innerWidth + padding * 2
    readonly final property int exclusiveZone: !disabled && (Config.bar.persistent || screenState.bar) ? contentWidth : Config.border.thickness
    readonly final property bool shouldBeVisible: !fullscreen && !disabled && (Config.bar.persistent || screenState.bar || isHovered)
    final property bool isHovered

    // Port: no `as Bar` casts here. On waku the cast of a Loader item to a type of the same module came
    // back null, so the hover path (Interactions -> checkPopout) did nothing. The item is called untyped.
    function closeTray(): void {
        content.item?.closeTray();
    }

    function checkPopout(y: real): void {
        content.item?.checkPopout(y);
    }

    function debugEntries(): string {
        return content.item ? content.item.debugEntries() : "no content";
    }

    function openPopoutNamed(name: string): bool {
        return content.item ? content.item.openPopoutNamed(name) : false;
    }

    function entryItem(id: string): var {
        return content.item ? content.item.entryItem(id) : null;
    }

    function emptyAt(x: real, y: real): bool {
        return content.item ? content.item.emptyAt(x, y) : false;
    }

    function clickClock(): string {
        return content.item ? content.item.clickClock() : "no content";
    }

    function handleWheel(y: real, angleDelta: point): void {
        content.item?.handleWheel(y, angleDelta);
    }

    clip: true
    visible: width > Config.border.thickness
    implicitWidth: fullscreen ? 0 : Config.border.thickness

    states: State {
        name: "visible"
        when: root.shouldBeVisible

        PropertyChanges {
            root.implicitWidth: root.contentWidth
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitWidth"
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitWidth"
                type: Anim.Emphasized
            }
        }
    ]

    Loader {
        id: content

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right

        active: root.shouldBeVisible

        sourceComponent: Bar {
            width: root.contentWidth
            screen: root.screen
            screenState: root.screenState
            popouts: root.popouts
            fullscreen: root.fullscreen
        }
    }
}
