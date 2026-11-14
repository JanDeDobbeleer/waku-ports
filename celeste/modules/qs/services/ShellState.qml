pragma Singleton

import QtQuick
import Quickshell
import Celeste
import qs.components
import qs.services
import qs.compat
import waku.services as S
import "ShellStateHelpers.js" as ShellStateHelpers

Singleton {
    final property ShellRoot shellRoot

    function anySidebarOpen(): bool {
        return ShellStateHelpers.anySidebarOpen(states.instances);
    }

    function forScreen(screen: ShellScreen): ScreenState {
        return ShellStateHelpers.forScreen(screen, states.instances);
    }

    function forActive(): ScreenState {
        return ShellStateHelpers.forScreenForActive(states.instances, components.instances, S.WindowControl, Hypr);
    }

    function forDashboardToggle(): ScreenState {
        return ShellStateHelpers.forDashboardToggle(states.instances, forActive());
    }

    function componentsFor(screen: ShellScreen): Components {
        return ShellStateHelpers.componentsFor(screen, components.instances);
    }

    function componentsForActive(): Components {
        return ShellStateHelpers.componentsForActive(components.instances, S.WindowControl, Hypr);
    }

    Variants {
        id: states

        model: Screens.screens

        ScreenState {}
    }

    Variants {
        id: components

        model: Screens.screens

        Components {}
    }

    component Components: QtObject {
        required final property ShellScreen modelData

        final property var background
        final property var rootWindow
        final property var interactionWrapper
        final property var bar
        final property var panels

        function find(name: string, rootItem: Item): var {
            return ShellStateHelpers.find(CUtils, rootItem, rootWindow, name, 0);
        }

        function findAll(name: string, rootItem: Item): var {
            return ShellStateHelpers.find(CUtils, rootItem, rootWindow, name, 1);
        }

        function findMatching(pattern: string, rootItem: Item): var {
            return ShellStateHelpers.find(CUtils, rootItem, rootWindow, pattern, 2);
        }
    }

    component ComponentRef: QtObject {
        required final property ShellScreen screen
        required final property string slot
        required final property var component

        readonly final property QtObject target: ShellState.componentsFor(screen)

        onTargetChanged: {
            if (target)
                target[slot] = component;
        }
        Component.onDestruction: {
            if (target && target[slot] === component)
                target[slot] = null;
        }
    }
}
