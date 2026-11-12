pragma Singleton

import QtQuick
import Quickshell
import Celeste
import qs.components
import qs.services
import qs.compat
import waku.services as S

Singleton {
    final property ShellRoot shellRoot

    function anySidebarOpen(): bool {
        return states.instances.some(s => s.sidebar);
    }

    function forScreen(screen: ShellScreen): ScreenState {
        for (const s of states.instances)
            if (s.modelData === screen)
                return s;
        return null;
    }

    function forActive(): ScreenState {
        const c = componentsForActive();
        return c ? forScreen(c.modelData) : null;
    }

    function forDashboardToggle(): ScreenState {
        const active = forActive();
        if (active?.dashboard)
            return active;
        return states.instances.find(s => s.dashboard) ?? active;
    }

    function componentsFor(screen: ShellScreen): Components {
        for (const c of components.instances)
            if (c.modelData === screen)
                return c;
        return null;
    }

    function componentsForActive(): Components {
        const handle = typeof S.WindowControl.monitor === "function" ? S.WindowControl.monitor(S.WindowControl.foreground()) : 0;
        if (handle) {
            for (const c of components.instances)
                if (c.rootWindow?.monitorHandle === handle)
                    return c;
        }
        const mon = Hypr.focusedMonitor;
        for (const c of components.instances)
            if (Hypr.monitorFor(c.modelData) === mon)
                return c;
        return null;
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
            return CUtils.findChild(rootItem ?? rootWindow?.contentItem, name);
        }

        function findAll(name: string, rootItem: Item): var {
            return CUtils.findChildren(rootItem ?? rootWindow?.contentItem, name);
        }

        function findMatching(pattern: string, rootItem: Item): var {
            return CUtils.findChildrenMatching(rootItem ?? rootWindow?.contentItem, pattern);
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
