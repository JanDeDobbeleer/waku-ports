pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Celeste.Config
import qs.components
import qs.utils
import qs.modules.bar.popouts as BarPopouts
import "BarWrapperHelpers.js" as BarWrapperHelpers

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
        BarWrapperHelpers.closeTray(content.item);
    }

    function checkPopout(y: real): void {
        BarWrapperHelpers.checkPopout(content.item, y);
    }

    function debugEntries(): string {
        return BarWrapperHelpers.debugEntries(content.item);
    }

    function openPopoutNamed(name: string): bool {
        return BarWrapperHelpers.openPopoutNamed(content.item, name);
    }

    function entryItem(id: string): var {
        return BarWrapperHelpers.entryItem(content.item, id);
    }

    function emptyAt(x: real, y: real): bool {
        return BarWrapperHelpers.emptyAt(content.item, x, y);
    }

    function clickClock(): string {
        return BarWrapperHelpers.clickClock(content.item);
    }

    function handleWheel(y: real, angleDelta: point): void {
        BarWrapperHelpers.handleWheel(content.item, y, angleDelta);
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
