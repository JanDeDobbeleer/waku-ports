.pragma library

function anySidebarOpen(states) {
    for (let i = 0; i < states.length; i++) {
        if (states[i].sidebar)
            return true;
    }
    return false;
}

function forScreen(screen, states) {
    for (let i = 0; i < states.length; i++) {
        if (states[i].modelData === screen)
            return states[i];
    }
    return null;
}

function forScreenForActive(states, components, windowControl, hypr) {
    const component = componentsForActive(components, windowControl, hypr);
    return component ? forScreen(component.modelData, states) : null;
}

function forDashboardToggle(states, active) {
    if (active && active.dashboard)
        return active;
    for (let i = 0; i < states.length; i++) {
        if (states[i].dashboard)
            return states[i];
    }
    return active;
}

function componentsFor(screen, components) {
    for (let i = 0; i < components.length; i++) {
        if (components[i].modelData === screen)
            return components[i];
    }
    return null;
}

function componentsForActive(components, windowControl, hypr) {
    const handle = typeof windowControl.monitor === "function" ? windowControl.monitor(windowControl.foreground()) : 0;
    if (handle) {
        for (let i = 0; i < components.length; i++) {
            if (components[i].rootWindow && components[i].rootWindow.monitorHandle === handle)
                return components[i];
        }
    }
    const monitor = hypr.focusedMonitor;
    for (let i = 0; i < components.length; i++) {
        if (hypr.monitorFor(components[i].modelData) === monitor)
            return components[i];
    }
    return null;
}

function find(cutils, rootItem, rootWindow, name, mode) {
    const item = rootItem || (rootWindow ? rootWindow.contentItem : null);
    if (mode === 0)
        return cutils.findChild(item, name);
    if (mode === 1)
        return cutils.findChildren(item, name);
    return cutils.findChildrenMatching(item, name);
}
